import Foundation
import blahtexcxx
import WStringCompat

/// A wrapper class for Blahtex's Interface class
public class BlahtexRenderer {
    private var interface: blahtexwrapper.Interface
    
    public init() {
        self.interface = blahtexwrapper.Interface()
    }
    
    /// Represents an error thrown by the library or during conversion
    public enum BlahtexError: Error, Equatable {
        /// Could not convert some input or output from a C++ wstring to a Swift string.
        /// This should almost never happen.
        case unconvertibleString
        /// Some defined Blahtex error occured.
        /// Usually this represents an issue with the input.
        /// The error code provided by Blahtex is included, if it can be parsed.
        /// Additionally, any arguments provided related to that error will be included in `args`.
        /// If there was a failure parsing, ``BlahtexError/unconvertibleString`` will be thrown instead.
        case blahtexError(code: String, args: [String])
        /// Some other C++ exception occurred.
        /// This is likely the fault of the caller.
        /// The string representation from `std::exception.what()` is included.
        case otherError(String)
        
        internal init(for exception: blahtexwrapper.AnyException) {
            if exception.isBlahtexException() {
                guard let code = String(exception.blahtexException().GetCode()) else {
                    self = .unconvertibleString
                    return
                }
                let argsVec = exception.blahtexException().GetArgs()
                
                guard let args = try? argsVec.map({ 
                    guard let asString = String($0) else { throw BlahtexError.unconvertibleString }
                    return asString
                }) else { // An error was thrown parsing one of the strings
                    self = .unconvertibleString 
                    return
                }
                
                self = .blahtexError(code: code, args: args)
            } else {
                self = .otherError(String(exception.standardException().GetMessage()))
            }
        }
    }
    
    /// Processes some Blahtex input. Internally, Blahtex will build a tree representation of the code.
    public func processInput(_ input: String, displayStyle: Bool = false) throws(BlahtexRenderer.BlahtexError) {
        guard let wstring = std.wstring(input) else {
            throw .unconvertibleString
        }
        
        let result = interface.ProcessInput(wstring, displayStyle)
        if result.isException() {
            let exception = result.exception()
            
            throw BlahtexError(for: exception)
        }
    }
    
    /// Returns the MathML representation of the processed input.
    /// Should only be called after ``/Blahtex/BlahtexRenderer/processInput(_:displayStyle:)`` has been called.
    public func getMathML() throws(BlahtexRenderer.BlahtexError) -> String {
        let result = interface.GetMathml()
        
        guard !result.isException() else {
            let exception = result.exception()
            
            throw BlahtexError(for: exception)
        }
        
        let mathML = result.value()
        
        guard let mathMLString = String(mathML) else {
            throw .unconvertibleString
        }
        
        return mathMLString
    }
    
    public struct MathMLOptions {
        public enum SpacingControl: UInt32 {
            /// Blahtex outputs spacing commands everywhere possible, doesn't
            /// leave any choice to the MathML renderer.
            case strict = 0
            
            /// Blahtex outputs spacing commands where it thinks a typical MathML
            /// renderer is likely to do something visually unsatisfactory
            /// without additional help. The aim is to get good agreement with
            /// TeX without overly bloated MathML markup.
            case moderate = 1
            
            /// Blahtex only outputs spacing commands when the user specifically
            /// asks for them, using TeX commands like `\,` or `\quad`.
            case relaxed = 2
            
            func asCxxSpacingControl() -> blahtex.MathmlOptions.SpacingControl {
                return .init(rawValue: self.rawValue)
            }
            
            init?(_ value: blahtex.MathmlOptions.SpacingControl) {
                self.init(rawValue: value.rawValue)
            }
        }
        
        /// Controls blahtex's MathML spacing markup output. It
        /// corresponds to the command line `--spacing` option.
        ///
        /// Blahtex always uses TeX's rules (or an approximation thereof) to
        /// determine spacing, but the ``SpacingControl`` values describe how much of
        /// the time it actually outputs markup (<mspace>, lspace, rspace) to
        /// implement its spacing decisions.
        public var spacingControl: SpacingControl = .strict
        
        /// If set, blahtex will use MathML version
        /// 1 font attributes (fontstyle, fontweight, fontfamily) instead of
        /// mathvariant, and it will handle the fancier fonts (script,
        /// bold-script, fraktur, bold-fraktur, double-struck) by explicitly
        /// using appropriate MathML entities (e.g. `&Afr;`).
        public var useVersion1FontAttributes: Bool = false
        
        /// Discussed in ``/Blahtex/BlahtexRenderer/EncodingOptions/allowPlane1``.
        public var allowPlane1: Bool = false
    }
    
    /// Settings for the MathML output.
    public var mathMLOptions: MathMLOptions {
        get {
            return MathMLOptions(
                spacingControl: .init(interface.interface.mMathmlOptions.mSpacingControl)!,
                useVersion1FontAttributes: interface.interface.mMathmlOptions.mUseVersion1FontAttributes,
                allowPlane1: interface.interface.mMathmlOptions.mAllowPlane1
            )
        }
        set(newValue) {
            interface.interface.mMathmlOptions.mSpacingControl = newValue.spacingControl.asCxxSpacingControl()
            interface.interface.mMathmlOptions.mUseVersion1FontAttributes = newValue.useVersion1FontAttributes
            interface.interface.mMathmlOptions.mAllowPlane1 = newValue.allowPlane1
        }
    }
    
    public struct EncodingOptions {
        public enum MathMLEncoding: UInt32 {
            /// Directly in Unicode
            case raw = 0
            /// Use e.g `&#x2329;`
            case numeric = 1
            /// Use e.g. `&lang;`
            case short = 2
            /// Use e.g. `&LeftAngleBracket;`
            case long = 3
            
            func asCxxMathMLEncoding() -> blahtex.EncodingOptions.MathmlEncoding {
                return .init(self.rawValue)
            }
            
            init?(_ value: blahtex.EncodingOptions.MathmlEncoding) {
                self.init(rawValue: value.rawValue)
            }
        }
        
        /// Tells what to do with non-ASCII MathML characters.
        /// It corresponds to the `--mathml-encoding` option on the command line.
        public var mathMLEncoding: MathMLEncoding = .numeric
        
        /// Tells what to do with non-ASCII, non-MathML characters:
        /// * true means use unicode directly
        /// * false means use e.g. `&#x1234;`
        public var otherEncodingRaw: Bool = false
        
        /// Tells whether to allow unicode plane-1 characters.
        /// (This facility is included because some browsers don't have decent
        /// support for plane 1 characters.)
        ///
        /// If this flag is NOT set, then blahtex will never output things like
        /// `&#x1d504;`, even when ``mathMLEncoding`` is set to ``MathMLEncoding/raw``
        /// or ``MathMLEncoding/numeric``. Instead it will fall back on something
        /// like `&Afr;`.
        /// 
        /// (This flag is also present in ``MathMLOptions``.)
        public var allowPlane1: Bool = false
    }
    
    /// Settings for the output encoding.
    public var encodingOptions: EncodingOptions {
        get {
            return EncodingOptions(
                mathMLEncoding: .init(interface.interface.mEncodingOptions.mMathmlEncoding)!,
                otherEncodingRaw: interface.interface.mEncodingOptions.mOtherEncodingRaw,
                allowPlane1: interface.interface.mEncodingOptions.mAllowPlane1
            )
        }
        set(newValue) {
            interface.interface.mEncodingOptions.mMathmlEncoding = newValue.mathMLEncoding.asCxxMathMLEncoding()
            interface.interface.mEncodingOptions.mOtherEncodingRaw = newValue.otherEncodingRaw
            interface.interface.mEncodingOptions.mAllowPlane1 = newValue.allowPlane1
        }
    }
}
