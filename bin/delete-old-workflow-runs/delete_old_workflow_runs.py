#!/usr/bin/env python3

#
# quick and dirty script to delete old workflow runs from a GitHub repository
# no tests, no linting, no documentation, no guarantees, no problems
#

import requests
import datetime
import os
import sys
from dotenv import load_dotenv

extra_debug = False


def list_workflows(gh_token, repo_owner, repo_name):
    """List all workflows in the repository to help identify workflow IDs/names."""
    url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/actions/workflows"
    headers = {"Authorization": f"token {gh_token}"}
    response = requests.get(url, headers=headers)
    
    if response.status_code != 200:
        print(f"Error fetching workflows: {response.status_code} - {response.text}")
        return []
        
    workflows = response.json().get("workflows", [])
    print(f"\nAvailable workflows in {repo_owner}/{repo_name}:")
    print("-" * 60)
    for workflow in workflows:
        print(f"ID: {workflow['id']:8} | Name: {workflow['name']}")
        print(f"         | File: {workflow['path']}")
        print(f"         | State: {workflow['state']}")
        print("-" * 60)
    
    return workflows


def fetch_workflow_runs(gh_token, repo_owner, repo_name, workflow_filter=None):
    page = 1
    workflow_runs = []

    while True:
        print(f"Fetching page {page} of workflow runs...")
        
        # Build URL with optional workflow filter
        if workflow_filter:
            # Can filter by workflow ID or workflow filename
            url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/actions/workflows/{workflow_filter}/runs?per_page=500&page={page}"
        else:
            url = f"https://api.github.com/repos/{repo_owner}/{repo_name}/actions/runs?per_page=500&page={page}"
            
        headers = {"Authorization": f"token {gh_token}"}
        response = requests.get(url, headers=headers)
        
        if response.status_code != 200:
            print(f"Error fetching workflow runs: {response.status_code} - {response.text}")
            break
            
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
    # Check for list-workflows command
    if len(sys.argv) > 1 and sys.argv[1] == "list-workflows":
        load_dotenv()
        gh_token = os.getenv("GH_TOKEN")
        repo_owner = os.getenv("REPO_OWNER")
        repo_name = os.getenv("REPO_NAME")
        
        if not all([gh_token, repo_owner, repo_name]):
            print("Error: Missing required environment variables for listing workflows.")
            print("Please set GH_TOKEN, REPO_OWNER, and REPO_NAME in your .env file.")
            exit(1)
            
        list_workflows(gh_token, repo_owner, repo_name)
        exit(0)
    
    # Load environment variables from .env file
    load_dotenv()

    gh_token = os.getenv("GH_TOKEN")
    repo_owner = os.getenv("REPO_OWNER")
    repo_name = os.getenv("REPO_NAME")
    days_old = int(os.getenv("DAYS_OLD", "180"))
    workflow_filter = os.getenv("WORKFLOW_FILTER")  # Optional: workflow ID or filename

    # Validate required environment variables
    if not all([gh_token, repo_owner, repo_name]):
        print("Error: Missing required environment variables.")
        print("Please set GH_TOKEN, REPO_OWNER, and REPO_NAME in your .env file or environment.")
        print("\nExample .env file:")
        print("GH_TOKEN=your_github_token_here")
        print("REPO_OWNER=your_github_username_or_org")
        print("REPO_NAME=your_repository_name")
        print("DAYS_OLD=180")
        print("WORKFLOW_FILTER=build.yml  # Optional: specific workflow file or ID")
        print("\nUsage:")
        print("python delete_old_workflow_runs.py                 # Delete old runs from all workflows")
        print("python delete_old_workflow_runs.py list-workflows  # List all available workflows")
        exit(1)

    date_threshold = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=days_old)

    if workflow_filter:
        print(f"Deleting workflow runs older than {days_old} days from {repo_owner}/{repo_name} for workflow: {workflow_filter}")
    else:
        print(f"Deleting workflow runs older than {days_old} days from {repo_owner}/{repo_name}")
    print(f"Date threshold: {date_threshold}")

    workflow_runs = fetch_workflow_runs(gh_token, repo_owner, repo_name, workflow_filter)
    print(f"Fetched {len(workflow_runs)} workflow runs.")
    delete_old_runs(workflow_runs, gh_token, repo_owner, repo_name, date_threshold, days_old)


if __name__ == "__main__":
    main()
