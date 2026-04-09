import subprocess

from libqtile import qtile


def start_picom() -> None:
    if qtile.core.name != "x11":
        return

    subprocess.Popen([
        "picom",
        "--config",
        "/home/rakman/.config/picom/picom.conf",
    ])
