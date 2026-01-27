#!/usr/bin/env python3

from __future__ import annotations

import argparse
import datetime
from typing import Iterable

import requests
import logging

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)


class WorkflowRunError(RuntimeError):
    """Raised when workflow run operations fail."""


def list_workflows(gh_token: str, repo_owner: str, repo_name: str) -> list[dict[str, str]]:
    """List all workflows in the repository to help identify workflow IDs/names."""
    url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/actions/workflows"
    headers = {"Authorization": f"token {gh_token}"}
    response = requests.get(url, headers=headers, timeout=30)

    if response.status_code != 200:
        raise WorkflowRunError(f"Error fetching workflows: {response.status_code} - {response.text}")

    workflows = response.json().get("workflows", [])
    logger.info("Available workflows in %s/%s:", repo_owner, repo_name)
    for workflow in workflows:
        logger.info(
            "ID: %s | Name: %s | File: %s | State: %s",
            workflow.get("id"),
            workflow.get("name"),
            workflow.get("path"),
            workflow.get("state"),
        )

    return workflows


def fetch_workflow_runs(
    gh_token: str,
    repo_owner: str,
    repo_name: str,
    workflow_filter: str | None = None,
) -> list[dict[str, str]]:
    page = 1
    workflow_runs: list[dict[str, str]] = []

    while True:
        logger.info("Fetching page %s of workflow runs...", page)

        if workflow_filter:
            url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/actions/workflows/{workflow_filter}/runs?per_page=500&page={page}"
        else:
            url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/actions/runs?per_page=500&page={page}"

        headers = {"Authorization": f"token {gh_token}"}
        response = requests.get(url, headers=headers, timeout=30)

        if response.status_code != 200:
            raise WorkflowRunError(f"Error fetching workflow runs: {response.status_code} - {response.text}")

        runs = response.json().get("workflow_runs", [])
        if not runs:
            break

        workflow_runs.extend(runs)
        page += 1

    return workflow_runs


def delete_runs(
    runs_to_delete: Iterable[dict[str, str]],
    gh_token: str,
    repo_owner: str,
    repo_name: str,
) -> None:
    """Deletes a list of workflow runs."""
    headers = {"Authorization": f"token {gh_token}"}
    for run in runs_to_delete:
        run_id = run["id"]
        logger.info("Deleting run %s, created at %s", run_id, run["created_at"])
        url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/actions/runs/{run_id}"
        response = requests.delete(url, headers=headers, timeout=30)
        if response.status_code not in {204, 202}:
            logger.warning(
                "Failed to delete run %s: %s - %s",
                run_id,
                response.status_code,
                response.text,
            )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Delete old GitHub Actions workflow runs.")
    subparsers = parser.add_subparsers(dest="command")

    subparsers.add_parser("list-workflows", help="List workflows in the repository")

    parser.add_argument(
        "--gh-token",
        required=True,
        help="GitHub token with actions:read and actions:write",
    )
    parser.add_argument("--repo-owner", required=True, help="Repository owner")
    parser.add_argument("--repo-name", required=True, help="Repository name")
    parser.add_argument(
        "--days-old",
        type=int,
        default=180,
        help="Delete runs older than this many days",
    )
    parser.add_argument(
        "--workflow-filter",
        help="Workflow ID or filename to filter runs",
    )

    return parser.parse_args()


def run_list_workflows(gh_token: str, repo_owner: str, repo_name: str) -> int:
    list_workflows(gh_token, repo_owner, repo_name)
    return 0


def run_delete_workflow_runs(
    gh_token: str,
    repo_owner: str,
    repo_name: str,
    days_old: int,
    workflow_filter: str | None,
) -> int:
    date_threshold = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=days_old)

    if workflow_filter is not None:
        logger.info(
            "Deleting workflow runs older than %s days from %s/%s for workflow: %s",
            days_old,
            repo_owner,
            repo_name,
            workflow_filter,
        )
    else:
        logger.info(
            "Deleting workflow runs older than %s days from %s/%s",
            days_old,
            repo_owner,
            repo_name,
        )
    logger.info("Date threshold: %s", date_threshold)

    workflow_runs = fetch_workflow_runs(gh_token, repo_owner, repo_name, workflow_filter)
    logger.info("Fetched %s workflow runs.", len(workflow_runs))

    runs_to_delete = []
    for run in workflow_runs:
        created_at = datetime.datetime.strptime(run["created_at"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
        if created_at < date_threshold:
            runs_to_delete.append(run)

    if not runs_to_delete:
        logger.info("No workflow runs found older than the threshold. Nothing to delete.")
        return 0

    logger.info("Found %s workflow run(s) to delete.", len(runs_to_delete))
    confirm = input("Are you sure you want to permanently delete these workflow runs? (yes/no): ")
    if confirm.lower() != "yes":
        logger.info("Deletion cancelled by user.")
        return 0

    delete_runs(runs_to_delete, gh_token, repo_owner, repo_name)
    return 0


def main() -> int:
    """Console script entrypoint."""
    args = parse_args()

    try:
        if args.command == "list-workflows":
            return run_list_workflows(args.gh_token, args.repo_owner, args.repo_name)

        return run_delete_workflow_runs(
            args.gh_token,
            args.repo_owner,
            args.repo_name,
            args.days_old,
            args.workflow_filter,
        )
    except WorkflowRunError as exc:
        logger.error("%s", exc)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
