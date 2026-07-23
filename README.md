# Brew GUI

A native macOS SwiftUI control center for common Homebrew workflows.

## Features

- Search formulae and casks with `brew search TEXT` or `brew search /REGEX/`
- Inspect packages with `brew info`
- Install, upgrade, uninstall, and list formulae or casks
- Run maintenance commands: `brew update`, `brew upgrade`, `brew config`, `brew doctor`
- Use advanced commands: `brew install --verbose --debug`, `brew create`, `brew edit`
- Stream command output in the app and keep a small command history
- Follow the app language configured in macOS System Settings. English and Simplified Chinese are included.

## Run From Source

```sh
swift run BrewGUI
```

## Build a macOS App Bundle

```sh
./scripts/build-app.sh
open .build/app/BrewGUI.app
```

The app searches for Homebrew in `/opt/homebrew/bin/brew`, `/usr/local/bin/brew`, and then the process `PATH`.

## Language

The app uses native macOS localization. To switch languages, open System Settings, choose General, then Language & Region, and set the language for Brew GUI in Applications. Relaunch the app after changing that setting.

## Notes

This app calls `brew` directly with structured process arguments. It does not build shell command strings from user input.
