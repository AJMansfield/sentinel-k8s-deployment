#!/bin/sh

set -e

dir_list="$1"
base_path="$2"
base_path="${base_path:-.}" # substitute "." if blank
base_path="${base_path%/}" # strip trailing slash

if [ ! -r "$dir_list" ]; then
  echo "Can't read directory list: $dir_list"
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
    owner=$(echo "$line" | cut -d '|' -f 2)
    attrs=$(echo "$line" | cut -d '|' -f 3)

    [ -n "$owner" ] && chown_cmd="chown -R -H -c $owner $path" || chown_cmd=''
    [ -n "$attrs" ] && chmod_cmd="chmod -R -c $attrs $path" || chmod_cmd=''

    # recursively create, chown, and chmod the specified directories
    (
      cd "$base_path" ;
      set -x ;
      mkdir -p "$path" ;
      $chown_cmd ;
      $chmod_cmd ;
    )

done < "$dir_list"
