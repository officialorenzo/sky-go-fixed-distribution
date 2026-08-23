#!/bin/zsh

set -euo pipefail

resources_dir=${0:A:h}
sky_version='26.2.3'
sky_pkg_url='https://desktopclient.ott.sky.com/skygodesktop/IT/production/26.2.3/SkyGo_production_26.2.3_it_production.pkg'
sky_pkg_sha256='fd37c637592d7e636eb24395ef212c9771f717c152aa5cb6b7229d938a6b11a4'
electron_version='41.10.3'
electron_zip_url='https://github.com/electron/electron/releases/download/v41.10.3/electron-v41.10.3-darwin-x64.zip'
electron_zip_sha256='7218af14b48457ed128f33392bf0497725300db97d474b6cca7237f0c44d847d'

status_file=${SKYGO_FIXED_STATUS_FILE:-}
destination_app=${SKYGO_FIXED_DESTINATION:-'/Applications/Sky Go Fixed.app'}
sky_override=${SKYGO_FIXED_SKY_APP:-}
electron_override=${SKYGO_FIXED_ELECTRON_APP:-}
launcher_binary="$resources_dir/SkyGoFixedLauncher"
compatibility_hook="$resources_dir/skygo-compat.js"
custom_icon="$resources_dir/SkyGo.icns"
final_info="$resources_dir/SkyGoFixedInfo.plist"
privileged_installer="$resources_dir/install-application.sh"
temp_dir=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/skygo-fixed-installer.XXXXXX")

cleanup() {
  /bin/rm -rf "$temp_dir"
}
trap cleanup EXIT

report() {
  progress=$1
  message=$2
  print -r -- "$progress|$message"
  if [[ -n "$status_file" ]]; then
    print -r -- "$progress|$message" >| "$status_file"
  fi
}

verify_sha256() {
  file_path=$1
  expected=$2
  actual=$(/usr/bin/shasum -a 256 "$file_path" | /usr/bin/awk '{print $1}')
  [[ "$actual" == "$expected" ]] || {
    print -u2 -- "Controllo SHA-256 fallito per ${file_path:t}."
    return 1
  }
}

report 0.03 'Controllo dei componenti…'
for required_file in "$launcher_binary" "$compatibility_hook" "$custom_icon" "$final_info" "$privileged_installer"; do
  [[ -f "$required_file" ]] || { print -u2 -- "File mancante: $required_file"; exit 1; }
done

if [[ -n "$sky_override" ]]; then
  sky_source="$sky_override"
else
  report 0.08 "Download di Sky Go $sky_version dal server ufficiale…"
  sky_pkg="$temp_dir/SkyGo.pkg"
  /usr/bin/curl -fsSL --retry 3 --retry-delay 1 -o "$sky_pkg" "$sky_pkg_url"
  verify_sha256 "$sky_pkg" "$sky_pkg_sha256"

  signature=$(/usr/sbin/pkgutil --check-signature "$sky_pkg")
  [[ "$signature" == *'Developer ID Installer: SKY Italia Srl (64346Y5J98)'* ]] || {
    print -u2 -- 'La firma del pacchetto Sky non è quella prevista.'
    exit 1
  }
  [[ "$signature" == *'Notarization: trusted by the Apple notary service'* ]] || {
    print -u2 -- 'Il pacchetto Sky non risulta notarizzato.'
    exit 1
  }

  report 0.28 'Estrazione dei componenti ufficiali Sky…'
  /usr/sbin/pkgutil --expand-full "$sky_pkg" "$temp_dir/sky-package"
  sky_source="$temp_dir/sky-package/Sky_Go.pkg/Payload/Sky Go.app"
fi
[[ -d "$sky_source" ]] || { print -u2 -- 'Sky Go ufficiale non è stato trovato.'; exit 1; }

if [[ -n "$electron_override" ]]; then
  electron_source="$electron_override"
else
  report 0.34 "Download del motore compatibile Electron $electron_version…"
  electron_zip="$temp_dir/Electron.zip"
  /usr/bin/curl -fsSL --retry 3 --retry-delay 1 -o "$electron_zip" "$electron_zip_url"
  verify_sha256 "$electron_zip" "$electron_zip_sha256"
  /usr/bin/ditto -x -k "$electron_zip" "$temp_dir/electron"
  electron_source="$temp_dir/electron/Electron.app"
fi
[[ -d "$electron_source" ]] || { print -u2 -- 'Il motore Electron non è stato trovato.'; exit 1; }

report 0.58 'Creazione di Sky Go Fixed…'
staging_app="$temp_dir/Sky Go Fixed.app"
staging_contents="$staging_app/Contents"
staging_macos="$staging_contents/MacOS"
staging_resources="$staging_contents/Resources"
runtime_app="$staging_resources/Sky Go Fixed Runtime.app"

/bin/mkdir -p "$staging_macos" "$staging_resources"
/bin/cp "$launcher_binary" "$staging_macos/SkyGoFixedLauncher"
/bin/cp "$final_info" "$staging_contents/Info.plist"
/bin/cp "$compatibility_hook" "$staging_resources/skygo-compat.js"
/bin/cp "$custom_icon" "$staging_resources/SkyGo.icns"
/usr/bin/ditto "$electron_source" "$runtime_app"

for resource_name in app.asar app.asar.sig app.asar.unpacked bi.txt ii.txt config-encrypt.txt com electron.asar.sig; do
  source_path="$sky_source/Contents/Resources/$resource_name"
  [[ -e "$source_path" ]] && /usr/bin/ditto "$source_path" "$runtime_app/Contents/Resources/$resource_name"
done

for framework_name in Mantle.framework ReactiveObjC.framework Squirrel.framework skygoplayerx.framework; do
  source_path="$sky_source/Contents/Frameworks/$framework_name"
  [[ -e "$source_path" ]] && /usr/bin/ditto "$source_path" "$runtime_app/Contents/Frameworks/$framework_name"
done

/bin/cp "$custom_icon" "$runtime_app/Contents/Resources/SkyGo.icns"

runtime_plist="$runtime_app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleExecutable Electron' "$runtime_plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.skygofixed.unofficial.runtime.v3' "$runtime_plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleDisplayName Sky Go Fixed' "$runtime_plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleName Sky Go Fixed' "$runtime_plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $sky_version" "$runtime_plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIconFile SkyGo.icns' "$runtime_plist"
/usr/libexec/PlistBuddy -c 'Delete :LSEnvironment' "$runtime_plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c 'Set :LSUIElement true' "$runtime_plist" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c 'Add :LSUIElement bool true' "$runtime_plist"

report 0.76 'Ottimizzazione delle risorse…'
for locale_root in \
  "$runtime_app/Contents/Resources" \
  "$runtime_app/Contents/Frameworks/Electron Framework.framework/Versions/A/Resources"; do
  [[ -d "$locale_root" ]] || continue
  for locale_dir in "$locale_root"/*.lproj(N); do
    case "${locale_dir:t}" in
      it.lproj|en.lproj|en_GB.lproj) ;;
      *) /bin/rm -rf "$locale_dir" ;;
    esac
  done
done

report 0.84 'Verifica e firma locale dell’app…'
/bin/chmod 755 "$staging_macos/SkyGoFixedLauncher"
/usr/bin/xattr -cr "$staging_app"
/usr/bin/codesign --force --deep --sign - "$runtime_app"
/usr/bin/xattr -cr "$staging_app"
/usr/bin/codesign --force --deep --sign - "$staging_app"
/usr/bin/codesign --verify --deep --strict "$staging_app"

report 0.92 'Installazione nella cartella Applicazioni…'
install_application() {
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
}

destination_folder=${destination_app:h}
if [[ -w "$destination_folder" ]]; then
  install_application "$staging_app" "$destination_app"
else
  report 0.94 'macOS richiede il permesso per installare in Applicazioni…'
  /usr/bin/osascript - "$privileged_installer" "$staging_app" "$destination_app" <<'APPLESCRIPT'
on run argv
  set installerScript to item 1 of argv
  set sourceApp to item 2 of argv
  set targetApp to item 3 of argv
  do shell script quoted form of installerScript & " " & quoted form of sourceApp & " " & quoted form of targetApp with administrator privileges
end run
APPLESCRIPT
fi

/usr/bin/codesign --verify --deep --strict "$destination_app"

report 1.0 'Installazione completata'
