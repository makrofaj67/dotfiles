# Damnfiles

Personal Arch Linux dotfiles powered by **Hyprland** and **Quickshell**, managed with **Chezmoi**.

---

## Screenshots

<div align="center">

### Desktop
![Desktop](screenshots/desktop.png)

<br>

| Window Switcher | Lockscreen |
| :---: | :---: |
| ![Switcher](screenshots/switcher.png) | ![Lockscreen](screenshots/lockscreen.png) |
| **Notifications & Cliphist** | **Launcher & Notes** |
| ![Notifications](screenshots/notificationcliphist.png) | ![Launcher](screenshots/launcherandnotes.png) |
| **Terminal** | **Editor (Neovim)** |
| ![Terminal](screenshots/terminal.png) | ![Editor](screenshots/editor.png) |

</div>

---

## Stack & Components

- **OS:** Arch Linux
- **Compositor:** Hyprland (Lua)
- **Bar & Shell:** Quickshell (TopBar, Notifications, Switcher, Launcher, Notes)
- **Plugin:** `hypr-qswitcher-plugin` ([OC] C++)
- **Lockscreen:** `hyprlock` + `hypridle`
- **Display Manager:** SDDM
- **Qt Theme:** Darkly / hl-orange
- **GTK Theme:** Darkly-gtk / hl-orange
- **Terminal:** Kitty
- **Editor:** Neovim
- **Shell:** Fish
- **Multiplexer:** Zellij
- **File Manager:** Yazi
- **Clipboard:** CopyQ
- **Manager:** Chezmoi

---

## Installation

```bash
chezmoi init --apply https://github.com/makrofaj67/dotfiles.git
```
