# Lockedin-Huawei

Native ArkTS/ArkUI app for the Huawei HackYeah challenge. The current demo displays
`67` after clicking **Pokaż 67**. Application source lives in [`src/`](src/).

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
