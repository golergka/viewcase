#if os(macOS)
  import Foundation
  import SwiftUI
  import Viewcase

  @main struct ViewcaseExampleApp: App {
    init() {
      do {
        if try ViewcaseCLI.run(
          arguments: Array(CommandLine.arguments.dropFirst()),
          stories: Self.stories)
        {
          exit(0)
        }
      } catch {
        FileHandle.standardError.write(Data((error.localizedDescription + "\n").utf8))
        exit(2)
      }
    }

    var body: some Scene {
      WindowGroup("Viewcase Example") {
        ViewcaseCatalog("Example App", stories: Self.stories)
          .frame(minWidth: 900, minHeight: 680)
      }
    }

    @MainActor private static var stories: [ViewcaseStory] {
      [
        ViewcaseStory("Default", group: "Profile", tags: ["user", "card"]) {
          ProfileCard(name: "Maya Chen", role: "iOS Engineer")
        },
        ViewcaseStory("Long name", group: "Profile", tags: ["localization"]) {
          ProfileCard(
            name: "Alexandria Montgomery-Santos",
            role: "Principal Product Designer")
        },
        ViewcaseStory("Interactive", group: "Controls", tags: ["state", "button"]) {
          CounterCard()
        },
        ViewcaseStory("Error", group: "Status", tags: ["failure", "offline"]) {
          StatusCard(
            title: "Couldn’t refresh projects",
            detail: "Check your connection and try again.")
        },
      ]
    }
  }

  private struct ProfileCard: View {
    let name: String
    let role: String

    var body: some View {
      HStack(spacing: 16) {
        Image(systemName: "person.crop.circle.fill")
          .font(.system(size: 52))
          .foregroundStyle(.blue)
        VStack(alignment: .leading) {
          Text(name).font(.title2.bold())
          Text(role).foregroundStyle(.secondary)
        }
      }
      .padding(24)
    }
  }

  private struct CounterCard: View {
    @State private var count = 0

    var body: some View {
      VStack(spacing: 14) {
        Text("Count: \(count)").font(.title2.monospacedDigit())
        HStack {
          Button("Decrease") { count -= 1 }
          Button("Increase") { count += 1 }.buttonStyle(.borderedProminent)
        }
      }
      .padding(24)
    }
  }

  private struct StatusCard: View {
    let title: String
    let detail: String

    var body: some View {
      VStack(spacing: 12) {
        Image(systemName: "exclamationmark.triangle").font(.largeTitle)
        Text(title).font(.title2.bold())
        Text(detail).foregroundStyle(.secondary)
      }
        .frame(width: 420, height: 280)
    }
  }
#endif
