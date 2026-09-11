import SwiftUI

/// A searchable, interactive catalog for registered SwiftUI view states.
public struct ViewcaseCatalog: View {
  private let title: String
  private let stories: [ViewcaseStory]

  @State private var selection: String?
  @State private var query = ""
  @State private var appearance = ViewcaseAppearance.system
  @State private var textSize = ViewcaseTextSize.system
  @State private var viewport = ViewcaseViewport.responsive
  @State private var resetID = 0

  public init(_ title: String, stories: [ViewcaseStory]) {
    self.title = title
    self.stories = stories
    _selection = State(initialValue: stories.first?.id)
  }

  public var body: some View {
    NavigationSplitView {
      sidebar
    } detail: {
      detail
    }
    .onChange(of: filteredStories.map(\.id)) { visibleIDs in
      if selection.map({ visibleIDs.contains($0) }) != true {
        selection = visibleIDs.first
      }
    }
  }

  private var sidebar: some View {
    List(selection: $selection) {
      ForEach(groups, id: \.self) { group in
        Section(group) {
          ForEach(filteredStories.filter { $0.group == group }) { story in
            Text(story.title).tag(story.id)
          }
        }
      }
    }
    .searchable(text: $query, prompt: "Search stories and tags")
    .navigationTitle(title)
  }

  @ViewBuilder private var detail: some View {
    if let story = selectedStory {
      VStack(spacing: 0) {
        controls(for: story)
        Divider()
        preview(story)
      }
      .navigationTitle(story.title)
    } else {
      VStack(spacing: 12) {
        Image(systemName: query.isEmpty ? "rectangle.on.rectangle" : "magnifyingglass")
          .font(.largeTitle)
        Text(query.isEmpty ? "Select a story" : "No matching stories")
          .font(.title2)
      }
      .foregroundStyle(.secondary)
    }
  }

  private var filteredStories: [ViewcaseStory] {
    let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !term.isEmpty else { return stories }
    return stories.filter { story in
      ([story.title, story.group] + story.tags)
        .contains { $0.localizedCaseInsensitiveContains(term) }
    }
  }

  private var groups: [String] {
    filteredStories.reduce(into: []) { result, story in
      if !result.contains(story.group) { result.append(story.group) }
    }
  }

  private var selectedStory: ViewcaseStory? {
    guard let selection else { return nil }
    return stories.first { $0.id == selection }
  }

  private func controls(for story: ViewcaseStory) -> some View {
    HStack(spacing: 12) {
      Text(story.group).foregroundStyle(.secondary)
      Spacer()
      Picker("Appearance", selection: $appearance) {
        ForEach(ViewcaseAppearance.allCases) { Text($0.rawValue).tag($0) }
      }
      Picker("Text size", selection: $textSize) {
        ForEach(ViewcaseTextSize.allCases) { Text($0.rawValue).tag($0) }
      }
      Picker("Viewport", selection: $viewport) {
        ForEach(ViewcaseViewport.allCases) { Text($0.rawValue).tag($0) }
      }
      Button("Reset") { resetID += 1 }
    }
    .labelsHidden()
    .padding(12)
  }

  private func preview(_ story: ViewcaseStory) -> some View {
    ScrollView([.horizontal, .vertical]) {
      story.makeContent()
        .id(resetID)
        .viewcaseTextSize(textSize)
        .preferredColorScheme(appearance.colorScheme)
        .frame(
          width: viewport.size?.width,
          height: viewport.size?.height,
          alignment: .topLeading)
        .frame(
          maxWidth: viewport == .responsive ? .infinity : nil,
          maxHeight: viewport == .responsive ? .infinity : nil,
          alignment: .topLeading)
        .background(ViewcasePlatformColor.canvas)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
          RoundedRectangle(cornerRadius: 12)
            .stroke(.primary.opacity(0.12))
        }
        .shadow(color: .black.opacity(0.12), radius: 18, y: 6)
        .padding(28)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(ViewcasePlatformColor.workspace)
  }
}

extension View {
  @ViewBuilder func viewcaseTextSize(_ size: ViewcaseTextSize) -> some View {
    switch size {
    case .system: self
    case .large: dynamicTypeSize(.xxxLarge)
    case .accessibility: dynamicTypeSize(.accessibility3)
    }
  }
}

private enum ViewcasePlatformColor {
  #if os(macOS)
    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let workspace = Color(nsColor: .underPageBackgroundColor)
  #else
    static let canvas = Color(uiColor: .systemBackground)
    static let workspace = Color(uiColor: .secondarySystemBackground)
  #endif
}
