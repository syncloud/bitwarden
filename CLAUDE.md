# Debugging CI failures

Stages (amd64, arm64, arm) run in parallel. A build can be `status: running` while individual stages have already failed — always drill into per-stage, per-step status instead of waiting on the top-level build status. Do not assume a "running" build is healthy.

When a CI build fails, always start by identifying the failing step:
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/bitwarden/builds/{N}" | python3 -c "
import json,sys
b=json.load(sys.stdin)
for stage in b.get('stages',[]):
    print(stage.get('name'), '-', stage.get('status'))
    for step in stage.get('steps',[]):
        if step.get('status') == 'failure':
            print('   ', step.get('number'), step.get('name'), '-', step.get('status'))
"
```

Then get the step log (stage=pipeline index, step=step number):
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/bitwarden/builds/{N}/logs/{stage}/{step}" | python3 -c "
import json,sys; [print(l.get('out',''), end='') for l in json.load(sys.stdin)]
" | tail -80
```

# CI

http://ci.syncloud.org:8080/syncloud/bitwarden

CI is Drone CI (JS SPA). Check builds via API:
```
curl -s "http://ci.syncloud.org:8080/api/repos/syncloud/bitwarden/builds?limit=5"
```

## CI Artifacts

Artifacts are served at `http://ci.syncloud.org:8081` (returns JSON directory listings).

Browse the top level for a build (returns distro subdirs + snap file):
```
curl -s "http://ci.syncloud.org:8081/files/bitwarden/{build}-{arch}/"
```

Each distro dir contains `app/`, `platform/`, and for upgrade/UI tests also `desktop/`, `refresh.journalctl.log`, `video.mkv`:
```
curl -s "http://ci.syncloud.org:8081/files/bitwarden/{build}-{arch}/{distro}/"
curl -s "http://ci.syncloud.org:8081/files/bitwarden/{build}-{arch}/{distro}/app/"
curl -s "http://ci.syncloud.org:8081/files/bitwarden/{build}-{arch}/{distro}/desktop/"
```

Directory structure:
```
{build}-{arch}/
  {distro}/
    app/
      journalctl.log          # full journal from integration test teardown
      ps.log, netstat.log     # process/network state at teardown
    platform/                 # platform logs
    desktop/                  # UI test artifacts (amd64 only)
      journalctl.log
      screenshot/
        {test-name}.png
        {test-name}.html.log
      log/
    refresh.journalctl.log    # full journal from upgrade test (pre/post-refresh)
    video.mkv                 # selenium recording
```

Download a file directly:
```
curl -O "http://ci.syncloud.org:8081/files/bitwarden/282-amd64/bookworm/refresh.journalctl.log"
curl -O "http://ci.syncloud.org:8081/files/bitwarden/282-amd64/bookworm/app/journalctl.log"
curl -O "http://ci.syncloud.org:8081/files/bitwarden/282-amd64/bookworm/desktop/journalctl.log"
```

# Project Structure

- **Snap app** packaging Vaultwarden (Bitwarden-compatible server) for Syncloud
- Architectures: amd64, arm64, arm
- Single distro: bookworm
- CI pipelines defined in `.drone.jsonnet`

## Key directories

- `cli/` — Go snap hooks and CLI (`install`, `configure`, `post-refresh`, `cli`)
  - Uses `github.com/syncloud/golib` and `cobra` for commands
  - Built with `CGO_ENABLED=0` for static binaries
- `bin/` — Service launcher scripts (`service.bitwarden.sh`, `service.nginx.sh`)
- `config/` — nginx config and `.env` for vaultwarden
- `nginx/` — nginx build/test scripts
- `test/` — Python integration tests (pytest), UI tests (selenium), upgrade tests
- `meta/snap.yaml` — Snap metadata (services: server, nginx, storage-change, access-change, backup/restore)
- `build.sh` — Copies vaultwarden binary and web-vault from upstream container
- `package.sh` — Creates snap package

## Build pipeline steps (per arch)

1. `version` — writes build number
2. `nginx` / `nginx test` — build and test nginx
3. `build` — copy vaultwarden binary from upstream Docker image
4. `cli` — compile Go snap hooks
5. `package` — create `.snap` file
6. `test bookworm` — integration tests against platform service container
7. (amd64 only) `selenium` + `test-ui` + `test-upgrade` — UI and upgrade tests

# Running Drone builds locally

Generate `.drone.yml` from jsonnet (run from project root):
```
drone jsonnet --stdout --stream > .drone.yml
```

Run a specific pipeline with selected steps:
```
drone exec --pipeline amd64 --trusted \
  --include version \
  --include nginx \
  --include "nginx test" \
  --include build \
  --include cli \
  --include package \
  --include "test bookworm" \
  .drone.yml
```
