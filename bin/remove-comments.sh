#!/usr/bin/env bash

input_file=$1
output_file=$(mktemp)

# Use sed to remove comments
sed '/^\s*#/d;/^\s*$/d' "$input_file" > "$output_file"
mv $input_file $input_file.bak
mv $output_file $input_file
ruff format $input_file

echo "Comments removed and saved to $output_file"