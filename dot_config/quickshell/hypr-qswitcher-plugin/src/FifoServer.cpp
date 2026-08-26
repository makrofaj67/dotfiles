#include "FifoServer.hpp"
#include "Dispatcher.hpp"
#include <Compositor.hpp>

#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <wayland-server-core.h>
#include <cerrno>
#include <cstring>
#include <cstdlib>
#include <sstream>
#include <unordered_map>

extern HANDLE PHANDLE;

namespace FifoServer {

static wl_event_source* s_pPipeSource = nullptr;
static int              s_PipeFd      = -1;
static std::string      s_FifoPath;
static std::string      s_pipeBuffer;

static std::string resolveFifoPath() {
    const char* rd = std::getenv("XDG_RUNTIME_DIR");
    if (rd && rd[0] != '\0')
        return std::string(rd) + "/qswitcher.fifo";
    return std::format("/tmp/qswitcher-{}.fifo", getuid());
}

bool parseFifoLine(const std::string& line, SParsedCommand& cmd) {
    if (line.empty())
        return false;

    std::istringstream iss(line);
    std::string firstToken;
    if (!(iss >> firstToken))
        return false;

    if (firstToken == "START") {
        cmd.type = ECommandType::START;
        std::string token;
        if (!(iss >> token)) return false;
        if (isDigits(token)) iss >> token;
        cmd.address = token;
        return !cmd.address.empty();
    } else if (firstToken == "MOVE") {
        cmd.type = ECommandType::MOVE;
        std::string token;
        if (!(iss >> token)) return false;
        if (isDigits(token)) {
            parseNumber(token, cmd.seq);
            if (!(iss >> token)) return false;
        }
        cmd.address = token;
        std::string wsToken;
        if (!(iss >> wsToken >> cmd.x >> cmd.y)) return false;
        parseNumber(wsToken, cmd.wsId);
        return true;
    } else if (firstToken == "DROP") {
        cmd.type = ECommandType::DROP;
        std::string token;
        if (!(iss >> token)) return false;
        if (isDigits(token)) {
            parseNumber(token, cmd.seq);
            if (!(iss >> token)) return false;
        }
        cmd.address = token;
        std::string wsToken;
        if (!(iss >> wsToken >> cmd.x >> cmd.y)) return false;
        parseNumber(wsToken, cmd.wsId);
        iss >> cmd.monName;
        return true;
    } else if (firstToken == "CANCEL") {
        cmd.type = ECommandType::CANCEL;
        std::string token;
        if (!(iss >> token)) return false;
        if (isDigits(token)) iss >> token;
        cmd.address = token;
        return !cmd.address.empty();
    } else if (isDigits(firstToken)) {
        // Fallback: raw format "<seq> <addr> <ws> <x> <y>"
        cmd.type = ECommandType::MOVE;
        parseNumber(firstToken, cmd.seq);
        std::string wsToken;
        if (!(iss >> cmd.address >> wsToken >> cmd.x >> cmd.y)) return false;
        parseNumber(wsToken, cmd.wsId);
        return true;
    }
    return false;
}

void executeFifoBatch(const std::vector<SParsedCommand>& batch) {
    std::unordered_map<std::string, SParsedCommand> pendingMoves;

    auto flushPendingMoves = [&pendingMoves]() {
        for (const auto& [addr, moveCmd] : pendingMoves) {
            Dispatcher::dispatchDragMove(moveCmd.seq, moveCmd.address, moveCmd.wsId, moveCmd.x, moveCmd.y);
        }
        pendingMoves.clear();
    };

    for (const auto& cmd : batch) {
        if (cmd.type == ECommandType::MOVE) {
            pendingMoves[cmd.address] = cmd;
        } else {
            // Control event encountered: flush any accumulated MOVEs first
            flushPendingMoves();

            if (cmd.type == ECommandType::START)
                Dispatcher::dispatchDragStart(cmd.address);
            else if (cmd.type == ECommandType::DROP)
                Dispatcher::dispatchDrop(cmd.address, cmd.wsId, cmd.x, cmd.y, cmd.monName);
            else if (cmd.type == ECommandType::CANCEL)
                Dispatcher::dispatchCancel(cmd.address);
        }
    }
    flushPendingMoves();
}

void drainCompleteLines() {
    size_t lastNewline = s_pipeBuffer.find_last_of('\n');
    if (lastNewline == std::string::npos)
        return;

    std::string        completeData = s_pipeBuffer.substr(0, lastNewline);
    std::istringstream stream(completeData);
    std::string        line;
    std::vector<SParsedCommand> batch;

    while (std::getline(stream, line)) {
        while (!line.empty() && (line.back() == '\r' || line.back() == ' '))
            line.pop_back();
        if (line.empty())
            continue;

        SParsedCommand cmd;
        if (parseFifoLine(line, cmd))
            batch.push_back(cmd);
    }

    s_pipeBuffer = s_pipeBuffer.substr(lastNewline + 1);

    if (!batch.empty())
        executeFifoBatch(batch);
}

static int handlePipeData(int fd, uint32_t mask, void* /*data*/) {
    if (mask & WL_EVENT_ERROR) {
        Log::logger->log(Log::ERR, "[hypr-qswitcher] FIFO error event");
        return 0;
    }

    char buffer[4096];
    while (true) {
        const ssize_t bytes = read(fd, buffer, sizeof(buffer) - 1);
        if (bytes < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK)
                break;
            Log::logger->log(Log::ERR, "[hypr-qswitcher] FIFO read error errno={}", errno);
            s_pPipeSource = nullptr;
            return 0;
        }
        if (bytes == 0)
            break;

        s_pipeBuffer.append(buffer, static_cast<size_t>(bytes));

        if (s_pipeBuffer.size() > 16384) {
            Log::logger->log(Log::WARN, "[hypr-qswitcher] PIPE OVERFLOW ({} bytes). Keeping complete lines only.", s_pipeBuffer.size());
            drainCompleteLines();
            s_pipeBuffer.clear();
            continue;
        }

        drainCompleteLines();
    }

    return 1;
}

bool init() {
    s_FifoPath = resolveFifoPath();
    unlink(s_FifoPath.c_str());
    if (mkfifo(s_FifoPath.c_str(), 0600) != 0 && errno != EEXIST) {
        Log::logger->log(Log::ERR, "[hypr-qswitcher] Failed to mkfifo '{}': {}", s_FifoPath, strerror(errno));
        if (PHANDLE)
            HyprlandAPI::addNotification(PHANDLE, "[hypr-qswitcher] Failed to create FIFO!", CHyprColor(1.0f, 0.2f, 0.2f, 1.0f), 5000);
        return false;
    }

    s_PipeFd = open(s_FifoPath.c_str(), O_RDWR | O_NONBLOCK);
    if (s_PipeFd < 0) {
        Log::logger->log(Log::ERR, "[hypr-qswitcher] Failed to open FIFO '{}': {}", s_FifoPath, strerror(errno));
        if (PHANDLE)
            HyprlandAPI::addNotification(PHANDLE, "[hypr-qswitcher] Failed to open FIFO!", CHyprColor(1.0f, 0.2f, 0.2f, 1.0f), 5000);
        return false;
    }

    if (g_pCompositor && g_pCompositor->m_wlEventLoop) {
        s_pPipeSource = wl_event_loop_add_fd(g_pCompositor->m_wlEventLoop, s_PipeFd, WL_EVENT_READABLE, handlePipeData, nullptr);
        Log::logger->log(Log::INFO, "[hypr-qswitcher] FIFO listener on {}", s_FifoPath);
    }
    return true;
}

void cleanup() {
    if (s_pPipeSource) {
        wl_event_source_remove(s_pPipeSource);
        s_pPipeSource = nullptr;
    }
    if (s_PipeFd >= 0) {
        close(s_PipeFd);
        s_PipeFd = -1;
    }
    if (!s_FifoPath.empty())
        unlink(s_FifoPath.c_str());
    s_pipeBuffer.clear();
}

} // namespace FifoServer
