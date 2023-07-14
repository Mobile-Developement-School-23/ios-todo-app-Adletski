import Foundation

final class DateMapper {
    private lazy var defaultFormatter: DateFormatter = {
        let defaultFormatter = DateFormatter()
        defaultFormatter.dateFormat = "d MMMM"
        defaultFormatter.locale = Locale(identifier: "ru")
        return defaultFormatter
    }()
    private lazy var calendarFormatter: DateFormatter = {
        let calendarFormatter = DateFormatter()
        calendarFormatter.dateStyle = .medium
        calendarFormatter.locale = Locale(identifier: "ru")
        return calendarFormatter
    }()
    func defaultFormat(from date: Date) -> String {
        defaultFormatter.string(from: date)
    }
    func calendarFormat(from date: Date) -> String {
        calendarFormatter.string(from: date)
    }
}
