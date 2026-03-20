#!/usr/bin/env python3
"""
Trigger CI on PRs by pushing an empty commit via the GitHub API.

Supports single PR (pass PR number as argument) or batch mode with fzf
multi-select (Tab to select multiple PRs).
"""

import json
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed


def get_repo_info() -> str:
    result = subprocess.run(
        ["git", "config", "--get", "remote.origin.url"],
        capture_output=True,
        text=True,
        check=True,
    )
    url = result.stdout.strip()
    match = re.search(r"github\.com[:/]([^/]+)/([^/\.]+)", url)
    if not match:
        print("❌ Could not parse GitHub repo from remote URL", file=sys.stderr)
        sys.exit(1)
    return f"{match.group(1)}/{match.group(2)}"


def gh(*args: str, check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(["gh", *args], capture_output=True, text=True, check=check)


def trigger_ci_via_api(pr_number: str, repo: str) -> None:
    result = gh("pr", "view", pr_number, "--json", "headRefName,headRefOid", "--jq", "{branch: .headRefName, sha: .headRefOid}")
    pr_data = json.loads(result.stdout.strip())
    branch = pr_data.get("branch", "")
    head_sha = pr_data.get("sha", "")

    if not branch or not head_sha:
        print(f"❌ PR #{pr_number}: Could not get branch or SHA", file=sys.stderr)
        return

    print(f"  → Branch: {branch}, SHA: {head_sha[:7]}")

    tree_result = gh("api", f"repos/{repo}/git/commits/{head_sha}", "--jq", ".tree.sha")
    tree_sha = tree_result.stdout.strip()

    commit_result = gh(
        "api", f"repos/{repo}/git/commits",
        "--method", "POST",
        "--field", "message=trigger ci",
        "--field", f"tree={tree_sha}",
        "--field", f"parents[]={head_sha}",
        "--jq", ".sha",
    )
    new_sha = commit_result.stdout.strip()

    gh(
        "api", f"repos/{repo}/git/refs/heads/{branch}",
        "--method", "PATCH",
        "--field", f"sha={new_sha}",
        "--silent",
    )
    print(f"✓ PR #{pr_number}: Empty commit pushed via API")


def process_pr(pr_number: str, repo: str, trigger_ci: bool, approve_pr: bool, enable_auto: bool) -> None:
    print(f"→ Processing PR #{pr_number}...")

    if trigger_ci:
        print(f"  → Triggering CI for PR #{pr_number}...")
        trigger_ci_via_api(pr_number, repo)

    if approve_pr:
        print(f"  → Attempting to approve PR #{pr_number}...")
        result = gh("pr", "review", pr_number, "--approve", check=False)
        if result.returncode == 0:
            print(f"✓ PR #{pr_number}: Approved")
        else:
            print(f"⚠ PR #{pr_number}: Approval failed or already approved")

    if enable_auto:
        print(f"  → Attempting to enable auto-merge for PR #{pr_number}...")
        result = gh("pr", "merge", pr_number, "--auto", "--squash", check=False)
        if result.returncode == 0:
            print(f"✓ PR #{pr_number}: Auto-merge enabled")
        else:
            print(f"⚠ PR #{pr_number}: Auto-merge failed (may already be enabled)")

    print()


def prompt_yes_no(question: str, default_yes: bool = False) -> bool:
    hint = "[Y/n]" if default_yes else "[y/N]"
    answer = input(f"{question} {hint}: ").strip().lower()
    if not answer:
        return default_yes
    return answer.startswith("y")


def fetch_unapproved_prs() -> list[tuple[str, str]]:
    result = gh(
        "pr", "list",
        "--state", "open",
        "--limit", "50",
        "--json", "number,title,reviewDecision",
        "--jq", r'.[] | select(.reviewDecision != "APPROVED") | "\(.number)\t\(.title)"',
    )
    lines = result.stdout.strip().splitlines()
    prs = []
    for line in lines:
        parts = line.split("\t", 1)
        if len(parts) == 2:
            prs.append((parts[0], parts[1]))
    return prs


def select_with_fzf(prs: list[tuple[str, str]]) -> list[str]:
    lines = "\n".join(f"{num}\t{title}" for num, title in prs)
    result = subprocess.run(
        ["fzf", "--multi", "--height=20", "--reverse", "--header=Select PRs (Tab to select multiple, Enter to confirm, ESC to exit)"],
        input=lines,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0 or not result.stdout.strip():
        return []
    return [line.split("\t", 1)[0] for line in result.stdout.strip().splitlines()]


def main() -> None:
    args = sys.argv[1:]

    if args and args[0] in ("-h", "--help"):
        print("Usage: prs.py [PR_NUMBER]")
        print("Triggers CI on a PR by pushing an empty commit using GitHub API")
        print()
        print("Supports batch processing with fzf multi-select (Tab to select multiple PRs)")
        sys.exit(0)

    repo = get_repo_info()

    if args:
        pr_number = args[0]
        trigger = prompt_yes_no("Trigger CI?", default_yes=True)
        approve = prompt_yes_no("Approve?", default_yes=False)
        auto = prompt_yes_no("Auto-merge?", default_yes=False)
        process_pr(pr_number, repo, trigger, approve, auto)
        return

    # Batch mode — requires fzf
    if subprocess.run(["command", "-v", "fzf"], capture_output=True, shell=False).returncode != 0:
        result = subprocess.run(["which", "fzf"], capture_output=True)
        if result.returncode != 0:
            print("❌ fzf is required for batch processing")
            print("Install with: brew install fzf")
            sys.exit(1)

    while True:
        print()
        print("→ Fetching unapproved PRs, using Python...")
        prs = fetch_unapproved_prs()

        if not prs:
            print("✓ No unapproved open PRs found")
            break

        selected = select_with_fzf(prs)

        if not selected:
            print()
            print("✓ Done")
            break

        count = len(selected)
        print()
        print(f"Selected {count} PR(s)")
        print()

        print(f"Default actions for all {count} PR(s):")
        trigger = prompt_yes_no("  Trigger CI?", default_yes=True)
        approve = prompt_yes_no("  Approve?", default_yes=True)
        auto = prompt_yes_no("  Auto-merge?", default_yes=False)

        print()
        print(f"→ Processing {count} PR(s) in parallel (max 5 concurrent)...")
        print()

        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = {executor.submit(process_pr, pr, repo, trigger, approve, auto): pr for pr in selected}
            for future in as_completed(futures):
                future.result()

        print(f"✓ Completed processing {count} PR(s)")


if __name__ == "__main__":
    main()
