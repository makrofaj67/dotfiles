from libqtile.config import Group, Key
from libqtile.lazy import lazy

groups = [Group(i) for i in "123456789"]


def append_group_keys(keys: list[Key], mod: str) -> None:
    for group in groups:
        keys.extend(
            [
                # mod + group number = switch to group
                Key(
                    [mod],
                    group.name,
                    lazy.group[group.name].toscreen(),
                    desc=f"Switch to group {group.name}",
                ),
                # mod + shift + group number = switch to & move focused window to group
                Key(
                    [mod, "shift"],
                    group.name,
                    lazy.window.togroup(group.name, switch_group=True),
                    desc=f"Switch to & move focused window to group {group.name}",
                ),
            ]
        )
