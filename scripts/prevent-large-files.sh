#!/bin/sh

# 最大大小（单位：字节），例如 10MB
maxsize=10485760

echo "checking file size..."

for file in $(git diff --cached --name-only); do
  if [ -f "$file" ]; then
    filesize=$(wc -c <"$file")
    if [ "$filesize" -gt "$maxsize" ]; then
      echo "FS ignore lage files: $file (${filesize} bytes > 10MB)"
      git reset HEAD "$file"
    fi
  fi
done
