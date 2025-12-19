# Query Artifactory Tool

Makes searching Artifactory a little less painful. Requires the jf client to be installed and configured (that is now part of the dev-container setup).

The tool now recursively calls the Artifactory API until it finds the requested number of tags that match the specified length criteria.

## Usage

### Command Line

```bash
# Return the 5 most recent Docker tags for data-platform-validation:
poetry run python query_artifactory.py data-platform-validation docker

# Return the 5 most recent Helm tags for data-platform-validation:
poetry run python query_artifactory.py data-platform-validation helm

# Return the 5 most recent PyPI tags for sre-libs:
poetry run python query_artifactory.py sre-libs pypi

# Return Docker tags with custom tag length:
poetry run python query_artifactory.py data-platform-validation docker --tag-length 8

# Return more results:
poetry run python query_artifactory.py data-platform-validation docker --limit 10
```

### Interactive Mode

```bash
# Run interactively with menu options:
./run.zsh

# Run interactively with extra arguments:
./run.zsh --limit 10 --tag-length 8
```

The interactive mode now allows you to:

- Select from predefined common options for Docker, Helm, and PyPI artifacts
- Enter custom names for any artifact type
- Pass additional arguments like `--limit` and `--tag-length`

## Docker and Helm Options Management

The Docker and Helm options lists are automatically generated from the repository structure:

- **Docker options**: Scans `sre/apps` and `database/apps` for directories containing Dockerfiles
- **Helm options**: Scans `sre/charts` and `database/charts` for directories containing Chart.yaml

To regenerate both options lists:

```bash
./generate-options.zsh
# or
make options
```

This will create/update the `.docker-options` and `.helm-options` files with all available applications. These files are auto-generated and should not be edited manually.

## Makefile Targets

- `make test` - Run tests
- `make lint` - Run linting
- `make run` - Run the tool interactively
- `make docker` - Quick Docker queries
- `make helm` - Quick Helm queries
- `make pypi` - Quick PyPI queries

## Development

Uses Poetry for dependency management and DexcomLogger for logging.

## Dependencies

- `sre-libs` - For DexcomLogger
- `jf` CLI tool - For Artifactory API access
