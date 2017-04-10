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


/*
zh_Hans_HK	Chinese

//es	Spanish
*/
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
	var selectedLocale: Locale = Locale(identifier: locales["English"]!)
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
	
	@IBOutlet weak var micButton: UIButton!
	@IBOutlet weak var speechTextLabel: PaddingLabel!
	@IBOutlet weak var toggleTextLabel: PaddingLabel!
	@IBOutlet weak var toggleSwitch: UISwitch!
	@IBOutlet weak var correctImage: UIImageView!
	
    //Class variables
    //Camera-related variables
    var sessionIsActive = false
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    let photoOutput = AVCapturePhotoOutput()
    var beginZoomScale: CGFloat = 1.0
    var zoomScale: CGFloat = 1.0
    
    
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
    
}

extension HomeViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        //CAMERA
        //starts the capture session
        startSession()
        
        //initializing data manager for word history
		
        //VISUALS
        
        //Language labels
        inLanguage.text = ""
        outLanguage.text = ""
		
		correctImage.alpha = 0.0
		correctImage.isHidden = false
                
        inLanguage.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        inLanguage.layer.cornerRadius = 10
        inLanguage.clipsToBounds = true
        
        outLanguage.backgroundColor = UIColor.white.withAlphaComponent(0.6)
        outLanguage.layer.cornerRadius = 10
        outLanguage.clipsToBounds = true
		
		micButton.layer.cornerRadius = 30
		micButton.backgroundColor = UIColor.white.withAlphaComponent(0.7)
		
		
		speechTextLabel.backgroundColor = UIColor.white.withAlphaComponent(0.7)
		speechTextLabel.layer.cornerRadius = 8
		speechTextLabel.clipsToBounds = true
		
		//toggleTextLabel.backgroundColor = UIColor.white.withAlphaComponent(0.7)
		//toggleTextLabel.layer.cornerRadius = 10

		
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
    }
    func addActionSheet() -> UIAlertController {
        let alertController = UIAlertController(title: "You found a new word!", message: nil, preferredStyle: .actionSheet)
        
        let saveButton = UIAlertAction(title: "Save to words", style: .default, handler: { (action) -> Void in
            print("About to save a word")
            self.captureTimer = Timer.scheduledTimer(timeInterval: self.captureInteral, target: self, selector: #selector(self.takePicture), userInfo: nil, repeats: true)
			
			//Do-Catch saves the word if necessary, and updates 'lastSeen' and 'timesSeen'
			self.historyDataManager.saveWord(word: self.inLanguage.text!, image: self.currentImage)
			
            //Delegation to the history when saving
            HomeViewController.updateHistoryDelegate?.didReceiveData(
                word: self.inLanguage.text!,
                translation: self.outLanguage.text!,
                image: self.currentImage!)
        })
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            print("Cancel button tapped")
            self.captureTimer = Timer.scheduledTimer(timeInterval: self.captureInteral, target: self, selector: #selector(self.takePicture), userInfo: nil, repeats: true)
            
        })
        
        alertController.addAction(saveButton)
        alertController.addAction(cancelButton)
        
        return alertController
    }
    @IBAction func pressQuery(_ sender: Any) {
		captureTimer.invalidate()
		self.tabBarController?.present(self.alert, animated: true, completion: nil)
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
	@IBAction func toggleSwitch(_ sender: Any){
		if toggleSwitch.isOn{	//quiz mode
			toggleTextLabel.text = "Quiz"
			outLanguage.isHidden = true
			micButton.isHidden = false
			micButton.isEnabled = true
			queryButton.isHidden = true
			
		}else{
			toggleTextLabel.text = "Search"
			outLanguage.isHidden = false
			micButton.isEnabled = false
			micButton.isHidden = true
			speechTextLabel.isHidden = true
			queryButton.isHidden = false
		}
		
		
		
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
            var translation = ""
            var results = [(String,Float)]()
            
            inception3Net.getResults().forEach({ (label,prob) in
                
                let newResult = (label,prob)
                results.append(newResult)
            })
            
            //sort the results
            results.sort { $0.1 > $1.1 }
//            print("First one!: \(results.first?.0)")
            translation = (results.first?.0)!
            
            let delimiter = ","
            //take first item from tuple
            let newstr = results.first?.0
            let token = newstr?.components(separatedBy: delimiter)
            translation = (token?.first!)!
            
            DispatchQueue.main.async {
                
                //unhiding the labels
                if self.inLanguage.isHidden {
                    self.inLanguage.isHidden = false
                    self.outLanguage.isHidden = false
                }
                
                self.inLanguage.text = translation
                
                if trans1[translation] != nil {
                    self.outLanguage.text = trans1[translation]
                } else {
                    self.outLanguage.text = trans2[translation]
                }
            }

        }
        
        let endTime = CACurrentMediaTime()
//        print("Running Time: \(endTime - startTime) [sec]")
        completion(true)
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
}

extension HomeViewController: AVCapturePhotoCaptureDelegate {
    //delegate method called from takePicture()
    //random little change
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
//                print("just got the data!")
            })
            
            
        } else {
//            print("some error here")
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
				self.pressMic(self.micButton)
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
			self.displayCorrectImage(correct: true)
			return
		}
		for transcription in transcriptions!{
			print("is \(outLanguage.text!) equal to \(transcription.formattedString)?")
			if transcription.formattedString == outLanguage.text!{
				print("yes")
				self.displayCorrectImage(correct: true)
				return
			}else{
				print("no")
			}
		}
		print("didn't get it")
		self.displayCorrectImage(correct: true)
	}
	func setMicUI(status: SpeechStatus) {
		switch status {
		case .ready:
			print("setting image to recognizing")
		micButton.setImage(#imageLiteral(resourceName: "Microphone-48"), for: .normal)
		case .recognizing:
			print("setting image to recognizing")
		micButton.setImage(#imageLiteral(resourceName: "Audio Wave Filled-50"), for: .normal)
		case .unavailable:
			print("setting image to recognizing")
			micButton.setImage(#imageLiteral(resourceName: "No Microphone-48"), for: .normal)
		}
	}
	func displayCorrectImage(correct: Bool){
		if correct{
			correctImage.image = #imageLiteral(resourceName: "checkmark-green")
		}else{
			correctImage.image = #imageLiteral(resourceName: "redX")
		}
		animateFadeIn(imageView: correctImage)
		
	}
	func animateFadeIn(imageView: UIImageView){
		DispatchQueue.main.async {
			UIView.animate(withDuration: 1, delay: 0, options: .transitionCrossDissolve, animations: {
				imageView.alpha = 1.0
			}, completion: { (done) in
				self.animateFadeOut(imageView: imageView)
			})
		}
	}
	func animateFadeOut(imageView: UIImageView){
		DispatchQueue.main.async {
			UIView.animate(withDuration: 1, delay: 0.3, options: .transitionCrossDissolve, animations: {
				imageView.alpha = 0.0
			}, completion: nil)
		}
	}
	
}

/*
{(nl-NL",
"es-MX",
"zh-TW",
"fr-FR",
"it-IT",
"vi-VN",
"en-ZA",
"ca-ES",
"es-CL",
"ko-KR",
"ro-RO",
"fr-CH",
"en-PH",
"en-CA",
"en-SG",
"en-IN",
"en-NZ",
"it-CH",
"fr-CA",
"da-DK",
"de-AT",
"pt-BR",
"yue-CN",
"zh-CN",
"sv-SE",
"es-ES",
"ar-SA",
"hu-HU",
"fr-BE",
"en-GB",
"ja-JP",
"zh-HK",
"fi-FI",
"tr-TR",
"nb-NO",
"en-ID",
"en-SA",
"pl-PL",
"id-ID",
"ms-MY",
"el-GR",
"cs-CZ",
"hr-HR",
"en-AE",
"he-IL",
"ru-RU",
"de-CH",
"en-AU",
"de-DE",
"nl-BE",
"th-TH",
"pt-PT",
"sk-SK",
"en-US",
"en-IE",
"es-CO",
"uk-UA",
"es-US"
)}
*/
