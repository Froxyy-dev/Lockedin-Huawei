# The Missing App — how it works

Everyone has one: the app that *should* exist for their situation, but nobody built it. The reminder that
fits the way you actually live. The helper your grandmother would use. The tiny tool for the one thing that
keeps going wrong. **The Missing App** makes that app for you, on your phone, from a sentence.

```
   you                     the service                                        your phone
 ────────             ─────────────────────────────────────────────────    ──────────────
 "I keep forgetting    Planner ──▶ spec ──▶ you refine/accept ──▶ Workers    the app you
  to drink water"                                                 build it   were missing,
                                                                  & verify   installed,
                                                                  ──▶ deploy ─▶ ready to open
```

## 1. Say what you need, in your words

No forms, no feature lists, no "select a template". You describe a problem, an idea, or just what is going on,
the way you would tell a friend. Urgent, vague, half a thought: all fine.

## 2. The Planner designs the solution

A designer, not a chatbot. The Planner reads your words the way a thoughtful product designer would: who you
are, what is really going on, the moments when the problem actually happens, and what the app must do in
those moments. Then it writes a **spec you can read in a minute**: what the app is, what it does, how it works,
a scene from your life with it, and what it deliberately does not do.

The Planner knows the only way it can help you is to make an app, and it knows what your phone can really
do: location and movement, sensors, voice, notifications, cards on the home screen, your watch, and the
voice and language services behind the scenes. It designs with all of that, in plain words.

## 3. The feedback loop: you stay in charge

Nothing is built until you say so. Read the summary, open the full spec, and either accept it or tell it
what to change. Every version is kept, so you can always go back.

```
                 ┌───────────────────────────────────────────────┐
                 │                                               │
   your words ──▶│  Planner  ──▶  Spec v1  ──▶  you read it      │
                 │                  ▲             │              │
                 │                  │     "make it simpler",     │
                 │                  │     "add my daughter",     │
                 │                  │     "no reminders at night"│
                 │                  │             │              │
                 │               Spec v2  ◀──── suggest changes  │
                 │                  │                            │
                 │                  ▼                            │
                 │              accept  ──────────────────▶ build│
                 └───────────────────────────────────────────────┘
```

Suggest changes as often as you like; each round produces a new version of the spec that remembers
everything before it. Accept when it is exactly yours.

## 4. Workers build it

When you accept, a **Worker**, an AI software engineer, gets the spec and nothing else: not your raw
words, not your data. It works inside your app's own private project, with real engineering sources at
hand: the official HarmonyOS SDK, the device's actual capabilities, offline documentation and curated
ArkTS/ArkUI guidance. It writes native HarmonyOS code, builds, runs, looks at the result and fixes what it
finds. Fast mode builds the smallest complete version of your spec first; you can stop it at any moment,
and your app simply returns to its last finished version.

## 5. A fully headless toolchain, in the cloud

No IDE, no screen, no human clicking "Run". The whole factory is command-line only and runs on a server:

```
   accept
     │
     ▼
   private git workspace for your app  ──▶  headless HarmonyOS emulator (no window, no GUI)
     │                                              │
     ▼                                              ▼
   Worker writes the code  ──▶  build  ──▶  install  ──▶  launch  ──▶  inspect
                                                                        │
                       independent verification: compiles? starts? no crash? the screen shows the spec?
                                                                        │
                                                 pass ──▶ version saved (rev N)      fail ──▶ back to last good
```

The verification does not trust the Worker's word. The build server compiles the app, installs it on a
clean headless emulator, launches it, checks for crashes and reads the live widget tree. Only an app that
really runs becomes a version of your creation.

## 6. Installed directly on your device

The finished app is delivered straight to your phone: its own name, its own icon, ready in your launcher
and opened with one tap from The Missing App. Paid services such as natural voices or language
understanding work out of the box: the app talks to them through our service gateway, so no key ever sits
on your phone and nothing can run up a bill in your name.

Want more? Suggest a change, accept, and a new version is built on top of the last one. Your app grows
with you, one sentence at a time.

---

**For the curious:** every creation is `you → project → git repository`. Specs are tagged `spec-N`, successful
builds `rev-N`, so any version can be opened, compared or restored. The Planner and the Workers share exactly
one artifact, the spec. Workers are interchangeable (Claude Code today, Codex too) behind one contract, run
inside the project's own repository only, and are stopped completely the moment you press Cancel. The full
design lives in the environment repository under `docs/HARNESS.md`.
