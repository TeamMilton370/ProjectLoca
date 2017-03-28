//
//  DataManagerInterface.swift
//  Project Loca
//
//  Created by Tyler Angert on 2/19/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import UIKit

class DataInterface: NSObject, DataInterfaceDelegate {
    
    //This class receives raw camera data and delegates both the image recognition and translation tasks.
    //returns back the information to the main VC.
    static let sharedInstance = DataInterface()
    //delegates
    static var imageRecognitionDelegate: ImageRecognitionDelegate?
    static var translationDelegate: TranslationDelegate?
    static var updateUIDelegate: UpdateUIDelegate?
    
    //instances
    var imageRecognitionManager = ImageRecognitionManager()
    var translationManager = TranslationManager()
    
    //data storage variables
    var analyzedImageLabels = [String]()
    var translatedImageLabels = [String]()
    
    override init() {
        super.init()
        HomeViewController.dataIntefaceDelegate = self
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.sendDataToTranslator),
                                               name: ImageRecognitionManager.sharedInstance.finishedImageAnalysis,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateUIWithTranslation),
                                               name: TranslationManager.sharedInstance.finshedTranslation,
                                               object: nil)
    }
    
    
    //function is called from HomeVC once camera data has arrived.
    func didReceiveData(analysisMethod: analysisMethod, data: Data) {
        let dataProvider = CGDataProvider(data: data as CFData)
        let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.right)
        
        //sends data as an image to the image recognition delegate
        DataInterface.imageRecognitionDelegate?.didReceiveImage(analysisMethod: analysisMethod, image: image)
        
    }
    
    //this is called once the image recognition is finished.
    func sendDataToTranslator() {
        print("About to send data!")
        DataInterface.translationDelegate?.didReceiveText(input: analyzedImageLabels.first!)
    }
    
    //this is called once the translation is finished
    func updateUIWithTranslation(){
        print("Sending to UI!")
        print("Analyzed image labels: \(analyzedImageLabels)")
        print("Translated image labels: \(translatedImageLabels)")
        DataInterface.updateUIDelegate?.didReceiveTranslation(
            input1: analyzedImageLabels.first!,
            input2: translatedImageLabels.last!)
    }
    
}
