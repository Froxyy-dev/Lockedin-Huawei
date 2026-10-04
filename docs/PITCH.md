# The Missing App — pitch (Huawei HackYeah 2026)

*Three minutes, spoken. Demo runs on the client emulator next to the speaker.*

## The missing app

Everyone has one. The app that should exist for their situation, but nobody built it: the reminder that fits the way
you live, the helper your grandmother would use, the tool for the one thing that keeps going wrong. The market for
those apps is every person, and it has never been served, because software only gets written for enough people.

**The Missing App makes that app for you. On your HarmonyOS phone. From one sentence.**

## How it works (the demo)

1. **You say what you need**, in your words. *(type a sentence)*
2. **A planner designs the solution**: a one-minute spec in plain language, written like a product designer who knows
   what your phone can do. You refine it until it is yours. Nothing is built before you accept. *(refine once, accept)*
3. **An AI engineer builds it**, in a private workspace, on a headless HarmonyOS toolchain, against the real SDK and
   the real device capabilities. It builds, runs and inspects its own work on an emulator in the cloud.
4. **The build server verifies it independently**: compiles, installs clean, launches, checks for crashes, reads the
   screen. Only an app that really runs becomes a version.
5. **It lands on your phone**, with its own name and icon, one tap away. Every version is kept; the next sentence
   builds on the last one.

## Born connected

The generated apps are not toys, because they are born connected. A registry of services, voice, language, vision,
lives on the server; the planner designs with them and the engineer wires them in through one proxy that holds the
keys. The app on the phone never carries a secret, every call is metered, and adding a capability to the registry
upgrades every future app. *(the demo app talks, reads, or understands, through a real service)*

## Why HarmonyOS, why Huawei

Within a year, any large lab will turn a sentence into an app. What they cannot own is the phone in the person's hand.

- **Distribution:** the app is installed directly on the device, through the platform's own tooling and signing.
- **Trust:** the person already has a Huawei account, a store and a billing relationship.
- **Judgment:** which services belong in which apps is a platform decision, enforced in one place, the registry and
  the proxy.

HarmonyOS is the natural home for apps born connected: one ecosystem that owns the device, the store, the keys and
the services. We built the factory; the platform brings the people.

## The business

- **Subscription** for creating and refining: how many apps, how much engineering effort.
- **Metered services** behind the proxy: voice, language, vision, on a per-use basis, one bill.
- **Platform gate:** every app passes the platform's verification before it reaches a phone.

## What is real today

- Four apps created end to end today: a water companion, a used-book finder, a CPR coach that speaks with ElevenLabs
  voices, an emergency helper. Minutes from sentence to phone.
- A deterministic harness around non-deterministic agents: versioned workspaces (git tag per spec and per build),
  independent verification, cancel that stops real processes, interchangeable engineers (Claude Code, Codex), a
  service proxy with keys on the server, and a test suite that proves every failure mode without spending a token.
- Everything headless, command-line only, reproducible on any Linux box: the official HarmonyOS CLI toolchain and
  the official emulator with no window.

## One line

**The Missing App: describe it, and your phone has it. Apps born connected, on HarmonyOS.**
