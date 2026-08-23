#!/bin/zsh

set -euo pipefail

source_app=$1
target_app=$2
target_folder=${target_app:h}

/bin/mkdir -p "$target_folder"
if [[ -e "$target_app" || -L "$target_app" ]]; then
  timestamp=$(/bin/date '+%Y%m%d-%H%M%S')
  backup_app="${target_app%.app} precedente $timestamp.app"
  /bin/mv "$target_app" "$backup_app"
fi

/usr/bin/ditto "$source_app" "$target_app"
/usr/bin/xattr -cr "$target_app"
/usr/bin/codesign --verify --deep --strict "$target_app"
/usr/bin/touch "$target_app"
