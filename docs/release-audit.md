# Pre-release template audit

Audit baseline: `47c12ac` on branch `all`, following GitHub Actions run
[44642337016](https://github.com/oSoWoSo/DistroHopper/actions/runs/44642337016).

## Verified in this pass

- All 103 template paths were inspected, including the Ubuntu flavour symlinks.
- Metadata generation was attempted for all 101 non-Windows templates.
- Download URL checks across those templates reported **629 PASS and 11 FAIL**
  after the fixes below. **94 templates reported passes and no failures**.
- All **118 Bats regression tests passed**, including the website build test.
- `shellcheck -S error qget generate dh` passed.
- `shellcheck -s bash -S error templates/*` passed.

These are metadata and network URL checks, **not downloaded-image checksum
verification, installation tests, or VM boot tests**. Live download checks used
the default architecture; multi-architecture regression fixtures do not certify
that every upstream architecture currently downloads or boots. Windows and
Windows Server require the separate opt-in probe and were not live-tested here.

## Fixed

| Area | Correction | Commit |
| --- | --- | --- |
| Fedora | Resolve published KDE/Atomic ISO variants; hide betas superseded by final releases | `368571b` |
| KDE Neon | Use `desk`/`big` checksum filename stems inside the existing edition directories | `a6c00bb` |
| Solus | Discover editions for the selected release, including historical `XFCE-Beta` images | `cec18e5` |
| NetBSD | Resolve ISO/checksum URLs from the shared release images tree | `56fb6a5` |
| Alpine | Resolve old ISO names; omit branches/architectures without built images | `93cf029` |
| Ubuntu / Server | Select the newest point ISO; resolve server dailies under the development codename; reject empty manifests | `d3f4c97` |
| Talos | Fall back to official GitHub release assets when the third-party feed is empty | `669ea67` |
| SparkyLinux | Remove a dangling ShellCheck directive | `816e2fb` |

Test maintenance also removed the CLI suite's dependency on generated local
metadata, corrected stale icon/Mageia expectations, and made `tests/test-all.sh`
run every Bats suite rather than four selected suites. The legacy shell tests
in that runner still include checks requiring a generated repository-local
`public/` directory; the standalone Bats result above does not imply that those
legacy checks passed on a clean checkout.

## Remaining release blockers

| Template / area | Observed result | Next step |
| --- | --- | --- |
| blendOS | One failed URL: obsolete `23.06` GNOME image on `images.blendos.co` | Replace the obsolete GitHub-tag resolver with the current official download source, verifying the mirror and its matching checksum. The documented new mirrors could not be reached locally during this pass. |
| HoloISO | One failed URL: release notes point at a 2024 image on `cd2.holoiso.ru.eu.org` | Establish a current official installer source before replacing the URL. |
| Manjaro | Seven passes, four empty-URL failures for i3/Cinnamon full/minimal | Community metadata endpoint returns a GitLab startup HTML page instead of JSON. Confirm a supported replacement or explicitly report temporary unavailability; do not silently mark these downloads as passing. |
| Neko-Void | Four passes, five failed Hugging Face bucket links | Official website advertises bucket URLs returning 404. A repository copy exists for at least i3, but a fallback must verify each image/checksum rather than assume all bucket images have equivalent copies. |
| Whonix | No generated entries; live server requests timed out | Recheck upstream connectivity, then verify release discovery and all three bundle editions. |
| macOS | No standard PASS/FAIL rows; legacy resolver output includes a missing temporary-file diagnostic | Normalize the check path and validate recovery URLs without treating zero counted results as success. |
| RebornOS | No standard PASS/FAIL rows; legacy output includes raw HTTP headers and `PASS-` | Normalize result reporting and verify the actual image URL. |
| CI dependency setup | Raspberry Pi OS job failed fetching an Ubuntu security package index (HTTP 404), before template checks | Rerun/verify the runner's package repositories; this is distinct from a Raspberry Pi image failure. |

The original Mageia and Redox download failures did not reproduce in the local
catalog check. Both reported only passes; this does not establish that their
upstream servers cannot fail intermittently.

## Rechecking

Run the offline regression suites and syntax checks first:

```sh
bats tests/*.bats
shellcheck -S error qget generate dh
shellcheck -s bash -S error templates/*
```

For live checks, put generated metadata outside the checkout if desired:

```sh
export PUBLIC_DIR="$(mktemp -d)"
./generate kde-neon
./qget --check kde-neon
```

Repeat for the desired templates, including symlinked flavours. Inspect logs for
empty metadata, nonstandard output, and missing result rows as well as explicit
`FAIL:` lines. A successful generator exit or zero counted failures is not by
itself a release-readiness signal.
