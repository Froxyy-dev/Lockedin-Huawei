# Verified Linux environment

Run `./dev` from the Lockedin-Huawei root. It delegates to the
`suggested-host-venv` submodule and selects the application in `src/`.
The submodule is pinned to tested commit `f506e673add089f4e500a498cf90d19e66dac9f2`.

| Component | Tested version |
|---|---|
| Official Command Line Tools | 6.1.1.280 |
| Hvigor | 6.24.2 |
| OHPM | 6.1.2.268 |
| Bundled Node | 18.20.1 |
| HarmonyOS SDK | 6.1.1 / API24 |
| App minimum / target | API20 / API24 |
| Official Emulator | 26.0.0.402 |
| Phone image | HarmonyOS 6.1.0 / API23, software 6.1.0.115 |

✅ TESTED on Ubuntu22.04, 2026-10-03: lint/build, unsigned HAP installation,
app launch, headless and graphical emulator boot, HDC, logs, screenshot and CLI click.
The initial `src/` demo displayed **67** on a button click. The current frontend is
Harmony Create → staged capability planning → Care Guardian placeholder. All three
screens, prompt editing, microphone preview, reset and cancellation were verified;
no app crash was reported. Latest HAP size: 225070 bytes. Verification files and screenshots remain
local in `suggested-host-venv/out/`, which is ignored by Git.

✅ TESTED GPS injection command returned success. Location delivery to an app,
geofencing and motion APIs remain ⚠️ NOT TESTED.
Physical-device signing remains ⚠️ NOT TESTED; the unsigned debug HAP works on
this emulator. CLT26 cannot build this project's explicit API24 configuration
(`00303313`); use the prescribed CLT6.1.1.280.

Local settings are ignored in `suggested-host-venv/.env.local`. On this host the
emulator uses a larger root filesystem under `/var/tmp`; administrators may clean
that directory. Java uses the retained private JDK21 outside this repository.
On a clean machine install normal JDK17/21, following the submodule README.
SDKs, images and caches are local installations, not Git artifacts.

```bash
./dev doctor
./dev check
./dev run
./dev inspect
./dev shot
./dev emu stop
./dev emu start --window
./dev start
```

Duplicate backups and the organizer-repository checkout were removed after the
working environment was verified. Challenge resources bundled with `src/` and
PDF rules in `docs/` remain. The original smoke-test installation outside this
repository was not removed.

Current UI evidence: `suggested-host-venv/out/harmony-create/` (ignored). The flow
uses a local demo planner, not AI or actual health/watch capabilities. Reduced-motion
support is guarded for API23+; toggling the system preference was not tested.
