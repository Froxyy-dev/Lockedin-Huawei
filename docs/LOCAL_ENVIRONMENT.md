# Linux development environment

Run commands from the Lockedin-Huawei repository root. `./dev` delegates to
`suggested-host-venv/dev`; the application lives in `src/`.

```bash
./dev doctor
./dev check
./dev emu start                 # headless
./dev run
./dev inspect
./dev shot
./dev emu stop
./dev emu start --window        # graphical phone window
```

This environment follows the downloaded repository: official Huawei CLT6.1.1.280,
HarmonyOS SDK API24, minimum app compatibility API20, and the official Emulator
26.0.0.402 running a phone image at API23. See that repository's README and
`docs/ENVIRONMENT.md` for setup instructions and documented limitations.
Machine-local settings belong in `suggested-host-venv/.env.local`.
Emulator data uses the larger root partition on this host; `/var/tmp` may be cleaned
by administrators. Toolchain and isolated tool caches are local to the downloaded checkout.

The previous API26 setup remains intact. Its checkpoint is in the git-ignored
`backups/harmony26-smoke-test-*` directory. `RESTORE.txt` explains how to start it;
`SHA256SUMS` verifies the saved project/evidence and emulator-instance archives.
SDK archives and base images were retained at their original locations rather than duplicated.
Do not run both environments on conflicting emulator/HDC ports.

## Verification on 2026-10-03

- ✅ TESTED archive hash equals the README's `b9caf7b73c541b90e6c8f3c7c3de7f2bea9b35e41e80cd3525f2f759ebf16cf4`.
- ✅ TESTED `./dev check`: no lint defects; unsigned debug HAP built (121349 bytes).
- ✅ TESTED headless HOS23 cold boot, unlocked and connected after approximately 60 seconds.
- ✅ TESTED `./dev run --no-build`: `install bundle successfully`, `start ability successfully`; bundle `com.hackyeah.jit`, PID 3794 at verification.
- ✅ TESTED `./dev inspect`: no app crashes, visible text `Hello World`.
- ✅ TESTED `./dev ui click 4`: visible text changed to `Welcome`, also confirmed in screenshot.
- ✅ TESTED screenshots and app logs through CLI.
- ✅ TESTED `./dev gps 50.067 19.991`: command returned `Scenario simulation success`. Coordinates received by an app and the system Location switch remain ⚠️ NOT TESTED.

Evidence: `suggested-host-venv/out/setup-evidence/`; screenshot `out/shot-173013.jpeg`.
The active emulator was left running headless; the older API26 emulator remains stopped.
Java currently uses the retained private JDK21 from the smoke-test setup; its path is set in `.env.local`.
On another machine, use a normal JDK17/21 installation as the downloaded repository instructs.

To switch to a visible phone window:

```bash
./dev emu stop
./dev emu start --window
./dev start
```

The downloaded environment is a separate Git checkout (`suggested-host-venv/.git`),
not yet vendored into this parent repository. Its local configuration, toolchain,
caches and output are git-ignored. To recreate that checkout, clone
`https://github.com/szymon-hajderek/suggested-host-venv.git` into `suggested-host-venv`
and follow its README. No changes were pushed.

## Application source

The application project now lives in `src/` in this parent repository. The root
`./dev` defaults HOS_APP to that directory. The original environment template remains
in `suggested-host-venv/app/`. The current app has a button labeled `Pokaż 67`;
clicking it reveals `67`. Lint/build, installation, launch and the CLI click were
verified on the windowed API23 emulator.
