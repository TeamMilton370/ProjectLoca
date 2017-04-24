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
	let quizResults = List<QuizResult>()	
	
	var correctQuizzesByDay: [Date: [QuizResult]]{
		var toReturn = [Date: [QuizResult]]()
		
		for quiz in quizResults{
			if quiz.correct{
				if toReturn[quiz.date.startOfDay] == nil{
					print("date is new")
					var quizArray = [QuizResult]()
					quizArray.append(quiz)
					toReturn[quiz.date.startOfDay] = quizArray
				}else{
					toReturn[quiz.date.startOfDay]!.append(quiz)
				}
			}
		}
		return toReturn
	}
	var inCorrectQuizzesByDay: [Date: [QuizResult]]{
		var toReturn = [Date: [QuizResult]]()
		
		for quiz in quizResults{
			if quiz.correct == false{
				if toReturn[quiz.date.startOfDay] == nil{
					print("date is new")
					var quizArray = [QuizResult]()
					quizArray.append(quiz)
					toReturn[quiz.date.startOfDay] = quizArray
				}else{
					toReturn[quiz.date.startOfDay]!.append(quiz)
				}
			}
		}
		return toReturn
	}
	
	var correctQuizDataPoints: [(x: Int, size: Int)]{
		var toReturn = [(x: Int, size: Int)]()
		var counter = 0 //no more than 10
		
		for (date,array) in correctQuizzesByDay.sorted(by: { (first, second) -> Bool in
				return first.key.compare(second.key) == .orderedAscending
		}){
			let size: Int = array.count
			let x = Int(date.timeIntervalSince1970)
			counter = counter + 1
			if counter == 10{
				break
			}
		}
		return toReturn
	}
	
	var inCorrectQuizDataPoints: [(x: Int, size: Int)]{
		print("grabbing correct data points")
		var toReturn = [(x: Int, size: Int)]()
		var counter = 0 //no more than 10
		for (date,array) in inCorrectQuizzesByDay.sorted(by: { (first, second) -> Bool in
			return first.key.compare(second.key) == .orderedAscending
		}){
			let size: Int = array.count
			let x = Int(date.timeIntervalSince1970)
			counter = counter + 1
			print("got an incorrect data point")

			if counter == 10{
				break
			}
		}
		return toReturn
	}
	
    
    var masteryLevel: Int {
        get {
            return 0
        }
    }
}
