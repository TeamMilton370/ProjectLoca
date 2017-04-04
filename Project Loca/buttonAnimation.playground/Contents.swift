//: Playground - noun: a place where people can play

import UIKit
import PlaygroundSupport


class ViewController: UIViewController {
    
    var button = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //make color white
        view.backgroundColor = UIColor.white
        buttonSetup()
        view.addSubview(button)
        
    }
    
    func buttonSetup() {
        //UI Stuff
        button.frame = CGRect(x: 75, y: 175, width: 200, height: 60)
        button.backgroundColor = UIColor.clear
        button.layer.cornerRadius = 30
        button.setTitle("What's that?", for: .normal)
        button.setTitleColor(UIColor.darkGray, for: .normal)
        
        button.layer.borderColor = UIColor.darkGray.cgColor
        button.layer.borderWidth = 2
        
        //Gesture recognizer
        button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tap(sender:))))
    }
    
    func tap(sender: UITapGestureRecognizer) {
        //perform animation on tap
        animate(button: self.button)
    }
    
    var isPressed = false
    func animate(button: UIButton) {
        
        UIView.animate(withDuration: 0.75, delay: 0.0, usingSpringWithDamping: 20, initialSpringVelocity: 20, options: .curveEaseInOut, animations: {
            
            if !self.isPressed {
                print("Showing mic button")
                let newX = button.frame.width/2 + button.frame.minX/2
                button.frame = CGRect(x: newX, y: 175, width: 70, height: 60)
                button.setTitle("Mic", for: .normal)
                self.isPressed = true
            } else {
                print("Showing what's that button")
                button.frame = CGRect(x: 75, y: 175, width: 200, height: 60)
                button.setTitle("What's that?", for: .normal)
                self.isPressed = false
            }
            
        }) { (Bool) in
            print("Completed")
        }
    }
    
    
    func ResizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width*heightRatio, height: size.height*heightRatio)
        } else {
            newSize = CGSize(width: size.width*heightRatio, height: size.height*widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

let testVC = ViewController()
testVC.title = "Animations"
let navController = UINavigationController(rootViewController: testVC)

navController.view.frame.size = CGSize(width: 350, height: 550)

PlaygroundPage.current.liveView = navController.view
