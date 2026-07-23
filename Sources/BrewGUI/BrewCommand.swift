import Foundation

struct BrewCommand: Equatable, Sendable {
    var title: String
    var arguments: [String]
    var workingDirectory: URL?

    var displayText: String {
        (["brew"] + arguments)
            .map(Self.shellDisplay)
            .joined(separator: " ")
    }

    private static func shellDisplay(_ value: String) -> String {
        if value.rangeOfCharacter(from: CharacterSet.whitespacesAndNewlines.union(.init(charactersIn: "\"'"))) == nil {
            return value
        }

        return "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

enum BrewCommandFactory {
    static func search(query: String, isRegex: Bool) -> BrewCommand {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let needle = isRegex ? "/\(trimmed)/" : trimmed
        return BrewCommand(title: L10n.format("command.search", needle), arguments: ["search", needle])
    }

    static func info(items: [String]) -> BrewCommand {
        BrewCommand(title: L10n.string("command.info"), arguments: ["info"] + items)
    }

    static func install(items: [String], verboseDebug: Bool = false) -> BrewCommand {
        let prefix = verboseDebug ? ["install", "--verbose", "--debug"] : ["install"]
        return BrewCommand(title: verboseDebug ? L10n.string("command.install.debug") : L10n.string("command.install"), arguments: prefix + items)
    }

    static func update() -> BrewCommand {
        BrewCommand(title: L10n.string("command.update"), arguments: ["update"])
    }

    static func upgrade(items: [String]) -> BrewCommand {
        BrewCommand(title: items.isEmpty ? L10n.string("command.upgrade.all") : L10n.string("command.upgrade"), arguments: ["upgrade"] + items)
    }

    static func uninstall(items: [String]) -> BrewCommand {
        BrewCommand(title: L10n.string("command.uninstall"), arguments: ["uninstall"] + items)
    }

    static func list(items: [String]) -> BrewCommand {
        BrewCommand(title: items.isEmpty ? L10n.string("command.list.installed") : L10n.string("command.list"), arguments: ["list"] + items)
    }

    static func config() -> BrewCommand {
        BrewCommand(title: L10n.string("command.config"), arguments: ["config"])
    }

    static func doctor() -> BrewCommand {
        BrewCommand(title: L10n.string("command.doctor"), arguments: ["doctor"])
    }

    static func create(url: String, noFetch: Bool) -> BrewCommand {
        var arguments = ["create", url]
        if noFetch {
            arguments.append("--no-fetch")
        }
        return BrewCommand(title: L10n.string("command.create.formula"), arguments: arguments)
    }

    static func edit(items: [String]) -> BrewCommand {
        BrewCommand(title: items.isEmpty ? L10n.string("command.edit") : L10n.string("command.edit.formula.cask"), arguments: ["edit"] + items)
    }

    static func commands() -> BrewCommand {
        BrewCommand(title: L10n.string("command.commands"), arguments: ["commands"])
    }

    static func help(command: String) -> BrewCommand {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        return BrewCommand(title: trimmed.isEmpty ? L10n.string("command.help") : L10n.format("command.help.specific", trimmed), arguments: trimmed.isEmpty ? ["help"] : ["help", trimmed])
    }
}

enum BrewInputParser {
    static func tokens(from rawValue: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var quote: Character?
        var isEscaped = false

        for character in rawValue {
            if isEscaped {
                current.append(character)
                isEscaped = false
                continue
            }

            if character == "\\" {
                isEscaped = true
                continue
            }

            if let activeQuote = quote {
                if character == activeQuote {
                    quote = nil
                } else {
                    current.append(character)
                }
                continue
            }

            if character == "\"" || character == "'" {
                quote = character
                continue
            }

            if character.isWhitespace {
                if !current.isEmpty {
                    tokens.append(current)
                    current = ""
                }
                continue
            }

            current.append(character)
        }

        if isEscaped {
            current.append("\\")
        }

        if !current.isEmpty {
            tokens.append(current)
        }

        return tokens
    }
}
