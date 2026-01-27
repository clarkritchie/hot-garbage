# Delete Old Workflow Runs

Delete old GitHub Actions workflow runs.

## Setup

```bash
❯ poetry install
```

## Usage

```bash
❯ poetry run python main.py \
  --gh-token "${GH_TOKEN}" \
  --repo-owner dexcom-inc \
  --repo-name sre \
  --days-old 180
```

```bash
❯ poetry run python main.py \
  --gh-token "${GH_TOKEN}" \
  --repo-owner dexcom-inc \
  --repo-name sre \
  list-workflows
```

```bash
❯ poetry run python main.py \
  --gh-token "${GH_TOKEN}" \
  --repo-owner dexcom-inc \
  --repo-name sre \
  --days-old 180 \
  --workflow-filter cloudfunction-g7-us-ios-egv-bulk-upload-udp2.yaml
```

## Options

- `--gh-token` (required)
- `--repo-owner` (required)
- `--repo-name` (required)
- `--days-old` (default: 180)
- `--workflow-filter` (optional)
