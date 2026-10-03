# Local HarmonyOS environment

The active development environment is `suggested-host-venv/`, and the application is
`src/`. Read both directories' AGENTS.md before working there.
Use `./dev` from this repository root; it delegates to the downloaded environment.
Build SDK: API 24. Minimum compatibility: API 20. Emulator: HOS23 / API 23.
Do not change SDK levels or substitute the older smoke-test application without the user's direction.

The previous API26 smoke-test setup remains intact outside this checkout. A local,
git-ignored checkpoint of its project, evidence and stopped emulator instance is in
`backups/harmony26-smoke-test-*`, with restoration commands in `RESTORE.txt`.
Never commit toolchains, images, local environment configuration, backups or secrets.
