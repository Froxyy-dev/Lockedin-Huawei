# Lockedin-Huawei

Native ArkTS/ArkUI app for the Huawei HackYeah challenge. **The Missing App** lets
a user describe a need, submit it to a local generation backend,
and open the generated native application. Application source lives in [`src/`](src/).
The capability executor accepts a supplied plan; the planner is developed separately. Care Guardian supports a tested laptop voice bridge and caregiver calling. Real health/watch integration is not implemented.

The Linux development environment is the independent
[`suggested-host-venv`](https://github.com/szymon-hajderek/suggested-host-venv)
Git submodule. This repository pins a tested commit; newer environment versions
are adopted explicitly. SDK: API24; minimum compatibility: API20; emulator: API23.

## Clone and install

```bash
git clone --recurse-submodules https://github.com/Froxyy-dev/Lockedin-Huawei.git
cd Lockedin-Huawei
# For an existing checkout:
git submodule update --init --recursive
```

Install JDK17/21 and the Linux prerequisites listed in the submodule's
[README](suggested-host-venv/README.md). Obtain the two official Huawei ZIPs named
below; SDKs, emulator images, credentials and local caches are not committed.

```bash
./dev setup --clt /path/to/commandline-tools-linux-x64-6.1.1.280.zip \
            --emu /path/to/commandline-tools-linux-x64-26.0.0.851.zip
./dev doctor
./dev check
# Review Huawei's agreements before accepting them:
./dev emu setup --accept-licenses
./dev emu start --window
./dev run
```

`./dev` defaults to this repository's `src/`, rather than the environment's sample
app. Machine-specific settings belong in `suggested-host-venv/.env.local`.
Use `HOS_EMU_HOME` there when images/instances need a larger partition.

## Develop

```bash
./dev check       # lint and build
./dev run         # build, install/update, launch
./dev inspect    # process, crashes, UI and logs
./dev shot       # screenshot
./dev emu stop
```

Build artifact: `src/entry/build/default/outputs/default/entry-default-unsigned.hap`.
Unsigned debug installation was verified on the emulator; physical devices require
separate signing. See [local verification and caveats](docs/LOCAL_ENVIRONMENT.md).
Challenge rules and evaluation criteria are in [`docs/`](docs/).

## Update the environment independently

```bash
git submodule update --remote suggested-host-venv
./dev doctor
./dev check
# Verify install/launch against the emulator before adopting the new version.
./dev run
# Commit the new submodule pointer in this repository:
git add suggested-host-venv
git commit -m "chore: update development environment"
```

For normal clones/pulls, use `git submodule update --init --recursive` to restore
the version pinned by the main repository. That command does not upgrade upstream.
Develop and publish environment changes in its own repository before committing
its new pointer here; a local-only submodule commit cannot be cloned by teammates.

## Frontend and Care Guardian demo

Editable prompt → Create → real backend status → Open your app. The prompt microphone remains a visual preview; Care Guardian's voice runtime uses a separately configured audio bridge. For a plan-based Care Guardian generation, use the CLI recipe in [Care Guardian setup](suggested-host-venv/docs/CARE_GUARDIAN.md). The planner owner must attach the plan to the client request; the current Create screen submits a prompt only.

Components live in `src/entry/src/main/ets/components/`. Native capability modules and runtime are in the independently versioned environment. SDKs, private generated apps/HAPs, recordings, phone numbers and provider keys are not distributed in Git.

### Local generator integration

The Create action submits to the local bot API and polls real job status. Configuration is read from ignored `src/entry/src/main/resources/rawfile/bot.json` (`baseUrl`, `token`); never commit this file or a HAP containing this local token. Current emulator URL: `http://10.0.2.2:8787`.

Use `suggested-host-venv/dev bot serve` to start the server from its own template. The root `./dev` targets the client emulator `MissingAppClient` (15603); generation verification uses `HOS23` (15601). Run `HDC_TARGET=127.0.0.1:15603 BOT_AGENT_LAUNCH=0 suggested-host-venv/dev bot agent` for delivery. Create → real generation/build → install → Open your app. Back returns to the prompt; it does not cancel a queued server job. Select Claude or Codex in suggested-host-venv/bot/generator.local.conf. Claude runs Opus with a subagent cap; Codex keeps its own timeout and repair settings.

Client configuration: copy `src/entry/src/main/resources/rawfile/bot.example.json` to `bot.json` in the same folder and replace the placeholder token with the local server BOT_TOKEN. The real bot.json is ignored; keep HAPs containing its token private.

## Harness: creations, specs and versioned builds (branch `harness-client`)

The **Harness** button opens the creations flow: describe a problem → read the planner's plain-language spec →
refine or accept → the worker builds the app → open it. Every creation is a git repository on the server, with one
tagged spec and one tagged build per revision, so any version can be inspected or diffed.

```bash
suggested-host-venv/dev bot serve        # build server (:8787)
suggested-host-venv/dev harness serve    # harness API (:8788): planner, revisions, builds
```

Client configuration: copy `src/entry/src/main/resources/rawfile/harness.example.json` to `harness.json` and set the
local token (the real file is ignored). Design and API: [`suggested-host-venv/docs/HARNESS.md`](suggested-host-venv/docs/HARNESS.md).
Client tests: [`tests/README.md`](tests/README.md).

## Get the Care Guardian feature branch

```bash
git fetch origin
git switch --track origin/feature/care-guardian-worker
git submodule update --init --recursive
```

The feature branch pins the published environment commit; no separate submodule branch checkout is needed to run it. For a fresh clone use `git clone --branch feature/care-guardian-worker --recurse-submodules https://github.com/Froxyy-dev/Lockedin-Huawei.git`. Configure your own `suggested-host-venv/.env.local` from its example and follow [Care Guardian setup](suggested-host-venv/docs/CARE_GUARDIAN.md). Physical phones need signing; emulator installation is verified.
