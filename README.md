# mirror-helm

OCX mirror for [Helm](https://helm.sh), the package manager for Kubernetes.
Publishes the official Helm release binaries to `ocx.sh/helm` with cascade
tags after a smoke test per `(version, platform)`.

Helm ships its binaries on the **get.helm.sh** CDN, not as GitHub release
assets — each `helm/helm` release carries only detached signatures and
checksums (`.asc` / `.sha256sum`). So this mirror runs a small `generate.py`
that enumerates the authoritative version list from helm/helm GitHub releases
and synthesizes the canonical `https://get.helm.sh/helm-vX.Y.Z-OS-ARCH.EXT`
download URLs into a `url_index` document. The script uses
[`ocx-mirror-sdk`](https://github.com/ocx-sh/ocx-mirror-sdk) (pinned to the
published wheel via PEP 723 inline metadata).

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror.yml` | hand | `ocx-mirror pipeline generate ci` |
| `generate.py` | hand | — |
| `tests/smoke.star` | hand | — |
| `metadata.json`, `CATALOG.md`, `logo.*` | hand | — |
| `.github/workflows/*.yml` | generated | re-run when `mirror.yml` changes |

CI fails on drift via `ocx-mirror pipeline generate ci --check`.

## Bumping the SDK pin

Edit the `[tool.uv.sources]` block at the top of `generate.py` to point at
a newer wheel:

```toml
ocx-mirror-sdk = { url = "https://github.com/ocx-sh/ocx-mirror-sdk/releases/download/vX.Y.Z/ocx_mirror_sdk-X.Y.Z-py3-none-any.whl" }
```

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_MIRROR_REGISTRY_TOKEN` + `OCX_MIRROR_REGISTRY_USER` | `ocx package push` to `ocx.sh` |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets (Helm logo, mirrored
binaries) are out of scope; see [`NOTICE.md`](NOTICE.md).
