#!/usr/bin/env python3
import os
import shutil

skill_sources = [
    ("~/Projects/dexcom-inc/sre/.github/skills", "~/.config/opencode/skills"),
    ("~/Projects/clarkritchie/hot-garbage/skills", "~/.config/opencode/skills"),
]

# Each entry is (src, dest, is_dir).
# is_dir=True  → copy entire directory (shutil.copytree); dest is replaced if it exists
# is_dir=False → copy single file (shutil.copy2)
paths = [
    ("~/Projects/etc/api-keys.zshrc", "~/Projects/.devcontainer/local.env", False),
    ("~/Projects/clarkritchie/hot-garbage/configs/gitconfig", "~/.gitconfig", False),
    ("~/Projects/clarkritchie/hot-garbage/configs/Projects.code-workspace", "~/Projects/Projects.code-workspace", False),
    ("~/Projects/clarkritchie/hot-garbage/configs/zshrc", "~/.zshrc", False),
    ("~/Projects/clarkritchie/hot-garbage/configs/clark-zsh-aliases.zshrc", "~/Projects/etc", False),
    ("~/Projects/clarkritchie/hot-garbage/configs/git-hooks", "~/.config/git/hooks", True),
    ("~/Projects/clarkritchie/hot-garbage/configs/opencode.jsonc", "~/.config/opencode/opencode.jsonc", False),
]

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
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        shutil.copy2(src, dest)

    print(f"✅ Copied {os.path.basename(src)} to {dest}")


def sync_skills(src_root, dest_root):
    """Copy every <name>/SKILL.md directory from src_root into dest_root.

    Mirrors ~/Projects/.../.github/skills/<name>/SKILL.md into
    ~/.config/opencode/skills/<name>/SKILL.md, preserving any other files
    that live alongside SKILL.md in each skill's directory.
    """
    src_root = os.path.expanduser(src_root)
    dest_root = os.path.expanduser(dest_root)

    if not os.path.isdir(src_root):
        print(f"⚠️  Warning: {src_root} not found")
        return

    for name in sorted(os.listdir(src_root)):
        skill_src = os.path.join(src_root, name)
        skill_md = os.path.join(skill_src, "SKILL.md")
        if not os.path.isfile(skill_md):
            continue
        skill_dest = os.path.join(dest_root, name)
        copy_path(skill_src, skill_dest, is_dir=True)


print("== Configs ==")
for src, dest, is_dir in paths:
    copy_path(os.path.expanduser(src), os.path.expanduser(dest), is_dir)

print("\n== Skills ==")
for src, dest in skill_sources:
    sync_skills(src, dest)

gitconfig_local = os.path.expanduser("~/.gitconfig.local")
if not os.path.isfile(gitconfig_local):
    print(f"\n⚠️  {gitconfig_local} not found — create it with your [user] block:")
    print("  [user]")
    print("    name = Your Name")
    print("    email = you@example.com")
    print("    signingkey = YOUR_GPG_KEY")