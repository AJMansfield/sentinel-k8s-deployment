#!/bin/sh

set -e

file_list="$1"
base_path="$2"
base_path="${base_path:-.}" # substitute "." if blank
base_path="${base_path%/}" # strip trailing slash

if [ ! -r "$file_list" ]; then
  echo "Can't read file list: $file_list"
  echo "Usage: $0 <file_list> [base_path]"
  exit 1
fi
if [ ! -d "$base_path" ]; then
  echo "Directory not found: $base_path"
  echo "Usage: $0 <file_list> [base_path]"
  exit 1
fi

(
  set -x ;
  cd "$base_path" ; # for the logging
)

while read line; do
    # Split the line into its components
    path=$(echo "$line" | cut -d '|' -f 1)
    ctime=$(echo "$line" | cut -d '|' -f 2)
    size=$(echo "$line" | cut -d '|' -f 3)
    
    dir="$(dirname "$path")"
    [ -n "$size" ] && trunc_cmd="truncate -s \"$size\" \"$path\"" || trunc_cmd=''
    [ -n "$ctime" ] && ctime_cmd="touch -d \"$ctime\" \"$path\"" || ctime_cmd=''

    # Create the file with the specified size and set the ctime
    (
      cd "$base_path" ;
      set -x ;
      mkdir -p "$dir" ;
      $trunc_cmd ;
      $ctime_cmd ;
    )

done < "$file_list"
