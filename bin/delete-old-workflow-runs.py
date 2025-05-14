#!/usr/bin/env python3

#
# quick and dirty script to delete old workflow runs from a GitHub repository
# no tests, no linting, no documentation, no guarantees, no problems
#

import requests
import datetime
import os

GH_TOKEN = os.getenv("GH_TOKEN")
REPO_OWNER = os.getenv("REPO_OWNER")
REPO_NAME = os.getenv("REPO_NAME")
DAYS_OLD = 180

date_threshold = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(
    days=DAYS_OLD
)


def fetch_workflow_runs():
    page = 1
    workflow_runs = []

    while True:
        print(f"Fetching page {page} of workflow runs...")
        url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/actions/runs?per_page=500&page={page}"
        headers = {"Authorization": f"token {GH_TOKEN}"}
        response = requests.get(url, headers=headers)
        runs = response.json().get("workflow_runs", [])

        if not runs:
            break

        workflow_runs.extend(runs)
        page += 1

    return workflow_runs


def delete_old_runs(workflow_runs):
    for run in workflow_runs:
        created_at = datetime.datetime.strptime(
            run["created_at"], "%Y-%m-%dT%H:%M:%SZ"
        ).replace(tzinfo=datetime.timezone.utc)
        run_id = run["id"]
        print(f"Created at: {created_at}, Date threshold: {date_threshold}")
        if created_at < date_threshold:
            print(f"Deleting run {run_id}, created at {created_at}")
            url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/actions/runs/{run_id}"
            headers = {"Authorization": f"token {GH_TOKEN}"}
            requests.delete(url, headers=headers)
        else:
            print(f"Run {run_id} is not older than {DAYS_OLD} days, skipping deletion")


workflow_runs = fetch_workflow_runs()
print(f"Fetched {len(workflow_runs)} workflow runs.")
delete_old_runs(workflow_runs)
