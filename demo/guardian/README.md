# Care Guardian: direct demo development

This is a snapshot of the working native Care Guardian app, independent of the planner and generator. Edit `app/entry/src/main/ets/pages/Index.ets` for UI and `app/entry/src/main/ets/care/` for device behavior. The dedicated backend snapshot is `../../suggested-host-venv/demo/guardian/care/`; edit that directory for voice, response classification and escalation. Changes here do not regenerate or replace `src/` or worker capabilities in `bot/`.

## Setup and run

From the repository root, after setting up the official SDK/emulator with the existing environment instructions:

```bash
git submodule update --init --recursive
./dev bot care-deps
# Fill suggested-host-venv/.env.local from its .env.example:
# ELEVENLABS_API_KEY, OPENAI_API_KEY, ELEVENLABS_PHONE_NUMBER_ID,
# DEMO_RECIPIENT_NUMBER (E.164), DEMO_CAREGIVER_NAME.
# Complete the existing Twilio/ElevenLabs phone setup if necessary.
./demo/guardian/dev setup
./demo/guardian/dev deps
./demo/guardian/dev check
./demo/guardian/dev runtime        # leave running in a terminal
# Another terminal:
./demo/guardian/dev run
./demo/guardian/dev inspect
./demo/guardian/dev shot demo/guardian/.local/guardian.jpeg
```

Three shakes initiate a **real** ElevenLabs voice session using laptop microphone/speakers by default. Say “No, I don't feel well”, then “I feel dizzy”. When asked whether to contact the caregiver, silence or an unrelated response leads to a real phone call. The four-second window starts after the question audio finishes; location acquisition and provider submission can add delay. Explicit refusal prevents automatic escalation. OpenAI checks response relevance. This is a hackathon demonstration, not a medical safety system.

```bash
./demo/guardian/dev stop-runtime  # stops this demo only; an existing phone call is independent
```

For iteration, edit the checked-in files, then `./demo/guardian/dev check` and `./demo/guardian/dev run --no-build`. Restart the demo backend after Python changes. No generation job, prompt or planner is needed. Demo prompts in `care/prompts.py` are supplied per new voice session/caregiver call, so restarting the backend applies edits without recreating remote agents.

## Isolation and local data

- Dedicated bundle: `com.hackyeah.guardian.demo`; generic worker apps cannot overwrite it.
- Dedicated backend port: `8789`; existing worker runtime remains on `8788`.
- Dedicated ignored state: `.local/care/` (agent IDs, scoped token, recipient, SQLite).
- Backend secrets remain in `suggested-host-venv/.env.local`; never embed provider keys in ArkTS.
- `setup` creates/reuses demo agents and writes an ignored `app/entry/src/main/resources/rawfile/care.json`. It does not modify native source.
- This machine initially reuses the existing validated remote agents, with a new app-scoped token and isolated state. A teammate's first setup provisions their own agents.
- Defaults target the existing `MissingAppClient` emulator, HDC port `15603`. Override `HOS_EMU_NAME` and `HOS_EMU_HDC_PORT` for another instance.
- For a physical phone set `GUARDIAN_DEVICE_URL=http://<laptop-LAN-IP>:8789` and `GUARDIAN_BIND=0.0.0.0` before setup/runtime; physical-device signing is still required and has not been tested. Do not expose this backend publicly.
- Location availability is not guaranteed. Emulator coordinates are explicitly marked simulated. Native emulator microphone remains unreliable; laptop audio is the tested path.

Build/install/UI launch are validated separately from placing calls; launching the demo does not start a voice check-in automatically.

## Validation of this snapshot

- Lint: no defects; official Hvigor build successful, unsigned HAP 190709 bytes. Compiler warnings remain for legacy native-audio API calls.
- Installed and launched `com.hackyeah.guardian.demo` on `127.0.0.1:15603`; UI shows the shake-to-start screen with laptop audio enabled. Screenshot visually inspected at `.local/guardian.jpeg`.
- Dedicated backend `/health` responds on port 8789; 14 isolated backend tests pass (mocked external calls).
- No new live voice session or phone call was started during isolation. End-to-end behavior is inherited from the previously tested app/runtime and still needs a live retest on this dedicated configuration.

## Demo presentation

Launcher name and icon are Care Guardian. Audio diagnostics are hidden by default; long-press the top Care Guardian header to reveal them. Laptop microphone/speakers remain the default. Three shakes begin the real test; Session controls are available only in hidden audio options (long-press the header).

## Background shake wake on the emulator

The native accelerometer listener remains active after pressing Home. Three impulses emit `GuardianWake: BACKGROUND_SHAKE_REQUEST`. While `./demo/guardian/dev runtime` is running, its dedicated HDC adapter opens the existing `com.hackyeah.guardian.demo/EntryAbility` without force-stopping the process. The foreground lifecycle then starts the pending voice check-in. Start the app once after reboot/build (`./demo/guardian/dev run --no-build`), press Home and leave it alive in the background; use the emulator's Shake control. One official `-shake` scenario produces the three impulses:

```bash
./demo/guardian/dev ui key Home
./demo/guardian/dev emu -shake
```

This is a **host-assisted emulator demo**, not a privileged standalone background-launch feature. It needs the laptop backend/HDC bridge and the native process alive; force-stop, process eviction, device reboot, lock-screen behavior and prolonged background suspension are not covered. Background startup of ordinary apps is restricted; see the local API 24 `application/UIAbilityContext.d.ts` and [Huawei UIAbilityContext documentation](https://developer.huawei.com/consumer/en/doc/harmonyos-references-V14/js-apis-inner-application-uiabilitycontext-V14).

Validated on this emulator: Home → native three-shake event → HDC foreground launch → pending check-in attempts backend connection, retaining the same PID. The voice backend was intentionally stopped for this wake test, so the expected connection error confirmed entry into the check-in without creating a live voice session/call. Backend and bridge were then restored, with the app left on Home and no session active. Restarting the bridge discards existing shake logs. `stop-runtime` stops the backend and its bridge together. For wake-only debugging: `./demo/guardian/dev wake-bridge` (Ctrl+C to stop).

## Conversation-first demo screen

The primary view shows an ordered, scrollable history of the current check-in, with Grandpa and Care Guardian speech in separate bubbles. Voice status is a small row below the header. No Start or End/Reset button appears in the presentation UI. History remains visible after disconnect and clears when a new shake-triggered check-in begins; it is held in memory and not persisted to disk. Long-press the header for the hidden Stop session control. Closed sessions automatically re-arm shaking.

UI validation uses a local ignored fixture with representative provider events, not a real phone call. Screenshots: `.local/conversation.jpeg` and `.local/conversation-compact.jpeg`.

## Grandpa, four-second escalation and mocked location

Demo narration uses Grandpa/he/him. The internal `grandma_agent` config key remains for compatibility with already provisioned agent IDs; it does not control narration. The native conversation history labels his speech Grandpa.

The dedicated backend's checked-in `context.json` supplies a **mock** HackYeah location at Tauron Arena, Kraków (50.067, 19.991). It is not live GPS. The caregiver call opens with a brief incident explanation and **does not volunteer location**. Ask “Where is he?” and the agent answers using the supplied location. The mock is also available to the companion. With this mock enabled, escalation does not wait up to five seconds for device GPS.

The timer starts after caregiver-question audio. Continuous raw VAD/noise cannot postpone it beyond its deadline; punctuation-only ASR such as “...” is not a meaningful response. Repeated contact questions cannot restart the timer. Pending semantic classification can delay a decision; explicit refusal still prevents automatic escalation. Logs include silence_window, reply_checked, silence_due, escalation_started and call_result, without logging transcript text or credentials. Phone ringing can occur later than the four-second trigger because provider submission/carrier setup takes time.

Validation: 20 tests passed, including a real-time relay with mocked providers submitting exactly once after approximately 4.02 seconds despite noise, ellipsis and a repeated question. No real outbound call was placed by this regression test. A real ElevenLabs WebSocket probe confirmed an opening about “Your grandfather…” with no location, followed by a HackYeah answer to “Where is he?”. This probe did not capture laptop audio or dial a phone. Per-session overrides use the [official ElevenLabs WebSocket protocol](https://elevenlabs.io/docs/eleven-agents/api-reference/eleven-agents/websocket).
