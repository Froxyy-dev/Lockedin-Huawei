# AI Workflow

This project uses AI-assisted development. Keep this document current and public-safe. Do not include credentials, tokens, personal data, private endpoints, or confidential prompts.

## Tools used

| Model, agent, MCP server, or Agent Skill | Version or source | Role in the project |
| --- | --- | --- |
| Codex | GPT-6; local CLI agent | Linux environment setup, backup, build and emulator verification |

## Important prompts and instructions

- `AGENTS.md` — repository-wide hackathon constraints and working agreement.
- [Summarize the important project prompt or reusable instruction. Include the full public-safe text when practical.]

## AI-assisted work log

| Date | Tool/model | Request or task | Generated or changed | Human review and validation |
| --- | --- | --- | --- | --- |
| 2026-10-03 | Codex / GPT-6 | Use downloaded suggested-host-venv as Linux environment and retain previous test setup | Machine-local setup, fallback archive, environment verification; no application feature changes | Verified supplied CLT6.1.1.280 hash; lint/build passed; official API23 emulator booted headless; unsigned HAP installed; com.hackyeah.jit ran; UI click changed Hello World to Welcome; logs and screenshot verified. GPS injection command accepted, app location not tested. |

| 2026-10-03 | Codex / GPT-6 | Put the application in src and show 67 after clicking a button; run visible emulator | Copied template source into src, added Pokaż 67 button and state-controlled number, routed ./dev to src | Lint/build passed; HAP installed; app ran; initial UI had button only; CLI click displayed Text 67; no crash logs. |

| 2026-10-03 | Codex / GPT-6 | Commit required files and keep the environment independent | Added tested upstream environment as a submodule, documented clone/update setup, removed duplicate backups and organizer checkout | Remote contains pinned commit; root wrapper selects src; doctor/build and live app inspected after cleanup. No SDKs or credentials staged. |

| 2026-10-03 | Codex / GPT-6 | Build the specified native Harmony Create frontend in src; no real AI or health backend | Modular Create, prompt, capability, action, planning and placeholder components; tokens and mock planner; six local SVG icons | Lint/build, installation and launch passed. Screenshots inspected across three visual iterations; staged checkmarks, microphone log, edited prompt propagation, navigation, reset and timer cancellation verified. Fresh Celia keyboard configured in Basic mode. Reduced-motion preference implemented but setting toggle not exercised. |

| 2026-10-03 | Codex / GPT-6 | Fix clipped initial letter in prompt and rename product to The Missing App | Removed inner TextArea corner clipping, added text inset, updated header/back controls and launcher labels | Build and native screenshot verification performed on emulator. |

## Workflow

### Ideation and architecture

[Describe how AI influenced the product idea, scope, architecture, and platform-capability choice.]

### Implementation

[Describe the AI-assisted coding workflow and how generated output was reviewed before acceptance.]

### Testing and debugging

[Record builds, linting, tests, device/emulator runs, UI inspection, logs, screenshots, and manual checks.]

## Unsuccessful approaches

- Using CLT26 to build the API24 project failed with 00303313; installed the prescribed CLT6.1.1.280 instead. Huawei image download stalled and succeeded after a restart; partial download was preserved.

## Known limitations

- [Product, platform, model, data, testing, or tooling limitation.]

## Lessons learned

- [Concise lesson that would help reproduce or improve the work.]

## AI feature disclosure

Complete this section only if AI is part of the product itself; otherwise write "Not applicable."

- Model or service: [Name/version/provider]
- Inference flow: [On-device, remote, or hybrid; inputs and outputs]
- Data handling and privacy: [What leaves the device, retention, consent, and safeguards]
- Failure and fallback behavior: [How errors, latency, offline use, and unsafe output are handled]
- Evaluation: [Test cases, quality measures, human review, and known model limitations]


### Local generator integration (not committed)
User requested a local Codex generator test, then reported the UI did not submit. Added native NetworkKit client, ignored rawfile bot.json configuration, INTERNET permission, real job polling/error states, installation readiness and startAbility for com.hackyeah.generated. Separate client emulator MissingAppClient:15603 and verification HOS23:15601; device agent installs without launching. Local Codex adapter uses existing ChatGPT login; no Claude budget caps apply. No commits/pushes. Validation evidence is in suggested-host-venv/out/jobs and out/client-device-agent.log. Generation creates UI; real watch/health capabilities remain unimplemented.

Validation: UI Create submitted job 20261003-194930-5eb1; generator succeeded, delivery reported ok on 15603; Open your app invoked the native inter-app confirmation and opened Watch check-in. I need help updated visible text with an explicit simulation/no-messaging disclosure. Build/lint passed. Screenshots: backend-ready.jpeg and generated-watch-checkin.jpeg in ignored out/harmony-create.

### Generator failure and shake test
User job 20261003-195721-28af failed because @State scale conflicts with ArkUI CustomComponent.scale; ACCELEROMETER permission was missing. Updated local Codex prompt to avoid component-method field collisions and allow module.json5 permissions. Added max-two compiler-driven repair attempts to runner using ignored out/codex-agent.py (repair branches not exercised in this successful retry). Repeated the exact user prompt from UI as job 20261003-200056-530e: succeeded in 171 seconds, installed and opened. TESTED ./dev emu -shake: native UI changed from Potrząśnij telefonem to 67!, number bounding box changed; animation ended at Potrząśnij ponownie. No commits/pushes. Original failed job kept for evidence.
