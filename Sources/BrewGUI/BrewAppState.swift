import Foundation

@MainActor
final class BrewAppState: ObservableObject {
    @Published var output = ""
    @Published var history: [BrewHistoryItem] = []
    @Published var lastExitCode: Int32?
    @Published var selectedHistoryID: BrewHistoryItem.ID?

    @Published var searchResults: [String] = []
    @Published var installedItems: [String] = []

    @Published private(set) var currentCommand: BrewCommand?

    let runner = BrewRunner()

    var isRunning: Bool {
        runner.isRunning
    }

    func run(_ command: BrewCommand, capture: CaptureMode = .none) {
        Task {
            currentCommand = command
            var capturedOutput = ""
            await runner.run(command) { [weak self] event in
                guard let self else { return }
                switch event {
                case .started(let displayText):
                    self.lastExitCode = nil
                    self.output = "$ \(displayText)\n\n"
                    self.history.insert(BrewHistoryItem(command: command, exitCode: nil, date: Date()), at: 0)
                    self.selectedHistoryID = self.history.first?.id
                case .output(let text):
                    self.output += text
                    capturedOutput += text
                case .finished(let exitCode):
                    self.lastExitCode = exitCode
                    self.output += "\n\n[\(L10n.format("output.exit.code", Int(exitCode)))]\n"
                    if let first = self.history.first, first.command == command {
                        self.history[0].exitCode = exitCode
                    }
                    if exitCode == 0 {
                        self.applyCapture(capture, output: capturedOutput)
                    }
                    self.currentCommand = nil
                case .failed(let message):
                    self.output += "\n[\(L10n.string("output.error"))] \(message)\n"
                    self.currentCommand = nil
                }
            }
        }
    }

    func cancel() {
        runner.cancel()
    }

    func clearOutput() {
        output = ""
        lastExitCode = nil
    }

    func rerun(_ item: BrewHistoryItem) {
        run(item.command)
    }

    private func applyCapture(_ capture: CaptureMode, output: String) {
        let lines = output
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        switch capture {
        case .none:
            break
        case .search:
            searchResults = lines
        case .installedList:
            installedItems = lines
        }
    }
}

enum CaptureMode {
    case none
    case search
    case installedList
}

struct BrewHistoryItem: Identifiable, Equatable {
    let id = UUID()
    var command: BrewCommand
    var exitCode: Int32?
    var date: Date
}
