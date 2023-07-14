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
    
//    func add(_ item: ToDoItem) {
//        toDoItems.append(item)
//        let coreDataItem = ToDoItemCD(context: context)
//        coreDataItem.id = item.id
//        coreDataItem.text = item.text
//        coreDataItem.isDone = item.isDone
//        coreDataItem.deadline = item.deadline
//        coreDataItem.priority = Int64(item.priority.rawValue)
//        coreDataItem.creationDate = item.creationDate
//        coreDataItem.modificatonDate = item.modificationDate
//        do {
//            try context.save()
//            print("save success")
//        } catch {
//            print("add failed")
//        }
//    }
//
//    func delete(with id: String) {
//        toDoItems = toDoItems.filter{ $0.id != id }
//        do {
//            let request = ToDoItemCD.fetchRequest() as NSFetchRequest<ToDoItemCD>
//            let predicate = NSPredicate(format: "id CONTAINS %@", id)
//            request.predicate = predicate
//            let fetchedItems = try context.fetch(request)
//            guard let deletingItem = fetchedItems.first else {
//                print("didnt find item")
//                return
//            }
//            context.delete(deletingItem)
//            do {
//                try context.save()
//                print("core data delete success")
//            } catch {
//                print("delete one failed")
//            }
//        } catch {
//            print("deleting request failed")
//        }
//    }
//
//    func load() throws -> [ToDoItem] {
//        do {
//            let items = try context.fetch(ToDoItemCD.fetchRequest())
//            for element in items {
//                toDoItems.append(element.asLocal)
//            }
//        } catch {
//            print("loading all items failed")
//        }
//        return toDoItems
//    }
//
//    func edit(_ item: ToDoItem) {
//        toDoItems = toDoItems.filter{ $0.id != item.id }
//        do {
//            let request = ToDoItemCD.fetchRequest() as NSFetchRequest<ToDoItemCD>
//            let predicate = NSPredicate(format: "id CONTAINS %@", item.id)
//            request.predicate = predicate
//            let fetchedItems = try context.fetch(request)
//            guard let editingItem = fetchedItems.first else {
//                return
//            }
//            editingItem.id = item.id
//            editingItem.text = item.text
//            editingItem.isDone = item.isDone
//            editingItem.deadline = item.deadline
//            editingItem.priority = Int64(item.priority.rawValue)
//            editingItem.creationDate = item.creationDate
//            editingItem.modificatonDate = item.modificationDate
//            toDoItems.append(editingItem.asLocal)
//            do {
//                try context.save()
//                print("core data edit success")
//            } catch {
//                print("core data edit failed")
//            }
//        } catch {
//        }
//    }
//
//    func replaceItems(with items: [ToDoItem]) {
//        toDoItems = []
//        for item in items {
//            add(item)
//        }
//    }
    
    func add(_ item: ToDoItem) {
        items.insert(item, at: 0)
    }

    func delete(_ id: String) {
        items.removeAll(where: { $0.id == id })
    }

    func saveToJSON(to file: String, completion: @escaping (Error?) -> Void) {
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw FileCacheErrors.noSuchDirectory
          }

          let path = directory.appending(path: "\(file).json")
          let serializedtasks = self.items.map { $0.json }
          let data = try JSONSerialization.data(withJSONObject: serializedtasks)
          try data.write(to: path)

          DispatchQueue.main.async {
            completion(nil)
          }
        } catch {
          DispatchQueue.main.async {
            completion(error)
          }
        }
      }
    }

    func saveToCSV(to file: String, completion: @escaping (Error?) -> Void) {
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw FileCacheErrors.noSuchDirectory
          }

          let path = directory.appending(path: "\(file).csv")
          var convertItems = self.items.map { $0.csv }
          convertItems.insert("id,text,createdAt,deadline,changedAt,priority,isDone", at: 0)

          let data = convertItems.joined(separator: "\n").data(using: .utf8)!
          try data.write(to: path, options: .atomic)

          DispatchQueue.main.async {
            completion(nil)
          }
        } catch {
          DispatchQueue.main.async {
            completion(error)
          }
        }
      }
    }

    func loadFromJSON(from file: String, completion: @escaping (Error?) -> Void) {
      do {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
          throw FileCacheErrors.noSuchDirectory
        }

        let path = directory.appending(path: "\(file).json")
        let data = try Data(contentsOf: path)
        let json = try JSONSerialization.jsonObject(with: data)

        guard let json = json as? [Any] else {
          throw FileCacheErrors.somethingWrongWithData
        }

        let convertItems = json.compactMap { ToDoItem.parse(json: $0) }
          .sorted { $0.createdAt.timeIntervalSince1970 > $1.createdAt.timeIntervalSince1970 }
        items = convertItems

        DispatchQueue.main.async {
          completion(nil)
        }
      } catch {
        DispatchQueue.main.async {
          completion(error)
        }
      }
    }

    func loadFromCSV(from file: String, completion: @escaping (Error?) -> Void) {
      do {
        guard let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
          throw FileCacheErrors.noSuchDirectory
        }

        let path = directory.appending(path: "\(file).csv")
        let data = try String(contentsOf: path, encoding: .utf8)
        let rows = data.split(separator: "\n")

        var convertedItems = [ToDoItem]()

        for row in 1 ..< rows.count {
          convertedItems.append(ToDoItem.parse(csv: String(rows[row]))!)
        }

        items = convertedItems

        DispatchQueue.main.async {
          completion(nil)
        }
      } catch {
        DispatchQueue.main.async {
          completion(error)
        }
      }
    }
}
