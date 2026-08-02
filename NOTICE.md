# NOTICE

This repository packages and redistributes upstream software published by
[The Helm Authors](https://helm.sh). The Apache-2.0 license in
[`LICENSE`](LICENSE) covers the OCX pipeline files authored here. It does
**not** cover any upstream-derived asset — each package's redistributed bytes
carry their own license, recorded below.

Each package's logo is reproduced for catalog identification only, under
nominative fair use. The marks remain the property of their respective owners
and no endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `helm` | `ghcr.io/ocx-contrib/helm/helm` | `Apache-2.0` |

---

## `helm`

Upstream: <https://github.com/helm/helm> (binaries distributed via
<https://get.helm.sh>).
Published to `ghcr.io/ocx-contrib/helm/helm`.

| Component | SPDX | Holder |
|---|---|---|
| Helm (`helm`) | **Apache-2.0** | Copyright The Helm Authors |

Permissive; redistribution of the compiled binary is granted provided the
license and attribution notices are retained. Upstream's own archives ship a
`LICENSE` and `README.md` alongside the binary, and this mirror republishes the
archive contents byte-for-byte, so those notices travel with the bundle. The
canonical terms are those of
<https://github.com/helm/helm/blob/main/LICENSE>. The published binaries
statically link third-party Go modules under permissive licenses, enumerated in
upstream's `go.mod`.

The Helm name and logo are CNCF / The Linux Foundation marks, used for catalog
identification under nominative fair use.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
