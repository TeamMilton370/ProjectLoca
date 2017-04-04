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
import AKPickerView
import MetalKit
import MetalPerformanceShaders
import Accelerate


class HomeViewController: UIViewController {
	
	var localTranslator: LocalTranslator!
	
	//Delegate
	var photoCaptureDelegate: PhotoCaptureDelegate!
	var neuralNetDelegate: NeuralNetDelegate!
	var translationDelegate: TranslationDelegate!
	
    @IBOutlet weak var previewView: CameraView!
    //IBOutlets
    @IBOutlet weak var queryButton: UIButton!
//    @IBOutlet weak var languagePicker: AKPickerView!
    
    @IBOutlet weak var inLanguage: PaddingLabel!
    @IBOutlet weak var outLanguage: PaddingLabel!
    
	//Camera-related variables
    var sessionIsActive = false
	var captureSession = AVCaptureSession()
	var videoPreviewLayer: AVCaptureVideoPreviewLayer?
	let photoOutput = AVCapturePhotoOutput()

	
    //for picker view
    let languages = ["Spanish", "French", "Italian", "Japanese", "Chinese"]
    
    //action view
    var alert: UIAlertController!
    
    //neural network
    var inception3Net: Inception3Net!
    var device: MTLDevice?
    var commandQueue: MTLCommandQueue!
    
    var textureLoader : MTKTextureLoader!
    var ciContext : CIContext!
    
    static let session = URLSession.shared
    let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil) // Communicate with the session and other session objects on this queue.
    
    static var dataIntefaceDelegate: DataInterfaceDelegate?
    static var languageSetupDelegate: LanguageSetupDelegate?
	
	
	//for constant capture
	var captureTimer: Timer!
	var captureInteral: TimeInterval = 1

}
extension HomeViewController{
	override func viewDidLoad() {
		super.viewDidLoad()
		
		//local translator
		localTranslator = LocalTranslator()
		
		//protocal for camera and neuralNet
		self.photoCaptureDelegate = self
		self.neuralNetDelegate = self
        //CAMERA
        //starts the capture session
        startSession()
        
        //initializing data interface
        let _ = DataInterface()
        
        //VISUALS        
        //camera view
        inLanguage.text = ""
        outLanguage.text = ""
        
        inLanguage.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        inLanguage.layer.cornerRadius = 10
        inLanguage.clipsToBounds = true
        
        outLanguage.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        outLanguage.layer.cornerRadius = 10
        outLanguage.clipsToBounds = true
        
        //Query button
        queryButton.layer.borderColor = UIColor.darkGray.cgColor
        queryButton.layer.borderWidth = 2
        queryButton.layer.cornerRadius = 30
        queryButton.setTitleColor(UIColor.darkGray, for: .normal)
        queryButton.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        queryButton.frame = CGRect(x: 97, y: 590, width: 200, height: 60)

        self.previewView.frame = CGRect(x: self.view.frame.minX, y: self.view.frame.minY, width: self.view.frame.width, height: self.view.frame.height)
        
        //Neural Network
        // Load default device.
        device = MTLCreateSystemDefaultDevice()
        
        // Make sure the current device supports MetalPerformanceShaders.
        guard MPSSupportsMTLDevice(device) else {
            showAlert(title: "Not Supported", message: "MetalPerformanceShaders is not supported on current device", handler: { (action) in
                self.navigationController!.popViewController(animated: true)
            })
            return
        }
        
        // Create new command queue.
        commandQueue = device?.makeCommandQueue()
        
        // make a textureLoader to get our input images as MTLTextures
        textureLoader = MTKTextureLoader(device: device!)
        
        // Load the appropriate Network
        inception3Net = Inception3Net(withCommandQueue: commandQueue)
        
        // we use this CIContext as one of the steps to get a MTLTexture
        ciContext = CIContext.init(mtlDevice: device!)
        alert = addActionSheet()
               
		captureTimer = Timer.scheduledTimer(timeInterval: captureInteral, target: self, selector: #selector(executeTranslation), userInfo: nil, repeats: true)
	}
	func executeTranslation(){
		takePicture()
		//take picture -> capture -> didGetTexture -> neurlaNet.didGetResults -> Translate.performTranslate -> updateUI
		// run inference neural network to get predictions and display them
	}	//called by timer
	func takePicture() {
		let settings = AVCapturePhotoSettings()
		let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
		let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
		                     kCVPixelBufferWidthKey as String: 160,
		                     kCVPixelBufferHeightKey as String: 160,
		                     ]
		settings.previewPhotoFormat = previewFormat
		self.photoOutput.capturePhoto(with: settings, delegate: self)
	}	//calls capture
	func updateText(input1: String, input2: String?) {
		self.inLanguage.text = input1
		self.outLanguage.text = input2
		
		/*
		UIView.animate(withDuration: 0.75, delay: 0.0, usingSpringWithDamping: 20, initialSpringVelocity: 20, options: .curveEaseInOut, animations: {
		
		print("Showing mic button")
		let newX = self.queryButton.frame.width/1.5 + self.queryButton.frame.minX/1.5
		self.queryButton.frame = CGRect(x: newX, y: 590, width: 100, height: 60)
		self.queryButton.setTitle("Mic", for: .normal)
		
		}) { (Bool) in
		print("Completed animation")
		UIView.animate(withDuration: 0.75, animations: {
		self.queryButton.frame = CGRect(x: 97, y: 590, width: 200, height: 60)
		self.queryButton.setTitle("What's that?", for: .normal)
		
		})
		}
		*/
	}
	@IBAction func pressQuery(_ sender: Any) {
		if captureTimer.isValid{
			captureTimer.invalidate()
			self.tabBarController?.present(self.alert, animated: true, completion: nil)
		}else{
			captureTimer = Timer.scheduledTimer(timeInterval: captureInteral, target: self, selector: #selector(executeTranslation), userInfo: nil, repeats: true)
		}
	}
    func addActionSheet() -> UIAlertController {
        let alertController = UIAlertController(title: "You found a new word!", message: nil, preferredStyle: .actionSheet)
        
        let saveButton = UIAlertAction(title: "Save to words", style: .default, handler: { (action) -> Void in
<<<<<<< HEAD:ProjectLoca/Project Loca/HomeViewController.swift
			self.captureTimer = Timer.scheduledTimer(timeInterval: self.captureInteral, target: self, selector: #selector(self.executeTranslation), userInfo: nil, repeats: true)
=======
            print("About to save a word")
			self.captureTimer = Timer.scheduledTimer(timeInterval: self.captureInteral, target: self, selector: #selector(self.takePicture), userInfo: nil, repeats: true)
>>>>>>> 02fa56bcf605e7946d967e3f3a897b8d816311d4:ProjectLoca/Project Loca/e.swift

			
        })
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
<<<<<<< HEAD:ProjectLoca/Project Loca/HomeViewController.swift
			self.captureTimer = Timer.scheduledTimer(timeInterval: self.captureInteral, target: self, selector: #selector(self.executeTranslation), userInfo: nil, repeats: true)
=======
            print("Cancel button tapped")
			self.captureTimer = Timer.scheduledTimer(timeInterval: self.captureInteral, target: self, selector: #selector(self.takePicture), userInfo: nil, repeats: true)

>>>>>>> 02fa56bcf605e7946d967e3f3a897b8d816311d4:ProjectLoca/Project Loca/e.swift
        })
        
        alertController.addAction(saveButton)
        alertController.addAction(cancelButton)
        
        return alertController
    }
<<<<<<< HEAD:ProjectLoca/Project Loca/HomeViewController.swift
	func runNetwork(sourceTexture: MTLTexture) {
=======
    
    
    func didReceiveTranslation(input1: String, input2: String) {
        print("Original: \(input1)")
        print("Translation: \(input2)")
        
        self.inLanguage.text = input1
        self.outLanguage.text = input2
        
        UIView.animate(withDuration: 0.75, delay: 0.0, usingSpringWithDamping: 20, initialSpringVelocity: 20, options: .curveEaseInOut, animations: {
            
                print("Showing mic button")
                let newX = self.queryButton.frame.width/1.5 + self.queryButton.frame.minX/1.5
                self.queryButton.frame = CGRect(x: newX, y: 590, width: 100, height: 60)
                self.queryButton.setTitle("Mic", for: .normal)
            
        }) { (Bool) in
            print("Completed animation")
            UIView.animate(withDuration: 0.75, animations: {
                self.queryButton.frame = CGRect(x: 97, y: 590, width: 200, height: 60)
                self.queryButton.setTitle("What's that?", for: .normal)

            })
        }

    }
    
    @IBAction func pressQuery(_ sender: Any) {
		  if captureTimer.isValid{
			  captureTimer.invalidate()
		}else{
			self.captureTimer = Timer.scheduledTimer(timeInterval: self.captureInteral, target: self, selector: #selector(self.takePicture), userInfo: nil, repeats: true)

		}
		 self.tabBarController?.present(self.alert, animated: true, completion: nil)
	}
 func runNetwork(completion: @escaping (_ completed: Bool) -> Void) {
>>>>>>> 02fa56bcf605e7946d967e3f3a897b8d816311d4:ProjectLoca/Project Loca/e.swift
        let startTime = CACurrentMediaTime()
        // to deliver optimal performance we leave some resources used in MPSCNN to be released at next call of autoreleasepool,
        // so the user can decide the appropriate time to release this
		
		// display top-5 predictions for what the object should be labelled
		var resultString = ""
		var translation = ""
		var proababilities = [Float]()
        autoreleasepool{
            // encoding command buffer
            let commandBuffer = commandQueue.makeCommandBuffer()
            
            // encode all layers of network on present commandBuffer, pass in the input image MTLTexture
            inception3Net.forward(commandBuffer: commandBuffer, sourceTexture: sourceTexture)
            
            // commit the commandBuffer and wait for completion on CPU
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
			var resultsString = ""
			var translation = ""
			var results: [(String, Float)] = inception3Net.getResults()
			
			results.sort{$0.1 > $1.1}
			neuralNetDelegate.didGetResult(results: results)

        }
        
        let endTime = CACurrentMediaTime()
        print("Running Time: \(endTime - startTime) [sec]")
    }
	//initialization stuff
    func startSession() {
        if !sessionIsActive {
            captureSession = AVCaptureSession()
			
            //image quality
            captureSession.sessionPreset = AVCaptureSessionPresetMedium
            
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
            
            //adding camera input
            if error == nil && (captureSession.canAddInput(input)) {
                captureSession.addInput(input)
            }
            
            //adding camera output
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
            videoPreviewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            
            videoPreviewLayer!.frame = previewView.bounds
            previewView.layer.addSublayer(videoPreviewLayer!)
            captureSession.startRunning()
            
            sessionIsActive = true
        } else {
            captureSession.stopRunning()
            print("session running problem")
            sessionIsActive = false
        }
    }
	func getVideoAuthorization(){
		if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) ==  AVAuthorizationStatus.authorized{
            print("already authorized")
        }else{
			AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
				if granted {
					print("got it")
				} else {
					print("don't have video permission")
				}
			});
		}
	}
}
extension HomeViewController: PhotoCaptureDelegate{
	func didCaptureTexture(sourceTexture : MTLTexture?){
		guard sourceTexture != nil else {
			print("no texture found")
			return
		}
		runNetwork(sourceTexture: sourceTexture!)
	}
}
extension HomeViewController: NeuralNetDelegate{
	func didGetResult(results: [(String, Float)]){
		let firstResult = results[0].0
		let firstProbability = results[0].1
		let toReturn = "\(firstResult) \(firstProbability)"
		
		let translation = localTranslator.translate(word: firstResult)
		print("translation of \(firstResult) is \(translation)")
		updateText(input1: toReturn, input2: translation)
		//display results
		
	}
}
extension HomeViewController: AVCapturePhotoCaptureDelegate {
	func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?){
        
        if let error = error {
            print("error occure : \(error.localizedDescription)")
        }
        if  let sampleBuffer = photoSampleBuffer,
            let previewBuffer = previewPhotoSampleBuffer,
            let dataImage =  AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer:  sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {

            let dataProvider = CGDataProvider(data: dataImage as CFData)
            guard let cgImage = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {
                print("couldn't get an image")
                return
            }
            
            // get a texture from this CGImage
            do {
                let sourceTexture = try self.textureLoader.newTexture(with: cgImage, options: [:])
				photoCaptureDelegate.didCaptureTexture(sourceTexture: sourceTexture)
            }
            catch let error as NSError {
                fatalError("Unexpected error ocurred: \(error.localizedDescription).")
            }
<<<<<<< HEAD:ProjectLoca/Project Loca/HomeViewController.swift
=======
            
            // run inference neural network to get predictions and display them
            self.runNetwork(completion: { (gotData) in
                guard gotData else {
                    print("didn't get data")
                    return
                }
                
                print("just got the data!")
				
                
            })
            
            
>>>>>>> 02fa56bcf605e7946d967e3f3a897b8d816311d4:ProjectLoca/Project Loca/e.swift
        } else {
            print("some error here")
        }
    }
}
extension HomeViewController: AKPickerViewDelegate, AKPickerViewDataSource {
    func pickerView(_ pickerView: AKPickerView, titleForItem item: Int) -> String {
        return self.languages[item]
    }
    func numberOfItems(in pickerView: AKPickerView!) -> UInt {
        return UInt(languages.count)
    }
    func pickerView(_ pickerView: AKPickerView!, didSelectItem item: Int) {
        print("language selected: \(languages[item])")
        HomeViewController.languageSetupDelegate?.didChangeLanguage(language: languages[item])
    }
}
