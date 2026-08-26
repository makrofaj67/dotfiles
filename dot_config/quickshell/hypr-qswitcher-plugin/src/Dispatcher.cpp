#include "Dispatcher.hpp"
#include "SessionManager.hpp"

#include <desktop/state/FocusState.hpp>
#include <desktop/state/WindowState.hpp>
#include <desktop/state/GlobalWindowController.hpp>
#include <state/WorkspaceState.hpp>
#include <state/MonitorState.hpp>
#include <layout/LayoutManager.hpp>
#include <layout/target/Target.hpp>
#include <render/Renderer.hpp>
#include <managers/fullscreen/FullscreenController.hpp>
#include <Compositor.hpp>
#include <cmath>

namespace Dispatcher {

static bool windowIsPinned(PHLWINDOW pWindow) {
    return pWindow && pWindow->m_pinned;
}

static bool windowIsFullscreen(PHLWINDOW pWindow) {
    return pWindow && Fullscreen::controller()->isFullscreen(pWindow);
}

static bool windowIsGrouped(PHLWINDOW pWindow) {
    return pWindow && (pWindow->m_group != nullptr);
}

static bool workspaceIsSpecial(PHLWORKSPACE ws) {
    return ws && (ws->m_isSpecialWorkspace || ws->m_id <= 0);
}

static bool isWindowDraggable(PHLWINDOW pWindow, std::string& outError) {
    if (!pWindow || !pWindow->m_isMapped) {
        outError = "Window is unmapped or invalid";
        return false;
    }
    if (windowIsFullscreen(pWindow)) {
        outError = "Fullscreen windows cannot be dragged";
        return false;
    }
    if (windowIsPinned(pWindow)) {
        outError = "Pinned windows cannot be dragged";
        return false;
    }
    if (windowIsGrouped(pWindow)) {
        outError = "Grouped windows cannot be dragged";
        return false;
    }
    if (workspaceIsSpecial(pWindow->m_workspace)) {
        outError = "Special workspace windows cannot be dragged";
        return false;
    }
    return true;
}

void setWindowFloating(PHLWINDOW pWindow, bool wantFloat) {
    if (!pWindow || !pWindow->m_isMapped)
        return;

    MutationGuard guard;

    if (pWindow->m_isFloating == wantFloat)
        return;

    if (g_layoutManager->dragController() && g_layoutManager->dragController()->target() == pWindow->layoutTarget())
        g_layoutManager->endDragTarget();

    g_layoutManager->changeFloatingMode(pWindow->layoutTarget());

    if (pWindow->m_isFloating)
        Desktop::windowState()->raise(pWindow);

    if (pWindow->m_workspace) {
        pWindow->m_workspace->updateWindows();
        pWindow->m_workspace->updateWindowData();
    }

    if (pWindow->m_monitor) {
        if (auto pMon = pWindow->m_monitor.lock())
            g_layoutManager->recalculateMonitor(pMon);
    }

    if (g_pHyprRenderer)
        g_pHyprRenderer->damageWindow(pWindow, true);
}

void restoreWindowTilingIfEligible(PHLWINDOW pWindow, bool wasFloating) {
    if (!wasFloating && pWindow && pWindow->m_isMapped && !windowIsFullscreen(pWindow) && !windowIsPinned(pWindow))
        setWindowFloating(pWindow, false);
}

static PHLMONITOR resolveTargetMonitor(const std::string& monName, PHLWINDOW pWindow) {
    if (!monName.empty()) {
        auto pMon = State::monitorState()->query().name(monName).run();
        if (pMon)
            return pMon;
        Log::logger->log(Log::WARN, "[hypr-qswitcher] Specified target monitor '{}' not found, falling back to window monitor", monName);
    }
    if (pWindow && pWindow->m_monitor)
        return pWindow->m_monitor.lock();
    return nullptr;
}

static PHLWORKSPACE resolveOrCreateWorkspace(WORKSPACEID wsId, const std::string& monName, PHLWINDOW pWindow) {
    if (wsId <= 0 || State::workspaceState()->isSpecial(wsId))
        return nullptr;

    auto pTargetWs = State::workspaceState()->query().id(wsId).run();
    if (pTargetWs)
        return pTargetWs;

    PHLMONITOR pTargetMon = resolveTargetMonitor(monName, pWindow);
    if (!pTargetMon) {
        Log::logger->log(Log::ERR, "[hypr-qswitcher] Cannot create workspace {}: No valid monitor found", wsId);
        return nullptr;
    }

    return State::workspaceState()->create(wsId, pTargetMon->m_id, std::to_string(wsId));
}

static void reconcileTiledDropPosition(PHLWINDOW pWindow, const Vector2D& targetPos) {
    if (!pWindow || pWindow->m_isFloating || !pWindow->m_workspace || !pWindow->m_isMapped)
        return;

    Vector2D pWinSize       = pWindow->sizeAnimation() ? pWindow->sizeAnimation()->value() : Vector2D(0, 0);
    Vector2D droppedCenter  = targetPos + (pWinSize / 2.0);
    Vector2D curCenter      = (pWindow->positionAnimation() ? pWindow->positionAnimation()->value() : Vector2D(0, 0)) + (pWinSize / 2.0);

    for (const auto& w : Desktop::windowState()->windows()) {
        if (!w || w == pWindow || w->m_workspace != pWindow->m_workspace || w->m_isFloating || !w->m_isMapped)
            continue;

        Vector2D otherSize   = w->sizeAnimation() ? w->sizeAnimation()->value() : Vector2D(0, 0);
        Vector2D otherPos    = w->positionAnimation() ? w->positionAnimation()->value() : Vector2D(0, 0);
        Vector2D otherCenter = otherPos + (otherSize / 2.0);

        // Check if dropped inside another window's tile bounding box
        bool insideOtherBox = (droppedCenter.x >= otherPos.x && droppedCenter.x <= otherPos.x + otherSize.x &&
                               droppedCenter.y >= otherPos.y && droppedCenter.y <= otherPos.y + otherSize.y);

        // Check spatial inversion (e.g. dropped to the right, but placed on the left)
        bool intendedRight = (droppedCenter.x > otherCenter.x);
        bool actualRight   = (curCenter.x > otherCenter.x);
        bool xInversion    = (intendedRight != actualRight && std::abs(droppedCenter.x - otherCenter.x) > 40);

        bool intendedBelow = (droppedCenter.y > otherCenter.y);
        bool actualBelow   = (curCenter.y > otherCenter.y);
        bool yInversion    = (intendedBelow != actualBelow && std::abs(droppedCenter.y - otherCenter.y) > 40);

        if (insideOtherBox || xInversion || yInversion) {
            if (pWindow->layoutTarget() && w->layoutTarget()) {
                Log::logger->log(Log::INFO, "[hypr-qswitcher] Reconciling drop position: swapping 0x{:x} with 0x{:x}", 
                                reinterpret_cast<uintptr_t>(pWindow.get()), reinterpret_cast<uintptr_t>(w.get()));
                pWindow->layoutTarget()->swap(w->layoutTarget());

                if (pWindow->m_workspace) {
                    pWindow->m_workspace->updateWindows();
                    pWindow->m_workspace->updateWindowData();
                }
                if (auto pMon = pWindow->m_monitor.lock())
                    g_layoutManager->recalculateMonitor(pMon);
                break;
            }
        }
    }
}

static void reconcilePostDropFocus(PHLWORKSPACE pCurWs, PHLWINDOW pMovedWindow, bool workspaceChanged) {
    if (!workspaceChanged) {
        if (pMovedWindow && pMovedWindow->m_isMapped)
            Desktop::focusState()->fullWindowFocus(pMovedWindow, Desktop::FOCUS_REASON_DESKTOP_STATE_CHANGE);
    } else {
        // Cross-workspace drop: maintain focus on remaining window of the active workspace or clear to nullptr
        if (pCurWs) {
            auto remainingWin = pCurWs->getFirstWindow();
            if (remainingWin && remainingWin != pMovedWindow) {
                Desktop::focusState()->fullWindowFocus(remainingWin, Desktop::FOCUS_REASON_DESKTOP_STATE_CHANGE);
            } else {
                Desktop::focusState()->fullWindowFocus(nullptr, Desktop::FOCUS_REASON_DESKTOP_STATE_CHANGE);
            }
        }
    }
}

SDispatchResult dispatchDragStart(const std::string& addrArg) {
    if (addrArg.empty())
        return SDispatchResult{.success = false, .error = "Missing window address"};

    MutationGuard guard;

    auto pWindow = SessionManager::findWindowByAddress(addrArg);
    if (!pWindow) {
        Log::logger->log(Log::ERR, "[hypr-qswitcher] dragstart FAILED: Window not found for '{}'", addrArg);
        return SDispatchResult{.success = false, .error = "Window not found: " + addrArg};
    }

    std::string errReason;
    if (!isWindowDraggable(pWindow, errReason)) {
        Log::logger->log(Log::WARN, "[hypr-qswitcher] dragstart REFUSED for '{}': {}", addrArg, errReason);
        return SDispatchResult{.success = false, .error = errReason};
    }

    if (SessionManager::findValidSession(pWindow) != nullptr)
        return SDispatchResult{.success = true};

    SWindowState state{
        .window        = pWindow,
        .wasFloating   = pWindow->m_isFloating,
        .origSize      = pWindow->sizeAnimation()->value(),
        .origPos       = pWindow->positionAnimation()->value(),
        .origWorkspace = pWindow->m_workspace ? pWindow->m_workspace->m_id : 1,
        .lastSeq       = 0,
    };

    SessionManager::createSession(pWindow, state);
    std::string canonicalAddr = getWindowAddrStr(pWindow);

    Log::logger->log(Log::INFO, "[hypr-qswitcher] dragstart: window={}, wasFloating={}, origWs={}", canonicalAddr, state.wasFloating, state.origWorkspace);

    if (!state.wasFloating) {
        setWindowFloating(pWindow, true);
        pWindow->sizeAnimation()->setValueAndWarp(state.origSize);
        pWindow->positionAnimation()->setValueAndWarp(state.origPos);
    }

    if (g_pHyprRenderer)
        g_pHyprRenderer->damageWindow(pWindow, true);

    return SDispatchResult{.success = true};
}

SDispatchResult dispatchDragMove(long long seq, const std::string& addrArg, WORKSPACEID wsId, double targetX, double targetY) {
    if (!std::isfinite(targetX) || !std::isfinite(targetY))
        return SDispatchResult{.success = false, .error = "Non-finite coordinates provided"};

    MutationGuard guard;

    auto pWindow = SessionManager::findWindowByAddress(addrArg);
    if (!pWindow)
        return SDispatchResult{.success = false, .error = "Window not found: " + addrArg};

    auto* pSession = SessionManager::findValidSession(pWindow);
    if (!pSession)
        return SDispatchResult{.success = true};

    if (seq > 0 && seq <= pSession->lastSeq)
        return SDispatchResult{.success = true};
    if (seq > 0)
        pSession->lastSeq = seq;

    if (g_pHyprRenderer)
        g_pHyprRenderer->damageWindow(pWindow, true);

    pWindow->positionAnimation()->setValueAndWarp(Vector2D(targetX, targetY));

    if (g_pHyprRenderer)
        g_pHyprRenderer->damageWindow(pWindow, true);

    return SDispatchResult{.success = true};
}

SDispatchResult dispatchDrop(const std::string& addrArg, WORKSPACEID wsId, double targetX, double targetY, const std::string& monName) {
    if (!std::isfinite(targetX) || !std::isfinite(targetY))
        return SDispatchResult{.success = false, .error = "Non-finite coordinates provided"};

    MutationGuard guard;

    Log::logger->log(Log::INFO, "[hypr-qswitcher] C++ typed drop requested for '{}' to ws={}, pos=({}, {}), mon='{}'", addrArg, wsId, targetX, targetY, monName);

    auto pWindow = SessionManager::findWindowByAddress(addrArg);
    if (!pWindow) {
        SessionManager::eraseSession(addrArg);
        Log::logger->log(Log::ERR, "[hypr-qswitcher] drop FAILED: Window vanished for '{}'", addrArg);
        return SDispatchResult{.success = false, .error = "Window disappeared: " + addrArg};
    }

    auto* pSession = SessionManager::findValidSession(pWindow);
    if (!pSession) {
        std::string canonicalAddr = getWindowAddrStr(pWindow);
        Log::logger->log(Log::INFO, "[hypr-qswitcher] drop: auto-creating drag session fallback for {}", canonicalAddr);
        dispatchDragStart(canonicalAddr);
        pSession = SessionManager::findValidSession(pWindow);
    }

    const bool wasFloating = pSession ? pSession->wasFloating : false;

    // Transactional check: Resolve target workspace BEFORE session erasure
    const bool workspaceChanged = (!windowIsPinned(pWindow) && pWindow->m_workspace && pWindow->m_workspace->m_id != wsId);
    PHLWORKSPACE pTargetWs = nullptr;
    if (workspaceChanged) {
        pTargetWs = resolveOrCreateWorkspace(wsId, monName, pWindow);
        if (!pTargetWs) {
            Log::logger->log(Log::ERR, "[hypr-qswitcher] drop FAILED: Could not resolve/create workspace {}", wsId);
            return SDispatchResult{.success = false, .error = "Failed to resolve target workspace"};
        }
    }

    // Safely consume session
    SessionManager::eraseSession(getWindowAddrStr(pWindow));

    if (g_pHyprRenderer)
        g_pHyprRenderer->damageWindow(pWindow, true);

    auto pCurMon = Desktop::focusState()->monitor();
    auto pCurWs  = pCurMon ? pCurMon->m_activeWorkspace : nullptr;

    if (workspaceChanged && pTargetWs)
        Desktop::globalWindowController()->moveWindowToWorkspace(pWindow, pTargetWs);

    pWindow->positionAnimation()->setValueAndWarp(Vector2D(targetX, targetY));

    restoreWindowTilingIfEligible(pWindow, wasFloating);
    reconcileTiledDropPosition(pWindow, Vector2D(targetX, targetY));
    reconcilePostDropFocus(pCurWs, pWindow, workspaceChanged);

    if (g_pHyprRenderer)
        g_pHyprRenderer->damageWindow(pWindow, true);

    return SDispatchResult{.success = true};
}

SDispatchResult dispatchCancel(const std::string& addrArg) {
    if (addrArg.empty())
        return SDispatchResult{.success = false, .error = "Missing address"};

    MutationGuard guard;

    Log::logger->log(Log::INFO, "[hypr-qswitcher] C++ cancel requested for '{}'", addrArg);

    auto pWindow = SessionManager::findWindowByAddress(addrArg);
    if (!pWindow) {
        SessionManager::eraseSession(addrArg);
        return SDispatchResult{.success = false, .error = "Window disappeared: " + addrArg};
    }

    auto* pSession = SessionManager::findValidSession(pWindow);
    if (!pSession)
        return SDispatchResult{.success = true};

    SWindowState state = *pSession;
    SessionManager::eraseSession(getWindowAddrStr(pWindow));

    if (g_pHyprRenderer)
        g_pHyprRenderer->damageWindow(pWindow, true);

    auto pOrigWs = State::workspaceState()->query().id(state.origWorkspace).run();
    if (pOrigWs && !windowIsPinned(pWindow) && (!pWindow->m_workspace || pWindow->m_workspace->m_id != state.origWorkspace))
        Desktop::globalWindowController()->moveWindowToWorkspace(pWindow, pOrigWs);

    if (!state.wasFloating) {
        restoreWindowTilingIfEligible(pWindow, state.wasFloating);
    } else {
        pWindow->positionAnimation()->setValueAndWarp(state.origPos);
        pWindow->sizeAnimation()->setValueAndWarp(state.origSize);
    }

    if (g_pHyprRenderer)
        g_pHyprRenderer->damageWindow(pWindow, true);

    return SDispatchResult{.success = true};
}

} // namespace Dispatcher
