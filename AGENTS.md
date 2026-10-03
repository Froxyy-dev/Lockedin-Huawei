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

User-authorized exception: the directly editable Care Guardian demo lives in demo/guardian/app, with a dedicated backend in suggested-host-venv/demo/guardian. Use ./demo/guardian/dev for that flow; preserve src/ and the generic worker.
