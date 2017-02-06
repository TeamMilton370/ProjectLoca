//
//  ViewController.swift
//  Project Loca
//
//  Created by Jake Cronin on 2/2/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class HomeViewController: UIViewController{

	//UI Variables
	var previewView: UIView?
	
	
	//data variables
	var captureSession: AVCaptureSession?
	var captureDevice : AVCaptureDevice?
	var captureDeviceInput: AVCaptureDeviceInput?
	var videoPreviewLayer: AVCaptureVideoPreviewLayer?
	
	
	var stillImageOutput: AVCaptureStillImageOutput?
	

	
	override func viewDidLoad() {
		print("hello world")
		super.viewDidLoad()
		
	}
	
	func getVideoAuthorization(){
		if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) ==  AVAuthorizationStatus.authorized{
			startCapture()
		}else{
			AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
				if granted == true
				{
					print("got it")
					self.startCapture()
				}
				else
				{
					print("don't have video permission")
				}
			});
		}
	}
	
	func startCapture(){
		
		//check for authorization
		if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) != AVAuthorizationStatus.authorized{
			getVideoAuthorization()
		}
		
		//create capture session
		captureSession = AVCaptureSession()
		captureSession?.sessionPreset = AVCaptureSessionPresetLow
		
		//get video  device
		var defaultVideoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
		if let backCamera = AVCaptureDevice.defaultDevice(withDeviceType: AVCaptureDeviceType.builtInDualCamera, mediaType: AVMediaTypeVideo, position: .back){
			defaultVideoDevice = backCamera
		}
		
		//configure device input
		var deviceInput: AVCaptureDeviceInput?
		do{
			deviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice)
		}catch{
			print("error: \(error)")
		}
		
		//configure capture session
		captureSession?.beginConfiguration()
		if (captureSession?.canAddInput(deviceInput))!{
			captureSession?.addInput(deviceInput)
		}
		let dataOutput = AVCaptureVideoDataOutput()
		dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)] // 3
		dataOutput.alwaysDiscardsLateVideoFrames = true
		if (captureSession?.canAddOutput(dataOutput))!{
			captureSession?.addOutput(dataOutput)
		}
		captureSession?.commitConfiguration()
		//let queue = DispatchQueue(label: "com.invasivecode.videoQueue")
		//dataOutput.setSampleBufferDelegate(self, queue: queue)


		videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
		videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
		videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
		
		previewView = UIView()
		self.view.addSubview(previewView!)
		previewView!.frame = self.view.frame
		videoPreviewLayer?.frame = previewView!.bounds
		previewView?.layer.addSublayer(videoPreviewLayer!)
		
		
		captureSession?.startRunning()
	}
	

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

