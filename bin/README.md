
## update-helm-chart-version.py

`update-helm-chart-version.py` is a simple Python script to update the `version`/`appVersion` fields in a Helm chart when they change.

Use this in conjunction with a `pre-commit` hook like this (below).  Save this and make it executable in your project's `.git/hooks` directory.

```console
#!/usr/bin/env bash

# for brew python users:
# - python3 -m pip install semver

# put the complete path here or put this in your $PATH
update_script=update-helm-chart-version.py

script_path=$(dirname "$(realpath "$0")")
# Remove the last two directories from the path
base_path=$(dirname "$(dirname "$script_path")")
echo "The base path is: $base_path"

# Function to find the first Chart.yaml in any directory above the given file
find_chart_yaml() {
    dir=$(dirname "$1")
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/Chart.yaml" ]; then
            echo "$dir/Chart.yaml"
            return
        fi
        dir=$(dirname "$dir")
    done
}

# Check for changes in any files inside the charts directory
changed_files=$(git diff --cached --name-only | grep '^charts/')

if [ -n "$changed_files" ]; then
    echo "Changes detected in the following files inside the charts directory:"
    echo " - $changed_files"

    # Loop through each changed file and find the first Chart.yaml in any
    # directory above it
    for file in $changed_files; do
        chart_file=$(find_chart_yaml "$file")
        if [ -n "$chart_file" ]; then
            echo "Found Chart.yaml at $chart_file for changed file $file"
        else
            echo "No Chart.yaml found above $file"
            exit 1
        fi
    done

    # read -p "Do you want to continue with the commit? (y/n) " choice
    exec < /dev/tty
    read -p "Do you want to automatically bump the version in $chart_file? (y/n) " choice
    if [ "$choice" != "y" ]; then
        echo "Exiting..."
        exit 1
    else
       echo "before:"
       cat $chart_file
       echo "$base_path/etc/update_version.py $base_path/$chart_file"
       $update_script $base_path/$chart_file
       echo "---\nafter:"
       cat $chart_file
       git add $chart_file
    fi
    exec < /dev/tty
    read -p "Do you want to continue with the commit? (y/n) " choice
    if [ "$choice" != "y" ]; then
        echo "Exiting..."
        exit 1
    fi
else
    echo "No changes detected in Chart.yaml files inside the charts directory."
fi
```