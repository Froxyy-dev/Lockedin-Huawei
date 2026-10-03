# Lockedin-Huawei

Native ArkTS/ArkUI app for the Huawei HackYeah challenge. **The Missing App** lets
a user describe a need, previews a staged composition of Harmony capabilities,
and opens the **Care Guardian** placeholder. Application source lives in [`src/`](src/).
Planning is a local mock; no AI/backend, health/watch integration or recording is implemented.

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

## Frontend demo

Editable prompt → **Create with Harmony** → 3.5-second capability planning preview
→ **Open Care Guardian**. The back controls reset the flow and cancel pending timers.
The microphone briefly highlights and logs a preview action; it does not record.

Components are in `src/entry/src/main/ets/components/`; design tokens in `theme/`;
`model/HarmonyPlanner.ets` contains the typed plan and explicit demo fixture. Replace
the mock planner adapter when connecting a backend; page components consume the
plan rather than backend details. Edited prompts are echoed as the mock goal; the
capabilities and Care Guardian result remain the same demo fixture.

Reduced-motion preference is read through the SDK's API23 accessibility method
with a guarded fallback on older devices. Stage timing remains visible; motion is
disabled when that preference is enabled. The app requests no additional permissions.

Verified on the API23 phone emulator: editable input, microphone log, sequential
checkmarks, placeholder navigation, result reset and cancellation mid-planning.
Screenshots and visual iterations are recorded locally under the environment's
ignored `out/` directory. Fresh emulator keyboards can require one-time setup;
Celia Basic mode was used without cloud input features.

### Local generator integration

The Create action submits to the local bot API and polls real job status. Configuration is read from ignored `src/entry/src/main/resources/rawfile/bot.json` (`baseUrl`, `token`); never commit this file or a HAP containing this local token. Current emulator URL: `http://10.0.2.2:8787`.

Use `suggested-host-venv/dev bot serve` to start the server from its own template. The root `./dev` targets the client emulator `MissingAppClient` (15603); generation verification uses `HOS23` (15601). Run `HDC_TARGET=127.0.0.1:15603 BOT_AGENT_LAUNCH=0 suggested-host-venv/dev bot agent` for delivery. Create → real generation/build → install → Open your app. Back returns to the prompt; it does not cancel a queued server job. Select Claude or Codex in suggested-host-venv/bot/generator.local.conf. Claude cost/turn caps do not apply to Codex.

Client configuration: copy `src/entry/src/main/resources/rawfile/bot.example.json` to `bot.json` in the same folder and replace the placeholder token with the local server BOT_TOKEN. The real bot.json is ignored; keep HAPs containing its token private.
