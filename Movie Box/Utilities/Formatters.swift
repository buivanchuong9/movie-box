import Foundation

enum Formatters {
    static func year(from date: String?) -> String {
        guard let date, date.count >= 4 else { return "—" }
        let prefix = date.prefix(4)
        return prefix.allSatisfy(\.isNumber) ? String(prefix) : "—"
    }

    static func runtime(_ minutes: Int?) -> String {
        guard let minutes, minutes > 0 else { return "—" }
        let hours = minutes / 60
        let remainder = minutes % 60
        if hours == 0 { return "\(remainder)m" }
        if remainder == 0 { return "\(hours)h" }
        return "\(hours)h \(remainder)m"
    }

    static func rating(_ value: Double) -> String {
        guard value > 0 else { return "—" }
        return String(format: "%.1f", value)
    }

    static func count(_ value: Int) -> String {
        let number = Double(value)
        if value >= 1_000_000 {
            return String(format: "%.1fM", number / 1_000_000)
        }
        if value >= 1_000 {
            return String(format: "%.1fK", number / 1_000)
        }
        return "\(value)"
    }

    static func mediumDate(_ date: Date?) -> String {
        guard let date else { return "" }
        return output.string(from: date)
    }

    static func mediumDate(_ value: String?) -> String {
        guard let value, let date = input.date(from: String(value.prefix(10))) else {
            return year(from: value)
        }
        return output.string(from: date)
    }

    private static let input: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let output: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
