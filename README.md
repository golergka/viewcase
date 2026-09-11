# Viewcase

Viewcase is an interactive SwiftUI component catalog for macOS and iOS. Register a view with the state you want to review, then browse, search, resize, restyle, interact with, and reset it in a native catalog.

```swift
import Viewcase

let stories = [
  ViewcaseStory("Loaded", group: "Account") {
    AccountView(model: .fixture)
  },
  ViewcaseStory("Error", group: "Account", tags: ["offline"]) {
    AccountView(model: .failed)
  },
]

ViewcaseCatalog("My App", stories: stories)
```

Each story is an ordinary SwiftUI closure. It can contain bindings, local state, mock models, and simulated actions. Viewcase does not connect to production services or discover private runtime metadata.

## What it provides

- Native, embedded catalog navigation on macOS and iOS
- Explicit groups, names, stable identifiers, tags, and search
- System, Light, and Dark appearance modes
- System, large, and accessibility text sizes
- Responsive, phone, tablet, and desktop canvases
- Interactive views and one-click state reset
- Offscreen PNG rendering for agents and CI
- No third-party or binary dependencies

## Installation

Add this package in Xcode and link the `Viewcase` product to a development or internal app target:

```text
https://github.com/golergka/viewcase
```

Keep catalogs out of production builds unless shipping an internal gallery is intentional. Applications remain responsible for fixture data and for replacing network, persistence, analytics, and other production effects.

Run the included macOS example app:

```sh
Scripts/run-example
```

## Render from the command line

Agents and CI can render a registered story directly to a PNG without opening an interactive window or activating the application:

```sh
Scripts/run-example --list
Scripts/run-example \
  --render "Controls/Interactive" \
  --output /tmp/interactive-dark.png \
  --appearance dark \
  --text-size large \
  --viewport desktop
```

Use `--size 420x720` for an exact canvas instead of a viewport preset. The renderer constructs the story in an offscreen `NSHostingView`, captures it, writes the requested file, and exits. It never orders a window onto the screen and sets the process activation policy to prohibited.

## Why use Viewcase?

Viewcase covers interactive design review. The alternatives below solve related but different problems.

### Xcode previews

Xcode previews are excellent while editing one source file. Viewcase gives a team a persistent, searchable catalog that runs as an application, groups states across files and modules, and can be reviewed without opening each preview declaration in Xcode.

### Storybook-SwiftUI

Viewcase uses normal Swift values for registration and a native split-view layout. It does not depend on Objective-C runtime discovery, static reflection conventions, or a patched dependency. It also treats System appearance and an embedded macOS canvas as core behavior.

Storybook-SwiftUI has a broader existing Storybook-style API and may suit applications that already use its conventions. In our macOS evaluation, its story destination appeared in a detached navigation popover and its current package required a local compiler workaround.

### SnapshotPreviews

SnapshotPreviews discovers Xcode previews and renders them through an XCTest workflow. It is a strong fit for automated image export and Sentry Snapshots. Viewcase is a direct dependency with explicit registration and an interactive runtime browser; it does not require XCTest, preview metadata discovery, or the package’s prebuilt support framework.

Our command-line-only evaluation did not reproduce SnapshotPreviews’ documented Xcode setup, so it should not be read as evidence that the package is generally unusable.

### Point-Free SnapshotTesting

SnapshotTesting records images and asserts them in tests. Viewcase lets a person manipulate the live view and inspect many registered states. They complement each other: use Viewcase for exploration and SnapshotTesting for regression checks in CI.

### A custom preview application

Viewcase extracts the common catalog, navigation, canvas, appearance, sizing, and reset behavior. An application only supplies its stories and fixtures, instead of maintaining another preview shell.

## Design

Registration is deliberately explicit. Runtime discovery is convenient until compiler optimization, preview metadata, or platform differences hide a view. A `ViewcaseStory` is stable, searchable, and type-erased only at the catalog boundary.

Story content is rebuilt when Reset is pressed. Appearance, text size, viewport, search, and selection are local reactive state, so every control updates the canvas directly.

## Status

Viewcase currently targets macOS 13 and iOS 16 or newer. The package and macOS example are build-verified. The iOS API is present, but the example has not yet been exercised in an iOS simulator.

## License

MIT
