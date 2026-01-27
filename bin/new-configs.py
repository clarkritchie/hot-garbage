#!/usr/bin/env python3
import os
import shutil

def copy_path(src, dest, is_dir=False):
    """Copy a file or directory from src to dest."""
    if is_dir:
        if not os.path.isdir(src):
            print(f"⚠️  Warning: {src} not found")
            return
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        if os.path.exists(dest):
            shutil.rmtree(dest)
        shutil.copytree(src, dest)
        # Make hooks executable
        for item in os.listdir(dest):
            item_path = os.path.join(dest, item)
            if os.path.isfile(item_path) and not item.endswith('.sh'):
                os.chmod(item_path, 0o755)
    else:
        if not os.path.isfile(src):
            print(f"⚠️  Warning: {src} not found")
            return
        shutil.copy2(src, dest)

    print(f"✅ Copied {os.path.basename(src)} to {dest}")

paths = [
    ("~/Projects/clarkritchie/hot-garbage/configs/copilot-instructions.md", "~/Projects/dexcom-inc/sre/.github", False),
    ("~/Projects/clarkritchie/hot-garbage/configs/gitconfig", "~/.gitconfig", False),
    ("~/Projects/clarkritchie/hot-garbage/configs/Projects_main.code-workspace", "~/Projects/Projects.code-workspace", False),
    ("~/Projects/clarkritchie/hot-garbage/configs/clark-more-zsh.zshrc", "~/Projects/etc", False),
    ("~/Projects/clarkritchie/hot-garbage/configs/git-hooks", "~/.config/git/hooks", True),
]

for src, dest, is_dir in paths:
    copy_path(os.path.expanduser(src), os.path.expanduser(dest), is_dir)