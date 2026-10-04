# AI Workflow

The full, public-safe AI workflow for this submission is [`src/AI_WORKFLOW.md`](src/AI_WORKFLOW.md): the models,
agents and skills used, the main prompts, the development workflow, how generated output was reviewed and tested,
unsuccessful approaches, limitations, lessons learned, and the AI feature disclosure for the product itself.

The environment repository (`suggested-host-venv`, pinned as a submodule) carries the planner prompt
(`planner/prompt.md`), the worker brief (`bot/workers/`, `bot/knowledge/`) and the agent playbook (`AGENTS.md`).

## Pre-existing and third-party components

Everything in this repository and in `suggested-host-venv` was written during HackYeah 2026, starting with the
environment's first commit on 2026-10-03 at 16:46. Components that existed before and were used as-is:

- the organizers' **Hackathon Template** project (`src/` started from it), the `hmos-*` Agent Skills and the
  `devecocli` 1.3.4 offline documentation, all from `onirodeveloper/hackyeah2026-challenge`;
- Huawei's **Command Line Tools 6.1.1.280** (hvigor, ohpm, hdc, HarmonyOS SDK API 24) and **Emulator 26.0.0.402** with
  the HarmonyOS 6.1.0 (API 23) phone image, downloaded by each developer and never redistributed (hashes in the
  environment README);
- third-party services reached only through the server-side proxy: OpenAI-compatible models (planner, worker),
  ElevenLabs (speech); Claude Code and Codex CLI as the worker agents;
- Python 3 standard library, git, Remotion (demo video edit only).

No API keys, tokens, signing material, phone numbers or personal data are in either repository.
