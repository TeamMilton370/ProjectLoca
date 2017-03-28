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
    func didReceiveText(input: String)
}

protocol UpdateDataInterfaceDelegate {
    func didFinishImageRecognition()
}


protocol LanguageSetupDelegate {
    func didChangeLanguage(language: String)
}

protocol UpdateUIDelegate {
    //the "..." means any amount of strings
    func didReceiveTranslation(input1: String, input2: String)
}
