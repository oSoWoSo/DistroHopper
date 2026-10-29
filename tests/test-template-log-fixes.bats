#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
}

@test "Rhino only advertises Lomiri where a matching image exists" {
	run bash -c '
		. "$1/templates/rhino-linux"
		RELEASE=2025.4
		printf "old:%s\n" "$(editions_)"
		RELEASE=2026.1
		printf "current:%s\n" "$(editions_)"
		unset RELEASE
		printf "all:%s\n" "$(editions_)"
		if output=$(RELEASE=2025.4 EDITION=lomiri ARCH=amd64 get_ 2>&1); then
			exit 1
		fi
		[ -z "${output}" ]
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[ "${output}" = $'old:unicorn\ncurrent:unicorn lomiri\nall:unicorn lomiri' ]
}

@test "Siduction resolves the current release, edition, image, and checksum" {
	run bash -c '
		web_pipe() {
			case "$1" in
				https://mirror.math.princeton.edu/pub/siduction/iso/)
					printf "%s\n" "<a href=\"/pub/siduction/iso/\">Parent</a>" "<a href=\"Big_Crime/\">Big_Crime/</a>";;
				*/iso/Big_Crime/)
					printf "%s\n" "<a href=\"/pub/siduction/iso/\">Parent</a>" "<a href=\"xorg/\">xorg/</a>" "<a href=\"lxqt/\">lxqt/</a>" "<a href=\"siduction-2026.1.0-Big_Crime-xorg-amd64-202610181325.iso\">image</a>" "<a href=\"siduction-2024.1.0-Shine_on-lxqt-amd64-202412261736.iso\">old image</a>";;
				*/iso/Big_Crime/xorg/)
					echo "<a href=\"siduction-2026.1.0-Big_Crime-xorg-amd64-202610181325.iso\">image</a>";;
				*.sha256)
					printf "%064d  siduction-2026.1.0-Big_Crime-xorg-amd64-202610181325.iso\n" 0;;
			esac
		}
		. "$1/templates/siduction"
		RELEASE=$(releases_ | head -n 1)
		printf "release=%s\n" "${RELEASE}"
		printf "%s\n" "$(editions_)"
		EDITION=xorg
		get_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[ "${lines[0]}" = "release=Big_Crime" ]
	[ "${lines[1]}" = "xorg" ]
	[[ "${lines[2]}" == "https://mirror.math.princeton.edu/pub/siduction/iso/Big_Crime/xorg/siduction-2026.1.0-Big_Crime-xorg-amd64-202610181325.iso "* ]]
	[[ "${lines[2]##* }" =~ ^[[:xdigit:]]{64}$ ]]
}

@test "PCLinuxOS uses the upstream case-sensitive edition names" {
	run bash -c '
		web_pipe() {
			case "$1" in
				*XFCE*) printf "%032d  pclinuxos64-XFCE-2026.10.iso\n" 0;;
				*MATE*) printf "%032d  pclinuxos64-MATE-2026.10.iso\n" 0;;
			esac
		}
		. "$1/templates/pclinuxos"
		RELEASE=2026.10
		EDITION=xfce
		get_
		EDITION=mate get_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[[ "${lines[0]}" == "https://ftp.fau.de/pclinuxos/iso/pclinuxos64-XFCE-2026.10.iso "* ]]
	[[ "${lines[1]}" == "https://ftp.fau.de/pclinuxos/iso/pclinuxos64-MATE-2026.10.iso "* ]]
	[[ "${lines[0]##* }" =~ ^[[:xdigit:]]{32}$ ]]
	[[ "${lines[1]##* }" =~ ^[[:xdigit:]]{32}$ ]]
}

@test "Talos normalizes prerelease tags and tolerates missing release assets" {
	run bash -c '
		atom_feed_iso_entries() {
			printf "%s\\t%s\\n" "1.15.0-alpha2" "https://github.com/siderolabs/talos/releases/download/v1.15.0-alpha.2/metal-amd64.iso"
		}
		web_pipe_json() {
			printf "{\"assets\":null}\\n"
		}
		. "$1/templates/talos-linux"
		RSS= DW=https://distrowatch.com/talos
		printf "release=%s\\n" "$(releases_)"
		RELEASE=1.15.0-alpha2
		ARCH=arm64
		get_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[ "${lines[0]}" = "release=1.15.0-alpha.2" ]
	[[ "${lines[1]}" == "https://github.com/siderolabs/talos/releases/download/v1.15.0-alpha.2/metal-arm64.iso "* ]]
}

@test "T4n OS editions and checksums follow files published in its feed" {
	run bash -c '
		web_pipe() {
			case "$1" in
				*t4n-os/rss*)
					printf "%s\n" \
						"<title>/T4n-OS_BASE/t4n_os-live-x86_64-20261023-base.iso</title>" \
						"<title>/T4n-OS_XFCE/t4n_os-live-x86_64-20261023-xfce.iso</title>";;
				*t4nos-base-sha256sums/download)
					printf "%064d  t4n_os-live-x86_64-20261023-base.iso\n" 0;;
				*t4nos-xfce-sha256sums/download)
					printf "%064d  t4n_os-live-x86_64-20261023-xfce.iso\n" 0;;
			esac
		}
		. "$1/templates/t4n-os"
		printf "%s\n" "$(editions_)"
		EDITION=base get_
		EDITION=xfce get_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[ "${lines[0]}" = "base" ]
	[ "${lines[1]}" = "xfce" ]
	[[ "${lines[2]}" == "https://sourceforge.net/projects/t4n-os/files/T4n-OS_BASE/t4n_os-live-x86_64-20261023-base.iso/download "* ]]
	[[ "${lines[3]}" == "https://sourceforge.net/projects/t4n-os/files/T4n-OS_XFCE/t4n_os-live-x86_64-20261023-xfce.iso/download "* ]]
	[[ "${lines[2]##* }" =~ ^[[:xdigit:]]{64}$ ]]
	[[ "${lines[3]##* }" =~ ^[[:xdigit:]]{64}$ ]]
}

@test "NixOS omits unavailable editions and never emits an error as a checksum" {
	run bash -c '
		web_check() {
			case "$1" in
				*/latest-nixos-gnome-*) return 1;;
				*) return 0;;
			esac
		}
		web_pipe() { echo "404 Not Found"; }
		. "$1/templates/nixos"
		RELEASE=26.05
		printf "%s\n" "$(editions_ | tr "\n" " " | sed "s/ $//")"
		EDITION=gnome get_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[ "${lines[0]}" = "minimal plasma" ]
	[[ "${lines[1]}" == "https://channels.nixos.org/nixos-26.05/latest-nixos-gnome-x86_64-linux.iso "* ]]
	[[ "${lines[1]}" != *404* ]]
}

@test "openSUSE does not advertise its unavailable Aeon image" {
	run bash -c '
		web_pipe() { echo "<html>no ISO folder</html>"; }
		. "$1/templates/opensuse"
		releases_ 
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[[ " ${output} " == *" tumbleweed "* ]]
	[[ " ${output} " == *" microos "* ]]
	[[ " ${output} " != *" aeon "* ]]
}

@test "openSUSE checksum parsing ignores error pages and accepts valid hashes" {
	run bash -c '
		CHECKSUM_BODY="<html>404 Not Found</html>"
		web_pipe() { printf "%s\n" "${CHECKSUM_BODY}"; }
		. "$1/templates/opensuse"
		RELEASE=15.3
		get_
		CHECKSUM_BODY="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef  openSUSE-Leap-15.2-DVD-x86_64-Current.iso"
		RELEASE=15.2
		get_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[[ "${lines[0]}" == "https://download.opensuse.org/distribution/leap/15.3/iso/openSUSE-Leap-15.3-DVD-x86_64-Current.iso "* ]]
	[[ "${lines[0]}" != *"<html>"* ]]
	[[ "${lines[1]}" == *"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef" ]]
}

@test "Mageia no longer advertises its broken Mageia 8 download" {
	run bash -c '
		. "$1/templates/mageia"
		releases_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[ "${output}" = "9" ]
}

@test "Manjaro ignores an unavailable community manifest cleanly" {
	run bash -c '
		web_pipe() { printf "<html>GitLab is starting</html>\n"; }
		. "$1/templates/manjaro"
		RELEASE=cinnamon EDITION=full
		get_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[ -z "${output}" ]
}

@test "Manjaro resolves current official full and minimal images" {
	run bash -c '
		web_pipe() {
			case "$1" in
				*/projects/manjarolinux/files/xfce/)
					echo "<a href=\"/projects/manjarolinux/files/xfce/26.1.3/\">26.1.3</a>";;
				*/files/xfce/26.1.3/)
					printf "%s\n" \
						"<a href=\"https://sourceforge.net/projects/manjarolinux/files/xfce/26.1.3/manjaro-xfce-26.1.3-full.iso/download\">" \
						"<a href=\"https://sourceforge.net/projects/manjarolinux/files/xfce/26.1.3/manjaro-xfce-26.1.3-minimal-261028-linux618.iso/download\">";;
				*.sha512/download)
					printf "%064d  image.iso\n" 0;;
			esac
		}
		. "$1/templates/manjaro"
		RELEASE=xfce EDITION=full
		get_
		EDITION=minimal
		get_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[[ "${lines[0]}" == "https://sourceforge.net/projects/manjarolinux/files/xfce/26.1.3/manjaro-xfce-26.1.3-full.iso/download "* ]]
	[[ "${lines[1]}" == "https://sourceforge.net/projects/manjarolinux/files/xfce/26.1.3/manjaro-xfce-26.1.3-minimal-261028-linux618.iso/download "* ]]
	[[ "${lines[0]##* }" =~ ^[[:xdigit:]]{64}$ ]]
	[[ "${lines[1]##* }" =~ ^[[:xdigit:]]{64}$ ]]
}

@test "Manjaro keeps community metadata parsing for full and minimal images" {
	run bash -c '
		web_pipe() {
			case "$1" in
				*file-info.json)
					printf "%s\n" "{\"community\":{\"cinnamon\":{\"image\":\"https://example.com/cinnamon.iso\",\"minimal\":{\"image\":\"https://example.com/cinnamon-minimal.iso\"}}}}";;
				*.sha512)
					printf "%064d  image.iso\n" 0;;
			esac
		}
		. "$1/templates/manjaro"
		RELEASE=cinnamon EDITION=full
		get_
		EDITION=minimal
		get_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[[ "${lines[0]}" == "https://example.com/cinnamon.iso "* ]]
	[[ "${lines[1]}" == "https://example.com/cinnamon-minimal.iso "* ]]
	[[ "${lines[0]##* }" =~ ^[[:xdigit:]]{64}$ ]]
	[[ "${lines[1]##* }" =~ ^[[:xdigit:]]{64}$ ]]
}

@test "Manjaro Sway uses its current ISO and checksum index" {
	run bash -c '
		web_pipe() {
			case "$1" in
				https://manjaro-sway.download/iso/)
					printf "%s\n" "<a href=\"/iso/202610250741/\">" "<a href=\"/iso/202610180719/\">";;
				*/202610250741/SHA256SUMS)
					printf "%064d  ./manjaro-sway-26.1.3.iso\n" 0;;
			esac
		}
		. "$1/templates/manjaro"
		RELEASE=sway
		editions_
		EDITION=full get_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[ "${lines[0]}" = "full" ]
	[[ "${lines[1]}" == "https://manjaro-sway.download/iso/latest/manjaro-sway.iso "* ]]
	[[ "${lines[1]##* }" =~ ^[[:xdigit:]]{64}$ ]]
}

@test "KDE Neon keeps missing-checksum diagnostics out of generated logs" {
	run bash -c '
		web_pipe() { :; }
		. "$1/templates/kde-neon"
		RELEASE=user EDITION=desktop OPERATION=show
		if SHOW_OUTPUT=$(get_ 2>&1); then exit 10; fi
		[ -z "${SHOW_OUTPUT}" ] || exit 11
		OPERATION=download
		if DOWNLOAD_OUTPUT=$(get_ 2>&1); then exit 12; fi
		[ -n "${DOWNLOAD_OUTPUT}" ] || exit 13
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
}

@test "Tails resolves its ISO from the current official manifest host" {
	run bash -c '
		web_pipe() {
			[ "$1" = "https://tails.net/install/v2/Tails/amd64/stable/latest.json" ] || return 1
			printf "%s\n" "{\"installations\":[{\"installation-paths\":[{\"type\":\"iso\",\"target-files\":[{\"url\":\"https://download.tails.net/tails.iso\",\"sha256\":\"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef\"}]}]}]}"
		}
		. "$1/templates/tails"
		RELEASE=stable
		get_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[[ "${output}" == "https://download.tails.net/tails.iso 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef" ]]
}

@test "TrueNAS selects the newest version from its Storj directory index" {
	run bash -c '
		web_pipe() {
			case "$1" in
				*/TrueNAS-SCALE-ElectricEel/)
					printf "%s\n" "<a href=\"./24.10.1/?wrap=1\"><span>24.10.1/</span></a>" "<a href=\"./24.10.2/?wrap=1\"><span>24.10.2/</span></a>";;
				*.iso.sha256)
					printf "%064d  TrueNAS-SCALE-24.10.2.iso\n" 0;;
			esac
		}
		. "$1/templates/truenas-scale"
		RELEASE=ElectricEel
		get_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[[ "${output}" == "https://download.sys.truenas.net/TrueNAS-SCALE-ElectricEel/24.10.2/TrueNAS-SCALE-24.10.2.iso "* ]]
	[[ "${output##* }" =~ ^[[:xdigit:]]{64}$ ]]
}

@test "Redox omits the architecture with no published image" {
	run bash -c '
		. "$1/templates/redox-os"
		arch_
	' _ "${REPO_ROOT}"
	[ "${status}" -eq 0 ]
	[[ " ${output} " == *" i586 "* ]]
	[[ " ${output} " != *" i686 "* ]]
}
