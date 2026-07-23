import SwiftUI

@main
struct BrewGUIApp: App {
    @StateObject private var appState = BrewAppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 980, minHeight: 680)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(after: .appInfo) {
                Button(L10n.string("menu.open.docs")) {
                    BrewLinks.openDocumentation()
                }
                .keyboardShortcut("?", modifiers: [.command, .shift])
            }
        }
    }
}
