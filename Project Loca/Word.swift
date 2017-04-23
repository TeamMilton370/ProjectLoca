//
//  Word.swift
//  Project Loca
//
//  Created by Jake Cronin on 4/4/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import CoreLocation
import RealmSwift

class Word: Object{
		
	dynamic var word: String!
	dynamic var translation: String?
	dynamic var dateAdded: Date!
	dynamic var lastSeen: Date!
	dynamic var timesSeen: Int = 0
    dynamic var progress: Progress?
    
    let coordinates = List<Location>()
	let images = List<RLMImage>()

}
