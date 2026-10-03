# The Missing App — Care Guardian executor specification

## Objective and ownership

The planner is implemented separately by a teammate. This worker accepts its version1 plan, composes executable native capabilities, provisions voice agents, builds/verifies a HAP and delivers it. Develop reusable capabilities in `suggested-host-venv`, not hand-edited generated apps. `src/` remains the creation client; connecting the planner's output to its request is the planner integration step.

Example request: “My grandma lives alone and wears a Huawei Watch. If something unusual happens I want to know. My number is [my_number].” First demo uses phone/emulator shake or Start check-in; no real watch integration.

## Generation

Supplied plan → validate capabilities/parameters → create/reuse companion and caregiver ElevenLabs agents → compose ArkTS/ArkUI modules → Codex gpt-6-sol polishes the page → independent lint/build/install/launch/inspect → HAP delivery. Existing prompt-only Codex/Claude generation remains supported.

Capabilities: ShakeTrigger, VoiceConversation, LocationProvider, ContactCaregiver, AgentSurface. Version1's exact JSON and teammate setup are in [Care Guardian integration](suggested-host-venv/docs/CARE_GUARDIAN.md). No separate planner implementation is introduced here.

## Runtime demonstration

1. Grandma feels unwell; three detected shakes within2s or Start check-in opens one voice session.
2. Agent: “Are you okay?” Grandma: “No, I don't feel well.”
3. Agent briefly asks what is wrong. Grandma: “I feel dizzy.”
4. Agent: “Would you like me to contact Mateusz?”
5. No meaningful related response for4s after estimated question playback ends → escalate once. No repeat question.
6. Relevant speech is evaluated, not merely treated as sound. Explicit agreement/contact request authorizes immediate contact. Explicit refusal prevents contact. A relevant question/request to wait resolves the pending deadline. Unrelated/unintelligible speech does not cancel it. VAD holds the action during speech; semantic classification holds it while the answer is evaluated. Classification failure stops automatic escalation and surfaces an error.
7. Runtime requests location with a5s grace period. Missing/denied position does not block the call and is not replaced with invented coordinates.
8. ElevenLabs/Twilio ring the configured caregiver's phone. Agent explains “Your grandmother stopped responding, so I contacted you” or the corresponding lack-of-meaningful-response/requested-help reason. No response is itself the incident, not “no information available”. Only reported symptoms and available location are supplied. Caregiver can converse with the alert agent.
9. Grandma's voice session and host capture/playback stop after call submission; End / Reset or leaving the page also ends the conversation. Phone calls already submitted are independent and must be ended on the phone.

## Platform and provider decisions

- Native ArkTS/ArkUI; build SDK API24, minimum API20, verified emulator API23.
- Real host microphone/speaker bridge is the current default, visibly labeled. Emulator native microphone failed on this host; native mode remains diagnostic. No scripted speech buttons replace the actual conversation.
- Two agents are created via ElevenLabs API per experience and reused across sessions. Voice-agent LLM defaults to gpt-6-luna for speed and short replies. Generation and semantic-response checking use gpt-6-sol.
- Foreground demo is accepted when background activation/floating UI is unavailable. Neither background activation nor watch hardware is claimed as working.
- Call reservation is stored before submission; duplicate events or an ambiguous provider error do not trigger automatic retries.
- Secrets and phone numbers stay in the backend's ignored `.env.local` / private runtime data. App-scoped runtime tokens are in private generated config/HAPs, never published. No signing credentials are committed.

## Validation status

TESTED: supplied-plan generation/build/install/launch; automatic agent/tool provisioning; user-confirmed host mic recognition and audible replies; real caregiver call accepted, observed in-progress and completed; duplicate/ambiguous-call unit tests; actual semantic API examples for agreement, refusal, unrelated reply and request to wait; latest native build with laptop default.

FAILED: native emulator microphone (`no available microphone found!!`, zero samples).

NOT YET VERIFIED: complete Care Guardian shake flow, exact live4s timing with all semantic branches, actual current location, physical-device signing/audio and activation from background. The absence of location is supported; the earlier call went through without it.

## Acceptance and handover

Generate/deploy from a supplied plan without manual edits to the resulting app. Exercise live conversation, irrelevant replies, refusal, reset, network/provider errors, location denial and a single real caregiver call. Distinguish verified behavior from pending device tests. Keep the environment independently versioned; push its commit before the parent submodule pointer. Teammates configure their own credentials and licensed SDK/emulator packages rather than copying private generated artifacts.
