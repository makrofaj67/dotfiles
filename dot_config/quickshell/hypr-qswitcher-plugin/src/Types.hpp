#pragma once

#define WLR_USE_UNSTABLE

#include <plugins/PluginAPI.hpp>
#include <desktop/view/Window.hpp>
#include <SharedDefs.hpp>

#include <string>
#include <string_view>
#include <format>
#include <cctype>
#include <charconv>

using CWindow = Desktop::View::CWindow;

inline int g_pluginMutationDepth = 0;

struct MutationGuard {
    MutationGuard() {
        ++g_pluginMutationDepth;
    }
    ~MutationGuard() {
        --g_pluginMutationDepth;
    }
};

struct SWindowState {
    PHLWINDOWREF window;
    bool         wasFloating   = false;
    Vector2D     origSize      = {0, 0};
    Vector2D     origPos       = {0, 0};
    WORKSPACEID  origWorkspace = 1;
    long long    lastSeq       = 0;
};

enum class ECommandType {
    START,
    MOVE,
    DROP,
    CANCEL
};

struct SParsedCommand {
    ECommandType type    = ECommandType::MOVE;
    std::string  address;
    WORKSPACEID  wsId    = 1;
    double       x       = 0;
    double       y       = 0;
    std::string  monName;
    long long    seq     = 0;
};

// Common string & numeric utilities
inline std::string getWindowAddrStr(PHLWINDOW pWindow) {
    if (!pWindow)
        return "";
    return std::format("0x{:x}", reinterpret_cast<uintptr_t>(pWindow.get()));
}

inline std::string addrFromRaw(Desktop::View::CWindow* p) {
    if (!p)
        return "";
    return std::format("0x{:x}", reinterpret_cast<uintptr_t>(p));
}

inline bool isDigits(const std::string& s) {
    return !s.empty() && s.find_first_not_of("0123456789") == std::string::npos;
}

template <typename T>
inline bool parseNumber(std::string_view sv, T& outVal) {
    if (sv.empty())
        return false;
    auto [ptr, ec] = std::from_chars(sv.data(), sv.data() + sv.size(), outVal);
    return ec == std::errc();
}
