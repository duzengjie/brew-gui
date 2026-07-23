import Foundation

enum BrewRunnerError: LocalizedError {
    case brewNotFound
    case alreadyRunning
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case .brewNotFound:
            L10n.string("error.brew.not.found")
        case .alreadyRunning:
            L10n.string("error.already.running")
        case .launchFailed(let message):
            L10n.format("error.launch.failed", message)
        }
    }
}

@MainActor
final class BrewRunner: ObservableObject {
    @Published private(set) var isRunning = false

    private var activeProcess: Process?

    func run(_ command: BrewCommand, onEvent: @escaping @MainActor (BrewRunEvent) -> Void) async {
        guard !isRunning else {
            onEvent(.failed(BrewRunnerError.alreadyRunning.localizedDescription))
            return
        }

        guard let brewURL = Self.findBrewExecutable() else {
            onEvent(.failed(BrewRunnerError.brewNotFound.localizedDescription))
            return
        }

        isRunning = true
        onEvent(.started(command.displayText))

        let process = Process()
        process.executableURL = brewURL
        process.arguments = command.arguments
        process.currentDirectoryURL = command.workingDirectory
        process.environment = Self.processEnvironment()

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        activeProcess = process

        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in
                onEvent(.output(text))
            }
        }

        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in
                onEvent(.output(text))
            }
        }

        do {
            try process.run()
        } catch {
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            activeProcess = nil
            isRunning = false
            onEvent(.failed(BrewRunnerError.launchFailed(error.localizedDescription).localizedDescription))
            return
        }

        await withCheckedContinuation { continuation in
            process.terminationHandler = { _ in
                continuation.resume()
            }
        }

        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil

        let remainingOutput = outputPipe.fileHandleForReading.readDataToEndOfFile()
        if !remainingOutput.isEmpty, let text = String(data: remainingOutput, encoding: .utf8) {
            onEvent(.output(text))
        }

        let remainingError = errorPipe.fileHandleForReading.readDataToEndOfFile()
        if !remainingError.isEmpty, let text = String(data: remainingError, encoding: .utf8) {
            onEvent(.output(text))
        }

        let exitCode = process.terminationStatus
        activeProcess = nil
        isRunning = false
        onEvent(.finished(exitCode))
    }

    func cancel() {
        guard let activeProcess, activeProcess.isRunning else { return }
        activeProcess.terminate()
    }

    static func findBrewExecutable() -> URL? {
        let candidates = [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew",
            "/home/linuxbrew/.linuxbrew/bin/brew"
        ]

        for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate) {
            return URL(fileURLWithPath: candidate)
        }

        let pathCandidates = processEnvironment()["PATH", default: ""]
            .split(separator: ":")
            .map { String($0) }

        for directory in pathCandidates {
            let candidate = URL(fileURLWithPath: directory).appendingPathComponent("brew").path
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return URL(fileURLWithPath: candidate)
            }
        }

        return nil
    }

    static func processEnvironment() -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let defaultPaths = [
            "/opt/homebrew/bin",
            "/opt/homebrew/sbin",
            "/usr/local/bin",
            "/usr/local/sbin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ]
        let existingPath = environment["PATH"] ?? ""
        environment["PATH"] = (defaultPaths + existingPath.split(separator: ":").map(String.init))
            .uniqued()
            .joined(separator: ":")
        return environment
    }
}

enum BrewRunEvent: Equatable {
    case started(String)
    case output(String)
    case finished(Int32)
    case failed(String)
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
