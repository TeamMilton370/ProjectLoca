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
					let newArray = [QuizResult]()
					newArray.append(word)
					toReturn[word.date.startOfDay] = newArray
				}else{
					toReturn[quiz.date.startOfDay]!.append(quiz)
				}
			}
		}
	}
	var inCorrectQuizzesByDay: [Date: [QuizResult]]{
		var toReturn = [Date: [QuizResult]]()
		
		for quiz in quizResults{
			if quiz.correct == false{
				if toReturn[quiz.date.startOfDay] == nil{
					print("date is new")
					let newArray = [QuizResult]()
					newArray.append(word)
					toReturn[word.date.startOfDay] = newArray
				}else{
					toReturn[quiz.date.startOfDay]!.append(quiz)
				}
			}
		}
	}
	
	var correctQuizDataPoints: [(x: Int, size: Int)]{
		var toReturn = [(x: Int, size: Int)]()
		var counter = 0 //no more than 10
		
		for (date,array) in correctQuizzesByDay.sorted({ (first: (key1: Date, value1: [QuizResult]), second: (key2: Date, value2: [QuizResult])) -> Bool in
				return first.key1.compare(second.key2)
		}){
			let size: Int = array.count
			let x = Int(date.timeIntervalSince1970)
			counter = counter + 1
			if conter = 10{
				break
			}
		}
		return toReturn
	}
	
	var inCorrectQuizDataPoints: [(x: Int, size: Int)]{
		var toReturn = [(x: Int, size: Int)]()
		var counter = 0 //no more than 10
		
		for (date,array) in inCorrectQuizzesByDay.sorted({ (first: (key1: Date, value1: [QuizResult]), second: (key2: Date, value2: [QuizResult])) -> Bool in
			return first.key1.compare(second.key2)
		}){
			let size: Int = array.count
			let x = Int(date.timeIntervalSince1970)
			counter = counter + 1
			if conter = 10{
				break
			}
		}
		return toReturn
	}
	
}
