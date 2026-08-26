#include "Types.hpp"
#include "SessionManager.hpp"
#include "Dispatcher.hpp"
#include "FifoServer.hpp"

#include <event/EventBus.hpp>
#include <lua.hpp>

inline HANDLE PHANDLE = nullptr;

static CHyprSignalListener g_pWindowCloseListener;
static CHyprSignalListener g_pWindowDestroyListener;
static CHyprSignalListener g_pWindowFullscreenListener;
static CHyprSignalListener g_pWindowPinListener;
static CHyprSignalListener g_pWindowMoveListener;
static CHyprSignalListener g_pWindowFloatingListener;
static long long           g_luaMoveSequence = 0;

// ─────────────────────────────────────────────────────────────────────────────
// Direct Typed Lua Bindings (Strict argument validation, zero string format)
// ─────────────────────────────────────────────────────────────────────────────

static int lua_dragstart(lua_State* L) {
    const char* addr = luaL_checkstring(L, 1);
    auto        res  = Dispatcher::dispatchDragStart(addr ? addr : "");
    lua_pushboolean(L, res.success);
    return 1;
}

static int lua_dragmove(lua_State* L) {
    const char* addr = luaL_checkstring(L, 1);
    WORKSPACEID ws   = static_cast<WORKSPACEID>(luaL_checkinteger(L, 2));
    double      x    = luaL_checknumber(L, 3);
    double      y    = luaL_checknumber(L, 4);
    auto        res  = Dispatcher::dispatchDragMove(++g_luaMoveSequence, addr ? addr : "", ws, x, y);
    lua_pushboolean(L, res.success);
    return 1;
}

static int lua_drop(lua_State* L) {
    const char* addr    = luaL_checkstring(L, 1);
    WORKSPACEID ws      = static_cast<WORKSPACEID>(luaL_checkinteger(L, 2));
    double      x       = luaL_checknumber(L, 3);
    double      y       = luaL_checknumber(L, 4);
    const char* monName = luaL_optstring(L, 5, "");
    auto        res     = Dispatcher::dispatchDrop(addr ? addr : "", ws, x, y, monName ? monName : "");
    lua_pushboolean(L, res.success);
    return 1;
}

static int lua_cancel(lua_State* L) {
    const char* addr = luaL_checkstring(L, 1);
    auto        res  = Dispatcher::dispatchCancel(addr ? addr : "");
    lua_pushboolean(L, res.success);
    return 1;
}

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    PHANDLE = handle;

    const std::string COMPOSITOR_HASH = __hyprland_api_get_hash();
    const std::string CLIENT_HASH     = __hyprland_api_get_client_hash();

    if (COMPOSITOR_HASH != CLIENT_HASH)
        HyprlandAPI::addNotification(PHANDLE, "[hypr-qswitcher] Mismatched Hyprland headers!", CHyprColor(1.0f, 0.2f, 0.2f, 1.0f), 5000);

    HyprlandAPI::addLuaFunction(PHANDLE, "qswitcher", "dragstart", lua_dragstart);
    HyprlandAPI::addLuaFunction(PHANDLE, "qswitcher", "dragmove", lua_dragmove);
    HyprlandAPI::addLuaFunction(PHANDLE, "qswitcher", "drop", lua_drop);
    HyprlandAPI::addLuaFunction(PHANDLE, "qswitcher", "cancel", lua_cancel);

    g_pWindowCloseListener = Event::bus()->m_events.window.close.listen([](PHLWINDOW w) {
        if (w)
            SessionManager::eraseSession(getWindowAddrStr(w));
    });

    g_pWindowDestroyListener = Event::bus()->m_events.window.destroy.listen([](const PHLWINDOWREF& ref) {
        if (CWindow* p = ref.get())
            SessionManager::eraseSession(addrFromRaw(p));
    });

    g_pWindowFullscreenListener = Event::bus()->m_events.window.fullscreen.listen([](PHLWINDOW w) {
        if (w)
            SessionManager::abortSessionExternal(getWindowAddrStr(w));
    });

    g_pWindowPinListener = Event::bus()->m_events.window.pin.listen([](PHLWINDOW w) {
        if (w)
            SessionManager::abortSessionExternal(getWindowAddrStr(w));
    });

    g_pWindowMoveListener = Event::bus()->m_events.window.moveToWorkspace.listen([](PHLWINDOW w, PHLWORKSPACE) {
        if (w)
            SessionManager::abortSessionExternal(getWindowAddrStr(w));
    });

    g_pWindowFloatingListener = Event::bus()->m_events.window.floating.listen([](PHLWINDOW w) {
        if (w)
            SessionManager::abortSessionExternal(getWindowAddrStr(w));
    });

    FifoServer::init();

    HyprlandAPI::addNotification(PHANDLE, "[hypr-qswitcher] Plugin Loaded Successfully!", CHyprColor(0.2f, 1.0f, 0.4f, 1.0f), 3000);

    return {"hypr-qswitcher", "Precision Live Switcher Backend for Quickshell", "rakman", "1.0"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    g_pWindowCloseListener      = {};
    g_pWindowDestroyListener    = {};
    g_pWindowFullscreenListener = {};
    g_pWindowPinListener        = {};
    g_pWindowMoveListener       = {};
    g_pWindowFloatingListener   = {};

    HyprlandAPI::removeLuaFunction(PHANDLE, "qswitcher", "dragstart");
    HyprlandAPI::removeLuaFunction(PHANDLE, "qswitcher", "dragmove");
    HyprlandAPI::removeLuaFunction(PHANDLE, "qswitcher", "drop");
    HyprlandAPI::removeLuaFunction(PHANDLE, "qswitcher", "cancel");

    FifoServer::cleanup();

    // Cleanly cancel and restore all active drag sessions
    auto activeAddrs = SessionManager::getAllActiveAddresses();
    for (const auto& addr : activeAddrs)
        Dispatcher::dispatchCancel(addr);

    SessionManager::clearAllSessions();
}
