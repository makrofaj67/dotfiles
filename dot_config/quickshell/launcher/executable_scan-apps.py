#!/usr/bin/env python3
import os
import glob
import json

# Pre-index icon files for instant O(1) lookup
icon_index = {}
icon_dirs = [
    os.path.expanduser("~/.local/share/icons"),
    "/usr/share/icons/hicolor",
    "/usr/share/icons/Papirus",
    "/usr/share/icons/Adwaita",
    "/usr/share/icons/breeze",
    "/usr/share/pixmaps"
]

for d in icon_dirs:
    if not os.path.isdir(d):
        continue
    for root, _, files in os.walk(d):
        for f in files:
            name, ext = os.path.splitext(f)
            if ext.lower() in [".png", ".svg", ".xpm"]:
                key = name.lower()
                full_path = os.path.join(root, f)
                if key not in icon_index or full_path.endswith(".svg") or full_path.endswith(".png"):
                    icon_index[key] = full_path

def resolve_icon(icon_name):
    if not icon_name:
        return ""
    if os.path.isabs(icon_name) and os.path.exists(icon_name):
        return icon_name
    key = icon_name.lower()
    if key in icon_index:
        return icon_index[key]
    if "." in key:
        short = key.split(".")[-1]
        if short in icon_index:
            return icon_index[short]
    return ""

def get_glyph(name, comment, categories):
    s = f"{name} {comment} {categories}".lower()
    if any(k in s for k in ["spotify", "music", "audio", "sound", "player"]): return "󰝚"
    if any(k in s for k in ["terminal", "bash", "shell", "console", "kitty", "alacritty"]): return "󰞷"
    if any(k in s for k in ["browser", "web", "firefox", "chrome", "chromium", "brave"]): return "󰈹"
    if any(k in s for k in ["code", "editor", "nvim", "neovim", "ide", "develop", "git"]): return "󰅩"
    if any(k in s for k in ["file", "manager", "thunar", "dolphin", "nautilus", "folder"]): return "󰉋"
    if any(k in s for k in ["game", "steam", "lutris", "play"]): return "󰊴"
    if any(k in s for k in ["chat", "discord", "telegram", "slack", "message"]): return "󰭹"
    if any(k in s for k in ["setting", "config", "control", "preference"]): return "󰒓"
    if any(k in s for k in ["image", "photo", "gimp", "draw", "inkscape", "paint"]): return "󰋩"
    if any(k in s for k in ["video", "vlc", "mpv", "movie"]): return "󰕼"
    if any(k in s for k in ["document", "pdf", "office", "writer", "calc"]): return "󰈙"
    return "󰀻"

# Discover all XDG desktop directories (including Flatpak, Snap, Nix, Local)
desktop_dirs = set([
    "/usr/share/applications",
    "/usr/local/share/applications",
    os.path.expanduser("~/.local/share/applications"),
    "/var/lib/flatpak/exports/share/applications",
    os.path.expanduser("~/.local/share/flatpak/exports/share/applications"),
    "/var/lib/snapd/desktop/applications",
    os.path.expanduser("~/.nix-profile/share/applications"),
    "/nix/var/nix/profiles/default/share/applications"
])

# Add XDG_DATA_DIRS and XDG_DATA_HOME
xdg_data_dirs = os.environ.get("XDG_DATA_DIRS", "")
for d in xdg_data_dirs.split(":"):
    if d.strip():
        desktop_dirs.add(os.path.join(d.strip(), "applications"))

xdg_data_home = os.environ.get("XDG_DATA_HOME", "")
if xdg_data_home.strip():
    desktop_dirs.add(os.path.join(xdg_data_home.strip(), "applications"))

apps = []
seen_names = set()

for d in desktop_dirs:
    if not os.path.isdir(d):
        continue
    for f in glob.glob(os.path.join(d, "**/*.desktop"), recursive=True):
        if not os.path.isfile(f):
            continue
        try:
            with open(f, "r", encoding="utf-8", errors="ignore") as fp:
                content = fp.read()
            
            name, generic_name, exec_cmd, icon, comment, categories = "", "", "", "", "", ""
            nodisplay, terminal = False, False
            keywords = ""
            
            for line in content.splitlines():
                line = line.strip()
                if line.startswith("[") and line != "[Desktop Entry]":
                    break
                if line.startswith("Name=") and not name:
                    name = line.split("=", 1)[1].strip()
                elif line.startswith("GenericName=") and not generic_name:
                    generic_name = line.split("=", 1)[1].strip()
                elif line.startswith("Exec=") and not exec_cmd:
                    exec_cmd = line.split("=", 1)[1].strip()
                elif line.startswith("Icon=") and not icon:
                    icon = line.split("=", 1)[1].strip()
                elif line.startswith("Comment=") and not comment:
                    comment = line.split("=", 1)[1].strip()
                elif line.startswith("Categories=") and not categories:
                    categories = line.split("=", 1)[1].strip().replace(";", " ")
                elif line.startswith("Keywords=") and not keywords:
                    keywords = line.split("=", 1)[1].strip().replace(";", " ")
                elif line.startswith("NoDisplay=true"):
                    nodisplay = True
                elif line.startswith("Terminal=true"):
                    terminal = True

            if nodisplay or not name or not exec_cmd:
                continue

            # Combine comment and generic name for better searchability
            full_comment = comment or generic_name
            all_keywords = f"{keywords} {generic_name} {categories}".strip()

            exec_clean = " ".join([arg for arg in exec_cmd.split() if not (arg.startswith("%") and len(arg) <= 2)])
            if terminal:
                exec_clean = f"kitty -e {exec_clean}"

            if name in seen_names:
                continue
            seen_names.add(name)

            icon_path = resolve_icon(icon)
            glyph = get_glyph(name, full_comment, categories)

            apps.append({
                "name": name,
                "exec": exec_clean,
                "icon": icon_path,
                "glyph": glyph,
                "comment": full_comment,
                "keywords": all_keywords
            })
        except Exception:
            pass

apps.sort(key=lambda x: x["name"].lower())
print(json.dumps(apps))
