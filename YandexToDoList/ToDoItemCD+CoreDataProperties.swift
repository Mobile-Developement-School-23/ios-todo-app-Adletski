import Foundation
import CoreData

extension ToDoItemCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ToDoItemCD> {
        return NSFetchRequest<ToDoItemCD>(entityName: "ToDoItemCD")
    }

    @NSManaged public var id: String
    @NSManaged public var text: String
    @NSManaged public var priority: Int64
    @NSManaged public var deadline: Date?
    @NSManaged public var isDone: Bool
    @NSManaged public var creationDate: Date
    @NSManaged public var modificatonDate: Date?

}

extension ToDoItemCD: Identifiable {

}
