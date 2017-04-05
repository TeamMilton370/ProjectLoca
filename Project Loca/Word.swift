//
//  Word.swift
//  Project Loca
//
//  Created by Jake Cronin on 4/4/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import RealmSwift

class Word: Object{
		
	dynamic var word: String!
	dynamic var translation: String?
	
	dynamic var dateAdded: Date!
	dynamic var lastSeen: Date!
	
	dynamic var image: Data?
	dynamic var timesSeen: Int = 0
		
		
}
