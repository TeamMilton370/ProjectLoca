//
//  HistoryDataManager.swift
//  Project Loca
//
//  Created by Tyler Angert on 4/4/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import RealmSwift

class HistoryDataManager {
	
	var maxImages: Int = 10
    var allWords = [Word]()
    
    //Singleton
    static let sharedInstance = HistoryDataManager()    
	
    func saveWord(word: String, image: UIImage?, location: CLLocationCoordinate2D?) -> Word{
		var rlmWord: Word?
		do{
			print("in save word and image to realm")
			let realm = try Realm()
			rlmWord = try realm.objects(Word.self).filter(NSPredicate(format: "word == %@", word)).first
			if rlmWord != nil{		//word exists, update it
				print("got \(word)")
				//now update times seen and last seen
				try realm.write{
					rlmWord!.timesSeen += 1
					rlmWord!.lastSeen = Date()
                    
                    let lastLocation = Location(latitude: (location?.latitude)!, longitude: (location?.longitude)!)
                    rlmWord!.coordinates.append(lastLocation)
				}
            } else{ //word does not exist. create new one
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
                    let lastLocation = Location(latitude: (location?.latitude)!, longitude: (location?.longitude)!)
                    rlmWord!.coordinates.append(lastLocation)
                    
                    //adds the word to the dictionary
                    self.allWords.append(rlmWord!)

				}
			}
            
			//if images are less than 10, save this new image
			let images = realm.objects(RLMImage.self)
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
		return rlmWord!
		
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
