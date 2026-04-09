from libqtile import hook

from bindings.groups import append_group_keys, groups
from bindings.keys import append_vt_keys, create_base_keys
from bindings.mouse import create_mouse
from display.layouts import floating_layout, layouts
from display.screens import extension_defaults, fake_screens, generate_screens, screens, widget_defaults
from system.compositor import start_picom
from system.core import mod, terminal
from system.input import configure_keyboard
from system.settings import (
    auto_fullscreen,
    auto_minimize,
    bring_front_click,
    cursor_warp,
    dgroups_app_rules,
    dgroups_key_binder,
    floats_kept_above,
    focus_on_window_activation,
    focus_previous_on_window_remove,
    follow_mouse_focus,
    idle_inhibitors,
    idle_timers,
    reconfigure_screens,
    wl_input_rules,
    wl_xcursor_size,
    wl_xcursor_theme,
    wmname,
)

keys = create_base_keys(mod, terminal)
append_vt_keys(keys)
append_group_keys(keys, mod)


@hook.subscribe.startup_once
def set_x11_keyboard_layout() -> None:
    configure_keyboard()
    start_picom()


# Drag floating layouts.
mouse = create_mouse(mod)
