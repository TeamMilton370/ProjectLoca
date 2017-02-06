//
//  ViewController.swift
//  Project Loca
//
//  Created by Jake Cronin on 2/2/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import UIKit
import AVFoundation

class HomeViewController: UIViewController {

	let captureSession = AVCaptureSession()
	var captureDevice : AVCaptureDevice?
	
	
	override func viewDidLoad() {
		print("hello world")
		super.viewDidLoad()
		
		captureDevice = AVCaptureDevice()
		var deviceInput = captureDevice.avcapture
		
		
		captureSession.sessionPreset = AVCaptureSessionPresetLow
		
		/*
		for device in devices {
			// Make sure this particular device supports video
			if (device.hasMediaType(AVMediaTypeVideo)) {
				// Finally check the position and confirm we've got the back camera
				if(device.position == AVCaptureDevicePosition.Back) {
					captureDevice = device as? AVCaptureDevice
				}
			}
		}*/
	
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

