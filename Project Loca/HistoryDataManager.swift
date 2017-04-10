//
//  HistoryDataManager.swift
//  Project Loca
//
//  Created by Tyler Angert on 4/4/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

struct wordTranslationPair: Hashable {
    var word: String!
    var translation: String!
    var image: UIImage!
    
    var hashValue: Int {
        let hash = self.word.hashValue
        return hash
    }
    
    init(word: String, translation: String, image: UIImage) {
        self.word = word
        self.translation = translation
        self.image = image
    }
    
    static func ==(lhs: wordTranslationPair, rhs: wordTranslationPair) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

class HistoryDataManager {
	
	var maxImages: Int = 10
    
    //Singleton
    static let sharedInstance = HistoryDataManager()
    
    //Data storage
    var originalWords = [String]()
    var translatedWords = [String]()
    
    //Stores a tuple containing an original word, its translation, and how many times it was seen
    var translationCountDictionary = [wordTranslationPair: Int]()
    var dict = [String: String]()
    
    init(){
        HomeViewController.updateHistoryDelegate = self
    }
    
}
extension HistoryDataManager: UpdateHistoryDelegate {
    
    func didReceiveData(word: String, translation: String, image: UIImage) {
        
        let pair = wordTranslationPair(word: word, translation: translation, image: image)
        
        if HistoryDataManager.sharedInstance.translationCountDictionary[pair] != nil {
            //update the count if it exists already
            HistoryDataManager.sharedInstance.translationCountDictionary[pair] = (HistoryDataManager.sharedInstance.translationCountDictionary[pair] ?? 0) + 1
        } else {
            HistoryDataManager.sharedInstance.translationCountDictionary[pair] = 1
        }
        
        for entry in HistoryDataManager.sharedInstance.translationCountDictionary {
            print("Word: \(entry.key.word!)")
            print("Translation: \(entry.key.translation!)")
            print("Seen count: \(entry.value)")
            print("\n")
        }
        
        
        print("Translation count: \(HistoryDataManager.sharedInstance.translationCountDictionary.count)")
        
    }
}
extension HistoryDataManager{	//Save Stuff
	
	func saveWord(word: String, image: UIImage?){
		do{
			print("in save word and image to realm")
			let realm = try Realm()
			var rlmWord = try realm.objects(Word).filter(NSPredicate(format: "word == %@", word)).first
			if rlmWord != nil{		//customer exists, update it
				print("got \(word)")
				//now update times seen and last seen
				try realm.write{
					rlmWord!.timesSeen = rlmWord!.timesSeen + 1
					rlmWord!.lastSeen = Date()
				}
			}else{ //customer does not exist. create new one
				print("Word is new, saving to realm")
				
				try realm.write {
					rlmWord = Word()
					realm.add(rlmWord!)
					rlmWord!.word = word
					if let t = trans1[word]{
						rlmWord!.translation = t
					}else{
						rlmWord!.translation = trans2[word]
					}
					rlmWord!.dateAdded = Date()
					rlmWord!.lastSeen = Date()
					rlmWord!.timesSeen = 1
				}
			}
			//if images are less than 10, save this new image
			let images = realm.objects(RLMImage)
			if image != nil && images.count < maxImages{
				//get new image url, save it in word, an save new image
				let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
				let fileName = "\(rlmWord!.word)\(rlmWord!.images.count)"
				let fileURL = documentsURL.appendingPathComponent(fileName)
				
				try realm.write {
					let rlmImage = RLMImage()
					rlmImage.imageURL = fileURL.absoluteString
					rlmImage.word = word
					rlmImage.dateAdded = Date()
					realm.add(rlmImage)
					rlmWord!.images.append(rlmImage)
				}
				//save image to phone
				let pngImageData = UIImagePNGRepresentation(image!)
				let result = try pngImageData!.write(to: fileURL)
			}
		}catch{
			print(error)
		}
		
	}
	func loadImageFromPath(path: String) -> UIImage? {
		let image = UIImage(contentsOfFile: path)
		if image == nil {
			print("missing image at: \(path)")
		}
		print("Loading image from path: \(path)") // this is just for you to see the path in case you want to go to the directory, using Finder.
		return image
	}
}
