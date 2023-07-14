import Foundation

struct List: Codable {
    let status: String
    let revision: Int
    let list: [ToDoItemNetworking]
}

struct PatchList: Codable {
    let list: [ToDoItemNetworking]
}

struct Element: Codable {
    let status: String
    let element: ToDoItemNetworking
    let revision: Int32
}

struct PostElement: Codable {
    let element: ToDoItemNetworking
}

struct ToDoItemNetworking: Codable {
    let id: String
    let text: String
    let importance: String
    let deadline: Int64?
    let done: Bool
    let color: String?
    let createdAt: Int64
    let changedAt: Int64
    let lastUpdatedBy: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case importance
        case deadline
        case done
        case color
        case createdAt = "created_at"
        case changedAt = "changed_at"
        case lastUpdatedBy = "last_updated_by"
    }
}
