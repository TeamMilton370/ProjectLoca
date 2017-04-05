//
//  HistoryDataManager.swift
//  Project Loca
//
//  Created by Tyler Angert on 4/4/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import UIKit

struct wordTranslationPair: Hashable {
    var word: String!
    var translation: String!
    var image: UIImage!
    var date: Date!
    
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
    
    //Singleton
    static let sharedInstance = HistoryDataManager()
    
    //Stores a tuple containing an original word, its translation, and how many times it was seen
    var translationCountDictionary = [wordTranslationPair: Int]()
    
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
