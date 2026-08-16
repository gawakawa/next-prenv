# Design

A preview environment on Cloud Run, created per PR and torn down when no longer needed
(Terraform + GitHub Actions + Artifact Registry).

## Lifecycle

- Create: the `preview` label triggers a deploy (push does not redeploy).
- Destroy (three independent paths): PR close / manual / daily GC of 3-day-idle envs → `tofu destroy`.
- AR images: server-side cleanup policy deletes images older than 7 days
  (longer than the 3-day GC, so an in-use image is never deleted first).

## Topology

One Cloud Run service, two containers: `app` (ingress, :3000) + `db` (MySQL sidecar).

## Database

`db` runs `mysql:8.4` directly from Docker Hub; data directory is emptyDir(MEMORY)
(no persistence, lost on scale-to-zero). Cloud Run has no one-shot container, so
`app` runs `pnpm migrate:deploy && pnpm seed` on every start before `pnpm start`
— the same commands `compose.yaml`'s `migrate` service runs, on the same
`builder`-stage image (CI builds `app` with `target: builder`, not the slim
standalone `runner` used by `docker compose up`'s `app` service, since only
`builder` has the full `prisma` CLI toolchain). `db`'s startup_probe (tcp:3306)
only passes after mysqld's init finishes, so `compose.yaml`'s migrate retry
loop isn't needed here.

## Access control

IAP-protected; only `iap_members` identities can access (no `allUsers`).

`terraform/env/dev` holds the persistent config, applied once manually (WIF,
deploy SA, tfstate bucket, AR, IAP bindings). `terraform/env/preview` holds the
temporary per-PR config, applied by CI with tfstate prefix `pr/<N>`. Kept
separate so tearing down one PR can never affect another PR or the persistent
config.

## Cache

Image tag = `git rev-parse HEAD^{tree}`; build is skipped if the tag exists.
A registry buildcache is also used so dependency layers survive across tags.
