# SIGNAL — The Game (ATC)

**SIGNAL** is a text-based iOS **training-style simulation** where **you play Toronto-area air traffic control**. The frequency is voiced by the OpenAI API: overlapping comms, static, and **technical** inflight difficulties (for example weather, low fuel, avionics confusion) around **DELVE123 Heavy**, **Lake Ontario**, and normal Toronto-area references—the radar view is **stylized** and **not** a real Nav Canada sectional.

This repository is a native **Swift / SwiftUI** app (iOS 17+).

## Requirements

- Xcode 15+ (project targets iOS 17)
- An [OpenAI API](https://platform.openai.com/) key with access to the Chat Completions API
- Optional: an **HTTPS** URL to **MP3 or AAC** audio you have the **legal right** to use (public domain, your own hosting, or Creative Commons with proper compliance)

## Quick start

1. Open `SIGNALTheGameATC.xcodeproj` in Xcode.
2. Select your development team under **Signing & Capabilities**.
3. Build and run on a simulator or device (`⌘R`).
4. In the app, open **Settings**, paste your **OpenAI API key**, choose a **model** if you like (default: `gpt-4o-mini`), then **Save**.
5. Tap **New** to start a run, then type ATC-style transmissions in the composer.

Command-line build (Simulator):

```bash
xcodebuild -scheme SIGNALTheGameATC -destination 'generic/platform=iOS Simulator' build
```

## Features

- **AI-driven radio**: System prompt in `SIGNALTheGameATC/Prompts/ATCSystemPrompt.swift` defines roles (you = ATC only; the model = everything on frequency).
- **Keychain**: API keys are stored on-device via Keychain, not in source control.
- **Radio bed**: Procedural static always runs; optional stream is mixed in if you configure a URL in Settings.
- **“Sectional-adjacent” scope**: `TorontoRadarView` shows a radar-style schematic with approximate geography.

## Configuration

| Setting | Purpose |
|--------|---------|
| OpenAI API key | Required for AI replies; saved in Keychain |
| Model | e.g. `gpt-4o-mini`, `gpt-4o` |
| HTTPS stream URL | Optional MP3/AAC bed; leave blank for static only |

`Info.plist` allows **arbitrary loads for media** so `AVPlayer` can reach user-supplied stream URLs. Tighten this for production if you only use a fixed set of domains.

## Use responsibly

The scenario is **fictional** and meant to read like **phraseology practice with AI**, not like real-world tragedy. Do not use the app to harass real ATC or to encourage harm. Adjust tone in `ATCSystemPrompt.swift` if your deployment needs stricter boundaries.

## Project layout

```
SIGNALTheGameATC/
├── SIGNALTheGameATCApp.swift    # App entry
├── ContentView.swift            # Main screen
├── Models/GameMessage.swift
├── Services/
│   ├── OpenAIService.swift      # Chat Completions client
│   ├── RadioAudioManager.swift
│   └── KeychainStore.swift
├── ViewModels/ATCGameViewModel.swift
├── Views/ TorontoRadarView.swift, SettingsView.swift
└── Prompts/ATCSystemPrompt.swift
```

## License

No license file is included in this repository unless you add one. Add a `LICENSE` if you plan to distribute the project.
