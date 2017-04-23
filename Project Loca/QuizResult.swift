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
	
	dynamic var word: Word!
	dynamic var date: Date!
	dynamic var correct = false
	dynamic var timeLapsed: TimeInterval = 0
	
}
