import UIKit

class ToDoItemCell: UITableViewCell {
    static let cellName = "ToDoItemCell"
    private lazy var dateMapper = DateMapper()

    private let statusImage: UIImageView = {
        let statusImage = UIImageView()
        statusImage.translatesAutoresizingMaskIntoConstraints = false
        return statusImage
    }()
    
    private let priorityImage: UIImageView = {
        let priorityImage = UIImageView()
        priorityImage.translatesAutoresizingMaskIntoConstraints = false
        return priorityImage
    }()
    
    private let taskLabel: UILabel = {
        let taskLabel = UILabel()
        taskLabel.translatesAutoresizingMaskIntoConstraints = false
        taskLabel.numberOfLines = 3
        taskLabel.textColor = UIColor.Editor.labelPrimary
        taskLabel.font = UIFont.systemFont(ofSize: 17)
        return taskLabel
    }()
    
    private let deadlineLabel: UILabel = {
        let deadlineLabel = UILabel()
        deadlineLabel.translatesAutoresizingMaskIntoConstraints = false
        deadlineLabel.textColor = UIColor.Editor.labelTertiary
        deadlineLabel.font = UIFont.systemFont(ofSize: 15)
        return deadlineLabel
    }()
    
    private let separator: UIView = {
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor.Editor.supportSeparator
        return separator
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.accessoryType = .disclosureIndicator
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCell(item: ToDoItem) {
        addSubview(statusImage)
        addSubview(priorityImage)
        addSubview(taskLabel)
        addSubview(deadlineLabel)
        addSubview(separator)
        setConstraints()
        var priority = true
        var deadline = true
        taskLabel.text = item.text
        switch item.priority {
        case .important: priorityImage.image = UIImage.Editor.doubleExclamation
        case .unimportant: priorityImage.image = UIImage.Editor.arrowDown
        case .regular: priority = false
        }
        if let ddl = item.deadline {
            let attachment = NSTextAttachment()
            attachment.image = UIImage(systemName: "calendar.badge.clock")?.withTintColor(UIColor.Editor.labelTertiary!)
            let attachmentString = NSAttributedString(attachment: attachment)
            let deadlineString = NSMutableAttributedString(string: "")
            let textAfterIcon = NSAttributedString(string: " " + dateMapper.defaultFormat(from: ddl))
            deadlineString.append(attachmentString)
            deadlineString.append(textAfterIcon)
            deadlineLabel.attributedText = deadlineString
        } else {
            deadline = false
        }
        if item.isDone {
            statusImage.image = UIImage.Editor.done
        } else {
            statusImage.image = UIImage.Editor.notDone
            statusImage.tintColor = UIColor.Editor.supportSeparator
        }
        if let ddl = item.deadline {
            if !item.isDone {
                if ddl < Date() {
                    statusImage.image = UIImage.Editor.overdue
                }
            }
        }
        switch (priority, deadline) {
        case (true, true): setConstraintsWithPriorityAndDeadline()
        case (true, false): setConstraintsWithoutDeadlineButWithPriority()
        case (false, true): setConstraintsWithoutPriorityButWithDeadline()
        case (false, false): setConstraintsWithoutPriorityAndDeadline()
        }
    }
    
    private func setConstraints() {
        statusImage.leftAnchor.constraint(equalTo: leftAnchor, constant: 16).isActive = true
        statusImage.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        statusImage.heightAnchor.constraint(equalToConstant: 24).isActive = true
        statusImage.widthAnchor.constraint(equalToConstant: 24).isActive = true
        
        separator.leftAnchor.constraint(equalTo: leftAnchor, constant: 52).isActive = true
        separator.rightAnchor.constraint(equalTo: rightAnchor, constant: 0).isActive = true
        separator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
    }
    
    private func setConstraintsWithoutPriorityAndDeadline() {
        taskLabel.leftAnchor.constraint(equalTo: statusImage.rightAnchor, constant: 12).isActive = true
        taskLabel.topAnchor.constraint(equalTo: topAnchor, constant: 17).isActive = true
        taskLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -17).isActive = true
        taskLabel.widthAnchor.constraint(equalTo: widthAnchor, constant: -91).isActive = true
    }
    
    private func setConstraintsWithoutPriorityButWithDeadline() {
        taskLabel.leftAnchor.constraint(equalTo: statusImage.rightAnchor, constant: 12).isActive = true
        taskLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
        taskLabel.bottomAnchor.constraint(equalTo: deadlineLabel.topAnchor, constant: 0).isActive = true
        taskLabel.widthAnchor.constraint(equalTo: widthAnchor, constant: -91).isActive = true
        
        deadlineLabel.leftAnchor.constraint(equalTo: taskLabel.leftAnchor, constant: 0).isActive = true
        deadlineLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
        deadlineLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        deadlineLabel.widthAnchor.constraint(equalTo: taskLabel.widthAnchor).isActive = true
    }
    
    private func setConstraintsWithoutDeadlineButWithPriority() {
        priorityImage.leftAnchor.constraint(equalTo: statusImage.rightAnchor, constant: 15).isActive = true
        priorityImage.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        priorityImage.heightAnchor.constraint(equalToConstant: 16).isActive = true
        priorityImage.widthAnchor.constraint(equalToConstant: 11).isActive = true
        
        taskLabel.leftAnchor.constraint(equalTo: priorityImage.rightAnchor, constant: 5).isActive = true
        taskLabel.topAnchor.constraint(equalTo: topAnchor, constant: 17).isActive = true
        taskLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -17).isActive = true
        taskLabel.widthAnchor.constraint(equalTo: widthAnchor, constant: -105).isActive = true
    }
    
    private func setConstraintsWithPriorityAndDeadline() {
        priorityImage.leftAnchor.constraint(equalTo: statusImage.rightAnchor, constant: 15).isActive = true
        priorityImage.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        priorityImage.heightAnchor.constraint(equalToConstant: 16).isActive = true
        priorityImage.widthAnchor.constraint(equalToConstant: 11).isActive = true
        
        taskLabel.leftAnchor.constraint(equalTo: priorityImage.rightAnchor, constant: 5).isActive = true
        taskLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12).isActive = true
        taskLabel.bottomAnchor.constraint(equalTo: deadlineLabel.topAnchor, constant: 0).isActive = true
        taskLabel.widthAnchor.constraint(equalTo: widthAnchor, constant: -105).isActive = true
        
        deadlineLabel.leftAnchor.constraint(equalTo: taskLabel.leftAnchor, constant: 0).isActive = true
        deadlineLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12).isActive = true
        deadlineLabel.heightAnchor.constraint(equalToConstant: 20).isActive = true
        deadlineLabel.widthAnchor.constraint(equalTo: taskLabel.widthAnchor).isActive = true
    }
    
    override func prepareForReuse() {
        statusImage.removeFromSuperview()
        priorityImage.removeFromSuperview()
        taskLabel.removeFromSuperview()
        deadlineLabel.removeFromSuperview()
        separator.removeFromSuperview()
        
        statusImage.image = UIImage()
        priorityImage.image = UIImage()
        deadlineLabel.text = ""
    }
}
