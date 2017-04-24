//
//  Extensions.swift
//  Project Loca
//
//  Created by Tyler Angert on 2/17/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }
    
    var png: Data? { return UIImagePNGRepresentation(self) }
    
    func jpeg(_ quality: JPEGQuality) -> Data? {
        return UIImageJPEGRepresentation(self, quality.rawValue)
    }
}
extension UIViewController {
    func showAlert(title: String, message: String, handler: ((UIAlertAction) -> Swift.Void)? = nil) {
        DispatchQueue.main.async { [unowned self] in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: handler))
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
extension UILabel {
    func addTextSpacing(spacing: Double ) {
        if let textString = text {
            let attributedString = NSMutableAttributedString(string: textString)
            attributedString.addAttribute(NSKernAttributeName, value: spacing, range: NSRange(location: 0, length: attributedString.length - 1))
            attributedText = attributedString
        }
    }
}
extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(drand48())
    }
	var percent: String{
		let numberFormatter = NumberFormatter()
		numberFormatter.numberStyle = .percent
		return numberFormatter.string(from: NSNumber(value: Float(self)))!
	}
	
	
}
extension UIColor {
    static func randomColor() -> UIColor {
        return UIColor(red:   .random(),
                       green: .random(),
                       blue:  .random(),
                       alpha: 1.0)
    }
}
extension Date {
	func days(after date: Date) -> Int{
		return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
	}
	func back(thisManyDays: Int) -> Date{
		return Calendar.current.date(byAdding: .day, value: thisManyDays, to: self)!
	}
    func toString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        return dateFormatter.string(from: self)
    }
	var startOfDay: Date{
		let calendar = Calendar.current
		let toReturn = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: self)
		return toReturn!
	}
}

extension String {
    func capitalizingFirstLetter() -> String {
        let first = String(characters.prefix(1)).capitalized
        let other = String(characters.dropFirst())
        return first + other
    }
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
