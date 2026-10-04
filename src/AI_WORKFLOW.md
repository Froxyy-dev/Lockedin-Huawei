# AI Workflow

This project uses AI-assisted development. Keep this document current and public-safe. Do not include credentials, tokens, personal data, private endpoints, or confidential prompts.

## Tools used

| Model, agent, MCP server, or Agent Skill | Version or source | Role in the project |
| --- | --- | --- |
| Codex | GPT-6; local CLI agent | Linux environment setup, backup, build and emulator verification; Care Guardian demo |
| Claude Code | Claude Fable 5.1 / Opus 5.5; local CLI agent | Headless environment, harness, planner, test framework, client harness screens, reviews |
| Planner model | OpenAI-compatible, default `gpt-6.1-sol` with fallbacks | In the product: turns a person's problem into a plain-language app spec |
| Worker agents | Claude Code headless (Opus only) or Codex CLI | In the product: implement the accepted spec inside the project's own git workspace |
| hmos-* Agent Skills | hackathon repository (`./dev skills`) | ArkTS/ArkUI rules and examples, loaded into the worker as a session plugin |
| devecocli docs | Huawei devecocli 1.3.4, offline | HarmonyOS guides and FAQs available to the worker without network |

## Important prompts and instructions

- `AGENTS.md` — repository-wide hackathon constraints and working agreement.
- `suggested-host-venv/AGENTS.md` — the environment playbook: the edit → check → run → inspect loop, a symptom → command
  debugging table, the evidence standard, and the rule that paid APIs are reachable only through registered services.
- `suggested-host-venv/planner/prompt.md` — the planner speaks as a product designer, not as the app. It is principle-based
  (understand the person and the moment, prefer the simplest dependable app, find things out instead of asking) and
  deliberately avoids per-case examples so good specs are a side effect of the principles, not of overfitting.
- `suggested-host-venv/bot/workers/claude` + `bot/knowledge/knowledge.md` — the worker brief: work only inside the
  project repository, ground every platform API in the SDK declarations, the device's real capabilities
  (`./dev caps`), offline docs or skills, and prove the result on the emulator before reporting.

## AI-assisted work log

| Date | Tool/model | Request or task | Generated or changed | Human review and validation |
| --- | --- | --- | --- | --- |
| 2026-10-03 | Codex / GPT-6 | Use downloaded suggested-host-venv as Linux environment and retain previous test setup | Machine-local setup, fallback archive, environment verification; no application feature changes | Verified supplied CLT6.1.1.280 hash; lint/build passed; official API23 emulator booted headless; unsigned HAP installed; com.hackyeah.jit ran; UI click changed Hello World to Welcome; logs and screenshot verified. GPS injection command accepted, app location not tested. |

| 2026-10-03 | Codex / GPT-6 | Put the application in src and show 67 after clicking a button; run visible emulator | Copied template source into src, added Pokaż 67 button and state-controlled number, routed ./dev to src | Lint/build passed; HAP installed; app ran; initial UI had button only; CLI click displayed Text 67; no crash logs. |

| 2026-10-03 | Codex / GPT-6 | Commit required files and keep the environment independent | Added tested upstream environment as a submodule, documented clone/update setup, removed duplicate backups and organizer checkout | Remote contains pinned commit; root wrapper selects src; doctor/build and live app inspected after cleanup. No SDKs or credentials staged. |

| 2026-10-03 | Codex / GPT-6 | Build the specified native Harmony Create frontend in src; no real AI or health backend | Modular Create, prompt, capability, action, planning and placeholder components; tokens and mock planner; six local SVG icons | Lint/build, installation and launch passed. Screenshots inspected across three visual iterations; staged checkmarks, microphone log, edited prompt propagation, navigation, reset and timer cancellation verified. Fresh Celia keyboard configured in Basic mode. Reduced-motion preference implemented but setting toggle not exercised. |

| 2026-10-03 | Codex / GPT-6 | Fix clipped initial letter in prompt and rename product to The Missing App | Removed inner TextArea corner clipping, added text inset, updated header/back controls and launcher labels | Build and native screenshot verification performed on emulator. |

| 2026-10-03 | Claude Code | Reproducible headless HarmonyOS environment and app-creator bot | `suggested-host-venv`: `./dev`, isolated HOME and hdc port, headless API 23 emulator, bot API with independent verification | Smoke test of the official CLI stack (report in the environment repo); bot jobs built, installed and inspected on the emulator. |

| 2026-10-03 | Claude Code | Planner: problem → plain-language app spec | `planner/` module, designer-voice prompt, services registry shared with the worker | Specs reviewed by the team on several real problems; prompt iterated to stay generic. |

| 2026-10-04 | Claude Code | Harness: creations, revisions, accept/refine, build | `harness/` (store, per-project git workspace, stages, HTTP API), client screens in `src/` | Unit, integration and contract tests; end-to-end runs on the emulator. |

| 2026-10-04 | Claude Code | Service proxy for generated apps | `/services/<id>/…` on the harness: server-held keys, exposed-path allowlist, optional daily cap; app config written at accept | Tests against a fake provider (key swap, refusals, limits); one live, free provider call through the proxy. |

| 2026-10-04 | Claude Code | Mock test framework, worker abstraction, platform knowledge for workers | Mock planner/agent/device behind env seams; `bot/workers/` contract; Opus-only worker with a hook-enforced subagent cap; SDK/docs/skills access; per-revision app name and icon | Unit and integration tiers green; real-emulator tier green with mocked models; a cheap real Claude run confirmed the subagent cap and knowledge access. |

## Workflow

### Ideation and architecture

The product is an app that makes apps. A person describes a problem in their own words. A **planner** model turns it
into a short spec a non-technical person can read, they refine or accept it, and a **worker** agent builds a native
HarmonyOS app from the spec. The architecture keeps every non-deterministic step behind a deterministic control loop:

```
client (src/) ─▶ harness API ─▶ planner ─▶ spec (versioned)
                     │ accept
                     ▼
                bot control loop: workspace ─▶ emulator ─▶ baseline build ─▶ worker ─▶ independent verify
                     │ success: commit + tag rev-N          failure: workspace reset to last good build
                     ▼
                client opens the generated app
```

- Each creation is `client → project → git workspace`. Specs are tagged `spec-N`, successful builds `rev-N`, so every
  revision has its spec, its code and a diff.
- The spec is the only artifact the planner and the worker share. The worker never sees the person's raw words.
- Workers are interchangeable behind one contract (`bot/workers/<name>`), routed by name, run inside the project's git
  repository only.
- Paid APIs live on the server as **services** added by developers; the planner and the worker read the same registry.

### Implementation

AI coding agents (Claude Code, Codex) implemented the environment, the harness and the client screens in small,
reviewed steps, each ending with lint/build, tests and an emulator check. Human review decided scope and design:
for example, the planner prompt was rewritten several times to stay generic instead of fitting the test cases, and the
team split keeps demo work and harness work in separate branches.

### Testing and debugging

- `./dev test unit` (fast, no network) and `./dev test integration` (real servers, real git, real HarmonyOS builds;
  mocked models and device, zero tokens). An opt-in tier runs the same flow on the real emulator.
- Mocks sit behind one environment variable each (planner endpoint, worker, device), so failures such as compile
  errors, crashes, planner outages and an unreachable build server are reproducible tests, not anecdotes.
- Contract tests check the client's ArkTS interfaces against the server's real JSON.
- Every worker result is verified independently: lint and build, clean install, launch, crash files, widget tree.

## Unsuccessful approaches

- Using CLT26 to build the API24 project failed with 00303313; installed the prescribed CLT6.1.1.280 instead. Huawei image download stalled and succeeded after a restart; partial download was preserved.
- A client POST with an empty body failed inside the HTTP kit with an opaque error; the client now always sends JSON and
  maps errors to readable text, and a contract test guards the shape.
- Early worker runs had turn and budget caps that cut real builds short; replaced by Opus with a hook-enforced subagent
  limit and an independent verification step.
- A prompt with worked examples biased the planner toward those cases; examples were removed from the prompt.

## Known limitations

- Paid services go through the server's proxy with one shared app token (an optional daily cap exists, off by default); per-user
  quotas and subscription gating are not built yet.
- Physical phones need AGC signing; generated apps are verified on the API 23 emulator only.
- The emulator cannot inject accelerometer or gyroscope data and has no camera; such features are built but not
  exercised end to end.

## Lessons learned

- Make the agent's step the only non-deterministic one, and verify its output independently of what it claims.
- Put every external dependency behind a single seam; mocks then make failure modes cheap, repeatable tests.
- Give agents ground truth (SDK declarations, device capabilities, docs) instead of relying on model memory.

## AI feature disclosure

Complete this section only if AI is part of the product itself; otherwise write "Not applicable."

- Model or service: planner on an OpenAI-compatible model (default `gpt-6.1-sol`, with fallbacks); worker on Claude
  Opus (Claude Code, headless) or Codex CLI. Generated apps may use registered services (OpenAI, ElevenLabs).
- Inference flow: remote. The client sends the person's text to the harness; the planner returns a spec; on accept
  the worker builds the app on the build server. Generated apps reach paid services only through the server.
- Data handling and privacy: the person's text goes to the planner model; the worker sees only the spec. Provider keys
  stay on the server and are never placed in an app. Per-client storage on the server, git-versioned.
- Failure and fallback behavior: planner retries and model fallbacks, then a clear "planner unavailable" error; failed
  builds keep the last good version of the app and report the reason (build error, crash, worker failure).
- Evaluation: automated tests with mocked models for every pipeline failure mode; spec quality reviewed by the team on
  real problems; generated apps verified on the emulator (build, install, launch, crash check, widget tree).


### Local generator integration (not committed)
User requested a local Codex generator test, then reported the UI did not submit. Added native NetworkKit client, ignored rawfile bot.json configuration, INTERNET permission, real job polling/error states, installation readiness and startAbility for com.hackyeah.generated. Separate client emulator MissingAppClient:15603 and verification HOS23:15601; device agent installs without launching. Local Codex adapter uses existing ChatGPT login; no Claude budget caps apply. No commits/pushes. Validation evidence is in suggested-host-venv/out/jobs and out/client-device-agent.log. Generation creates UI; real watch/health capabilities remain unimplemented.

Validation: UI Create submitted job 20261003-194930-5eb1; generator succeeded, delivery reported ok on 15603; Open your app invoked the native inter-app confirmation and opened Watch check-in. I need help updated visible text with an explicit simulation/no-messaging disclosure. Build/lint passed. Screenshots: backend-ready.jpeg and generated-watch-checkin.jpeg in ignored out/harmony-create.

### Generator failure and shake test
User job 20261003-195721-28af failed because @State scale conflicts with ArkUI CustomComponent.scale; ACCELEROMETER permission was missing. Updated local Codex prompt to avoid component-method field collisions and allow module.json5 permissions. Added max-two compiler-driven repair attempts to runner using ignored out/codex-agent.py (repair branches not exercised in this successful retry). Repeated the exact user prompt from UI as job 20261003-200056-530e: succeeded in 171 seconds, installed and opened. TESTED ./dev emu -shake: native UI changed from Potrząśnij telefonem to 67!, number bounding box changed; animation ended at Potrząśnij ponownie. No commits/pushes. Original failed job kept for evidence.

### Care Guardian executor
2026-10-03: Codex implements reusable native capabilities and a local ElevenLabs runtime from a supplied plan. Worker model gpt-6-sol; native audio, shake, location and escalation require independent device verification. Provider secrets remain backend-only.

### Care Guardian worker and runtime handover

Codex implemented reusable native shake, audio, location and voice UI capabilities in the independent environment, optional plan submission, ElevenLabs agent/tool provisioning, scoped runtime auth, a real echo-cancelled host audio bridge and persistent call reservations. Worker model gpt-6-sol was tested through CLI. User confirmed hearing the agent and recognition of live microphone speech; one real caregiver call was submitted, observed in-progress, and ended. Native emulator microphone failed with no available microphone and zero samples. Latest app with default laptop bridge builds/installs/launches. Backend tests cover contract/auth/duplicate-call and response timing; actual gpt-6-sol API classified four public synthetic responses correctly. Voice model changed to gpt-6-luna for concise replies. Location remains unavailable in the tested call; full shake, exact live4s semantic timing and physical-device/background behavior remain unverified. Added teammate dependency, phone-number, plan, runtime and shutdown commands. No credentials, real phone numbers, audio or generated HAPs are published.
