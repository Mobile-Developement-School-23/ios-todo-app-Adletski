import Foundation

protocol FileCacheServiceProtocol {
    
    func load(completion: @escaping (Result<[ToDoItem], Error>) -> Void)
    func add(_ newItem: ToDoItem)
    func delete(id: String)
    func edit(_ item: ToDoItem)
    func replaceItems(with items: [ToDoItem])
}

protocol FileCacheServiceDelegate: AnyObject {
    func didChangeItems(items: [ToDoItem])
}

final class FileCacheService: FileCacheServiceProtocol {
    
    weak var delegate: FileCacheServiceDelegate?
    
    private let queue = DispatchQueue(label: "FileCacheServiceQueue")
    private let fileCache = FileCache()
    
    func load(completion: @escaping (Result<[ToDoItem], Error>) -> Void) {
        queue.async {
            do {
                let items: [ToDoItem] = try self.fileCache.load()
                DispatchQueue.main.async {
                    completion(.success(items))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func add (_ newItem: ToDoItem) {
        queue.async {
            self.fileCache.add(newItem)
            DispatchQueue.main.async {
                self.delegate?.didChangeItems(items: self.fileCache.toDoItems)
            }
        }
    }
    
    func delete(id: String) {
        queue.async {
            self.fileCache.delete(with: id)
            DispatchQueue.main.async {
                self.delegate?.didChangeItems(items: self.fileCache.toDoItems)
            }
        }
    }
    
    func replaceItems(with items: [ToDoItem]) {
        queue.async {
            self.fileCache.replaceItems(with: items)
            DispatchQueue.main.async {
                self.delegate?.didChangeItems(items: self.fileCache.toDoItems)
            }
        }
    }
    
    func edit(_ item: ToDoItem) {
        queue.async {
            self.fileCache.edit(item)
            DispatchQueue.main.async {
                self.delegate?.didChangeItems(items: self.fileCache.toDoItems)
            }
        }
    }
}
