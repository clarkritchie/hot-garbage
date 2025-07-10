#!/usr/bin/env python3

#
# quick and dirty script to delete old workflow runs from a GitHub repository
# no tests, no linting, no documentation, no guarantees, no problems
#

import requests
import datetime
import os
from dotenv import load_dotenv

extra_debug = False


def fetch_workflow_runs(gh_token, repo_owner, repo_name):
    page = 1
    workflow_runs = []

    while True:
        print(f"Fetching page {page} of workflow runs...")
        url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/actions/runs?per_page=500&page={page}"
        headers = {"Authorization": f"token {gh_token}"}
        response = requests.get(url, headers=headers)
        runs = response.json().get("workflow_runs", [])

        if not runs:
            break

        workflow_runs.extend(runs)
        page += 1

    return workflow_runs


def delete_old_runs(workflow_runs, gh_token, repo_owner, repo_name, date_threshold, days_old):
    for run in workflow_runs:
        created_at = datetime.datetime.strptime(run["created_at"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=datetime.timezone.utc)
        run_id = run["id"]
        print(f"Created at: {created_at}, Date threshold: {date_threshold}") if extra_debug else None
        if created_at < date_threshold:
            print(f"Deleting run {run_id}, created at {created_at}")
            url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/actions/runs/{run_id}"
            headers = {"Authorization": f"token {gh_token}"}
            requests.delete(url, headers=headers)
        else:
            print(f"Run {run_id} is not older than {days_old} days, skipping deletion") if extra_debug else None


def main():
    """Main function to run the workflow deletion script."""
    # Load environment variables from .env file
    load_dotenv()

    gh_token = os.getenv("GH_TOKEN")
    repo_owner = os.getenv("REPO_OWNER")
    repo_name = os.getenv("REPO_NAME")
    days_old = int(os.getenv("DAYS_OLD", "180"))

    # Validate required environment variables
    if not all([gh_token, repo_owner, repo_name]):
        print("Error: Missing required environment variables.")
        print("Please set GH_TOKEN, REPO_OWNER, and REPO_NAME in your .env file or environment.")
        print("\nExample .env file:")
        print("GH_TOKEN=your_github_token_here")
        print("REPO_OWNER=your_github_username_or_org")
        print("REPO_NAME=your_repository_name")
        print("DAYS_OLD=180")
        exit(1)

    date_threshold = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=days_old)

    print(f"Deleting workflow runs older than {days_old} days from {repo_owner}/{repo_name}")
    print(f"Date threshold: {date_threshold}")

    workflow_runs = fetch_workflow_runs(gh_token, repo_owner, repo_name)
    print(f"Fetched {len(workflow_runs)} workflow runs.")
    delete_old_runs(workflow_runs, gh_token, repo_owner, repo_name, date_threshold, days_old)


if __name__ == "__main__":
    main()
