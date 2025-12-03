import Foundation

enum MacCloudError: Error, LocalizedError {
    ///
    /// The PHP installation could not be found.
    ///
    case missingPHP

    ///
    /// A programatically launched process terminated with a different status than 0.
    ///
    case processExitStatus(executable: URL?, arguments: [String]?, status: Int32)

    var errorDescription: String? {
        switch self {
            case .missingPHP:
                return "PHP could not be found."
            case let .processExitStatus(executable, arguments, status):
                return "\(executable?.path() ?? "nil") \(arguments?.joined(separator: " ") ?? "nil") terminated with status \(status)"
        }
    }

    var failureReason: String? {
        switch self {
            default:
                return nil
        }
    }

    var helpAnchor: String? {
        switch self {
            default:
                return nil
        }
    }

    var recoverySuggestion: String? {
        switch self {
            case .missingPHP:
                return "Install PHP via Homebrew."
            default:
                return nil
        }
    }
}
