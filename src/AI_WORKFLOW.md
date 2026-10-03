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
