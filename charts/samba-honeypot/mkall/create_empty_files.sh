#!/bin/sh

set -x

if [ "$#" -ne 1 ]; then
  echo "Usage: create_empty_files.sh <file_list>"
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "File not found: $1"
  exit 1
fi

while read line; do
    # Split the line into its components
    path=$(echo "$line" | cut -d '|' -f 1)
    ctime=$(echo "$line" | cut -d '|' -f 2)
    size=$(echo "$line" | cut -d '|' -f 3)

    dir=$(dirname "$path")
    [ -d "$dir" ] || mkdir -p "$dir"

    # Create the file with the specified size and set the ctime
    truncate -s "$size" "$path"
    touch -d "$ctime" "$path"
done < "$1"

chown -R nobody:nobody /shares/public
chmod -R 0755 /shares/public
chown -R nobod:nobody /shares/guest
chmod -R 0777 /shares/guest

mkdir -p /var/log/samba