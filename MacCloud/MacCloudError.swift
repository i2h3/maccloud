import Foundation

enum MacCloudError: Error, LocalizedError {
    ///
    /// The httpd binary could not be found.
    ///
    case missingApache

    ///
    /// The PHP installation could not be found.
    ///
    case missingPHP

    ///
    /// The unzip binary could not be found.
    ///
    case missingUnzip

    ///
    /// A programatically launched process terminated with a different status than 0.
    ///
    case processExitStatus(executable: URL?, arguments: [String]?, status: Int32)

    var errorDescription: String? {
        switch self {
            case .missingApache:
                return "Apache could not be found."
            case .missingPHP:
                return "PHP could not be found."
            case .missingUnzip:
                return "Unzip could not be found."
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
            case .missingApache:
                return "Install Apache via Homebrew."
            case .missingPHP:
                return "Install PHP via Homebrew."
            default:
                return nil
        }
    }
}
