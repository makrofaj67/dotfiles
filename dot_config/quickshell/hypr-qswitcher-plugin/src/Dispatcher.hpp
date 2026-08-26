#pragma once

#include "Types.hpp"
#include <string>

namespace Dispatcher {

SDispatchResult dispatchDragStart(const std::string& addrArg);

SDispatchResult dispatchDragMove(long long seq, const std::string& addrArg, WORKSPACEID wsId, double targetX, double targetY);

SDispatchResult dispatchDrop(const std::string& addrArg, WORKSPACEID wsId, double targetX, double targetY, const std::string& monName);

SDispatchResult dispatchCancel(const std::string& addrArg);

void setWindowFloating(PHLWINDOW pWindow, bool wantFloat);

void restoreWindowTilingIfEligible(PHLWINDOW pWindow, bool wasFloating);

} // namespace Dispatcher
