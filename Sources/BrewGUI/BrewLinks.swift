import AppKit
import Foundation

enum BrewLinks {
    static func openDocumentation() {
        guard let url = URL(string: "https://docs.brew.sh") else { return }
        NSWorkspace.shared.open(url)
    }
}
