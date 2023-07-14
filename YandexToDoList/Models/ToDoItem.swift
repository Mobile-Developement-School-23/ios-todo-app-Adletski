import Foundation

// MARK: - Priority Enum
public enum Priority: Int {
    case unimportant
    case regular
    case important
}

// MARK: - Protocol
protocol ToDoItemProtocol {
    static func parse(json: Any) -> ToDoItem?
    var json: Any { get }
}

public struct ToDoItem {
    
    // MARK: - Properties
    
    public let id: String
    public let text: String
    public let priority: Priority
    public let deadline: Date?
    public let isDone: Bool
    public let creationDate: Date
    public let modificationDate: Date?
    
    // MARK: - Init
    
    public init (
        id: String = UUID().uuidString,
        text: String,
        priority: Priority = .regular,
        deadline: Date? = nil,
        isDone: Bool = false,
        creationDate: Date = Date(),
        modificationDate: Date? = nil
    ) {
        self.id = id
        self.text = text
        self.priority = priority
        self.deadline = deadline
        self.isDone = isDone
        self.creationDate = creationDate
        self.modificationDate = modificationDate
    }
}

// MARK: - Extension

extension ToDoItem: ToDoItemProtocol {
    
    // MARK: - <ToDoItemProtocol>
    
    public static func parse(json: Any) -> ToDoItem? {
        var deadline:Date? = nil
        var modificationDate: Date? = nil
        var priority: Priority.RawValue
        guard let dictionary = json as? [String:Any] else {
            return nil
        }
        guard let id = dictionary[Dictionary.id] as? String else {
            return nil
        }
        guard let text = dictionary[Dictionary.text] as? String else {
            return nil
        }
        if let priorityFromJson = dictionary[Dictionary.priority] as? Priority.RawValue {
            priority = priorityFromJson
        } else {
            priority = 1
        }
        guard let isDone = dictionary[Dictionary.isDone] as? Bool else {
            return nil
        }
        guard let creationDate = dictionary[Dictionary.creationDate] as? TimeInterval else {
            return nil
        }
        if let deadlineTimeInterval = dictionary[Dictionary.deadline] as? TimeInterval {
            deadline = Date(timeIntervalSince1970: deadlineTimeInterval)
        }
        if let modificationDateTimeInterval = dictionary[Dictionary.modificationDate] as? TimeInterval {
            modificationDate = Date(timeIntervalSince1970: modificationDateTimeInterval)
        }
        
        let toDoItem = ToDoItem(
            id: id,
            text: text,
            priority: Priority(rawValue: priority) ?? .regular,
            deadline: deadline,
            isDone: isDone,
            creationDate: Date(timeIntervalSince1970: creationDate),
            modificationDate: modificationDate
        )
        
        return toDoItem
    }
    
    public  var json: Any {
        var dictionary:[String:Any] = [
            Dictionary.id: id,
            Dictionary.text: text,
            Dictionary.isDone: isDone,
            Dictionary.creationDate: creationDate.timeIntervalSince1970
        ]
        
        if priority != .regular {
            dictionary[Dictionary.priority] = priority.rawValue
        }
        
        if let deadlineChecked = deadline {
            dictionary[Dictionary.deadline] = deadlineChecked.timeIntervalSince1970
        }
        
        if let modificationDateChecked = modificationDate {
            dictionary[Dictionary.modificationDate] = modificationDateChecked.timeIntervalSince1970
        }
        
        return dictionary
    }
    
    private enum Dictionary {
        static let id = "id"
        static let text = "text"
        static let priority = "priority"
        static let deadline = "deadline"
        static let isDone = "isDone"
        static let creationDate = "creationDate"
        static let modificationDate = "modificationDate"
    }
}

extension ToDoItem {
    
    public func makeComplited() -> ToDoItem {
        let changingItem = self
        let changedItem =  ToDoItem(
            id: changingItem.id,
            text: changingItem.text,
            priority: changingItem.priority,
            deadline: changingItem.deadline,
            isDone: true,
            creationDate: changingItem.creationDate,
            modificationDate: changingItem.modificationDate
        )
        return changedItem
    }
}
