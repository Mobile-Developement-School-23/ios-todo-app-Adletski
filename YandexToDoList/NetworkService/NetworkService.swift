import Foundation
import UIKit

protocol NetworkServiceProtocol {
    
    func getAllToDoItems(
        completion: @escaping (Result<[ToDoItem], Error>) -> Void
    )
    
    func editToDoItem(
        _ item: ToDoItem,
        completion: @escaping (Result<ToDoItem, Error>) -> Void
    )
    
    func deleteToDoItem(
        at id: String,
        completion: @escaping (Result<ToDoItem, Error>) -> Void
    )
    
    func addToDoItem(
        _ item: ToDoItem,
        completion: @escaping (Result<ToDoItem, Error>) -> Void
    )
    
    func getToDoItem(
        at id: String,
        completion: @escaping (Result<ToDoItem, Error>) -> Void
    )
    
    func updateToDoList(
        _ list: [ToDoItem],
        completion: @escaping (Result<[ToDoItem], Error>) -> Void
    )
    
}

enum NetworkError: Error, LocalizedError {
    case wrongRevision
    case noConnection
    case decodeError
}

final class NetworkService: NetworkServiceProtocol {
    
    // MARK: - Properties
    
    private(set) var revision = "0"
    private let baseURL = "https://beta.mrdekk.ru/todobackend"
    private let token: String
    private let queue = DispatchQueue(label: "Network", qos: .background)
    
    // MARK: - LifeCycle
    
    init (token: String) {
        self.token = token
    }
    
    // MARK: - <NetworkServiceProtocol>
    
    func getAllToDoItems(completion: @escaping (Result<[ToDoItem], Error>) -> Void) {
        queue.async {
            guard let url = URL(string: self.baseURL + "/list") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                if let data = data {
                    do {
                        var toDoItemsList: [ToDoItem] = []
                        let result: List = try JSONDecoder().decode(List.self, from: data)
                        for element in result.list {
                            toDoItemsList.append(element.asLocal)
                        }
                        DispatchQueue.main.async {
                            self.revision = String(result.revision)
                            completion(.success(toDoItemsList))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    func editToDoItem(_ item: ToDoItem, completion: @escaping (Result<ToDoItem, Error>) -> Void) {
        queue.async {
            let toDoItem = item.asNetworking
            let body = PostElement(element: toDoItem)
            let data = try? JSONEncoder().encode(body)
            guard let data = data else { return }
            
            guard let url = URL(string: self.baseURL + "/list/" + item.id) else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
            request.setValue(self.revision, forHTTPHeaderField: "X-Last-Known-Revision")
            request.httpBody = data
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 400 {
                        let error = NetworkError.wrongRevision
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                        return
                    }
                }
                if let data = data {
                    do {
                        let result: Element = try JSONDecoder().decode(Element.self, from: data)
                        let toDoItem = result.element.asLocal
                        DispatchQueue.main.async {
                            self.revision = String(result.revision)
                            completion(.success(toDoItem))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    func deleteToDoItem(at id: String, completion: @escaping (Result<ToDoItem, Error>) -> Void) {
        queue.async {
            guard let url = URL(string: self.baseURL + "/list/" + id) else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
            request.setValue(self.revision, forHTTPHeaderField: "X-Last-Known-Revision")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 400 {
                        let error = NetworkError.wrongRevision
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                        return
                    }
                }
                
                if let data = data {
                    do {
                        let result: Element = try JSONDecoder().decode(Element.self, from: data)
                        let toDoItem = result.element.asLocal
                        DispatchQueue.main.async {
                            completion(.success(toDoItem))
                            self.revision = String(result.revision)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    func addToDoItem(_ item: ToDoItem, completion: @escaping (Result<ToDoItem, Error>) -> Void) {
        queue.async {
            let toDoItem = item.asNetworking
            let body = PostElement(element: toDoItem)
            let data = try? JSONEncoder().encode(body)
            guard let data = data else { return }
            guard let url = URL(string: self.baseURL + "/list") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
            request.setValue(self.revision, forHTTPHeaderField: "X-Last-Known-Revision")
            request.httpBody = data
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 400 {
                        let error = NetworkError.wrongRevision
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                        return
                    }
                }
                
                if let data = data {
                    do {
                        let result: Element = try JSONDecoder().decode(Element.self, from: data)
                        let toDoItem = result.element.asLocal
                        DispatchQueue.main.async {
                            self.revision = String(result.revision)
                            completion(.success(toDoItem))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    func getToDoItem(at id: String, completion: @escaping (Result<ToDoItem, Error>) -> Void) {
        queue.async {
            guard let url = URL(string: self.baseURL + "/list/" + id) else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                if let data = data {
                    do {
                        let result: Element = try JSONDecoder().decode(Element.self, from: data)
                        let toDoItem = result.element.asLocal
                        DispatchQueue.main.async {
                            self.revision = String(result.revision)
                            completion(.success(toDoItem))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            }
            task.resume()
        }
    }
    
    func updateToDoList(_ list: [ToDoItem], completion: @escaping (Result<[ToDoItem], Error>) -> Void) {
        queue.async {
            var toDoItemsList: [ToDoItemNetworking] = []
            for element in list {
                toDoItemsList.append(element.asNetworking)
            }
            let body = PatchList(list: toDoItemsList)
            let data = try? JSONEncoder().encode(body)
            guard let data = data else { return }
            guard let url = URL(string: self.baseURL + "/list") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue(self.revision, forHTTPHeaderField: "X-Last-Known-Revision")
            request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")
            request.httpBody = data
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                if let data = data {
                    do {
                        var toDoItemsList: [ToDoItem] = []
                        let result: List = try JSONDecoder().decode(List.self, from: data)
                        for element in result.list {
                            toDoItemsList.append(element.asLocal)
                        }
                        DispatchQueue.main.async {
                            self.revision = String(result.revision)
                            completion(.success(toDoItemsList))
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            }
            task.resume()
        }
    }
}

// MARK: - ToDoItem Extension

private extension ToDoItem {
        var asNetworking: ToDoItemNetworking {
            var importance = "basic"
            var deadline: Int64?
            var changedAt: Int64 = Int64(Date().timeIntervalSince1970)
            
            if self.priority == .unimportant {
                importance = "low"
            } else if self.priority == .important {
                importance = "important"
            }
            if let deadlineFromLocal = self.deadline {
                deadline = Int64(deadlineFromLocal.timeIntervalSince1970)
            }
            if let modificationDateFromLocal = self.modificationDate {
                changedAt = Int64(modificationDateFromLocal.timeIntervalSince1970)
            }
            let asNetworking = ToDoItemNetworking(
                id: self.id,
                text: self.text,
                importance: importance,
                deadline: deadline,
                done: self.isDone,
                color: nil,
                createdAt: Int64(self.creationDate.timeIntervalSince1970),
                changedAt: changedAt,
                lastUpdatedBy: UIDevice.current.identifierForVendor!.uuidString
            )
            return asNetworking
        }
}

// MARK: - ToDoItemNetworking Extension

private extension ToDoItemNetworking {
    var asLocal: ToDoItem {
        var priority: Priority = .regular
        var dealine: Date?
        
        if let deadlineFromNetwork = self.deadline {
            dealine = Date.init(timeIntervalSince1970: Double(deadlineFromNetwork))
        }
        let modificationDate = Date.init(timeIntervalSince1970: Double(self.changedAt))
        let creationDate = Date.init(timeIntervalSince1970: Double(self.createdAt))
        if self.importance == "low" {
            priority = .unimportant
        } else if self.importance == "important" {
            priority = .important
        }
        let asLocal = ToDoItem(
            id: self.id,
            text: self.text,
            priority: priority,
            deadline: dealine,
            isDone: self.done,
            creationDate: creationDate,
            modificationDate: modificationDate
        )
        return asLocal
    }
}
