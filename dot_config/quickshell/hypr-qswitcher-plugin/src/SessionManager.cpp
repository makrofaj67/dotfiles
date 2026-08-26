#include "SessionManager.hpp"
#include <desktop/state/ViewState.hpp>

namespace SessionManager {

static std::unordered_map<std::string, SWindowState> s_windowStates;

PHLWINDOW findWindowByAddress(const std::string& addrStr) {
    if (addrStr.empty())
        return nullptr;
    std::string selector = addrStr;
    if (!selector.starts_with("address:"))
        selector = "address:" + selector;
    return Desktop::viewState()->query().selector(selector).runWindow();
}

SWindowState* findValidSession(PHLWINDOW pWindow) {
    if (!pWindow)
        return nullptr;

    std::string canonicalAddr = getWindowAddrStr(pWindow);
    auto it = s_windowStates.find(canonicalAddr);
    if (it == s_windowStates.end())
        return nullptr;

    // Strict ABA pointer identity check
    if (it->second.window.lock() != pWindow) {
        s_windowStates.erase(it);
        return nullptr;
    }

    return &it->second;
}

bool createSession(PHLWINDOW pWindow, const SWindowState& state) {
    if (!pWindow)
        return false;
    std::string canonicalAddr = getWindowAddrStr(pWindow);
    s_windowStates[canonicalAddr] = state;
    return true;
}

bool eraseSession(const std::string& addr) {
    if (addr.empty())
        return false;
    return s_windowStates.erase(addr) > 0;
}

void abortSessionExternal(const std::string& addr) {
    if (addr.empty() || g_pluginMutationDepth > 0)
        return;
    auto it = s_windowStates.find(addr);
    if (it == s_windowStates.end())
        return;
    Log::logger->log(Log::WARN, "[hypr-qswitcher] aborting drag session after external compositor change: {}", addr);
    s_windowStates.erase(it);
}

std::vector<std::string> getAllActiveAddresses() {
    std::vector<std::string> addrs;
    addrs.reserve(s_windowStates.size());
    for (const auto& [addr, state] : s_windowStates)
        addrs.push_back(addr);
    return addrs;
}

void clearAllSessions() {
    s_windowStates.clear();
}

} // namespace SessionManager
