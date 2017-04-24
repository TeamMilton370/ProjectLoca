//
//  ViewController.swift
//  Project Loca
//
//  Created by Jake Cronin on 2/2/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import RealmSwift
import Speech
import UIKit
import AVFoundation
import Photos
import MetalKit
import MetalPerformanceShaders
import Accelerate
import CoreLocation
import SwiftSiriWaveformView

class HomeViewController: UIViewController {
	
	enum SpeechStatus {
		case ready
		case recognizing
		case unavailable
	}
    
	//MARK: Sppech recognition variables
	let audioEngine = AVAudioEngine()
	var speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()//locale: Locale(identifier: "es Spanish"))
	let request = SFSpeechAudioBufferRecognitionRequest()
	var recognitionTask: SFSpeechRecognitionTask?
	var selectedLocale: Locale = Locale(identifier: locales["Spanish"]!)
	var status = SpeechStatus.ready {
		didSet {
			self.setMicUI(status: status)
		}
	}
    
    var transcriptions: [SFTranscription]?
	
	
    //IBoutlets
    @IBOutlet weak var previewView: CameraView!
    @IBOutlet weak var queryButton: UIButton!
    @IBOutlet weak var inLanguage: PaddingLabel!
    @IBOutlet weak var outLanguage: PaddingLabel!
    @IBOutlet weak var modeSwitch: UISegmentedControl!
    @IBOutlet weak var micButton: UIButton!
	@IBOutlet weak var speechTextLabel: UILabel!
    @IBOutlet weak var checkmark: Checkmark! {
        didSet {
            checkmark.backgroundColor = UIColor.clear
        }
    }
    
    //blur stuff
    var blurEffect: UIBlurEffect = UIBlurEffect(style: .light)
    var blurView: UIVisualEffectView?

    //Class variables
    //Camera-related variables
    var sessionIsActive = false
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    let photoOutput = AVCapturePhotoOutput()
    var beginZoomScale: CGFloat = 1.0
    var zoomScale: CGFloat = 1.0
    
    //Locaiton
    let locationManager: CLLocationManager! = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D?
    
    //Action view
    var alert: UIAlertController!
    
    //Neural network
    var inception3Net: Inception3Net!
    var device: MTLDevice?
    var commandQueue: MTLCommandQueue!
    
    var textureLoader : MTKTextureLoader!
    var ciContext : CIContext!
    var sourceTexture : MTLTexture? = nil
    
    static let session = URLSession.shared
    let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil) // Communicate with the session and other session objects on this queue.
    
    //History data management
	let historyDataManager = HistoryDataManager()
    static var updateHistoryDelegate: UpdateHistoryDelegate?
    
    //Constant capture
    var captureTimer: Timer!
    var captureInteral: TimeInterval = 1
    var currentImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        //nav bar
        self.navigationController?.navigationBar.titleTextAttributes = [ NSFontAttributeName: UIFont(name: "Avenir", size: 20)!]

        //CAMERA
        //starts the capture session
        startSession()
        
        //VISUALS
        //top nav bar
        modeSwitch.tintColor = blue
        modeSwitch.setTitleTextAttributes([ NSFontAttributeName: UIFont(name: "Avenir", size: 14.0)! ], for: .normal)

        //buttons
        micButton.alpha = 0
        
        //Language labels
        inLanguage.text = ""
        outLanguage.text = ""
                
        inLanguage.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        inLanguage.layer.cornerRadius = 10
        inLanguage.clipsToBounds = true
        
        outLanguage.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        outLanguage.layer.cornerRadius = 10
        outLanguage.clipsToBounds = true
        
        inLanguage.isHidden = true
        outLanguage.isHidden = true
        speechTextLabel.alpha = 0
        
        blurView = UIVisualEffectView(effect: blurEffect)
        blurView?.frame = CGRect(x: outLanguage.bounds.minX, y: outLanguage.bounds.minY, width: outLanguage.bounds.width*3, height: outLanguage.bounds.height*3)
        outLanguage.addSubview(blurView!)
        outLanguage.autoresizesSubviews = true
        outLanguage.layoutIfNeeded()
        blurView?.alpha = 0

		micButton.layer.cornerRadius = 30
		micButton.backgroundColor = UIColor.white.withAlphaComponent(0.7)
				
        //Query button
        queryButton.layer.cornerRadius = 30
        queryButton.setTitleColor(UIColor.darkGray, for: .normal)
        queryButton.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        queryButton.frame = CGRect(x: 97, y: 590, width: 200, height: 60)
        
        //Sizing for video preview layer
        self.videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.previewView.frame = self.view.bounds
        self.previewView.clipsToBounds = true
        self.previewView.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(self.handleZoom(_:))))
        
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
		
		captureTimer = Timer.scheduledTimer(timeInterval: captureInteral, target: self, selector: #selector(takePicture), userInfo: nil, repeats: true)
        
        //Location
        if (CLLocationManager.locationServicesEnabled()) {
            print("enabled")
            
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        } else {
            print("Location services are not enabled");
        }
        
    }

    //MARK: IBActions
    @IBAction func pressQuery(_ sender: Any) {
		captureTimer.invalidate()
		self.tabBarController?.present(self.alert, animated: true, completion: nil)
    }
    
    enum mode {
        case quiz
        case dictionary
    }
    
    @IBAction func modeSwitch(_ sender: Any) {
        let send = sender as! UISegmentedControl
        switch(send.selectedSegmentIndex) {
        case 0:
            print("dictionary selected")
            switchMode(mode: .dictionary)
            break
        case 1:
            print("quiz selected")
            switchMode(mode: .quiz)
            break
        default:
            break
        }
    }
    
    //animation helper function
    func switchMode(mode: mode) {
        
        var button1: UIButton?
        var button2: UIButton?
        var alpha: CGFloat?
        
        switch mode {
        case .quiz:
            button1 = micButton
            button2 = queryButton
            alpha = 1
        case .dictionary:
            //this handles the microphone status when switching to dictionary mode in the middle of a quiz.
            if status == .recognizing {
                cancelRecording()
                status = .ready
            }
            button1 = queryButton
            button2 = micButton
            alpha = 0
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            self.blurView?.alpha = alpha!
        })
        
        button1!.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        
        //first animation
        UIView.animate(withDuration: 0.2, animations: {
            button2!.alpha = 0
            button2!.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            button2!.isEnabled = false
        })
        
        //second animation
        UIView.animate(withDuration: 0.2, animations: {
            button1!.isHidden = false
            button1!.alpha = 1
            button1!.isEnabled = true
            button1!.transform = CGAffineTransform.identity
        })
        
    }
    
	@IBAction func pressMic(_ sender: Any){
		switch status {
		case .ready:
			startRecording()
			status = .recognizing
		case .recognizing:
			cancelRecording()
			status = .ready
		default:
			initializeSpeechRecognition()
			break
		}
	}
    
    //Helper function to add an action sheet
    func addActionSheet() -> UIAlertController {
        let alertController = UIAlertController(title: "You found a new word!", message: nil, preferredStyle: .actionSheet)
        
        let saveButton = UIAlertAction(title: "Save to words", style: .default, handler: { (action) -> Void in
            print("About to save a word")
            self.captureTimer = Timer.scheduledTimer(timeInterval: self.captureInteral, target: self, selector: #selector(self.takePicture), userInfo: nil, repeats: true)
            
            //Do-Catch saves the word if necessary, and updates 'lastSeen' and 'timesSeen'
            self.historyDataManager.saveWord(word: self.inLanguage.text!, image: self.currentImage, location: self.locationManager.location?.coordinate)
        })
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            print("Cancel button tapped")
            self.captureTimer = Timer.scheduledTimer(timeInterval: self.captureInteral, target: self, selector: #selector(self.takePicture), userInfo: nil, repeats: true)
            
        })
        
        alertController.addAction(saveButton)
        alertController.addAction(cancelButton)
        
        return alertController
    }
    
    var gotResult = false
    
    //Neural network functions
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
            var translation = ""
            var results = [(String,Float)]()
            
            inception3Net.getResults().forEach({ (label,prob) in
                let newResult = (label,prob)
                results.append(newResult)
            })
            
            results.sort { $0.1 > $1.1 }
            translation = (results.first?.0)!
            
            let delimiter = ","
            let newstr = results.first?.0
            let token = newstr?.components(separatedBy: delimiter)
            translation = (token?.first!)!
            
            DispatchQueue.main.async {
                
                self.gotResult = true
                
                if self.gotResult {
                    self.inLanguage.isHidden = false
                    self.outLanguage.isHidden = false
                }
                
                self.inLanguage.text = translation

                
                //Checking for the 2 translation dictionaries
                if trans1[translation] != nil {
                    self.outLanguage.text = trans1[translation]
                } else {
                    self.outLanguage.text = trans2[translation]
                }
            }

        }
        
        let endTime = CACurrentMediaTime()
        completion(true)
    }
    
    func startSession() {
        if !sessionIsActive {
            captureSession = AVCaptureSession()
            
            //image quality
            captureSession.sessionPreset = AVCaptureSessionPresetHigh
            
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
                self.currentImage = UIImage(cgImage: cgImage)
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
            })
            
        } else {
        }
    }
}

extension HomeViewController {
    func handleZoom(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began {
            self.beginZoomScale = self.zoomScale
        } else if gesture.state == .changed {
            self.zoomScale = min(4.0, max(1.0, self.beginZoomScale * gesture.scale))
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.025)
            self.videoPreviewLayer?.setAffineTransform(CGAffineTransform(scaleX: self.zoomScale, y: self.zoomScale))
            CATransaction.commit()
            
        }
    }
}
extension HomeViewController: SFSpeechRecognizerDelegate{
	func initializeSpeechRecognition(){
		
		switch SFSpeechRecognizer.authorizationStatus() {
			case .notDetermined:
				askSpeechPermission()
			case .authorized:
				self.status = .ready
			case .denied, .restricted:
				self.status = .unavailable
		}
		
	}
	func askSpeechPermission(){
		SFSpeechRecognizer.requestAuthorization { status in
			OperationQueue.main.addOperation {
				switch status {
				case .authorized:
					self.status = .ready
				default:
					self.status = .unavailable
				}
			}
		}
	}
	func startRecording(){
        UIView.animate(withDuration: 0.2, animations: {
            self.speechTextLabel.text = ""
            self.speechTextLabel.alpha = 1
        })
        
		//pause timer
		captureTimer.invalidate()
		
		// Setup audio engine and speech recognizer
		speechRecognizer = SFSpeechRecognizer(locale: selectedLocale)
		guard let node = audioEngine.inputNode else {
			print("no audioengine inputNode")
			return
		}
		let recordingFormat = node.outputFormat(forBus: 0)
		node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
			self.request.append(buffer)
		}
		
		// Prepare and start recording
		audioEngine.prepare()
		do {
			print("starting audioEngine")
			try audioEngine.start()
			self.status = .recognizing
		} catch {
			return print(error)
		}
		
		// Analyze the speech
		recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
			if let result = result {
				print("got result: \(result.bestTranscription.formattedString)")
				self.speechTextLabel.text = result.bestTranscription.formattedString
				self.transcriptions = result.transcriptions
			} else if let error = error {
				print(error)
			}
		})
	}
    
	func cancelRecording() {
		audioEngine.stop()
		if let node = audioEngine.inputNode {
			node.removeTap(onBus: 0)
		}
        
		recognitionTask?.cancel()
		captureTimer = Timer.scheduledTimer(timeInterval: captureInteral, target: self, selector: #selector(takePicture), userInfo: nil, repeats: true)
        
		guard transcriptions != nil else{
			print("no transcriptions")
			return
		}
        
		for transcription in transcriptions!{
			print("is \(outLanguage.text!) equal to \(transcription.formattedString)?")
            //case insensitive comparison
			if transcription.formattedString.caseInsensitiveCompare(outLanguage.text!) == ComparisonResult.orderedSame {
				print("yes")
                displayQuizResult(correct: true)
				saveQuizResult(word: inLanguage.text!, correct: true, time: 0)
				return
			}else{
				print("no")
				saveQuizResult(word: inLanguage.text!, correct: false, time: 0)
                displayQuizResult(correct: false)
			}
		}
        
        UIView.animate(withDuration: 0.2, animations: {
            self.speechTextLabel.alpha = 0
        })
    }
    
	func displayQuizResult(correct: Bool){
        let duration = 0.6
        self.speechTextLabel.alpha = 0
        self.checkmark.alpha = 1
        
		if correct {
            checkmark.setColor(color: UIColor.green.cgColor)
            checkmark.setDuration(speed: CGFloat(duration))
            
            checkmark.start(completion: { (correct) in
                UIView.animate(withDuration: 0.2, delay: duration*2, options: .curveEaseInOut, animations: {
                    
                    self.checkmark.alpha = 0
                    
                }, completion: nil)
            })
            
		} else{
            checkmark.setColor(color: UIColor.red.cgColor)
            checkmark.setDuration(speed: CGFloat(duration))
            
            checkmark.startX(completion: { (correct) in
                UIView.animate(withDuration: 0.2, delay: duration*2, options: .curveEaseInOut, animations: {

                    self.checkmark.alpha = 0
                    
                }, completion: nil)
            })
		}
	}
    
    func animateResult(correct: Bool) {
    }
    
    func setMicUI(status: SpeechStatus) {
        switch status {
        case .ready:
            print("setting image to recognizing")
            micButton.setImage(#imageLiteral(resourceName: "mic"), for: .normal)
        case .recognizing:
            print("setting image to recognizing")
            micButton.setImage(#imageLiteral(resourceName: "Audio Wave Filled-50"), for: .normal)
        case .unavailable:
            print("setting image to recognizing")
            micButton.setImage(#imageLiteral(resourceName: "No Microphone-48"), for: .normal)
        }
    }
	
	func saveQuizResult(word: String, correct: Bool, time: TimeInterval){
		
		do{
			let realm = try Realm()
			var RLMword = try realm.objects(Word).filter(NSPredicate(format: "word == %@", word)).first
			if RLMword == nil{
				RLMword =  self.historyDataManager.saveWord(word: word, image: self.currentImage, location: self.locationManager.location?.coordinate)
			}
			
			try realm.write{
				let newQuiz: QuizResult = QuizResult()
				newQuiz.word = RLMword
				newQuiz.date = Date()
				newQuiz.correct = correct
				newQuiz.timeLapsed = time
				
				RLMword!.quizResults.append(newQuiz)
				RLMword?.lastSeen = Date()
			}
		}catch{
			print("error")
		}
		//get the word
		
		//
		
	}
	
}

extension HomeViewController: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        locationManager.stopUpdatingLocation()
        if ((error) != nil) {
            print(error)
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        print("called location manager")
        let last: CLLocation = locations.last! as! CLLocation
        self.currentLocation = last.coordinate

    }
    
}
