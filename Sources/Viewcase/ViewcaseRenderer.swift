#if os(macOS)
  import AppKit
  import SwiftUI

  public enum ViewcaseRenderError: LocalizedError {
    case invalidArguments(String)
    case storyNotFound(String)
    case imageCreationFailed

    public var errorDescription: String? {
      switch self {
      case .invalidArguments(let message): message
      case .storyNotFound(let id): "No story has the ID '\(id)'. Use --list to see available stories."
      case .imageCreationFailed: "Could not render the story as a PNG."
      }
    }
  }

  public struct ViewcaseRenderRequest {
    public let storyID: String
    public let outputURL: URL
    public let appearance: ViewcaseAppearance
    public let textSize: ViewcaseTextSize
    public let size: CGSize

    public init(
      storyID: String,
      outputURL: URL,
      appearance: ViewcaseAppearance = .system,
      textSize: ViewcaseTextSize = .system,
      size: CGSize = CGSize(width: 960, height: 700)
    ) {
      self.storyID = storyID
      self.outputURL = outputURL
      self.appearance = appearance
      self.textSize = textSize
      self.size = size
    }

    @MainActor public func render(stories: [ViewcaseStory]) throws {
      guard let story = stories.first(where: { $0.id == storyID }) else {
        throw ViewcaseRenderError.storyNotFound(storyID)
      }
      try ViewcaseRenderer.render(
        story,
        appearance: appearance,
        textSize: textSize,
        size: size,
        to: outputURL)
    }
  }

  public enum ViewcaseCLI {
    /// Handles Viewcase command-line arguments. Returns false when the catalog UI should launch.
    @MainActor public static func run(
      arguments: [String],
      stories: [ViewcaseStory]
    ) throws -> Bool {
      guard !arguments.isEmpty else { return false }
      if arguments == ["--list"] {
        for story in stories { print("\(story.id)\t\(story.group)\t\(story.title)") }
        return true
      }
      if arguments == ["--help"] {
        print(usage)
        return true
      }

      let request = try parse(arguments)
      try request.render(stories: stories)
      print(request.outputURL.path)
      return true
    }

    public static let usage = """
      Usage:
        APP --list
        APP --render STORY_ID --output FILE [--appearance system|light|dark]
            [--text-size system|large|accessibility] [--viewport phone|tablet|desktop]
            [--size WIDTHxHEIGHT]
      """

    private static func parse(_ arguments: [String]) throws -> ViewcaseRenderRequest {
      var storyID: String?
      var outputPath: String?
      var appearance = ViewcaseAppearance.system
      var textSize = ViewcaseTextSize.system
      var size = ViewcaseViewport.desktop.size!
      var index = 0

      func value(after option: String) throws -> String {
        guard index + 1 < arguments.count, !arguments[index + 1].isEmpty else {
          throw ViewcaseRenderError.invalidArguments("Missing value after \(option).\n\(usage)")
        }
        return arguments[index + 1]
      }

      while index < arguments.count {
        let option = arguments[index]
        switch option {
        case "--render":
          storyID = try value(after: option)
        case "--output":
          outputPath = try value(after: option)
        case "--appearance":
          let raw = try value(after: option)
          guard let parsed = ViewcaseAppearance.allCases.first(where: { $0.rawValue.lowercased() == raw.lowercased() }) else {
            throw ViewcaseRenderError.invalidArguments("Invalid appearance '\(raw)'.")
          }
          appearance = parsed
        case "--text-size":
          let raw = try value(after: option)
          guard let parsed = ViewcaseTextSize.allCases.first(where: { $0.rawValue.lowercased() == raw.lowercased() }) else {
            throw ViewcaseRenderError.invalidArguments("Invalid text size '\(raw)'.")
          }
          textSize = parsed
        case "--viewport":
          let raw = try value(after: option)
          guard let viewport = ViewcaseViewport.allCases.first(where: { $0.rawValue.lowercased() == raw.lowercased() }),
                let viewportSize = viewport.size
          else {
            throw ViewcaseRenderError.invalidArguments("Invalid render viewport '\(raw)'.")
          }
          size = viewportSize
        case "--size":
          size = try parseSize(try value(after: option))
        default:
          throw ViewcaseRenderError.invalidArguments("Unknown option '\(option)'.\n\(usage)")
        }
        index += 2
      }

      guard let storyID, let outputPath else {
        throw ViewcaseRenderError.invalidArguments("--render and --output are required.\n\(usage)")
      }
      return ViewcaseRenderRequest(
        storyID: storyID,
        outputURL: URL(fileURLWithPath: outputPath),
        appearance: appearance,
        textSize: textSize,
        size: size)
    }

    private static func parseSize(_ raw: String) throws -> CGSize {
      let parts = raw.lowercased().split(separator: "x", omittingEmptySubsequences: false)
      guard parts.count == 2,
            let width = Double(parts[0]), let height = Double(parts[1]),
            width > 0, height > 0
      else {
        throw ViewcaseRenderError.invalidArguments("Invalid size '\(raw)'; expected WIDTHxHEIGHT.")
      }
      return CGSize(width: width, height: height)
    }
  }

  @MainActor public enum ViewcaseRenderer {
    public static func render(
      _ story: ViewcaseStory,
      appearance: ViewcaseAppearance = .system,
      textSize: ViewcaseTextSize = .system,
      size: CGSize,
      to outputURL: URL
    ) throws {
      let app = NSApplication.shared
      app.setActivationPolicy(.prohibited)

      let content = story.makeContent()
        .viewcaseTextSize(textSize)
        .preferredColorScheme(appearance.colorScheme)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
      let hostingView = NSHostingView(rootView: content)
      hostingView.frame = NSRect(origin: .zero, size: size)
      if appearance != .system {
        hostingView.appearance = NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
      }

      let window = NSWindow(
        contentRect: hostingView.frame,
        styleMask: [.borderless],
        backing: .buffered,
        defer: false)
      window.contentView = hostingView
      hostingView.layoutSubtreeIfNeeded()

      guard let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
        throw ViewcaseRenderError.imageCreationFailed
      }
      hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
      guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw ViewcaseRenderError.imageCreationFailed
      }
      try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true)
      try png.write(to: outputURL, options: .atomic)
    }
  }
#endif
