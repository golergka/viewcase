import SwiftUI

/// One named, interactive state of a SwiftUI view.
public struct ViewcaseStory: Identifiable {
  public let id: String
  public let title: String
  public let group: String
  public let tags: [String]
  let makeContent: @MainActor () -> AnyView

  @MainActor public init<Content: View>(
    _ title: String,
    group: String = "Stories",
    id: String? = nil,
    tags: [String] = [],
    @ViewBuilder content: @escaping @MainActor () -> Content
  ) {
    self.id = id ?? "\(group)/\(title)"
    self.title = title
    self.group = group
    self.tags = tags
    self.makeContent = { AnyView(content()) }
  }
}

public enum ViewcaseAppearance: String, CaseIterable, Identifiable {
  case system = "System"
  case light = "Light"
  case dark = "Dark"

  public var id: Self { self }

  var colorScheme: ColorScheme? {
    switch self {
    case .system: nil
    case .light: .light
    case .dark: .dark
    }
  }
}

public enum ViewcaseTextSize: String, CaseIterable, Identifiable {
  case system = "System"
  case large = "Large"
  case accessibility = "Accessibility"

  public var id: Self { self }
}

public enum ViewcaseViewport: String, CaseIterable, Identifiable {
  case responsive = "Responsive"
  case phone = "Phone"
  case tablet = "Tablet"
  case desktop = "Desktop"

  public var id: Self { self }

  var size: CGSize? {
    switch self {
    case .responsive: nil
    case .phone: CGSize(width: 390, height: 700)
    case .tablet: CGSize(width: 768, height: 800)
    case .desktop: CGSize(width: 960, height: 700)
    }
  }
}
