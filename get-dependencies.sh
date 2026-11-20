#!/bin/sh
# Install build/runtime dependencies for the DistroHopper AppImage.
# Runs inside the pkgforge archlinux container (see .github/workflows/AppImage.yml).

set -eu

REPO_DIR="$(pwd)"

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	bash coreutils grep sed util-linux procps-ng unzip zsync \
	qemu-full fzf jq wget socat swtpm spice-gtk python3 \
	xdg-user-dirs \
	base-devel git autogen autoconf automake libtool pkgconf \
	gtk3 glib2 intltool gettext

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

# Build yad from source without the optional webkit/spell/sourceview
# dependencies (those pull in huge, often unavailable packages).
echo "Building yad..."
cd /tmp
rm -rf yad-src
git clone --depth 1 https://github.com/v1cont/yad.git yad-src
cd yad-src
autoreconf -fi
./configure --prefix=/usr --disable-html --disable-spell --disable-sourceview
make -j"$(nproc)"
make install

# Install DistroHopper itself into a predictable prefix.
cd "$REPO_DIR"
echo "Installing DistroHopper resources..."
echo "---------------------------------------------------------------"
mkdir -p /usr/share/distrohopper
cp -a dh generate qget q quickemu quickreport chunkcheck lib.sh dh-refresh public templates icons \
	/usr/share/distrohopper/
mkdir -p /usr/share/applications
cp dh.desktop /usr/share/applications/dh.desktop
mkdir -p /usr/share/icons/hicolor/scalable/apps
cp icons/hop.svg /usr/share/icons/hicolor/scalable/apps/hop.svg 2>/dev/null || true
