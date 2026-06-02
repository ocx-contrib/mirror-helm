# /// script
# requires-python = ">=3.13"
# dependencies = ["ocx-mirror-sdk"]
#
# [tool.uv.sources]
# ocx-mirror-sdk = { url = "https://github.com/ocx-sh/ocx-mirror-sdk/releases/download/v0.4.0/ocx_mirror_sdk-0.4.0-py3-none-any.whl" }
# ///
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 The OCX Authors

"""Generate url_index JSON for Helm.

Helm publishes its binaries on the get.helm.sh CDN, NOT as GitHub release
assets — every helm/helm release ships only detached signatures and
checksums (`.asc`, `.sha256sum.asc`). So the native `github_release`
mirror source would resolve zero archives. Instead we enumerate the
authoritative version list from helm/helm GitHub releases and synthesize
the canonical get.helm.sh download URLs (the scheme documented in every
release body's install section: `https://get.helm.sh/helm-vX.Y.Z-OS-ARCH.EXT`).
"""

import re

from ocx_mirror_sdk import IndexBuilder, github

REPO = "helm/helm"
DIST_URL = "https://get.helm.sh"
TAG_RE = re.compile(r"^v(?P<version>\d+\.\d+\.\d+)$")

# ocx platform -> (get.helm.sh os-arch token, archive extension).
# Only the platforms OCX can express are mirrored. Helm additionally ships
# exotic Linux arches (386, arm, loong64, ppc64le, riscv64, s390x) that have
# no OCX os/arch mapping; they are intentionally omitted.
PLATFORMS = {
    "linux-amd64": "tar.gz",
    "linux-arm64": "tar.gz",
    "darwin-amd64": "tar.gz",
    "darwin-arm64": "tar.gz",
    "windows-amd64": "zip",
    "windows-arm64": "zip",
}


def main() -> None:
    index = IndexBuilder()
    for release in github.list_releases(REPO, include_prereleases=False, include_drafts=False):
        match = TAG_RE.match(release.tag_name)
        if not match:
            continue
        version = match.group("version")

        assets: dict[str, str] = {}
        for token, ext in PLATFORMS.items():
            filename = f"helm-v{version}-{token}.{ext}"
            assets[filename] = f"{DIST_URL}/{filename}"

        index.add_version(version, assets=assets, prerelease=release.prerelease)

    index.emit()


if __name__ == "__main__":
    main()
