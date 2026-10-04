# The Missing App (Lockedin-Huawei)

**HackYeah 2026 · Huawei Challenge "Imagine What's Next" · Theme: Intelligent Experiences, with a Human-Centric purpose.**

**The Missing App** is a native ArkTS/ArkUI HarmonyOS app that makes the app you are missing, from one sentence.
You describe a need in your words. A planner designs a plain-language spec; you refine it or accept it. An AI
engineer then builds a native HarmonyOS app inside a versioned git workspace on a headless HarmonyOS toolchain, the
build server verifies it independently on an emulator (build, clean install, launch, crash check, widget tree), and
the app lands on your phone with its own name and icon, one tap away. Every spec and every successful build is a git
tag (`spec-N`, `rev-N`), so any version can be opened or diffed. Generated apps reach paid services (speech, language)
only through a server-side proxy, so no key ever sits on the phone. Application source lives in [`src/`](src/).

Everything in this repository and in the environment repository was written during the hackathon (first commit
2026-10-03 16:46). Pre-existing components are listed in [AI_WORKFLOW.md](AI_WORKFLOW.md).

## Submission

| Deliverable | Where |
|---|---|
| Source code | This repository (client app) and [`suggested-host-venv`](https://github.com/szymon-hajderek/suggested-host-venv) (environment, planner, harness, workers, service proxy), pinned as a submodule |
| Setup, build, install, launch | [Clone and install](#clone-and-install) below, then [Harness](#harness-creations-specs-and-versioned-builds-branch-harness-client); versions in [docs/LOCAL_ENVIRONMENT.md](docs/LOCAL_ENVIRONMENT.md) |
| Working `.hap` | [`submission/the-missing-app-entry-default-unsigned.hap`](submission/the-missing-app-entry-default-unsigned.hap), unsigned debug HAP for the emulator: `./dev install` or `hdc install <file>` |
| Demo recording | [`submission/demo-the-missing-app.mp4`](submission/demo-the-missing-app.mp4), 2 min 21 s emulator recording: prompt → spec → accept → build → install → using the generated app (PaperPick) → a one-sentence second revision |
| Architecture and implementation | [docs/HOW_IT_WORKS.md](docs/HOW_IT_WORKS.md) (how it works, with diagrams), [suggested-host-venv/docs/HARNESS.md](suggested-host-venv/docs/HARNESS.md) (data model, lifecycle, API), [docs/PITCH.md](docs/PITCH.md) |
| AI workflow and AI feature disclosure | [AI_WORKFLOW.md](AI_WORKFLOW.md) → [src/AI_WORKFLOW.md](src/AI_WORKFLOW.md) |
| Tests | `python3 -m unittest discover -s tests -t .` (client contract tests, [tests/README.md](tests/README.md)); `suggested-host-venv/dev test unit` and `… integration` (environment) |

Platform capabilities used: the HarmonyOS SDK (API 24), hvigor and hdc drive build, install and launch of the
generated apps; `startAbility` opens a generated app from The Missing App; generated apps use FormKit home-screen
cards, PDFKit, MediaKit, ArkWeb and the microphone; workers read the device's real SystemCapabilities (`./dev caps`)
as ground truth for `canIUse`. Verified on the HarmonyOS 6.1.0 (API 23) emulator. Not done: physical-device signing,
the emulator microphone, per-user quotas. Care Guardian (an earlier demo on `feature/care-guardian-worker`) uses a
laptop voice bridge; real health/watch integration is not implemented.

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
