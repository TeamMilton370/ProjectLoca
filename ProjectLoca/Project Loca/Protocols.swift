//
//  Protocols.swift
//  Project Loca
//
//  Created by Tyler Angert on 2/17/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import UIKit

//enum of analysis methods
enum analysisMethod {
    case google_api, metal_cnn
}

//Called from the MainVC -> Data Interface
protocol DataInterfaceDelegate {
    func didReceiveData(analysisMethod: analysisMethod, data: Data)
}

//Called from Data Interface -> ImageRecognition
protocol ImageRecognitionDelegate {
    func didReceiveImage(analysisMethod: analysisMethod, image: UIImage)
}


//Called from Data Intefcace -> Translation
protocol TranslationDelegate {
    func didTranslateText(translation: String)
}

protocol UpdateDataInterfaceDelegate {
    func didFinishImageRecognition()
}


protocol LanguageSetupDelegate {
    func didChangeLanguage(language: String)
}

protocol PhotoCaptureDelegate {
	func didCaptureTexture(sourceTexture : MTLTexture?)
}
protocol NeuralNetDelegate {
	func didGetResult(results: [(String, Float)])
}


