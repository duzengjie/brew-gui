import Testing
@testable import BrewGUI

@Test func tokenParserHandlesQuotesAndEscapes() {
    #expect(BrewInputParser.tokens(from: "wget \"visual studio code\" font\\ fira") == [
        "wget",
        "visual studio code",
        "font fira"
    ])
}

@Test func factoryBuildsSearchRegexCommand() {
    let command = BrewCommandFactory.search(query: "python.*", isRegex: true)
    #expect(command.arguments == ["search", "/python.*/"])
}

@Test func displayTextQuotesWhitespace() {
    let command = BrewCommand(title: "Install", arguments: ["install", "visual studio code"])
    #expect(command.displayText == "brew install 'visual studio code'")
}
