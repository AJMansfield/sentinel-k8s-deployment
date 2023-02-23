#!/bin/sh

set -e
script_path="$(dirname "$0")"

file_list="$1"
dir_list="$2"
base_path="$3"
base_path="${base_path:-.}" # substitute "." if blank
base_path="${base_path%/}" # strip trailing slash

usage="Usage: $0 <file_list> <dir_list> [base_path]"

if [ ! -r "$file_list" ]; then
  echo "Can't read file list: $file_list"
  echo "$usage"
  exit 1
fi
if [ ! -r "$dir_list" ]; then
  echo "Can't read directory list: $dir_list"
  echo "$usage"
  exit 1
fi
if [ ! -d "$base_path" ]; then
  echo "Directory not found: $base_path"
  echo "$usage"
  exit 1
fi

"$script_path/mkfiles.sh" "$file_list" "$base_path"
"$script_path/mkdirs.sh" "$dir_list" "$base_path"
