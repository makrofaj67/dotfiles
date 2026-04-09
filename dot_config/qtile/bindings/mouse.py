from libqtile.config import Click, Drag
from libqtile.lazy import lazy


def create_mouse(mod: str) -> list[Drag | Click]:
    return [
        Drag(
            [mod],
            "Button1",
            lazy.window.bring_to_front(),
            lazy.window.set_position(),
            start=lazy.window.get_position(),
        ),
        Drag(
            [mod, "shift"],
            "Button3",
            lazy.window.bring_to_front(),
            lazy.window.set_size_floating(),
            start=lazy.window.get_size(),
        ),
        Drag(
            [mod, "shift"],
            "Button1",
            lazy.window.bring_to_front(),
            lazy.window.set_position_floating(),
            start=lazy.window.get_position(),
        ),
        Click([mod], "Button2", lazy.window.toggle_floating()),
    ]
