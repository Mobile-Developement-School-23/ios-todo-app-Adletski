import Foundation

protocol RetryManagerDelegate: AnyObject {
    
    func indicate(isAcive: Bool)
    
    func markAsDirty()
}

final class RetryManager: NetworkServiceProtocol {
    
    // MARK: - Properties
    
    weak var delegate: RetryManagerDelegate?
    private let networkService: NetworkService
    private let minDelay = 2.0
    private let maxDelay = 120.0
    private let factor = 1.5
    private let jitter = 0.05
    private let exp = 2.7
    private var getAllCount = 0
    private var updateCount = 0
    private var editCount = 0
    private var deleteCount = 0
    private var addCount = 0
    private var getCount = 0
    
    private lazy var array: [Double] = {
        var array: [Double] = []
        var delay = minDelay
        var count = 0.0
        var resultDelay = 2.0
        var realResult = 2.0
        repeat {
            resultDelay = delay * pow(exp, count)
            var randomization = resultDelay * jitter
            var lower = resultDelay - randomization
            var upper = resultDelay + randomization
            realResult = Double.random(in: lower...upper)
            if realResult > maxDelay { break }
            if count == 0 && realResult < 2.0 {
                realResult = 2.0
            }
            array.append(realResult)
            count += 1
        } while realResult <= maxDelay
        return array
    }()
    
    // MARK: - Lifecycle
    
    init (token: String) {
        self.networkService = NetworkService(token: token)
    }
    
    // MARK: - <RetryManagerProtocol>
    
    func getAllToDoItems(completion: @escaping (Result<[ToDoItem], Error>) -> Void) {
        delegate?.indicate(isAcive: true)
        networkService.getAllToDoItems { result in
            switch result {
            case .success(let items):
                self.getAllCount = 0
                completion(.success(items))
                self.delegate?.indicate(isAcive: false)
                return
            case .failure(let error):
                self.getAllCount += 1
                if self.getAllCount > 5 {
                    self.getAllCount = 0
                    self.delegate?.markAsDirty()
                    self.delegate?.indicate(isAcive: false)
                    completion(.failure(error))
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + self.array[self.getAllCount - 1]) {
                    self.delegate?.indicate(isAcive: false)
                    self.getAllToDoItems { result in
                        switch result {
                        case .success(let items):
                            self.getAllCount = 0
                            completion(.success(items))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                        
                    }
                }
            }
        }
    }
    
    func editToDoItem(_ item: ToDoItem, completion: @escaping (Result<ToDoItem, Error>) -> Void) {
        delegate?.indicate(isAcive: true)
        networkService.editToDoItem(item) { result in
            switch result {
            case .success(let itemFromNetwork):
                self.editCount = 0
                completion(.success(itemFromNetwork))
                self.delegate?.indicate(isAcive: false)
            case .failure(let error):
                if error as? NetworkError == NetworkError.wrongRevision {
                    self.delegate?.markAsDirty()
                    self.delegate?.indicate(isAcive: false)
                    completion(.failure(NetworkError.wrongRevision))
                    return
                }
                self.editCount += 1
                if self.editCount > 5 {
                    self.editCount = 0
                    self.delegate?.markAsDirty()
                    self.delegate?.indicate(isAcive: false)
                    completion(.failure(error))
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + self.array[self.editCount - 1]) {
                    self.delegate?.indicate(isAcive: false)
                    self.editToDoItem(item) { result in
                        switch result {
                        case .success(let itemFromNetwork):
                            self.editCount = 0
                            completion(.success(itemFromNetwork))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
    }
    
    func deleteToDoItem(at id: String, completion: @escaping (Result<ToDoItem, Error>) -> Void) {
        delegate?.indicate(isAcive: true)
        networkService.deleteToDoItem(at: id) { result in
            switch result {
            case .success(let itemFromNetwork):
                self.deleteCount = 0
                completion(.success(itemFromNetwork))
                self.delegate?.indicate(isAcive: false)
            case .failure(let error):
                if error as? NetworkError == NetworkError.wrongRevision {
                    self.delegate?.markAsDirty()
                    self.delegate?.indicate(isAcive: false)
                    completion(.failure(NetworkError.wrongRevision))
                    return
                }
                self.deleteCount += 1
                if self.deleteCount > 5 {
                    self.deleteCount = 0
                    self.delegate?.markAsDirty()
                    self.delegate?.indicate(isAcive: false)
                    completion(.failure(NetworkError.noConnection))
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + self.array[self.deleteCount - 1]) {
                    self.delegate?.indicate(isAcive: false)
                    self.deleteToDoItem(at: id) { result in
                        switch result {
                        case .success(let itemFromNetwork):
                            self.deleteCount = 0
                            completion(.success(itemFromNetwork))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
    }
    
    func addToDoItem(_ item: ToDoItem, completion: @escaping (Result<ToDoItem, Error>) -> Void) {
        delegate?.indicate(isAcive: true)
        networkService.addToDoItem(item) { result in
            switch result {
            case .success(let itemFromNetwork):
                self.addCount = 0
                completion(.success(itemFromNetwork))
                self.delegate?.indicate(isAcive: false)
            case .failure(let error):
                if error as? NetworkError == NetworkError.wrongRevision {
                    self.delegate?.markAsDirty()
                    self.delegate?.indicate(isAcive: false)
                    completion(.failure(NetworkError.wrongRevision))
                    return
                }
                self.addCount += 1
                if self.addCount > 5 {
                    self.addCount = 0
                    self.delegate?.markAsDirty()
                    self.delegate?.indicate(isAcive: false)
                    completion(.failure(error))
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + self.array[self.addCount - 1]) {
                    self.delegate?.indicate(isAcive: false)
                    self.addToDoItem(item) { result in
                        switch result {
                        case .success(let itemFromNetwork):
                            self.addCount = 0
                            completion(.success(itemFromNetwork))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
    }
    
    func getToDoItem(at id: String, completion: @escaping (Result<ToDoItem, Error>) -> Void) {
        delegate?.indicate(isAcive: true)
        networkService.getToDoItem(at: id) { result in
            switch result {
            case .success(let itemFromNetwork):
                self.getCount = 0
                completion(.success(itemFromNetwork))
                self.delegate?.indicate(isAcive: false)
            case .failure(let error):
                self.getCount += 1
                if self.getCount > 5 {
                    self.getCount = 0
                    self.delegate?.markAsDirty()
                    self.delegate?.indicate(isAcive: false)
                    completion(.failure(error))
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + self.array[self.getCount - 1]) {
                    self.delegate?.indicate(isAcive: false)
                    self.getToDoItem(at: id) { result in
                        switch result {
                        case .success(let itemFromNetwork):
                            self.getCount = 0
                            completion(.success(itemFromNetwork))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
    }
    
    func updateToDoList(_ list: [ToDoItem], completion: @escaping (Result<[ToDoItem], Error>) -> Void) {
        self.delegate?.indicate(isAcive: true)
        self.networkService.updateToDoList(list) { result in
            switch result {
            case .success(let items):
                completion(.success(items))
                self.updateCount = 0
                self.delegate?.indicate(isAcive: false)
                return
            case .failure(let error):
                self.updateCount += 1
                if self.updateCount > 5 {
                    self.updateCount = 0
                    self.delegate?.markAsDirty()
                    self.delegate?.indicate(isAcive: false)
                    completion(.failure(error))
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + self.array[self.updateCount - 1]) {
                    self.delegate?.indicate(isAcive: false)
                    self.updateToDoList(list) { result in
                        switch result {
                        case .success(let items):
                            self.updateCount = 0
                            completion(.success(items))
                            return
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
    }
}
