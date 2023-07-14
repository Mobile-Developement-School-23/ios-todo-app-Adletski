import UIKit
protocol ToDoItemViewControllerDelegate: AnyObject {
    func didChanges(item: ToDoItem)
    func itemDeleted(itemID: String)
}

final class ToDoItemViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: ToDoItemViewControllerDelegate?
    var item: ToDoItem?
    
    private var propertiesViewHighConstraint = NSLayoutConstraint()
    private var datePickerWidthConstraint = NSLayoutConstraint()
    private var textViewWidthConstraintPortrait = NSLayoutConstraint()
    private var textViewWidthConstraintLandscape = NSLayoutConstraint()
    private var textViewHeightConstraintPortrait = NSLayoutConstraint()
    private var textViewHeightConstraintLandscape = NSLayoutConstraint()
    private var textViewHeightConstraitWithKeyboard = NSLayoutConstraint()
    private var deadlineLabelTopConstraint = 73.5
    private var deadlineButtonCounter = 0
    private var id = ""
    private var text = ""
    private var priority: Priority = .important
    private var isDone = false
    private var deadline = Date() + 86400
    private var creationDate = Date()
    private var modificationDate = Date()
    private lazy var dateMapper = DateMapper()
    
    // MARK: - Subviews
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = UIColor.Editor.backPrimary
        return scrollView
    }()
    
    private lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = UIColor.Editor.backSecondary
        textView.layer.cornerRadius = 16
        textView.text = Texts.whatToDo
        textView.textColor = UIColor.Editor.labelTertiary
        textView.font = UIFont.systemFont(ofSize: 17)
        textView.isScrollEnabled = false
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        return textView
    }()
    
    private lazy var propertiesView: UIView = {
        let propertiesView = UIView()
        propertiesView.translatesAutoresizingMaskIntoConstraints = false
        propertiesView.layer.cornerRadius = 16
        propertiesView.backgroundColor = UIColor.Editor.backSecondary
        return propertiesView
    }()
    
    private lazy var priorityLabel: UILabel = {
        let priorityLabel = UILabel()
        priorityLabel.translatesAutoresizingMaskIntoConstraints = false
        priorityLabel.text = Texts.priotity
        priorityLabel.font = UIFont.systemFont(ofSize: 17)
        priorityLabel.textColor = UIColor.Editor.labelPrimary
        return priorityLabel
    }()
    
    private lazy var deadlineLabel: UILabel = {
        let deadlineLabel = UILabel()
        deadlineLabel.translatesAutoresizingMaskIntoConstraints = false
        deadlineLabel.text = Texts.doUntil
        deadlineLabel.font = UIFont.systemFont(ofSize: 17)
        deadlineLabel.textColor = UIColor.Editor.labelPrimary
        return deadlineLabel
    }()
    
    private lazy var priorityChooser: UISegmentedControl = {
        let priorityChooser = UISegmentedControl()
        priorityChooser.translatesAutoresizingMaskIntoConstraints = false
        priorityChooser.insertSegment(with: UIImage.Editor.arrowDown, at: 0, animated: true)
        priorityChooser.insertSegment(with: UIImage.Editor.doubleExclamation, at: 2, animated: true)
        priorityChooser.insertSegment(withTitle: "нет", at: 1, animated: true)
        priorityChooser.layer.cornerRadius = 9
        priorityChooser.selectedSegmentIndex = 2
        priorityChooser.addTarget(self, action: #selector(priorityChanged), for: .valueChanged)
        priorityChooser.backgroundColor = UIColor.Editor.priorityChooser
        priorityChooser.selectedSegmentTintColor = UIColor.Editor.backElevated
        return priorityChooser
    }()
    
    private lazy var chooseDeadlineButton: UIButton = {
        let chooseDeadlineButton = UIButton()
        chooseDeadlineButton.translatesAutoresizingMaskIntoConstraints = false
        chooseDeadlineButton.setTitleColor(UIColor.Editor.blue, for: .normal)
        chooseDeadlineButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        chooseDeadlineButton.isHidden = true
        chooseDeadlineButton.addTarget(self, action: #selector(pressedChooseDeadlineButton), for: .touchUpInside)
        chooseDeadlineButton.contentHorizontalAlignment = .left
        return chooseDeadlineButton
    }()
    
    private lazy var deadlineSwitch: UISwitch = {
        let deadlineSwitch = UISwitch()
        deadlineSwitch.translatesAutoresizingMaskIntoConstraints = false
        deadlineSwitch.addTarget(self, action: #selector(pressedDeadlineSwitch), for: .touchUpInside)
        deadlineSwitch.tintColor = UIColor.Editor.switchColor
        deadlineSwitch.subviews[0].subviews[0].backgroundColor = UIColor.Editor.switchColor
        return deadlineSwitch
    }()
    
    private lazy var deleteButton: UIButton = {
        let deleteButton = UIButton()
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.backgroundColor = UIColor.Editor.backSecondary
        deleteButton.layer.cornerRadius = 16
        deleteButton.isEnabled = false
        deleteButton.setTitle(Texts.delete, for: .normal)
        deleteButton.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        deleteButton.setTitleColor(UIColor.Editor.labelTertiary, for: .disabled)
        deleteButton.setTitleColor(UIColor.Editor.red, for: .normal)
        deleteButton.addTarget(self, action: #selector(deleteItem), for: .touchUpInside)
        return deleteButton
    }()
    
    private lazy var firstLineView: UIView = {
        let firstLineView = UIView()
        firstLineView.translatesAutoresizingMaskIntoConstraints = false
        firstLineView.backgroundColor = UIColor.Editor.supportSeparator
        return firstLineView
    }()
    
    private lazy var secondLineView: UIView = {
        let secondLineView = UIView()
        secondLineView.translatesAutoresizingMaskIntoConstraints = false
        secondLineView.backgroundColor = UIColor.Editor.supportSeparator
        secondLineView.isHidden = true
        return secondLineView
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.minimumDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.preferredDatePickerStyle = .inline
        datePicker.datePickerMode = .date
        datePicker.locale = Locale(identifier: "ru")
        datePicker.addTarget(self, action: #selector(datePickerDateChoosed), for: .valueChanged)
        return datePicker
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        propertiesViewHighConstraint = propertiesView.heightAnchor.constraint(equalToConstant: 112.5)
        setLayout()
        setNavigationBar()
        setConstraints()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissKeyboard)
        )
        tap.delegate = self
        view.addGestureRecognizer(tap)
        view.updateConstraints()
        
        textView.delegate = self
        
        if let id = item?.id {
            self.id = id
        }
        if let text = item?.text {
            textView.text = text
            textView.textColor = UIColor.Editor.labelPrimary
            deleteButton.isEnabled = true
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
        priorityChooser.selectedSegmentIndex = item?.priority.rawValue ?? 2
        if let deadline = item?.deadline {
            deadlineSwitch.isOn = true
            chooseDeadlineButton.setTitle(dateMapper.calendarFormat(from: deadline), for: .normal)
            chooseDeadlineButton.isHidden = false
            deadlineLabelTopConstraint = 66.5
            changeDeadlineLabelConstraints()
            datePicker.setDate(deadline, animated: true)
            self.deadline = deadline
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        AppUtility.lockOrientation(.all)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
    }
    
    override func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        if UIDevice.current.orientation.isLandscape {
            textView.isScrollEnabled = true
            scrollView.isScrollEnabled = false
            scrollView.contentInset.bottom -= 200.5
            removeDatePicker()
            textViewHeightConstraintPortrait.isActive = false
            textViewHeightConstraintLandscape.isActive = true
            propertiesView.isHidden = true
            deleteButton.isHidden = true
        } else {
            textView.isScrollEnabled = false
            scrollView.isScrollEnabled = true
            scrollView.contentInset.bottom += 200.5
            textViewHeightConstraintLandscape.isActive = false
            textViewHeightConstraintPortrait.isActive = true
            propertiesView.isHidden = false
            deleteButton.isHidden = false
        }
    }
    
    // MARK: - Setting Constraints
    
    private func setConstraints() {
        scrollView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0).isActive = true
        scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0).isActive = true
        scrollView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        
        textView.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 16).isActive = true
        textView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16).isActive = true
        textView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32).isActive = true
        textViewHeightConstraintPortrait = textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        textViewHeightConstraintLandscape = textView.heightAnchor.constraint(greaterThanOrEqualToConstant: view.frame.width - 128)
        
        propertiesView.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 16).isActive = true
        propertiesView.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 16).isActive = true
        propertiesView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32).isActive = true
        propertiesViewHighConstraint.isActive = true
        
        priorityLabel.leftAnchor.constraint(equalTo: propertiesView.leftAnchor, constant: 16).isActive = true
        priorityLabel.topAnchor.constraint(equalTo: propertiesView.topAnchor, constant: 17).isActive = true
        priorityLabel.heightAnchor.constraint(equalToConstant: 22).isActive = true
        priorityLabel.widthAnchor.constraint(equalToConstant: 79).isActive = true
        
        deadlineLabel.leftAnchor.constraint(equalTo: propertiesView.leftAnchor, constant: 16).isActive = true
        deadlineLabel.topAnchor.constraint(equalTo: propertiesView.topAnchor, constant: deadlineLabelTopConstraint).isActive = true
        deadlineLabel.heightAnchor.constraint(equalToConstant: 22).isActive = true
        deadlineLabel.widthAnchor.constraint(equalToConstant: 248).isActive = true
        
        priorityChooser.topAnchor.constraint(equalTo: propertiesView.topAnchor, constant: 10).isActive = true
        priorityChooser.rightAnchor.constraint(equalTo: propertiesView.rightAnchor, constant: -12).isActive = true
        priorityChooser.heightAnchor.constraint(equalToConstant: 36).isActive = true
        priorityChooser.widthAnchor.constraint(equalToConstant: 150).isActive = true
        
        chooseDeadlineButton.leftAnchor.constraint(equalTo: propertiesView.leftAnchor, constant: 16).isActive = true
        chooseDeadlineButton.topAnchor.constraint(equalTo: propertiesView.topAnchor, constant: 88.5).isActive = true
        chooseDeadlineButton.heightAnchor.constraint(equalToConstant: 18).isActive = true
        chooseDeadlineButton.widthAnchor.constraint(equalToConstant: 248).isActive = true
        
        deadlineSwitch.rightAnchor.constraint(equalTo: propertiesView.rightAnchor, constant: -12).isActive = true
        deadlineSwitch.topAnchor.constraint(equalTo: propertiesView.topAnchor, constant: 69).isActive = true
        deadlineSwitch.heightAnchor.constraint(equalToConstant: 31).isActive = true
        deadlineSwitch.widthAnchor.constraint(equalToConstant: 51).isActive = true
        
        deleteButton.leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: 16).isActive = true
        deleteButton.topAnchor.constraint(equalTo: propertiesView.bottomAnchor, constant: 16).isActive = true
        deleteButton.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32).isActive = true
        deleteButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        deleteButton.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 0).isActive = true
        
        firstLineView.leftAnchor.constraint(equalTo: propertiesView.leftAnchor, constant: 16).isActive = true
        firstLineView.topAnchor.constraint(equalTo: priorityChooser.bottomAnchor, constant: 10).isActive = true
        firstLineView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        firstLineView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -64).isActive = true
        
        secondLineView.leftAnchor.constraint(equalTo: propertiesView.leftAnchor, constant: 16).isActive = true
        secondLineView.topAnchor.constraint(equalTo: firstLineView.bottomAnchor, constant: 58).isActive = true
        secondLineView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        secondLineView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -64).isActive = true
        
        if view.frame.height > view.frame.width {
            textViewHeightConstraintLandscape.isActive = false
            textViewHeightConstraintPortrait.isActive = true
        } else {
            scrollView.contentInset.bottom -= textView.frame.maxY
            textViewWidthConstraintPortrait.isActive = false
            textViewHeightConstraintLandscape.isActive = true
            propertiesView.isHidden = true
            deleteButton.isHidden = true
            scrollView.contentInset.bottom -= 200.5
            textView.isScrollEnabled = true
            scrollView.isScrollEnabled = false
        }
    }
    
    private func changeDeadlineLabelConstraints() {
        deadlineLabel.removeFromSuperview()
        propertiesView.addSubview(deadlineLabel)
        
        deadlineLabel.leftAnchor.constraint(equalTo: propertiesView.leftAnchor, constant: 16).isActive = true
        deadlineLabel.topAnchor.constraint(equalTo: propertiesView.topAnchor, constant: deadlineLabelTopConstraint).isActive = true
        deadlineLabel.heightAnchor.constraint(equalToConstant: 22).isActive = true
        deadlineLabel.widthAnchor.constraint(equalToConstant: 248).isActive = true
        
    }
    
    // MARK: - Private
    
    private func setLayout() {
        view.backgroundColor = UIColor.Editor.backPrimary
        view.layer.cornerRadius = 16
        view.addSubview(scrollView)
        scrollView.addSubview(textView)
        scrollView.addSubview(propertiesView)
        propertiesView.addSubview(priorityLabel)
        propertiesView.addSubview(deadlineLabel)
        propertiesView.addSubview(priorityChooser)
        propertiesView.addSubview(chooseDeadlineButton)
        propertiesView.addSubview(deadlineSwitch)
        propertiesView.addSubview(firstLineView)
        propertiesView.addSubview(secondLineView)
        scrollView.addSubview(deleteButton)
    }
    
    private func setNavigationBar() {
        self.navigationItem.title = Texts.task
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.Editor.labelPrimary]
        navigationController?.navigationBar.titleTextAttributes = textAttributes as [NSAttributedString.Key : Any]
        navigationController?.navigationBar.tintColor = UIColor.Editor.blue
        let cancelItem = UIBarButtonItem(title: Texts.cancel, style: .plain, target: self, action: #selector(close))
        let saveItem = UIBarButtonItem(title: Texts.save, style: .done, target: self, action: #selector(saveItem))
        saveItem.isEnabled = false
        self.navigationItem.rightBarButtonItem = saveItem
        self.navigationItem.leftBarButtonItem = cancelItem
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
    }
    
    private func showDatePicker() {
        UIView.transition(with: propertiesView, duration: 0.73, options: .transitionCurlDown, animations: { [self] in
            propertiesView.addSubview(datePicker)
            propertiesView.bringSubviewToFront(datePicker)
        }, completion: nil)
        secondLineView.isHidden = false
        
        propertiesViewHighConstraint.isActive = false
        
        datePicker.leftAnchor.constraint(equalTo: propertiesView.leftAnchor, constant: 0).isActive = true
        datePicker.topAnchor.constraint(equalTo: deadlineLabel.bottomAnchor, constant: 28.5).isActive = true
        datePickerWidthConstraint = datePicker.widthAnchor.constraint(equalToConstant: propertiesView.frame.width)
        datePickerWidthConstraint.isActive = true
        
        propertiesView.bottomAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 0).isActive = true
    }
    
    private func removeDatePicker() {
        UIView.transition(with: propertiesView, duration: 1, options: .transitionCrossDissolve, animations: { [self] in
            datePicker.removeFromSuperview()
        }, completion: nil)
        secondLineView.isHidden = true
        
        propertiesViewHighConstraint.isActive = true
    }
    
    private func clearAllFields() {
        textView.text = Texts.whatToDo
        textView.textColor = UIColor.Editor.labelTertiary
        deadlineSwitch.isOn = false
        priorityChooser.selectedSegmentIndex = 2
        removeDatePicker()
        chooseDeadlineButton.isHidden = true
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        deleteButton.isEnabled = false
        self.id = UUID().uuidString
        textView.endEditing(true)
    }
    
    // MARK: - Actions
    
    @objc func pressedChooseDeadlineButton() {
        textView.endEditing(true)
        if deadlineButtonCounter % 2 == 0 {
            deadlineButtonCounter += 1
            showDatePicker()
            datePicker.setDate(deadline, animated: true)
        } else {
            deadlineButtonCounter += 1
            removeDatePicker()
        }
    }
    
    @objc func pressedDeadlineSwitch() {
        textView.endEditing(true)
        if deadlineSwitch.isOn == true {
            chooseDeadlineButton.isHidden = false
            deadlineLabelTopConstraint = 66.5
            changeDeadlineLabelConstraints()
            let date = Date() + 86400
            self.deadline = date
            chooseDeadlineButton.setTitle(dateMapper.calendarFormat(from: date), for: .normal)
        } else {
            chooseDeadlineButton.isHidden = true
            deadlineLabelTopConstraint = 73.5
            changeDeadlineLabelConstraints()
            removeDatePicker()
            deadlineButtonCounter = 0
        }
    }
    
    @objc func datePickerDateChoosed() {
        chooseDeadlineButton.setTitle(dateMapper.calendarFormat(from: datePicker.date), for: .normal)
        self.deadline = datePicker.date
    }
    
    @objc func priorityChanged() {
        textView.endEditing(true)
        switch priorityChooser.selectedSegmentIndex {
        case 0: priority = .unimportant
        case 1: priority = .regular
        case 2: priority = .important
        default: break
        }
    }
    
    @objc func saveItem() {
        let id = item?.id ?? UUID().uuidString
        let text = textView.text ?? ""
        var deadlineForSave: Date? = deadline
        if deadlineSwitch.isOn == false {
            deadlineForSave = nil
        }
        let isDone = item?.isDone ?? false
        let creationDate = item?.creationDate ?? Date()
        let modificationDate = Date()
        let item = ToDoItem(
            id: id,
            text: text,
            priority: priority,
            deadline: deadlineForSave,
            isDone: isDone,
            creationDate: creationDate,
            modificationDate: modificationDate
        )
        delegate?.didChanges(item: item)
        navigationController?.dismiss(animated: true)
    }
    
    @objc func dismissKeyboard() {
        textView.endEditing(true)
    }
    
    @objc func deleteItem() {
        delegate?.itemDeleted(itemID: self.id)
        navigationController?.dismiss(animated: true)
        dismissKeyboard()
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
            guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                return
            }
            if view.frame.height > view.frame.width {
                if (deleteButton.frame.maxY + keyboardSize.height) > scrollView.frame.height {
                    scrollView.contentInset.bottom += keyboardSize.height + 16
                    scrollView.contentOffset = CGPoint(
                        x: 0,
                        y: 0 + (deleteButton.frame.maxY + keyboardSize.height - scrollView.frame.height) + 16
                    )
                }
            } else {
                textViewHeightConstraintLandscape.isActive = false
                textViewHeightConstraitWithKeyboard = textView.heightAnchor.constraint(
                    equalToConstant: self.view.safeAreaLayoutGuide.layoutFrame.height - keyboardSize.height - 32
                )
                textViewHeightConstraitWithKeyboard.isActive = true
                
            }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.contentOffset = CGPoint(x: 0, y: 0 )
        if view.frame.height < view.frame.width {
            textViewHeightConstraitWithKeyboard.isActive = false
            textViewHeightConstraintLandscape.isActive = true
            // разобраться почему иногда вылезает баг
        }
    }
    
    @objc func close() {
        navigationController?.dismiss(animated: true)
    }
    
}

// MARK: - <UITextViewDelegate>

extension ToDoItemViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == Texts.whatToDo {
            textView.text = nil
            textView.textColor = UIColor.Editor.labelPrimary
            self.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = Texts.whatToDo
            textView.textColor = UIColor.Editor.labelTertiary
            self.navigationItem.rightBarButtonItem?.isEnabled = false
            deleteButton.isEnabled = false
        } else {
            self.navigationItem.rightBarButtonItem?.isEnabled = true
            self.text = textView.text
            deleteButton.isEnabled = true
        }
    }
}

// MARK: - <UIGestureRecognizerDelegate>

extension ToDoItemViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.isDescendant(of: propertiesView) ?? false {
            return false
        }
        return true
    }
}
