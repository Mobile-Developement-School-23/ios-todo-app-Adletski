import Foundation
import UIKit

extension UIImage {
    enum Editor {
        static let arrowDown = UIImage(named: "arrowDownIcon.png")
        static let doubleExclamation = UIImage(named: "doubleExclamationMarkIcon.png")
        static let done = UIImage(
            named: "Ellipse 0",
            in: Bundle(identifier: "org.cocoapods.ToDoItemModel"),
            compatibleWith: nil
        )
        static let notDone = UIImage(named: "Ellipse 1")
        static let overdue = UIImage(named: "Ellipse 2")
        static let add = UIImage(systemName: "plus.circle.fill")
        static let checkmark = UIImage(systemName: "checkmark.circle.fill")
        static let info = UIImage(systemName: "info.circle.fill")
        static let delete = UIImage(systemName: "trash.fill")
    }
}
