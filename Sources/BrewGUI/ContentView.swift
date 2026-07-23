import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: BrewAppState
    @State private var selectedTab: BrewTab = .search

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
                .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 260)
        } detail: {
            VStack(spacing: 0) {
                HeaderView()
                Divider()
                HSplitView {
                    Group {
                        switch selectedTab {
                        case .search:
                            SearchView()
                        case .packages:
                            PackageActionsView()
                        case .maintenance:
                            MaintenanceView()
                        case .advanced:
                            AdvancedView()
                        }
                    }
                    .frame(minWidth: 470, maxWidth: .infinity, maxHeight: .infinity)

                    ConsoleView()
                        .frame(minWidth: 390, maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
}

enum BrewTab: String, CaseIterable, Identifiable {
    case search
    case packages
    case maintenance
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .search:
            L10n.string("tab.search")
        case .packages:
            L10n.string("tab.packages")
        case .maintenance:
            L10n.string("tab.maintenance")
        case .advanced:
            L10n.string("tab.advanced")
        }
    }

    var systemImage: String {
        switch self {
        case .search:
            "magnifyingglass"
        case .packages:
            "shippingbox"
        case .maintenance:
            "stethoscope"
        case .advanced:
            "hammer"
        }
    }
}

struct SidebarView: View {
    @Binding var selectedTab: BrewTab

    var body: some View {
        List(BrewTab.allCases, selection: $selectedTab) { tab in
            Label(tab.title, systemImage: tab.systemImage)
                .tag(tab)
        }
        .listStyle(.sidebar)
        .navigationTitle(L10n.string("app.name"))
    }
}

struct HeaderView: View {
    @EnvironmentObject private var appState: BrewAppState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.string("header.title"))
                    .font(.headline)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if appState.isRunning {
                ProgressView()
                    .controlSize(.small)
                Button(L10n.string("button.stop"), role: .destructive) {
                    appState.cancel()
                }
                .keyboardShortcut(".", modifiers: .command)
            }

            Button {
                BrewLinks.openDocumentation()
            } label: {
                Label(L10n.string("button.docs"), systemImage: "book")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    private var statusText: String {
        if let command = appState.currentCommand {
            return L10n.format("status.running", command.displayText)
        }

        if let exitCode = appState.lastExitCode {
            return exitCode == 0 ? L10n.string("status.last.success") : L10n.format("status.last.exit", Int(exitCode))
        }

        return L10n.string("status.ready")
    }
}

struct CommandCard<Content: View>: View {
    var title: String
    var subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            content
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        }
    }
}

struct SearchView: View {
    @EnvironmentObject private var appState: BrewAppState
    @State private var query = ""
    @State private var isRegex = false
    @State private var selectedResult: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CommandCard(title: L10n.string("search.card.title"), subtitle: L10n.string("search.card.subtitle")) {
                    HStack {
                        TextField(L10n.string("search.placeholder"), text: $query)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit(runSearch)

                        Toggle(L10n.string("toggle.regex"), isOn: $isRegex)
                            .toggleStyle(.switch)
                            .fixedSize()

                        Button {
                            runSearch()
                        } label: {
                            Label(L10n.string("button.search"), systemImage: "magnifyingglass")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appState.isRunning)
                    }
                }

                CommandCard(title: L10n.string("results.card.title"), subtitle: L10n.string("results.card.subtitle")) {
                    if appState.searchResults.isEmpty {
                        ContentUnavailableView(L10n.string("results.empty.title"), systemImage: "magnifyingglass", description: Text(L10n.string("results.empty.description")))
                            .frame(height: 180)
                    } else {
                        List(appState.searchResults, id: \.self, selection: $selectedResult) { result in
                            Text(result)
                                .font(.system(.body, design: .monospaced))
                        }
                        .frame(minHeight: 220)

                        HStack {
                            Button {
                                runForSelection(.info)
                            } label: {
                                Label(L10n.string("button.info"), systemImage: "info.circle")
                            }
                            .disabled(selectedResult == nil || appState.isRunning)

                            Button {
                                runForSelection(.install)
                            } label: {
                                Label(L10n.string("button.install"), systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(selectedResult == nil || appState.isRunning)
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    private func runSearch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        appState.run(BrewCommandFactory.search(query: trimmed, isRegex: isRegex), capture: .search)
    }

    private func runForSelection(_ action: ResultAction) {
        guard let selectedResult else { return }
        switch action {
        case .info:
            appState.run(BrewCommandFactory.info(items: [selectedResult]))
        case .install:
            appState.run(BrewCommandFactory.install(items: [selectedResult]))
        }
    }

    private enum ResultAction {
        case info
        case install
    }
}

struct PackageActionsView: View {
    @EnvironmentObject private var appState: BrewAppState
    @State private var packageInput = ""
    @State private var selectedInstalled: String?

    private var items: [String] {
        BrewInputParser.tokens(from: packageInput)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CommandCard(title: L10n.string("packages.card.title"), subtitle: L10n.string("packages.card.subtitle")) {
                    TextField(L10n.string("packages.placeholder"), text: $packageInput)
                        .textFieldStyle(.roundedBorder)

                    HStack {
                        Button {
                            appState.run(BrewCommandFactory.info(items: items))
                        } label: {
                            Label(L10n.string("button.info"), systemImage: "info.circle")
                        }
                        .disabled(items.isEmpty || appState.isRunning)

                        Button {
                            appState.run(BrewCommandFactory.install(items: items))
                        } label: {
                            Label(L10n.string("button.install"), systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(items.isEmpty || appState.isRunning)

                        Button {
                            appState.run(BrewCommandFactory.upgrade(items: items))
                        } label: {
                            Label(L10n.string("button.upgrade"), systemImage: "arrow.up.circle")
                        }
                        .disabled(appState.isRunning)

                        Button(role: .destructive) {
                            appState.run(BrewCommandFactory.uninstall(items: items))
                        } label: {
                            Label(L10n.string("button.uninstall"), systemImage: "trash")
                        }
                        .disabled(items.isEmpty || appState.isRunning)
                    }
                }

                CommandCard(title: L10n.string("installed.card.title"), subtitle: L10n.string("installed.card.subtitle")) {
                    HStack {
                        Button {
                            appState.run(BrewCommandFactory.list(items: []), capture: .installedList)
                        } label: {
                            Label(L10n.string("button.refresh.list"), systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(appState.isRunning)

                        if let selectedInstalled {
                            Text(selectedInstalled)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }

                    if appState.installedItems.isEmpty {
                        ContentUnavailableView(L10n.string("installed.empty.title"), systemImage: "list.bullet", description: Text(L10n.string("installed.empty.description")))
                            .frame(height: 170)
                    } else {
                        List(appState.installedItems, id: \.self, selection: $selectedInstalled) { item in
                            Text(item)
                                .font(.system(.body, design: .monospaced))
                        }
                        .frame(minHeight: 220)

                        HStack {
                            Button {
                                runSelectedInstalled(.info)
                            } label: {
                                Label(L10n.string("button.info"), systemImage: "info.circle")
                            }
                            .disabled(selectedInstalled == nil || appState.isRunning)

                            Button {
                                runSelectedInstalled(.upgrade)
                            } label: {
                                Label(L10n.string("button.upgrade"), systemImage: "arrow.up.circle")
                            }
                            .disabled(selectedInstalled == nil || appState.isRunning)

                            Button(role: .destructive) {
                                runSelectedInstalled(.uninstall)
                            } label: {
                                Label(L10n.string("button.uninstall"), systemImage: "trash")
                            }
                            .disabled(selectedInstalled == nil || appState.isRunning)
                        }
                    }
                }
            }
            .padding(18)
        }
    }

    private func runSelectedInstalled(_ action: InstalledAction) {
        guard let selectedInstalled else { return }
        switch action {
        case .info:
            appState.run(BrewCommandFactory.info(items: [selectedInstalled]))
        case .upgrade:
            appState.run(BrewCommandFactory.upgrade(items: [selectedInstalled]))
        case .uninstall:
            appState.run(BrewCommandFactory.uninstall(items: [selectedInstalled]))
        }
    }

    private enum InstalledAction {
        case info
        case upgrade
        case uninstall
    }
}

struct MaintenanceView: View {
    @EnvironmentObject private var appState: BrewAppState
    @State private var helpCommand = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CommandCard(title: L10n.string("maintenance.card.title"), subtitle: L10n.string("maintenance.card.subtitle")) {
                    HStack {
                        Button {
                            appState.run(BrewCommandFactory.update())
                        } label: {
                            Label(L10n.string("button.update"), systemImage: "arrow.down.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(appState.isRunning)

                        Button {
                            appState.run(BrewCommandFactory.upgrade(items: []))
                        } label: {
                            Label(L10n.string("button.upgrade.all"), systemImage: "arrow.up.circle")
                        }
                        .disabled(appState.isRunning)
                    }
                }

                CommandCard(title: L10n.string("troubleshooting.card.title"), subtitle: L10n.string("troubleshooting.card.subtitle")) {
                    HStack {
                        Button {
                            appState.run(BrewCommandFactory.config())
                        } label: {
                            Label(L10n.string("button.config"), systemImage: "gearshape")
                        }
                        .disabled(appState.isRunning)

                        Button {
                            appState.run(BrewCommandFactory.doctor())
                        } label: {
                            Label(L10n.string("button.doctor"), systemImage: "stethoscope")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(appState.isRunning)
                    }
                }

                CommandCard(title: L10n.string("help.card.title"), subtitle: L10n.string("help.card.subtitle")) {
                    HStack {
                        TextField(L10n.string("help.placeholder"), text: $helpCommand)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                appState.run(BrewCommandFactory.help(command: helpCommand))
                            }

                        Button {
                            appState.run(BrewCommandFactory.help(command: helpCommand))
                        } label: {
                            Label(L10n.string("button.help"), systemImage: "questionmark.circle")
                        }
                        .disabled(appState.isRunning)

                        Button {
                            appState.run(BrewCommandFactory.commands())
                        } label: {
                            Label(L10n.string("button.commands"), systemImage: "terminal")
                        }
                        .disabled(appState.isRunning)
                    }
                }
            }
            .padding(18)
        }
    }
}

struct AdvancedView: View {
    @EnvironmentObject private var appState: BrewAppState
    @State private var debugInstallInput = ""
    @State private var createURL = ""
    @State private var createNoFetch = false
    @State private var editInput = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CommandCard(title: L10n.string("advanced.debug.card.title"), subtitle: L10n.string("advanced.debug.card.subtitle")) {
                    HStack {
                        TextField(L10n.string("advanced.debug.placeholder"), text: $debugInstallInput)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            appState.run(BrewCommandFactory.install(items: BrewInputParser.tokens(from: debugInstallInput), verboseDebug: true))
                        } label: {
                            Label(L10n.string("button.run.debug.install"), systemImage: "ladybug")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(BrewInputParser.tokens(from: debugInstallInput).isEmpty || appState.isRunning)
                    }
                }

                CommandCard(title: L10n.string("advanced.create.card.title"), subtitle: L10n.string("advanced.create.card.subtitle")) {
                    HStack {
                        TextField("https://example.com/archive.tar.gz", text: $createURL)
                            .textFieldStyle(.roundedBorder)
                        Toggle(L10n.string("toggle.no.fetch"), isOn: $createNoFetch)
                            .toggleStyle(.switch)
                            .fixedSize()
                        Button {
                            appState.run(BrewCommandFactory.create(url: createURL.trimmingCharacters(in: .whitespacesAndNewlines), noFetch: createNoFetch))
                        } label: {
                            Label(L10n.string("button.create"), systemImage: "plus.square.on.square")
                        }
                        .disabled(createURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || appState.isRunning)
                    }
                }

                CommandCard(title: L10n.string("advanced.edit.card.title"), subtitle: L10n.string("advanced.edit.card.subtitle")) {
                    HStack {
                        TextField(L10n.string("advanced.edit.placeholder"), text: $editInput)
                            .textFieldStyle(.roundedBorder)
                        Button {
                            appState.run(BrewCommandFactory.edit(items: BrewInputParser.tokens(from: editInput)))
                        } label: {
                            Label(L10n.string("button.edit"), systemImage: "square.and.pencil")
                        }
                        .disabled(appState.isRunning)
                    }
                }

                CommandCard(title: L10n.string("docs.card.title"), subtitle: L10n.string("docs.card.subtitle")) {
                    Button {
                        BrewLinks.openDocumentation()
                    } label: {
                        Label(L10n.string("button.open.docs.site"), systemImage: "safari")
                    }
                }
            }
            .padding(18)
        }
    }
}

struct ConsoleView: View {
    @EnvironmentObject private var appState: BrewAppState
    @State private var selectedHistory: BrewHistoryItem.ID?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label(L10n.string("console.output"), systemImage: "terminal")
                    .font(.headline)
                Spacer()
                Button {
                    appState.clearOutput()
                } label: {
                    Label(L10n.string("button.clear"), systemImage: "xmark.circle")
                }
                .disabled(appState.output.isEmpty || appState.isRunning)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            TextEditor(text: .constant(appState.output))
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor))

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(L10n.string("console.history"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                }

                if appState.history.isEmpty {
                    Text(L10n.string("history.empty"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    List(appState.history, selection: $selectedHistory) { item in
                        HStack(spacing: 8) {
                            Image(systemName: statusImage(for: item.exitCode))
                                .foregroundStyle(statusColor(for: item.exitCode))
                            Text(item.command.displayText)
                                .font(.system(.caption, design: .monospaced))
                                .lineLimit(1)
                            Spacer()
                        }
                        .tag(item.id)
                        .contextMenu {
                            Button(L10n.string("button.run.again")) {
                                appState.rerun(item)
                            }
                            .disabled(appState.isRunning)
                        }
                    }
                    .frame(height: 120)
                }
            }
            .padding(12)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func statusImage(for exitCode: Int32?) -> String {
        guard let exitCode else { return "clock" }
        return exitCode == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    private func statusColor(for exitCode: Int32?) -> Color {
        guard let exitCode else { return .secondary }
        return exitCode == 0 ? .green : .orange
    }
}
