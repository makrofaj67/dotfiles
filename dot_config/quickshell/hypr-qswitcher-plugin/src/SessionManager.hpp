#pragma once

#include "Types.hpp"
#include <unordered_map>
#include <vector>
#include <string>

namespace SessionManager {

PHLWINDOW findWindowByAddress(const std::string& addrStr);

SWindowState* findValidSession(PHLWINDOW pWindow);

bool createSession(PHLWINDOW pWindow, const SWindowState& state);

bool eraseSession(const std::string& addr);

void abortSessionExternal(const std::string& addr);

std::vector<std::string> getAllActiveAddresses();

void clearAllSessions();

} // namespace SessionManager
