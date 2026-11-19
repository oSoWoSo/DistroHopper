# Deploying the website to Cloudron Surfer

The website is hosted by Cloudron Surfer, not GitHub Pages. Keep the existing
A/AAAA records for `dh.osowoso.org` pointing at the hosting provider.

The `Test` workflow calls the reusable website workflow after the distro test
matrix finishes on the repository's default branch. Individual download-test
failures do not prevent deployment; cancelled or skipped matrices do.

When called by `Test`, the website workflow downloads the same run's
`diagnostics-*` artifacts and merges their `public/` metadata, including the
URL/status data used by the catalog. It does not regenerate metadata. Failed
download checks still leave their metadata available; individual missing distro
outputs are tolerated, but an entirely empty catalog stops deployment rather
than triggering a second generation pass. Standalone manual website runs generate
metadata once because they have no preceding matrix.

The workflow builds `website/` once through `web-deploy --build`, commits that
built tree to the `website` branch, then uploads the same tree with
`web-deploy --surfer`. Surfer serves the uploaded files, not the branch directly;
the branch is an inspectable copy of the build, not GitHub Pages hosting.

`scripts/publish-website-branch` preserves existing branch history, removes stale
files, skips unchanged commits, and creates the branch if absent. It uses a
temporary Git worktree so the source checkout and built directory stay intact.
Pushes are never forced. The workflow and its caller grant `contents: write` for
this branch update; repository rules must permit GitHub Actions to push to
`website`. A branch-push failure stops the subsequent upload. If the Surfer upload
fails, the branch can be ahead of the live server until a successful retry.

## GitHub Actions configuration

The repository-specific deployment target is fixed in
`.github/workflows/website.yml`:

```yaml
SURFER_SERVER: https://dh.osowoso.org
```

These values are not secrets and require no repository variables. Under
**Settings → Secrets and variables → Actions**, configure only these secrets:

| Kind | Name | Value |
| --- | --- | --- |
| Secret | `SURFER_USER` | Cloudron username allowed to deploy this site |
| Secret | `SURFER_TOKEN` | Cloudron **app password** for Surfer, not the account's main password |

**Deployment replaces the contents of the server's default site.** The workflow
does not pass `--site-name` or create sites, aliases, or DNS records.
`SURFER_SITE_NAME` remains an optional local override for explicitly selecting
an existing named site; it is not required for this deployment.

The credential names match OCO's Surfer workflows. `SURFER_TOKEN` is used as
the password for Basic authentication (the CLI's `--password` option), not as a
Bearer/API token.

Both the parent `Test` workflow and a manual run of **Build and deploy website**
use the same settings. The parent explicitly passes the two secrets to the
reusable workflow. Missing settings fail the job before the expensive build.

CI installs Node 24 and the pinned `@cloudron/surfer@7.2.0` CLI, which supports
username/app-password authentication and `surfer deploy`. The installed local
7.4.1 CLI supports the same interface. The old `cloudron-surfer` package uses a
different authentication interface and must not be substituted.

## Local use

An already-configured Surfer CLI can use its saved server and credentials:

```bash
./web-deploy --build
SURFER_SERVER=https://dh.osowoso.org ./web-deploy --surfer
```

Alternatively:

```bash
SURFER_SERVER=https://dh.osowoso.org ./web-deploy --build-and-deploy
```

Optional `SURFER_SERVER`, `SURFER_USER`, `SURFER_TOKEN`, and
`SURFER_MESSAGE` environment variables override saved configuration for this
invocation; the script does not rewrite `~/.surfer.json`. Username and password
overrides must be supplied together. Keep credentials out of committed `.env`
files, shell history, and logs. Do not run deployment commands under `bash -x`.
The Surfer CLI accepts credential overrides as command-line arguments, so use
saved credentials instead on shared local machines where process arguments may
be visible to other users.

`OUT_DIR` selects a different built directory. Relative paths are resolved from
the DistroHopper repository. Uploads require a nonempty `index.html` and refuse
trees containing `.git`, `.env`, or `.env.*` files. A failed build prevents the
combined command from uploading; a Surfer failure propagates as a nonzero exit.

To preview safely, build locally without `--surfer`, inspect `website/`, and only
then run the explicit deployment command. Tests mock Surfer and do not contact
the production server.
