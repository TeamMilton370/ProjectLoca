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


class HomeViewController: UIViewController, UpdateUIDelegate {
    
    //IBOutlets
    @IBOutlet weak var queryButton: UIButton!
    @IBOutlet weak var previewView: CameraView!
    @IBOutlet weak var languagePicker: AKPickerView!
    
    @IBOutlet weak var inLanguage: UILabel!
    @IBOutlet weak var outLanguage: UILabel!
    
	//Camera-related variables
    var sessionIsActive = false
	var captureSession = AVCaptureSession()
	var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    //for picker view
    let languages = ["Spanish", "French", "Italian", "Japanese", "Chinese"]
    
    //neural network
    var inception3Net: Inception3Net!
    var device: MTLDevice?
    var commandQueue: MTLCommandQueue!
    
    var textureLoader : MTKTextureLoader!
    var ciContext : CIContext!
    var sourceTexture : MTLTexture? = nil

    
    static let session = URLSession.shared
    let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil) // Communicate with the session and other session objects on this queue.
    
    static var dataIntefaceDelegate: DataInterfaceDelegate?
    static var languageSetupDelegate: LanguageSetupDelegate?
    static var updateUIDelegate: UpdateUIDelegate?

    
	override func viewDidLoad() {
		super.viewDidLoad()
        print("hello world")
        //CAMERA
        //starts the capture session
        startSession()
        
        //initializing data interface
        let _ = DataInterface()
        DataInterface.updateUIDelegate = self
        
        //VISUALS        
        //camera view
        inLanguage.text = ""
        outLanguage.text = ""
        
        //Query button
        queryButton.layer.borderColor = UIColor.darkGray.cgColor
        queryButton.layer.borderWidth = 2
        queryButton.layer.cornerRadius = 30
        queryButton.setTitleColor(UIColor.darkGray, for: .normal)
        queryButton.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        queryButton.frame = CGRect(x: 97, y: 590, width: 200, height: 60)

        
        //Language Picker
        self.languagePicker.dataSource = self
        self.languagePicker.delegate = self
        
        self.languagePicker.font = UIFont(name: "HelveticaNeue-Light", size: 20)!
        self.languagePicker.highlightedFont = UIFont(name: "HelveticaNeue", size: 20)!
        self.languagePicker.pickerViewStyle = .styleFlat
        self.languagePicker.isMaskDisabled = false
        self.languagePicker.reloadData()
        self.languagePicker.interitemSpacing = 5
        
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
	}
    
    
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
        takePicture()
    }
    
    func runNetwork(completion: @escaping (_ completed: Bool) -> Void) {
        let startTime = CACurrentMediaTime()
        
        // to deliver optimal performance we leave some resources used in MPSCNN to be released at next call of autoreleasepool,
        // so the user can decide the appropriate time to release this
        autoreleasepool{
            // encoding command buffer
            let commandBuffer = commandQueue.makeCommandBuffer()
            
            // encode all layers of network on present commandBuffer, pass in the input image MTLTexture
            inception3Net.forward(commandBuffer: commandBuffer, sourceTexture: sourceTexture)
            
            // commit the commandBuffer and wait for completion on CPU
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
            // display top-5 predictions for what the object should be labelled
            var resultStr = ""
            
            inception3Net.getResults().forEach({ (label,prob) in
                resultStr = resultStr + label + "\t" + String(format: "%.1f", prob * 100) + "%\n\n"
            })
            
            DispatchQueue.main.async {
                self.inLanguage.text = resultStr
            }
        }
        
        let endTime = CACurrentMediaTime()
        print("Running Time: \(endTime - startTime) [sec]")
        completion(true)
    }

    
    let photoOutput = AVCapturePhotoOutput()
    func takePicture() {
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 160,
                             kCVPixelBufferHeightKey as String: 160,
                             ]
        settings.previewPhotoFormat = previewFormat
        
        self.photoOutput.capturePhoto(with: settings, delegate: self)
    }

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

extension HomeViewController: AVCapturePhotoCaptureDelegate {
    //delegate method called from takePicture()
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
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
                self.sourceTexture = try self.textureLoader.newTexture(with: cgImage, options: [:])
            }
            catch let error as NSError {
                fatalError("Unexpected error ocurred: \(error.localizedDescription).")
            }
            
            // run inference neural network to get predictions and display them
            self.runNetwork(completion: { (gotData) in
                guard gotData else {
                    print("didn't get data")
                    return
                }
                
                print("just got the data! starting animation")
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
            })
            
            
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
