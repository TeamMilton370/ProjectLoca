//
//  ImageRecognitionManager.swift
//  Project Loca
//
//  Created by Tyler Angert on 2/17/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import MetalKit
import MetalPerformanceShaders
import Accelerate

class ImageRecognitionManager: NSObject, ImageRecognitionDelegate {
    
    static let sharedInstance = ImageRecognitionManager()
    var updateDataInterfaceDelegate: UpdateDataInterfaceDelegate?
    let finishedImageAnalysis = Notification.Name.init(rawValue: "finishedImageAnalysis")
    
    //neural network variables
    //neural network
    var inception3Net: Inception3Net!
    var device: MTLDevice?
    var commandQueue: MTLCommandQueue!
    
    var textureLoader : MTKTextureLoader!
    var ciContext : CIContext!
    var sourceTexture : MTLTexture? = nil
    
    override init() {
        super.init()
       DataInterface.imageRecognitionDelegate = self
    }
    
    var googleAPIKey = "AIzaSyBRjyA574z2Dk_T6IVrLGImH8ThrSB2wqY"
    var googleURL: URL {
        return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
    }
    
    //custom delegate
    func didReceiveImage(analysisMethod: analysisMethod, image: UIImage) {
        switch analysisMethod {
            case .google_api:
                callGoogleVision(with: image)
            case .metal_cnn:
                print("need to refactor neural network")
        }
    }
        
    //GOOGLE VISION API
    func callGoogleVision(with pickedImage: UIImage) {
        print("Calling google vision")
        let imageBase64 =  base64EncodeImage(pickedImage)
        // Create our request URL
        var request = URLRequest(url: googleURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        // Build our API request
        let jsonRequest = [
            "requests": [
                "image": [
                    "content": imageBase64
                ],
                "features": [
                    [
                        "type": "LABEL_DETECTION",
                        "maxResults": 10
                    ]
                ]
            ]
        ]
        
        let jsonObject = JSON(jsonDictionary: jsonRequest)
        // Serialize the JSON
        guard let data = try? jsonObject.rawData() else {
            print("error, unable to make json raw data")
            return
        }
        request.httpBody = data
        // Run the request on a background thread
        DispatchQueue.global().async { self.runRequestOnBackgroundThread(request) }
    }
    
    func runRequestOnBackgroundThread(_ request: URLRequest) {
        print("calling google api in background")
        // run the request
        
        let task: URLSessionDataTask = HomeViewController.session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            self.analyzeResults(data)
        }
        task.resume()
    }
    
    func base64EncodeImage(_ image: UIImage) -> String {
        
        guard var imagedata = UIImagePNGRepresentation(image) else{
            print("error with imageData")
            return ""
        }
        // Resize the image if it exceeds the 2MB API limit
        if (imagedata.count > 2097152) {
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
            imagedata = resizeImage(newSize, image: image)
        }
        return imagedata.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
    func resizeImage(_ imageSize: CGSize, image: UIImage) -> Data {
        UIGraphicsBeginImageContext(imageSize)
        image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = UIImagePNGRepresentation(newImage!)
        UIGraphicsEndImageContext()
        return resizedImage!
    }
    
    func analyzeResults(_ dataToParse: Data) {
        print("analyzing results from google api call")
        DataInterface.sharedInstance.analyzedImageLabels.removeAll()

        
        // Update UI on the main thread
        DispatchQueue.main.async(execute: {
            // Use SwiftyJSON to parse results
            let json = JSON(data: dataToParse)
            let errorObj: JSON = json["error"]
            
            // Check for errors
            if (errorObj.dictionaryValue != [:]) {
                print("Error code \(errorObj["code"]): \(errorObj["message"])")
            } else {
                // Parse the response
                let responses: JSON = json["responses"][0]
                
                // Get label annotations
                let labelAnnotations: JSON = responses["labelAnnotations"]
                let numLabels = labelAnnotations.count
                var labels = [String]()
                print("we have \(numLabels) labels for this image")
                
                guard numLabels > 0 else {
                    print("no results")
                    return
                }
                
                for label in labelAnnotations {
                    let analyzedLabel = label.1["description"].stringValue
                    print(analyzedLabel)
                    DataInterface.sharedInstance.analyzedImageLabels.append(analyzedLabel)
                }
                
                //Post a notifcation that the analysis is complete
                NotificationCenter.default.post(name: self.finishedImageAnalysis, object: nil)
            }
        })
        
    }
}
