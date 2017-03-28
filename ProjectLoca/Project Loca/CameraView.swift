//
//  CameraView.swift
//  Project Loca
//
//  Created by Tyler Angert on 2/6/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class CameraView: UIView {
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    // MARK: UIView
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    

    
}
