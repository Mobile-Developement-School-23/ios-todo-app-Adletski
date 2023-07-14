import Foundation
import UIKit
import CocoaLumberjack
import CocoaLumberjackSwift
final class ToDoListViewController: UIViewController {
    
    // MARK: - Properties
    
    let fileCacheService = FileCacheService()
    var retryManager: RetryManager
    
    private var items: [ToDoItem] = []
    private var listIsDirty = true
    private var itemsShowed: [ToDoItem] = []
    private var selectedCellFrame = CGRect()
    private let defaults = UserDefaults.standard
    
    private var activeCounter = 0
    
    // MARK: - Subviews
    
    private let indicator = UIActivityIndicatorView(
        frame: CGRect(x: 0, y: 0, width: 25, height: 25)
    )
    
    private lazy var doneItemsCounterLabel: UILabel = {
        let doneItemsCounterLabel = UILabel()
        doneItemsCounterLabel.translatesAutoresizingMaskIntoConstraints = false
        doneItemsCounterLabel.font = UIFont.systemFont(ofSize: 15)
        doneItemsCounterLabel.textColor = UIColor.Editor.labelTertiary
        return doneItemsCounterLabel
    }()
    
    private lazy var showCompletedButton: UIButton = {
        let showCompletedButton = UIButton()
        showCompletedButton.translatesAutoresizingMaskIntoConstraints = false
        showCompletedButton.setTitle(Texts.show, for: .normal)
        showCompletedButton.setTitleColor(UIColor.Editor.blue, for: .normal)
        showCompletedButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        showCompletedButton.addTarget(self, action: #selector(showCompleted), for: .touchUpInside)
        showCompletedButton.contentHorizontalAlignment = .right
        return showCompletedButton
    }()
    
    private lazy var footerView: UIView = {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width - 32, height: 56))
        footerView.layer.cornerRadius = 16
        let footerButton = UIButton(frame: CGRect(x: 0, y: 0, width: view.frame.width - 32, height: 56))
        footerButton.addTarget(self, action: #selector(activateTextField), for: .touchUpInside)
        footerView.addSubview(footerButton)
        footerView.backgroundColor = UIColor.Editor.backSecondary
        footerView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return footerView
    }()
    
    private lazy var footerTextField: UITextField = {
        let footerTextField = UITextField()
        footerTextField.translatesAutoresizingMaskIntoConstraints = false
        footerTextField.textColor = UIColor.Editor.labelPrimary
        footerTextField.font = UIFont.systemFont(ofSize: 17)
        footerTextField.placeholder = Texts.new
        footerTextField.returnKeyType = .done
        footerTextField.autocorrectionType = .no
        footerTextField.spellCheckingType = .no
        return footerTextField
    }()
    
    private lazy var listTableView: UITableView = {
        let listTableView = UITableView()
        let backgroundView = UIView()
        listTableView.backgroundView = backgroundView
        backgroundView.backgroundColor = UIColor.Editor.backPrimary
        listTableView.translatesAutoresizingMaskIntoConstraints = false
        listTableView.backgroundColor = UIColor.Editor.backSecondary
        listTableView.register(ToDoItemCell.self, forCellReuseIdentifier: ToDoItemCell.cellName)
        listTableView.separatorStyle = .none
        listTableView.rowHeight = UITableView.automaticDimension
        return listTableView
    }()
    
    private lazy var addNewItemButton: UIButton = {
        let addNewItemButton = UIButton()
        addNewItemButton.translatesAutoresizingMaskIntoConstraints = false
        addNewItemButton.setBackgroundImage(UIImage.Editor.add, for: .normal)
        addNewItemButton.addTarget(self, action: #selector(createNew), for: .touchUpInside)
        addNewItemButton.backgroundColor = UIColor.Editor.backSecondary
        addNewItemButton.layer.cornerRadius = 45
        return addNewItemButton
        
    }()
    
    private lazy var headerView: UIView = {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width - 32, height: 44))
        headerView.backgroundColor = UIColor.Editor.backPrimary
        return headerView
    }()
    
    // MARK: - Lifecycle
    
    init (token: String) {
        self.retryManager = RetryManager(token: token)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLayout()
        setConstraints()
        setFooterAndHeader()
        footerTextField.delegate = self
        retryManager.delegate = self
        fileCacheService.delegate = self
        checkFirstLaunch()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
    }
    
    // MARK: - Constraints
    
    private func setConstraints() {
        listTableView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 16).isActive = true
        listTableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        listTableView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -16).isActive = true
        listTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0).isActive = true
        
        addNewItemButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -54).isActive = true
        addNewItemButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        addNewItemButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        addNewItemButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    // MARK: - Private
    
    private func setLayout(){
        view.backgroundColor = UIColor.Editor.backPrimary
        navigationItem.title = Texts.myTasks
        view.addSubview(listTableView)
        view.addSubview(addNewItemButton)
        listTableView.dataSource = self
        listTableView.delegate = self
        let rightBarButton = UIBarButtonItem(customView: indicator)
        navigationItem.rightBarButtonItem = rightBarButton
    }
    
    private func setFooterAndHeader() {
        footerView.addSubview(footerTextField)
        
        footerTextField.leftAnchor.constraint(equalTo: footerView.leftAnchor, constant: 52).isActive = true
        footerTextField.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 17).isActive = true
        footerTextField.widthAnchor.constraint(equalToConstant: 200).isActive = true
        footerTextField.heightAnchor.constraint(equalToConstant: 22).isActive = true
        
        listTableView.tableFooterView = footerView
        
        headerView.addSubview(doneItemsCounterLabel)
        headerView.addSubview(showCompletedButton)
        
        doneItemsCounterLabel.leftAnchor.constraint(equalTo: headerView.leftAnchor, constant: 16).isActive = true
        doneItemsCounterLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12).isActive = true
        doneItemsCounterLabel.widthAnchor.constraint(equalToConstant: 150).isActive = true
        doneItemsCounterLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        showCompletedButton.rightAnchor.constraint(equalTo: headerView.rightAnchor, constant: -16).isActive = true
        showCompletedButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12).isActive = true
        showCompletedButton.widthAnchor.constraint(equalToConstant: (self.view.frame.width - 75)).isActive = true
        showCompletedButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        listTableView.tableHeaderView = headerView
        
    }
    
    private func checkFirstLaunch() {
        if defaults.bool(forKey: "First Launch") {
            syncLocal()
            defaults.set(true, forKey: "First Launch")
        } else {
            retryManager.getAllToDoItems { result in
                switch result {
                case .success(let items):
                    self.listIsDirty = false
                    self.fileCacheService.replaceItems(with: items)
                case .failure(let error):
//                    DDLogMessageFormat(error)
                    print(error)
                }
            }
            defaults.set(true, forKey: "First Launch")
        }
    }
    
    private func presentToDoItemVC(item: ToDoItem?) {
        let viewController = ToDoItemViewController()
        let navVC = UINavigationController(rootViewController: viewController)
        viewController.item = item
        viewController.delegate = self
//        navVC.transitioningDelegate = self
        present(navVC, animated: true)
    }
    
    private func showItems() {
        doneItemsCounterLabel.text = Texts.isDone + " - \(self.items.filter{$0.isDone == true}.count)"
        if showCompletedButton.titleLabel?.text == Texts.show {
            itemsShowed = items.filter{ $0.isDone != true }.sorted{$0.creationDate < $1.creationDate}
            listTableView.reloadData()
        } else {
            itemsShowed = items.sorted{$0.creationDate < $1.creationDate}
            listTableView.reloadData()
        }
    }
    
    private func syncLocal() {
        fileCacheService.load { resultLocal in
            switch resultLocal {
            case .success(let itemsLocal):
                self.items = itemsLocal
                self.showItems()
                self.retryManager.updateToDoList(itemsLocal) { result in
                    switch result {
                    case .success(let items):
                        self.listIsDirty = false
                        self.fileCacheService.replaceItems(with: items)
                    case .failure(let error):
//                        DDLogError(error)
                        print(error)
                    }
                }
            case .failure(let error):
                print(error)
//                DDLogError(error)
                self.retryManager.getAllToDoItems { result in
                    switch result {
                    case .success(let items):
                        self.fileCacheService.replaceItems(with: items)
                    case .failure(let error):
//                        DDLogError(error)
                        print(error)
                    }
                }
            }
        }
        
    }
    
    // MARK: - Actions
    
    @objc func showCompleted() {
        if showCompletedButton.titleLabel?.text == Texts.show {
            itemsShowed = items.sorted{$0.creationDate < $1.creationDate}
            showCompletedButton.setTitle(Texts.hide, for: .normal)
            listTableView.reloadData()
        } else {
            itemsShowed = items.filter{ $0.isDone != true }.sorted{$0.creationDate < $1.creationDate}
            showCompletedButton.setTitle(Texts.show, for: .normal)
            listTableView.reloadData()
        }
    }
    
    @objc func createNew() {
        presentToDoItemVC(item: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        if (footerView.frame.maxY + keyboardSize.height + 150) > view.frame.height {
            listTableView.contentOffset = CGPoint(
                x: 0,
                y: 0 + (footerView.frame.maxY + keyboardSize.height + 150 - view.frame.height) + 16)
        }
    }
    
    @objc func activateTextField() {
        footerTextField.becomeFirstResponder()
    }
}

// MARK: - <TableViewDelegate,TableViewDataSource>

extension ToDoListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemsShowed.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ToDoItemCell.cellName) as! ToDoItemCell
        cell.setCell(item: itemsShowed[indexPath.row])
        cell.selectionStyle = .none
        cell.backgroundColor = UIColor.Editor.backSecondary
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCellFrame = CGRect()
        let cellFrameToTableView = listTableView.rectForRow(at: indexPath)
        let cellFrameToView = listTableView.convert(selectedCellFrame, to: tableView.superview)
        selectedCellFrame = CGRect(
            x: cellFrameToView.origin.x,
            y: cellFrameToTableView.origin.y + cellFrameToView.origin.y,
            width: cellFrameToTableView.width,
            height: cellFrameToTableView.height
        )
        presentToDoItemVC(item: itemsShowed[indexPath.row])
    }
    
    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let isDone = isDoneAction(at: indexPath)
        return UISwipeActionsConfiguration(actions: [isDone])
    }
    
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let info = infoAction(at: indexPath)
        let delete = deleteAction(at: indexPath)
        return UISwipeActionsConfiguration(actions: [delete, info])
    }
    
    private func isDoneAction(at indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: nil) { action, view, completion in
            let changingItem = self.itemsShowed[indexPath.row]
            let changedItem =  changingItem.makeComplited()
            self.fileCacheService.edit(changedItem)
            self.retryManager.editToDoItem(changedItem) { result in
                switch result {
                case .success(let item): self.fileCacheService.edit(item)
                case .failure(let error):
                    print(error)
//                    DDLogError(error)
                }
            }
            self.showItems()
            self.listTableView.reloadData()
            completion(true)
        }
        action.backgroundColor = UIColor.Editor.green
        action.image = UIImage.Editor.checkmark
        return action
    }
    
    private func infoAction(at indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: nil) { action, view, completion in
            self.presentToDoItemVC(item: self.itemsShowed[indexPath.row])
            completion(true)
        }
        action.backgroundColor = UIColor.Editor.grayLight
        action.image = UIImage.Editor.info
        return action
    }
    
    private func deleteAction(at indexPath: IndexPath) -> UIContextualAction {
        let action = UIContextualAction(style: .normal, title: nil) { action, view, completion in
            self.retryManager.deleteToDoItem(at: self.itemsShowed[indexPath.row].id) { result in
                switch result {
                case .success(_):
                    break
                case .failure(let error):
                    print(error)
//                    DDLogError(error)
                }
            }
            self.fileCacheService.delete(id: self.itemsShowed[indexPath.row].id)
            self.showItems()
            self.listTableView.reloadData()
            completion(true)
        }
        action.backgroundColor = UIColor.Editor.red
        action.image = UIImage.Editor.delete
        return action
    }
    
//    func tableView(
//        _ tableView: UITableView,
//        contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint
//    ) -> UIContextMenuConfiguration? {
//        return UIContextMenuConfiguration(identifier: nil, previewProvider: {
//            let viewController = PreviewViewController()
//            viewController.item = self.itemsShowed[indexPath.row]
//            return viewController
//        }, actionProvider: nil)
//    }
}

// MARK: - <UIControllerTransitionDelegate>

//extension ToDoListViewController: UIViewControllerTransitioningDelegate {
//    func animationController(
//        forPresented presented: UIViewController,
//        presenting: UIViewController,
//        source: UIViewController
//    ) -> UIViewControllerAnimatedTransitioning? {
//        return AnimatorForward(originFrame: selectedCellFrame)
//    }
//
//    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
//        return AnimatorBackward()
//    }
//}

// MARK: - <FileCacheServiceDelegate>

extension ToDoListViewController: FileCacheServiceDelegate {
    func didChangeItems(items: [ToDoItem]) {
        if listIsDirty {
            retryManager.updateToDoList(items) { result in
                switch result {
                case .success(let items):
                    self.listIsDirty = false
                    self.fileCacheService.replaceItems(with: items)
                case .failure(let error):
                    print(error)
//                    DDLogError(error)
                }
            }
        }
        self.items = items
        showItems()
        listTableView.reloadData()
    }
}

// MARK: - <ToDoItemViewControllerDelegate>

extension ToDoListViewController: ToDoItemViewControllerDelegate {
    
    func didChanges(item: ToDoItem) {
        let itemsIdArray = items.map{$0.id}
        if !itemsIdArray.contains(item.id) {
            fileCacheService.add(item)
            if listIsDirty == false {
                retryManager.addToDoItem(item) { result in
                    switch result {
                    case .success(let item): self.fileCacheService.edit(item)
                    case .failure(let error):
                        print(error)
//                        DDLogError(error)
                    }
                }
            }
        } else {
            fileCacheService.edit(item)
            retryManager.editToDoItem(item) { result in
                switch result {
                case .success(let item): self.fileCacheService.edit(item)
                case .failure(let error):
                    print(error)
//                    DDLogError(error)
                }
            }
        }
    }
    
    func itemDeleted(itemID: String) {
        fileCacheService.delete(id: itemID)
        retryManager.deleteToDoItem(at: itemID) { result in
            switch result {
            case .success(_):
                break
            case .failure(let error):
                print(error)
//                DDLogError(error)
            }
        }
    }
}

// MARK: - <UITextFieldDelegate>

extension ToDoListViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.hasText == true {
            if let text = textField.text {
                let item = ToDoItem(text: text)
                self.fileCacheService.add(item)
                if listIsDirty == false {
                    retryManager.addToDoItem(item) { result in
                        switch result {
                        case .success(let item): self.fileCacheService.edit(item)
                        case .failure(let error):
                            print(error)
//                            DDLogError(error)
                        }
                    }
                }
                textField.text = nil
            }
        }
        textField.resignFirstResponder()
        listTableView.reloadData()
        return true
    }
}

// MARK: - <RetryManagerDelegate>

extension ToDoListViewController: RetryManagerDelegate {
    
    func markAsDirty() {
        listIsDirty = true
    }
    
    func indicate(isAcive: Bool) {
        if isAcive {
            activeCounter += 1
        } else {
            activeCounter -= 1
        }
        if activeCounter > 0 {
            indicator.startAnimating()
        } else {
            indicator.stopAnimating()
        }
    }
}
