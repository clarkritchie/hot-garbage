"""
Tests for query_artifactory module.

Since this tool requires JFrog CLI and Artifactory access,
these tests focus on unit testing the components that can be
tested without external dependencies.
"""

import unittest
from unittest.mock import Mock, patch
import sys
import os

# Add the parent directory to the path so we can import the module
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from query_artifactory import JFrogClient, ArtifactoryQueryTool


class TestJFrogClient(unittest.TestCase):
    """Test the JFrogClient class."""

    def setUp(self):
        """Set up test fixtures."""
        self.client = JFrogClient()

    def test_init(self):
        """Test JFrogClient initialization."""
        self.assertEqual(self.client.base_command, ["jf", "rt"])

    @patch("subprocess.run")
    def test_run_command_success(self, mock_run):
        """Test successful command execution."""
        mock_result = Mock()
        mock_result.stdout = '{"test": "data"}'
        mock_run.return_value = mock_result

        success, output = self.client._run_command(["test", "command"])

        self.assertTrue(success)
        self.assertEqual(output, '{"test": "data"}')
        mock_run.assert_called_once()

    @patch("subprocess.run")
    def test_run_command_timeout(self, mock_run):
        """Test command timeout handling."""
        from subprocess import TimeoutExpired

        mock_run.side_effect = TimeoutExpired("cmd", 30)

        success, output = self.client._run_command(["test", "command"])

        self.assertFalse(success)
        self.assertEqual(output, "")

    @patch("subprocess.run")
    def test_run_command_file_not_found(self, mock_run):
        """Test file not found error handling."""
        mock_run.side_effect = FileNotFoundError()

        success, output = self.client._run_command(["test", "command"])

        self.assertFalse(success)
        self.assertEqual(output, "")

    def test_curl_command_construction(self):
        """Test curl command construction."""
        with patch.object(self.client, "_run_command") as mock_run:
            mock_run.return_value = (True, "success")

            self.client.curl("/test/endpoint")

            expected_command = ["jf", "rt", "curl", "/test/endpoint", "--silent"]
            mock_run.assert_called_once_with(expected_command)

    def test_search_command_construction(self):
        """Test search command construction."""
        with patch.object(self.client, "_run_command") as mock_run:
            mock_run.return_value = (True, "[]")

            self.client.search("pattern/*", limit=10)

            expected_command = [
                "jf",
                "rt",
                "s",
                "--sort-by=created",
                "--sort-order=desc",
                "--limit=10",
                "--offset=0",
                "pattern/*",
            ]
            mock_run.assert_called_once_with(expected_command)

    def test_search_with_offset(self):
        """Test search method with offset parameter."""
        with patch.object(self.client, "_run_command") as mock_run:
            mock_run.return_value = (True, "[]")

            result = self.client.search("test/*", offset=50)

            self.assertEqual(result, [])
            # Verify offset was included in command
            call_args = mock_run.call_args[0][0]
            self.assertIn("--offset=50", call_args)


class TestArtifactoryQueryTool(unittest.TestCase):
    """Test the ArtifactoryQueryTool class."""

    def setUp(self):
        """Set up test fixtures."""
        self.tool = ArtifactoryQueryTool()

    def test_init(self):
        """Test ArtifactoryQueryTool initialization."""
        self.assertIsInstance(self.tool.client, JFrogClient)
        self.assertEqual(self.tool.docker_repo, "dexcom-docker-dev-virtual")
        self.assertEqual(self.tool.helm_repo, "dexcom-helm-dev-virtual")
        self.assertEqual(self.tool.pypi_repo, "dexcom-pypi-dev-local")

    @patch.object(JFrogClient, "search")
    def test_query_docker_no_artifacts(self, mock_search):
        """Test Docker query when no artifacts are found."""
        mock_search.return_value = []

        results = self.tool.query_docker("test-item")

        self.assertEqual(results, [])

    @patch.object(JFrogClient, "search")
    def test_query_docker_with_7_char_tags(self, mock_search):
        """Test Docker query with 7-character tags."""
        mock_artifacts = [
            {
                "path": "dexcom-docker-dev-virtual/test-item/abc1234/manifest.json",
                "created": "2025-01-01T10:00:00.000Z",
                "sha1": "abcdef1234567890",
            },
            {
                "path": "dexcom-docker-dev-virtual/test-item/xyz9876/manifest.json",
                "created": "2025-01-02T10:00:00.000Z",
                "sha1": "1234567890abcdef",
            },
        ]
        mock_search.return_value = mock_artifacts

        results = self.tool.query_docker("test-item", limit=2)

        self.assertEqual(len(results), 2)
        # Should be sorted by timestamp descending
        self.assertIn("xyz9876", results[0])
        self.assertIn("abc1234", results[1])

    @patch.object(JFrogClient, "search")
    def test_query_helm(self, mock_search):
        """Test Helm query."""
        mock_artifacts = [
            {
                "path": "dexcom-helm-dev-virtual/test-chart/test-chart-1.0.0.tgz",
                "created": "2025-01-01T10:00:00.000Z",
                "sha1": "abcdef1234567890",
            }
        ]
        mock_search.return_value = mock_artifacts

        results = self.tool.query_helm("test-chart")

        self.assertEqual(len(results), 1)
        self.assertIn("test-chart-1.0.0", results[0])

    @patch.object(JFrogClient, "search")
    def test_query_pypi(self, mock_search):
        """Test PyPI query."""
        mock_artifacts = [
            {
                "path": "dexcom-pypi-dev-local/test-package/test_package-1.0.0-py3-none-any.whl",
                "created": "2025-01-01T10:00:00.000Z",
                "sha1": "abcdef1234567890",
            }
        ]
        mock_search.return_value = mock_artifacts

        results = self.tool.query_pypi("test-package")

        self.assertEqual(len(results), 1)
        self.assertIn("test_package-1.0.0-py3-none-any.whl", results[0])

    @patch.object(JFrogClient, "search")
    def test_query_docker_with_custom_tag_length(self, mock_search):
        """Test Docker query with custom tag length."""
        mock_artifacts = [
            {
                "path": "dexcom-docker-dev-virtual/test-item/abc12345/manifest.json",
                "created": "2025-01-01T10:00:00.000Z",
                "sha1": "abcdef1234567890",
            },
            {
                "path": "dexcom-docker-dev-virtual/test-item/xyz9876/manifest.json",
                "created": "2025-01-02T10:00:00.000Z",
                "sha1": "1234567890abcdef",
            },
            {
                "path": "dexcom-docker-dev-virtual/test-item/longertag/manifest.json",
                "created": "2025-01-03T10:00:00.000Z",
                "sha1": "fedcba0987654321",
            },
        ]
        mock_search.return_value = mock_artifacts

        # Test with 8-character tags
        results = self.tool.query_docker("test-item", limit=5, tag_length=8)

        self.assertEqual(len(results), 1)
        self.assertIn("abc12345", results[0])

    @patch.object(JFrogClient, "search")
    def test_query_docker_recursive_calls(self, mock_search):
        """Test Docker query with recursive API calls to find enough tags."""
        # First call returns some artifacts but not enough 7-char tags
        first_batch = [
            {
                "path": "dexcom-docker-dev-virtual/test-item/longtag/manifest.json",
                "created": "2025-01-01T10:00:00.000Z",
                "sha1": "abcdef1234567890",
            }
        ] * 100  # 100 artifacts, none with 7-char tags

        # Second call returns artifacts with 7-char tags
        second_batch = [
            {
                "path": "dexcom-docker-dev-virtual/test-item/abc1234/manifest.json",
                "created": "2025-01-02T10:00:00.000Z",
                "sha1": "1234567890abcdef",
            },
            {
                "path": "dexcom-docker-dev-virtual/test-item/xyz9876/manifest.json",
                "created": "2025-01-03T10:00:00.000Z",
                "sha1": "fedcba0987654321",
            },
        ]

        # Mock search to return different results on subsequent calls
        mock_search.side_effect = [first_batch, second_batch]

        results = self.tool.query_docker("test-item", limit=2, tag_length=7)

        # Should have made 2 API calls
        self.assertEqual(mock_search.call_count, 2)
        # Should find the 2 tags from second batch
        self.assertEqual(len(results), 2)
        self.assertIn("xyz9876", results[0])  # Most recent first
        self.assertIn("abc1234", results[1])


if __name__ == "__main__":
    unittest.main()
