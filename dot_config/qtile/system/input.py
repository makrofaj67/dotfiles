import subprocess

from libqtile import qtile


def configure_keyboard() -> None:
    if qtile.core.name != "x11":
        return

    subprocess.run(["setxkbmap", "tr"], check=False)
