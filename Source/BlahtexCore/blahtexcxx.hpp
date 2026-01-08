// Include all headers in the BlahtexCore directory

#include "InputSymbolTranslation.h"
#include "Interface.h"
#include "LayoutTree.h"
#include "MacroProcessor.h"
#include "Manager.h"
#include "MathmlNode.h"
#include "Misc.h"
#include "Parser.h"
#include "ParseTree.h"
#include "Token.h"
#include "XmlEncode.h"

#include <optional>
#include <string>
#include <vector>

namespace blahtexwrapper {
    // Swift can't handle reference passes (e.g. blahtex::Exception&), 
    // so we need to wrap the exception in a class which can copy those values for Swift to use
    class Exception {
        private:
            std::wstring code;
            std::vector<std::wstring> args;
        public:
            Exception(const blahtex::Exception& exception) : code(exception.GetCode()), args(exception.GetArgs()) {}
            std::wstring GetCode() const { return code; }
            std::vector<std::wstring> GetArgs() const { return args; }
    };
    
    class StandardException {
        std::string message;
        
        public:
            StandardException(const std::exception& e) : message(e.what()) {}
            std::string GetMessage() const { return message; }
    };
    
    class AnyException {
        std::variant<Exception, StandardException> error;
        
        public:
            AnyException(const Exception& exception) : error(exception) {}
            AnyException(const StandardException& exception) : error(exception) {}
            bool isBlahtexException() const { return std::holds_alternative<Exception>(error); }
            bool isStandardException() const { return std::holds_alternative<StandardException>(error); }
            Exception blahtexException() const {
                return std::get<Exception>(error);
            }
            StandardException standardException() const {
                return std::get<StandardException>(error);
            }
    };
    
    template <typename T>
    class Result {
        std::variant<T, AnyException> storage;
        
        public:
            Result(T value) : storage(std::move(value)) {}
            Result(Exception exception) : storage(AnyException(exception)) {}
            Result(StandardException exception) : storage(AnyException(exception)) {}
            
            bool isOK() const { return std::holds_alternative<T>(storage); }
            bool isException() const { return std::holds_alternative<AnyException>(storage); }
            
            T value() const { return std::get<T>(storage); }
            AnyException exception() const { return std::get<AnyException>(storage); }
    };
    
    class Interface {
        public:
            blahtex::Interface interface;
            
            Interface():
                interface(blahtex::Interface())
            {}
            
            Result<std::monostate> ProcessInput(const std::wstring& input, bool displayStyle = false) {
                try {
                    interface.ProcessInput(input, displayStyle);
                    return Result<std::monostate>(std::monostate());
                } catch (const blahtex::Exception& e) {
                    return Result<std::monostate>(Exception(e));
                } catch (const std::exception& e) {
                    return Result<std::monostate>(e);
                }
            }
            
            Result<std::wstring> GetMathml() {
                try {
                    return Result<std::wstring>(interface.GetMathml());
                } catch (const blahtex::Exception& e) {
                    return Result<std::wstring>(Exception(e));
                } catch (const std::exception& e) {
                    return Result<std::wstring>(e);
                }
            }
            
            Result<std::wstring> GetPurifiedTex() {
                try {
                    return Result<std::wstring>(interface.GetPurifiedTex());
                } catch (const blahtex::Exception& e) {
                    return Result<std::wstring>(Exception(e));
                } catch (const std::exception& e) {
                    return Result<std::wstring>(e);
                }
            }
            
            Result<std::wstring> GetPurifiedTexOnly() {
                try {
                    return Result<std::wstring>(interface.GetPurifiedTexOnly());
                } catch (const blahtex::Exception& e) {
                    return Result<std::wstring>(Exception(e));
                } catch (const std::exception& e) {
                    return Result<std::wstring>(e);
                }
            }
    };
}
