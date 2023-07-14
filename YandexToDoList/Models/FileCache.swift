import Foundation
import UIKit
import CoreData

protocol FileCacheProtocol {
    func add(_ item: ToDoItem)
    func delete(with id: String)
    func load() throws -> [ToDoItem]
    func edit(_ item: ToDoItem)
    func replaceItems(with items: [ToDoItem])
}

final class FileCache: FileCacheProtocol {
    
    // MARK: - Properties
    
    private(set) var toDoItems: [ToDoItem] = []
    fileprivate let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    // MARK: - <FileCacheProtocol>
    
    func add(_ item: ToDoItem) {
        toDoItems.append(item)
        let coreDataItem = ToDoItemCD(context: context)
        coreDataItem.id = item.id
        coreDataItem.text = item.text
        coreDataItem.isDone = item.isDone
        coreDataItem.deadline = item.deadline
        coreDataItem.priority = Int64(item.priority.rawValue)
        coreDataItem.creationDate = item.creationDate
        coreDataItem.modificatonDate = item.modificationDate
        do {
            try context.save()
            print("save success")
        } catch {
            print("add failed")
        }
    }
    
    func delete(with id: String) {
        toDoItems = toDoItems.filter{ $0.id != id }
        do {
            let request = ToDoItemCD.fetchRequest() as NSFetchRequest<ToDoItemCD>
            let predicate = NSPredicate(format: "id CONTAINS %@", id)
            request.predicate = predicate
            let fetchedItems = try context.fetch(request)
            guard let deletingItem = fetchedItems.first else {
                print("didnt find item")
                return
            }
            context.delete(deletingItem)
            do {
                try context.save()
                print("core data delete success")
            } catch {
                print("delete one failed")
            }
        } catch {
            print("deleting request failed")
        }
    }
    
    func load() throws -> [ToDoItem] {
        do {
            let items = try context.fetch(ToDoItemCD.fetchRequest())
            for element in items {
                toDoItems.append(element.asLocal)
            }
        } catch {
            print("loading all items failed")
        }
        return toDoItems
    }
    
    func edit(_ item: ToDoItem) {
        toDoItems = toDoItems.filter{ $0.id != item.id }
        do {
            let request = ToDoItemCD.fetchRequest() as NSFetchRequest<ToDoItemCD>
            let predicate = NSPredicate(format: "id CONTAINS %@", item.id)
            request.predicate = predicate
            let fetchedItems = try context.fetch(request)
            guard let editingItem = fetchedItems.first else {
                return
            }
            editingItem.id = item.id
            editingItem.text = item.text
            editingItem.isDone = item.isDone
            editingItem.deadline = item.deadline
            editingItem.priority = Int64(item.priority.rawValue)
            editingItem.creationDate = item.creationDate
            editingItem.modificatonDate = item.modificationDate
            toDoItems.append(editingItem.asLocal)
            do {
                try context.save()
                print("core data edit success")
            } catch {
                print("core data edit failed")
            }
        } catch {
        }
    }
    
    func replaceItems(with items: [ToDoItem]) {
        toDoItems = []
        for item in items {
            add(item)
        }
    }
}
