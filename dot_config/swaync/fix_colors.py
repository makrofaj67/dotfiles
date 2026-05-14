import os

paths = [
    os.path.expanduser("~/.config/gtk-3.0/colors.css"),
    os.path.expanduser("~/.config/gtk-4.0/colors.css")
]

for p in paths:
    if os.path.exists(p):
        with open(p, "r") as f:
            content = f.read()
        
        # Remove '_breeze' suffix which breaks GTK theme parsing
        new_content = content.replace("_breeze", "")
        
        with open(p, "w") as f:
            f.write(new_content)
        print(f"Fixed {p}")
