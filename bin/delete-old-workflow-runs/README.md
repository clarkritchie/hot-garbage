# Delete Old Workflow Runs

Quick and dirty script to delete old workflow runs from a GitHub repository.

No tests, no linting, no documentation, no guarantees, no problems.

## Setup

1. Install dependencies with Poetry:

   ```bash
   poetry install
   ```

2. Copy the example environment file and configure it:

   ```bash
   cp .env.example .env
   ```

3. Edit `.env` with your GitHub details:

   ```env
   GH_TOKEN=your_github_personal_access_token
   REPO_OWNER=your_github_username_or_org
   REPO_NAME=your_repository_name
   DAYS_OLD=180
   ```

## Usage

### With Poetry

```bash
# Run directly with Poetry
poetry run delete-old-workflow-runs

# Or enter the virtual environment
poetry shell
delete-old-workflow-runs
```

### As a Python module

```bash
poetry run python delete_old_workflow_runs.py
```

## Configuration

- `GH_TOKEN`: GitHub Personal Access Token with repo and actions permissions
- `REPO_OWNER`: GitHub username or organization name
- `REPO_NAME`: Repository name
- `DAYS_OLD`: Number of days to keep workflow runs (default: 180)

## GitHub Token Requirements

Your GitHub token needs the following permissions:

- `repo` (full repository access)
- `actions` (manage workflow runs)

Create a token at: <https://github.com/settings/tokens>
