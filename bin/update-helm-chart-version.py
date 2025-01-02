#!/usr/bin/env python3


import sys
import json
import semver
from ruamel.yaml import YAML

if len(sys.argv) != 2:
    print("Usage: python update_version.py <yaml_file>")
    sys.exit(1)

yaml_file = sys.argv[1]

yaml = YAML()
yaml.preserve_quotes = True

# Load the YAML file while preserving the order
with open(yaml_file, 'r') as file:
    data = yaml.load(file)

# Parse the versions
app_version = data['appVersion']
version = data['version']

current_app_version = semver.VersionInfo.parse(app_version)
current_version = semver.VersionInfo.parse(version)

updated_app_version = current_app_version.bump_patch()
updated_version = current_version.bump_patch()

data['appVersion'] = str(updated_app_version)
data['version'] = str(updated_version)

# Dump the YAML file while preserving the order
with open(yaml_file, 'w') as file:
    yaml.dump(data, file)

# Print the updated versions as a JSON object for easier parsing
print(json.dumps({"appVersion": str(updated_app_version), "version": str(updated_version)}))