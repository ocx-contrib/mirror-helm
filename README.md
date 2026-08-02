# mirror-helm

OCX mirror for [Helm](https://helm.sh), the package manager for Kubernetes.
One repository, one spec directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [helm](https://github.com/helm/helm) | [`helm/mirror.yml`](helm/mirror.yml) | `ghcr.io/ocx-contrib/helm/helm` | `ocx.sh/helm/helm` | `Apache-2.0` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

> This repository previously published the same upstream to the flat coordinate
> `ocx.sh/helm`. `helm/helm` is the grouped successor. Upstream's owner *is* the
> project (`helm/helm` on GitHub), so the namespace and the name coincide.

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
helm/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
├── scripts/generate.py the url_index generator (run by uv)
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — each
package carries its own, because a repo-root `logo.*` sits in no workflow's
`paths:` filter, so replacing it would publish nothing until some unrelated
edit happened to fire. The generator lives under `helm/` for the same reason:
the mirror workflow's path trigger is `helm/**`.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. Restate a block in full or
not at all.

## Why a `url_index` generator

Helm ships its binaries on the **get.helm.sh** CDN, not as GitHub release
assets — each `helm/helm` release carries only detached signatures and
checksums (`.asc` / `.sha256sum`), so the native `github_release` source would
resolve **zero** archives. `helm/scripts/generate.py` enumerates the
authoritative version list from helm/helm GitHub releases and synthesizes the
canonical `https://get.helm.sh/helm-vX.Y.Z-OS-ARCH.EXT` download URLs into a
`url_index` document. It uses
[`ocx-mirror-sdk`](https://github.com/ocx-sh/ocx-mirror-sdk), pinned to a
published wheel via PEP 723 inline metadata.

Because those URLs are **synthesized rather than read back from upstream**, a
generator regression is invisible to the spec's own regexes — every pattern
still matches exactly one *name*. After touching the generator, prove the URLs
resolve:

```bash
cd helm && uv run scripts/generate.py    # then HEAD the emitted URLs
```

`uv` is the generator's **runtime**, pinned in `ocx.toml` as the namespaced
`ocx.sh/astral-sh/uv:0`. Without it on PATH, discover dies before reading a
single release.

### Bumping the SDK pin

Edit the `[tool.uv.sources]` block at the top of `helm/scripts/generate.py`:

```toml
ocx-mirror-sdk = { url = "https://github.com/ocx-sh/ocx-mirror-sdk/releases/download/vX.Y.Z/ocx_mirror_sdk-X.Y.Z-py3-none-any.whl" }
```

## Platforms

`helm` publishes six platform entries: both Linux arches, both macOS arches and
both Windows arches. Upstream builds Helm as a pure-Go binary without cgo, so
get.helm.sh ships one Linux build per arch and it is **fully static** — no
`PT_INTERP`, no `DT_NEEDED`, and no musl/glibc variants to choose between.
`os.features` states what an artifact requires *of the host*, so both Linux
keys are **bare**: tagging them `+libc.musl` would be a false requirement that
hid them from every glibc host. The `alpine:3.20` container leg in
`mirror-base.yml` is what turns that claim into evidence; the measurement
itself is recorded above the `assets:` block in `helm/mirror.yml`.

The version floor is `3.16.0` because that is the first release shipping
`helm-vX.Y.Z-windows-arm64.zip` — below it the spec would resolve five
platforms and silently skip the sixth.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `helm/mirror.yml` | hand | yes — see below |
| `helm/scripts/generate.py` | hand | — |
| `helm/{metadata.json,CATALOG.md,logo.*}` | hand | — |
| `helm/tests/smoke.star` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec helm/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

## The binaries claim

Helm's archives wrap their contents in a single `<os>-<arch>/` directory;
`asset_type.strip_components: 1` drops it, so the executable lands *at* the
content root and the bundle's only PATH entry is a bare `${installPath}`.
`bin_scan` only looks *below* an `${installPath}/<dir>` entry, so `auto` /
`verify` is rejected at spec load with exit 65. `mirror-base.yml` therefore
sets `bin_scan: off` and `helm/metadata.json` hand-lists
`binaries: ["helm"]` — the blessed shape for this layout.

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
