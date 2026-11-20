#!/bin/sh
# Build the DistroHopper AppImage using quick-sharun (see pkgforge/quick-sharun).
# Runs after get-dependencies.sh inside the build container.

set -eu

ARCH=$(uname -m)
VERSION=0.93
export ARCH VERSION
export OUTPATH=./dist
export ICON=/usr/share/distrohopper/icons/hop.svg
export DESKTOP=/usr/share/applications/dh.desktop
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"

# Deploy DistroHopper and every binary it shells out to (plus shared libs).
quick-sharun \
	/usr/bin/bash \
	/usr/share/distrohopper/dh \
	/usr/share/distrohopper/generate \
	/usr/share/distrohopper/qget \
	/usr/share/distrohopper/q \
	/usr/share/distrohopper/quickemu \
	/usr/share/distrohopper/quickreport \
	/usr/share/distrohopper/chunkcheck \
	/usr/share/distrohopper/lib.sh \
	/usr/share/distrohopper/dh-refresh \
	/usr/bin/yad \
	/usr/bin/fzf \
	/usr/bin/jq \
	/usr/bin/wget \
	/usr/bin/socat \
	/usr/bin/qemu-system-x86_64 \
	/usr/bin/qemu-img

# Make sure resource directories ship inside the AppImage.
if [ -d ./AppDir ]; then
	for d in public templates icons; do
		[ -d "/usr/share/distrohopper/$d" ] && cp -a "/usr/share/distrohopper/$d" "./AppDir/" 2>/dev/null || true
	done
	# Use our own AppRun so PATH/APPDIR are set up for the bundled tools.
	cp ./AppRun ./AppDir/AppRun
	chmod +x ./AppDir/AppRun
fi

# Turn AppDir into an AppImage.
quick-sharun --make-appimage

# Smoke test (use --simple-test if the GUI cannot run in CI).
quick-sharun --test ./dist/*.AppImage
