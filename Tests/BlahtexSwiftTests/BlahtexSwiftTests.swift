import Testing

@testable import Blahtex

@Test func simpleOutput() async throws {
    let input = "| A \\cup B \\cup C | = | A | + | B | + | C | - | A \\cap B | - | B \\cap C | - | A \\cap C | + | A \\cap B \\cap C |"
    
    let renderer = BlahtexRenderer()
    
    renderer.mathMLOptions = .init(spacingControl: .moderate)
    
    try renderer.processInput(input)
    
    do {
        let mathML = try renderer.getMathML()
        #expect(mathML == "<mrow><mo stretchy=\"false\">|</mo><mi>A</mi><mo>&#x222a;</mo><mi>B</mi><mo>&#x222a;</mo><mi>C</mi><mo stretchy=\"false\">|</mo><mo>=</mo><mo stretchy=\"false\">|</mo><mi>A</mi><mo stretchy=\"false\">|</mo><mo>+</mo><mo stretchy=\"false\">|</mo><mi>B</mi><mo stretchy=\"false\">|</mo><mo>+</mo><mo stretchy=\"false\">|</mo><mi>C</mi><mo stretchy=\"false\">|</mo><mo>-</mo><mo stretchy=\"false\">|</mo><mi>A</mi><mo>&#x2229;</mo><mi>B</mi><mo stretchy=\"false\">|</mo><mo>-</mo><mo stretchy=\"false\">|</mo><mi>B</mi><mo>&#x2229;</mo><mi>C</mi><mo stretchy=\"false\">|</mo><mo>-</mo><mo stretchy=\"false\">|</mo><mi>A</mi><mo>&#x2229;</mo><mi>C</mi><mo stretchy=\"false\">|</mo><mo>+</mo><mo stretchy=\"false\">|</mo><mi>A</mi><mo>&#x2229;</mo><mi>B</mi><mo>&#x2229;</mo><mi>C</mi><mo stretchy=\"false\">|</mo></mrow>")
    } catch (let error) {
        #expect(Bool(false), "Error \(error) was thrown while rendering")
    } 
}

@Test func simpleError() async throws {
    let input = "2^{5"
    
    let renderer = BlahtexRenderer()
    
    #expect(throws: BlahtexRenderer.BlahtexError
        .inputError(.init(code: "UnmatchedOpenBrace", args: []))) {
        try renderer.processInput(input)
    }
    
    #expect(throws: BlahtexRenderer.BlahtexError
        .otherError("Layout tree not yet built in Manager::GenerateMathml")) {
        try renderer.getMathML()
    }
}

@Test func errorWithArgs() async throws {
    let input = "\\begin{bmatrix}5 \\\\ 7\\end{matrix}"
    
    let renderer = BlahtexRenderer()
    
    #expect(throws: BlahtexRenderer.BlahtexError
        .inputError(.init(
            code: "MismatchedBeginAndEnd", 
            args: ["\\begin{bmatrix}", "\\end{matrix}"]
        ))) {
        try renderer.processInput(input)
    }
}
