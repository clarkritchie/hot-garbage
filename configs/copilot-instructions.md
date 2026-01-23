# Copilot Instructions

## Role & Behavior

- Treat me as an experienced senior engineer; keep explanations concise unless I ask for depth.
- When I request code, prioritize correctness, readability, and maintainability over cleverness.
- Always include edge cases and assumptions when generating technical content.
- When I ask for options, give 2–3 solid alternatives with pros/cons.
- Structure answers as: assumptions → solution → tradeoffs → recommendation.

## GitHub Actions

- Avoid using third party actions and if they must be used, they must have verified authors.
- Default to "small" as the "runs-on" -- not "ubuntu-latest", unless I specify otherwise.
- Use caching for dependencies where possible.
- Name checkout steps "Checkout" and use "actions/checkout@v6".
- Use title casing for job and step names.

## YAML Formatting

- Always make YAML sequences as a new line with the same indentation, starting with - followed by a space and never as comma-separated items.
- Keep lists in YAML sorted alphabetically.
- Prefer to use double quotes in YAML.

## Markdown Formatting

- Use fenced code blocks with language specified.
- Use headings and subheadings to organize content.
- Use bullet points and numbered lists for clarity.
- Prefix example shell commands in Markdown files with "❯ " for consistency.

## Python Coding Style

- Prefer clear, explicit code over magic or overly abstract patterns.
- Type hints everywhere, no wildcard imports, prefer dataclasses, use f-strings.
- Use the DexcomLogging package from sre-libs (lib.dexcom_logging import DexcomLogging).
- Always use ruamel.yaml for YAML parsing and writing in Python, never pyyaml.
- Use poetry not pip for package management in Python projects.
- For logging, install DexcomLogging (from lib.dexcom_logging import DexcomLogging) and use that logger (logger = DexcomLogging().get_logger()) -- never use print statements
- We use Python 3.12, not anything lower.
- Prefer to use the console script entry point pattern for command line programs with the main function named main.py.
- Use "make lock" to re-generate the Poetry lock file, and never "poetry lock --no-update"

## Writing Style

- Keep writing direct, technical, and professional.
- Use bullet points and concise paragraphs.
- Avoid filler or overly formal phrasing.

## Code Output Rules

- When generating code, include:
  - Comments only where they add value.
  - A quick usage example, if helpful.
- When chaging code, check if there are tests that also need to be updated.

## Tools & Stack

- Assume I use VS Code, GitHub, GitHub Actions, GCP, Kubernetes, Python, Go, Helm, Pulumi, Docker, Bash, Zsh, and common Linux utilities.
- When creating Makefiles, there are reference Makefiles in the /workspace/dexcom-inc/sre/apps/Makefile.template and /workspace/dexcom-inc/database/apps/Makefile.template

## Security

- Highlight security implications.
- Use secure defaults and OWASP guidelines.

## Avoid

- Overly verbose explanations unless I ask.
- Placeholder variables like `foo` or `bar` try to use meaningful names.
- Adding unnecessary dependencies.
- Over-engineered solutions for simple problems.

## Other

- Tell me a joke every once in a while.