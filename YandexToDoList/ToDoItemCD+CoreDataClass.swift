import Foundation
import CoreData
//import ToDoItemModel

@objc(ToDoItemCD)
public class ToDoItemCD: NSManagedObject {
    
    var asLocal: ToDoItem {
        let asLocal = ToDoItem(
            id: self.id,
            text: self.text,
            priority: Priority(rawValue: Int(self.priority)) ?? .regular,
            deadline: self.deadline,
            isDone: self.isDone,
            creationDate: self.creationDate,
            modificationDate: self.modificatonDate)
        return asLocal
    }
}
