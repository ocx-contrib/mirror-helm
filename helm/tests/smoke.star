# helm/tests/smoke.star — stable across upstream Helm releases.
# Asserts behavior/contract (exit codes, version digits, rendered Kubernetes
# manifest kinds), never upstream-controlled prose. See testing-practices.md.
HELM = "helm.exe" if ocx.target_platform.os == ocx.os.Windows else "helm"

# Keep Helm's config/cache/data fully inside the scratch sandbox so the run
# never reads or writes the runner's own user config. These are plain
# (non-reserved) env keys that ocx.run overlays onto the composed env.
#
# HELM_* is the complete sandbox: helm consults XDG_CONFIG_HOME /
# XDG_CACHE_HOME / XDG_DATA_HOME only as FALLBACKS when the matching HELM_*
# is unset, so setting all three here leaves XDG never consulted — no reason
# to restate it. HOME is pinned anyway so the claim holds by construction
# rather than by helm's var precedence. No KUBECONFIG: `helm template`
# without --validate never opens a cluster connection, and pointing the var
# at a non-existent file would invent a failure mode rather than remove one.
HELM_ENV = {
    "HELM_CONFIG_HOME": ocx.scratch_root + "/helm-config",
    "HELM_CACHE_HOME": ocx.scratch_root + "/helm-cache",
    "HELM_DATA_HOME": ocx.scratch_root + "/helm-data",
    "HOME": ocx.scratch_root,
}

# Tier 1 + 2: liveness on the composed PATH + version shape. Helm prints
# `version.BuildInfo{Version:"vX.Y.Z", ...}` to stdout — match the digits
# only, never the vendor string or the exact version.
r_version = ocx.run(HELM, "version", env=HELM_ENV)
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# Tier 3: functional behavior on hermetic input.
# `helm create` scaffolds a real chart on disk (no network); `helm template`
# renders it offline (no cluster, no network) and emits Kubernetes manifests.
# Assert the stable rendered `kind:` tokens, not any help/log prose.
r_create = ocx.run(HELM, "create", "demo", env=HELM_ENV)
expect.ok(r_create)
expect.true(ocx.exists("demo/Chart.yaml"))

r_template = ocx.run(HELM, "template", "smoke-release", "demo", env=HELM_ENV)
expect.ok(r_template)
expect.contains(r_template.stdout, "kind: Deployment")
expect.contains(r_template.stdout, "kind: Service")
expect.contains(r_template.stdout, "apiVersion: apps/v1")

# No Tier 4: metadata.json declares only PATH (proven by Tier-1 liveness).
