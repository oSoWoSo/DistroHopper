# Deploying the website to Cloudron Surfer

The website is hosted by Cloudron Surfer, not GitHub Pages. Keep the existing
A/AAAA records for `dh.osowoso.org` pointing at the hosting provider.

The `Test` workflow calls the reusable website workflow after the distro test
matrix finishes on the repository's default branch. Individual download-test
failures do not prevent deployment; cancelled or skipped matrices do.

The website workflow generates distro metadata, builds `website/` through
`web-deploy --build`, then publishes it with `web-deploy --surfer`. It no longer
pushes a `website` branch or uses GitHub Pages configuration.

## GitHub Actions configuration

Under **Settings → Secrets and variables → Actions**, configure:

| Kind | Name | Value |
| --- | --- | --- |
| Variable | `SURFER_SERVER` | HTTPS URL of the Surfer app's authenticated admin/API endpoint, e.g. `https://surfer.example.com` |
| Variable | `SURFER_SITE_NAME` | Existing Surfer site name that serves `dh.osowoso.org`; use `default` only if this is the app's default site |
| Secret | `SURFER_USER` | Cloudron username allowed to deploy this site |
| Secret | `SURFER_TOKEN` | Cloudron **app password** for Surfer, not the account's main password |

**Deployment replaces the contents of the selected site.** Check the server and
site name in Surfer's administration interface before enabling it. If this
Surfer app hosts multiple sites, do not choose `default` unless that is actually
the DistroHopper site. This workflow does not create sites, aliases, or DNS
records.

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
SURFER_SITE_NAME=dh ./web-deploy --surfer
```

Replace `dh` with the existing site name from your Surfer instance. Alternatively:

```bash
SURFER_SITE_NAME=dh ./web-deploy --build-and-deploy
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
