//
//  QuizResult.swift
//  Project Loca
//
//  Created by Jake Cronin on 4/20/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import RealmSwift

class QuizResult: Object{
	
	dynamic var word: String!
	dynamic var date: Date!
	dynamic var correct: Bool!
	dynamic var timeLapsed: NSTimeInterval?
	
}
