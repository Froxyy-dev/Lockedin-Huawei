# Local HarmonyOS environment

The active development environment is `suggested-host-venv/`, and the application is
`src/`. Read both directories' AGENTS.md before working there.
Use `./dev` from this repository root; it delegates to the downloaded environment.
Build SDK: API 24. Minimum compatibility: API 20. Emulator: HOS23 / API 23.
Do not change SDK levels or substitute the older smoke-test application without the user's direction.

The environment is a Git submodule pinned to a tested upstream commit. Follow
README.md to update it; publish submodule changes upstream before recording their
commit here. Keep application code in src/. Do not commit SDKs, images, caches,
local environment configuration or secrets.

The harness client screens (`src/.../pages/Creations*`, `CreationPage`, `SpecPage`, `model/HarnessClient.ets`) talk
to the harness API described in `suggested-host-venv/docs/HARNESS.md`; their contract tests live in `tests/`.

# Never block, always log

No command may block the session: anything that can take more than a few seconds or wait for something
(servers, emulator, builds, installs, worker jobs, test tiers, planner calls, `tail -f`, interactive logins)
runs in the background with its output in a log file (`suggested-host-venv/out/*.log` or the session scratchpad),
and progress is read from that log. Short read-only commands only run in the foreground. Every action leaves a
trace the user can inspect later: a log file, a server request log, a job log, or a hilog tag. When something
long is started, say where its log is.
