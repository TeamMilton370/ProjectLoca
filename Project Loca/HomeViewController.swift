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

    @IBOutlet weak var previewView: CameraView!
    @IBOutlet weak var startButton: UIButton!
    var sessionIsActive = false

	//data variables
	var captureSession: AVCaptureSession?
	var captureDevice : AVCaptureDevice?
	var captureDeviceInput: AVCaptureDeviceInput?
	var videoPreviewLayer: AVCaptureVideoPreviewLayer?
	
	var stillImageOutput: AVCaptureStillImageOutput?
	
	override func viewDidLoad() {
		print("hello world")
		super.viewDidLoad()
//        startCapture()
	}
	
    @IBAction func startSession(_ sender: Any) {
        if sessionIsActive == false {
            captureSession = AVCaptureSession()
            captureSession?.sessionPreset = AVCaptureSessionPresetPhoto
            
            var defaultDevice: AVCaptureDevice?
            
            if let backCamera = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back) {
                defaultDevice = backCamera
            }
            
            var error: NSError?
            var input: AVCaptureDeviceInput!
            do {
                input = try AVCaptureDeviceInput(device: defaultDevice)
            } catch let error1 as NSError {
                error = error1
                input = nil
                print("Error: \(error!.localizedDescription)")
            }
            
            if error == nil && (captureSession?.canAddInput(input))! {
                captureSession?.addInput(input)
            }
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
            videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            
            videoPreviewLayer!.frame = previewView.bounds
            previewView.layer.addSublayer(videoPreviewLayer!)
            captureSession?.startRunning()
            
            sessionIsActive = true
        } else {
            captureSession?.stopRunning()
            sessionIsActive = false
        }
    }
    
    /* DATA
    let dataOutput = AVCaptureVideoDataOutput()
    dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)] // 3
    dataOutput.alwaysDiscardsLateVideoFrames = true
    if (captureSession?.canAddOutput(dataOutput))!{
    captureSession?.addOutput(dataOutput)
    }
    */
    
	func getVideoAuthorization(){
		if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) ==  AVAuthorizationStatus.authorized{
            print("already authorized")
        }else{
			AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
				if granted == true
				{
					print("got it")
				}
				else
				{
					print("don't have video permission")
				}
			});
		}
	}
	

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
	func practiceAPICall(){
		let todoEndpoint: String = "https://jsonplaceholder.typicode.com/todos/1"
		guard let url = URL(string: todoEndpoint) else {
			print("Error: cannot create URL")
			return
		}
		let urlRequest = URLRequest(url: url)
		
		let session = URLSession.shared
		let task = session.dataTask(with: urlRequest) { (data, response, error) in
			guard error == nil else{
				print(error)
				return
			}
			guard data != nil else{
				print("no data")
				return;
			}
			do{
				guard let todo = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else{
					print("error converting data to JSON")
					return
				}
				print("toDo is \(todo.description)")
				guard let todoTitle = todo["title"] as? String else{
					print("could not get title")
					return
				}
				print("the title is \(todoTitle)")
			}catch{
				print("error converting to JSON: \(error)")
			}
		}
		task.resume()	//execute call
	
	}

}

