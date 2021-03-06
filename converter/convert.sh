#!/bin/bash

set -e

cd "$(dirname "$0")"

cd ..
make cross
cd "$(dirname "$0")"

rm -rf out tmp
mkdir out tmp

for pf in src/*.zip; do
    echo "$pf"
    rm -rf tmp
    mkdir tmp
    unzip "$pf" -d "tmp"

    bn="$(basename "$pf" .zip)"
    ver="$(echo tmp/$bn/*_source | grep -Eo "[0-9]+\\.[0-9]+\\.[0-9]+")"
    kbn="kobopatch_$(echo $ver | sed "s/\\./-/g")"

    mkdir -p "tmp/$kbn/src/" "tmp/$kbn/bin/"
    for ps in tmp/$bn/*_source/*.patch; do
        cat "$ps" | sed 's/# patch_group/patch_group/g' > "tmp/$kbn/src/$(basename "$ps")"
    done
    cp ../build/kobop* "tmp/$kbn/bin/"
    echo "https://geek1011.github.io/KoboStuff/kobofirmware.html" > "tmp/$kbn/src/download_firmware_here.txt"
    cat <<EOF > "tmp/$kbn/kobopatch.yaml"
## Works with kobopatch v0.8 or later.
## You can update kobopatch by downloading the latest release from https://github.com/geek1011/kobopatch/releases. 
version: $ver
in: src/kobo-update-$ver.zip
out: KoboRoot.tgz
log: log.txt

## The patch format to use: kobopatch (.yaml) or patch32lsb(.patch)
patchFormat: patch32lsb

## This section lists the patch files and the corresponding binary in the tgz.
patches:
  src/nickel.patch: usr/local/Kobo/nickel
  src/libadobe.so.patch: usr/local/Kobo/libadobe.so
  src/libnickel.so.1.0.0.patch: usr/local/Kobo/libnickel.so.1.0.0
  src/librmsdk.so.1.0.0.patch: usr/local/Kobo/librmsdk.so.1.0.0

## You can put lines in the following section to override the enabled state of patches.
## The indentation matters! Each override should be indented by 4 spaces. Add to the 
## section below. This section can be copy and pasted into newer patch versions to
## keep your selections.
##
## Example of how it should look:
## overrides:
##   src/nickel.patch:
##     Custom synopsis/details line spacing: yes
##     Whatever the patch is called: no
##   src/libadobe.so.patch:
##     You get the idea: yes
overrides:
  src/nickel.patch:
  src/libadobe.so.patch:
  src/libnickel.so.1.0.0.patch:
  src/librmsdk.so.1.0.0.patch:

## TRANSLATIONS ##
# Optional, use only if lrelease is not in PATH and if translations are needed
# lrelease: /path/to/lrelease

# Uncomment the following to add translations (replace lc with the language code)
# translations:
#   src/whatever.ts: usr/local/Kobo/translations/trans_lc.qm

## ADDITIONAL FILES ##
# Uncomment the following to add additional files to the tgz (like init scripts or hyphen dicts)
# The files will be root-owned, and world readable, writable, and executable (0777)
# files:
#   src/whatever.txt: usr/local/Kobo/whatever.txt
EOF
    unix2dos "tmp/$kbn/kobopatch.yaml"
    cat <<'EOF' > "tmp/$kbn/kobopatch.sh"
#!/bin/bash
cd "$(dirname "$0")"
rm -f "KoboRoot.tgz"
case `uname -s` in
    Darwin)
	    ./bin/kobopatch-darwin-64bit
	    ;;
    Linux)
	    case `uname -m` in
	        i?86)
                ./bin/kobopatch-linux-32bit
		        ;;
	        x86_64)
                ./bin/kobopatch-linux-64bit
		        ;;
            arm*)
                ./bin/kobopatch-linux-arm
                ;;
            aarch64)
                ./bin/kobopatch-linux-arm
                ;;
            *)
                echo "Unsupported architecture"
	esac
	;;
esac
EOF
    chmod +x "tmp/$kbn/kobopatch.sh"
    cat <<'EOF' > "tmp/$kbn/kobopatch.bat"
@echo off
cd "%~dp0"
erase "KoboRoot.tgz" >nul 2>&1
"./bin/koboptch-windows.exe"
EOF
    unix2dos "tmp/$kbn/kobopatch.bat"
    cat <<EOF > "tmp/$kbn/readme.txt"
This is for use with firmware $ver.

=== How to use: ===
Make sure your kobo is already running the firmware version you are trying to patch.

1. Download the firmware from https://geek1011.github.io/KoboStuff/kobofirmware.html to the src folder.
   The zip should be called something like kobo-update-1.2.3456.zip
2. Enable patches in the files in the src folder (or use the overrides in kobopatch.yaml).
3. Run kobopatch.bat on Windows, or kobopatch.sh on Linux.
4. If the patching succeeded, a file named KoboRoot.tgz will be created.
   Copy it to the .kobo folder of your device.

=== To update kobopatch: ===
1. Download the updated version from https://github.com/geek1011/kobopatch/releases

=== To revert the patches: ===
1. Disable all patches.
2. Repeat steps 3-4 above.

=== Translations ===
kobopatch also supports compiling and adding ts files. lrelease should be in your PATH, or the path
should be specified in kobopatch.yaml.

This feature is not heavily tested.

=== To report bugs: ===
Open an issue on https://github.com/geek1011/kobopatch/issues, or respond to the thread on MobileRead.
Make sure you provide log.txt
EOF
    unix2dos "tmp/$kbn/readme.txt"
    cd tmp
    zip -r "../out/$kbn.zip" "$kbn"
    cd ..
    rm -rf tmp
done

echo "Converted. Make sure you test the converted zips to make sure they work."