#!/usr/bin/env python3
import os
import shutil

config_files = [
    (os.path.expanduser("~/Projects/clarkritchie/hot-garbage/configs/copilot-instructions.md"), os.path.expanduser("~/Projects/dexcom-inc/sre/.github")),
    (os.path.expanduser("~/Projects/clarkritchie/hot-garbage/configs/copilot-instructions.md"), os.path.expanduser("~/Projects/dexcom-inc/database/.github")),
    (os.path.expanduser("~/Projects/clarkritchie/hot-garbage/configs/gitconfig"), os.path.expanduser("~/.gitconfig")),
    (os.path.expanduser("~/Projects/clarkritchie/hot-garbage/configs/Projects_main.code-workspace"), os.path.expanduser("~/Projects/Projects_main.code-workspace")),
    (os.path.expanduser("~/Projects/clarkritchie/hot-garbage/configs/Projects_vnv.code-workspace"), os.path.expanduser("~/Projects/Projects_vnv.code-workspace")),
]

for src, dest in config_files:
    print(f"{src} ➡️ {dest}")
    if os.path.isfile(src):
        shutil.copy2(src, dest)
        print(f"✅ Copied {os.path.basename(src)} to {dest}")
    else:
        print(f"⚠️  Warning: {src} not found")