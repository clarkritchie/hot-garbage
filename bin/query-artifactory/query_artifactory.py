#!/usr/bin/env python3
"""
Artifactory Query Tool

Makes searching Artifactory a little less painful. Requires the jf client
to be installed and configured (that is now part of the dev-container setup).

The tool now recursively calls the Artifactory API until it finds the requested
number of tags that match the specified length criteria (default: 7 characters).

Usage:
    # Return the 5 most recent Docker tags for data-platform-validation:
    ./query_artifactory.py data-platform-validation docker

    # Return the 5 most recent Helm tags for data-platform-validation:
    ./query_artifactory.py data-platform-validation helm

    # Return the 5 most recent PyPi tags for sre-libs:
    ./query_artifactory.py sre-libs pypi

    # Return Docker tags with 8-character length:
    ./query_artifactory.py data-platform-validation docker --tag-length 8

    # Return more results:
    ./query_artifactory.py data-platform-validation docker --limit 10
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Tuple

# Initialize logger
from lib.dexcom_logging import DexcomLogging

logger = DexcomLogging(name="query-artifactory", log_to_file=False).get_logger()

try:
    from colorama import Fore, Style, init as colorama_init

    colorama_init(autoreset=True)
    HAS_COLORAMA = True
except ImportError as e:
    logger.error(f"Colorama import error: {e}")
    HAS_COLORAMA = False

    # Fallback if colorama is not available
    class Fore:
        GREEN = ""
        YELLOW = ""
        RED = ""
        CYAN = ""

    class Style:
        BRIGHT = ""
        RESET_ALL = ""


class JFrogClient:
    """Client for interacting with JFrog CLI."""

    def __init__(self):
        self.base_command = ["jf", "rt"]

    def _run_command(self, command: List[str]) -> Tuple[bool, str]:
        """Run a JFrog CLI command and return success status and output."""
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                check=True,
                timeout=30,  # 30 second timeout
            )
            return True, result.stdout
        except subprocess.CalledProcessError as e:
            logger.error(f"Error running command {' '.join(command)}: {e.stderr}")
            return False, ""
        except subprocess.TimeoutExpired:
            logger.error(f"Command timed out: {' '.join(command)}")
            return False, ""
        except FileNotFoundError:
            logger.error("Error: 'jf' command not found. Please install JFrog CLI.")
            return False, ""

    def curl(self, endpoint: str, silent: bool = True) -> Tuple[bool, str]:
        """Execute a JFrog RT curl command."""
        command = self.base_command + ["curl", endpoint]
        if silent:
            command.append("--silent")
        return self._run_command(command)

    def search(
        self,
        pattern: str,
        sort_by: str = "created",
        sort_order: str = "desc",
        limit: int = 5,
        offset: int = 0,
    ) -> List[Dict]:
        """Search for artifacts using a pattern."""
        command = self.base_command + [
            "s",
            f"--sort-by={sort_by}",
            f"--sort-order={sort_order}",
            f"--limit={limit}",
            f"--offset={offset}",
            pattern,
        ]

        success, output = self._run_command(command)
        if not success:
            return []

        try:
            return json.loads(output)
        except json.JSONDecodeError:
            logger.error("Error parsing JSON response for search")
            return []


class ArtifactoryQueryTool:
    """Main tool for querying Artifactory."""

    def __init__(self, environment: str = "dev"):
        self.client = JFrogClient()
        self.environment = environment
        self.docker_repo = f"dexcom-docker-{environment}-virtual"
        self.helm_repo = f"dexcom-helm-{environment}-virtual"
        self.pypi_repo = f"dexcom-pypi-{environment}-local"

    def query_docker(
        self, item_name: str, limit: int = 5, tag_length: int = 7
    ) -> List[str]:
        """Query Docker images and return formatted results."""
        logger.info(
            f"Fetching Docker image tags for {item_name} (filtering for {tag_length}-character tags)..."
        )

        # Recursively search for Docker artifacts until we have enough matching tags
        search_pattern = f"{self.docker_repo}/{item_name}/*"
        tag_artifacts = {}
        all_tags = set()
        offset = 0
        batch_size = 100
        max_iterations = 50  # Safety limit to prevent infinite loops

        for iteration in range(max_iterations):
            logger.debug(
                f"API call {iteration + 1}/{max_iterations}: offset={offset}, batch_size={batch_size}"
            )

            # Get batch of artifacts
            artifacts = self.client.search(
                search_pattern, limit=batch_size, offset=offset
            )

            if not artifacts:
                logger.debug(f"No more artifacts found at offset {offset}")
                break

            logger.debug(f"Found {len(artifacts)} artifacts in batch {iteration + 1}")

            # Process this batch of artifacts
            batch_tag_count = 0
            for artifact in artifacts:
                path = artifact.get("path", "")
                # Extract tag from path: dexcom-docker-dev-virtual/item/tag/...
                path_parts = path.split("/")
                if len(path_parts) >= 3:
                    tag = path_parts[2]  # Tag is the third part
                    all_tags.add(tag)
                    if len(tag) == tag_length:  # Only tags of specified length
                        batch_tag_count += 1
                        created = artifact.get("created", "")
                        # Keep the most recent artifact for each tag
                        if (
                            tag not in tag_artifacts
                            or created > tag_artifacts[tag]["created"]
                        ):
                            tag_artifacts[tag] = {
                                "created": created,
                                "artifact": artifact,
                            }

            logger.debug(
                f"Batch {iteration + 1}: found {batch_tag_count} new {tag_length}-character tags"
            )
            logger.debug(
                f"Progress: {len(tag_artifacts)}/{limit} {tag_length}-character tags found"
            )

            # Check if we have enough matching tags
            if len(tag_artifacts) >= limit:
                logger.debug(
                    f"✓ Found enough {tag_length}-character tags ({len(tag_artifacts)}) after {iteration + 1} API calls"
                )
                break

            # If we got fewer artifacts than batch_size, we've reached the end
            if len(artifacts) < batch_size:
                logger.debug(
                    f"Reached end of results (got {len(artifacts)} < {batch_size})"
                )
                break

            offset += batch_size

        # Debug logging to see what tags were found
        # logger.debug(f"All tags found: {sorted(all_tags)}")
        logger.debug(
            f"{tag_length}-character tags found: {sorted(tag_artifacts.keys())}"
        )
        logger.debug(
            f"Found {len(tag_artifacts)} unique {tag_length}-character tags out of {len(all_tags)} total tags"
        )

        if not tag_artifacts:
            logger.warning(
                f"No {tag_length}-character Docker image tags found for {item_name}"
            )
            return []

        # Format results and sort by creation date
        results = []
        for tag, data in tag_artifacts.items():
            artifact = data["artifact"]
            created = data["created"]
            sha = (artifact.get("sha1", "") or artifact.get("actualSha1", ""))[
                :8
            ] or "unknown"
            result = f"{created} {self.docker_repo}/{item_name}, Tag: {tag} (JFrog sha: {sha})"
            results.append(result)

        # Sort by timestamp (descending) and return top results
        sorted_results = sorted(results, reverse=True)[:limit]
        return sorted_results

    def query_helm(self, item_name: str, limit: int = 5) -> List[str]:
        """Query Helm charts and return formatted results."""
        search_pattern = f"{self.helm_repo}/{item_name}/*.tgz"
        artifacts = self.client.search(search_pattern, limit=limit)

        results = []
        for artifact in artifacts:
            created = artifact.get("created", "")
            path = artifact.get("path", "")

            # Extract filename and remove .tgz extension
            filename = Path(path).name
            chart_name_with_version = filename.replace(".tgz", "")

            sha = (artifact.get("sha1", "") or artifact.get("actualSha1", ""))[
                :8
            ] or "unknown"
            result = f"{created} {chart_name_with_version} (JFrog SHA: {sha})"
            results.append(result)

        return results

    def query_pypi(self, item_name: str, limit: int = 5) -> List[str]:
        """Query PyPI packages and return formatted results."""
        search_pattern = f"{self.pypi_repo}/{item_name}/*.whl"
        artifacts = self.client.search(search_pattern, limit=limit)

        results = []
        for artifact in artifacts:
            created = artifact.get("created", "")
            path = artifact.get("path", "")
            filename = Path(path).name
            sha = (artifact.get("sha1", "") or artifact.get("actualSha1", ""))[
                :8
            ] or "unknown"
            result = f"{created} {filename} (JFrog sha: {sha})"
            results.append(result)

        return results


def main():
    """Main function to parse arguments and run the query."""
    parser = argparse.ArgumentParser(
        description="Query JFrog Artifactory for artifacts",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Query Docker images (7-character tags)
  python query_artifactory.py data-platform-validation docker

  # Query Docker images with specific tag length
  python query_artifactory.py data-platform-validation docker --tag-length 8

  # Query Helm charts
  python query_artifactory.py data-platform-validation helm

  # Query PyPI packages
  python query_artifactory.py sre-libs pypi

  # Get more results
  python query_artifactory.py data-platform-validation docker --limit 10
        """,
    )

    parser.add_argument("item_name", help="Name of the item to search for")
    parser.add_argument(
        "artifact_type",
        choices=["docker", "helm", "pypi"],
        default="docker",
        nargs="?",
        help="Type of artifact to search for (default: docker)",
    )
    parser.add_argument(
        "environment",
        nargs="?",
        default="dev",
        help="Artifactory environment (default: dev)",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=5,
        help="Maximum number of results to return (default: 5)",
    )
    parser.add_argument(
        "--tag-length",
        type=int,
        default=7,
        help="Filter Docker tags by character length (default: 7)",
    )
    parser.add_argument(
        "--no-highlight",
        action="store_true",
        help="Disable highlighting of the most recent entry",
    )

    args = parser.parse_args()

    tool = ArtifactoryQueryTool(environment=args.environment)

    try:
        if args.artifact_type == "docker":
            results = tool.query_docker(args.item_name, args.limit, args.tag_length)
        elif args.artifact_type == "helm":
            results = tool.query_helm(args.item_name, args.limit)
        elif args.artifact_type == "pypi":
            results = tool.query_pypi(args.item_name, args.limit)
        else:
            logger.error(f"Unsupported artifact type: {args.artifact_type}")
            logger.error("Supported types are: docker, helm, pypi")
            sys.exit(1)

        if results:
            # Display all results with colors preserved
            for i, result in enumerate(results):
                if HAS_COLORAMA and i == 0 and not args.no_highlight:
                    # Highlight the most recent (first) result
                    print(f"{Fore.CYAN}{result}{Style.RESET_ALL}")
                else:
                    print(result)

            # Show most recent summary at the end (if highlighting is enabled)
            if not args.no_highlight:
                print()  # Add blank line
                most_recent = results[0]  # First result is most recent due to sorting
                if HAS_COLORAMA:
                    highlighted_result = f"{Fore.GREEN}{Style.BRIGHT}🔥 MOST RECENT: {most_recent}{Style.RESET_ALL}"
                    print(highlighted_result)  # Use print to preserve color formatting
                else:
                    print(f"🔥 MOST RECENT: {most_recent}")

            # Print Artifactory link
            print()
            if HAS_COLORAMA:
                print(
                    f"{Fore.YELLOW}Go to Artifactory: https://dexcom.jfrog.io/ui/packages/{args.artifact_type}:%2F%2F{args.item_name}{Style.RESET_ALL}"
                )
            else:
                print(
                    f"Go to Artifactory: https://dexcom.jfrog.io/ui/packages/{args.artifact_type}:%2F%2F{args.item_name}"
                )
        else:
            logger.warning(f"No results found for {args.item_name}")

    except KeyboardInterrupt:
        logger.error("Query interrupted by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"An error occurred: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
