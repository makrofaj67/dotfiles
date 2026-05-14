import os

css_fix = """
/* Fix for Oomox bright sidebars */
.sidebar,
placessidebar,
stack sidebar,
.sidebar list,
.sidebar row,
.sidebar grid,
treeview.sidebar {
    background-color: #0d0b09;
    color: #f1e6d8;
}

.sidebar row:selected,
placessidebar row:selected,
treeview.sidebar:selected {
    background-color: #ff9a2f;
    color: #0d0b09;
}

.sidebar row:hover,
placessidebar row:hover {
    background-color: rgba(255, 154, 47, 0.2);
}
"""

paths = [
    os.path.expanduser("~/.config/gtk-3.0/gtk.css"),
    os.path.expanduser("~/.config/gtk-4.0/gtk.css")
]

for p in paths:
    # check if already fixed
    if os.path.exists(p):
        with open(p, "r") as f:
            content = f.read()
        if "Fix for Oomox bright sidebars" not in content:
            with open(p, "a") as f:
                f.write("\n" + css_fix + "\n")
            print(f"Fixed {p}")
        else:
            print(f"Already fixed {p}")
