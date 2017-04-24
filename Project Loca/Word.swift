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
					//print("date is new")
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
		print("in incorrect quizzes by day with \(quizResults.count)")
		var toReturn = [Date: [QuizResult]]()
		
		for quiz in quizResults{
			if quiz.correct == false{
				if toReturn[quiz.date.startOfDay] == nil{
					print("found unique day")
					var quizArray = [QuizResult]()
					quizArray.append(quiz)
					toReturn[quiz.date.startOfDay] = quizArray
				}else{
					print("adding onto existing day")
					toReturn[quiz.date.startOfDay]!.append(quiz)
				}
			}else{
				print("quiz is true, not adding")
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
		print("grabbing incorrect data points")
		var toReturn = [(x: Int, size: Int)]()
		var counter = 0 //no more than 10
		for (date,array) in inCorrectQuizzesByDay.sorted(by: { (first, second) -> Bool in
			return first.key.compare(second.key) == .orderedAscending
		}){
			let size: Int = array.count
			let x = date.days(after: Date())	//days behind today (today is zero, yesterday is -1)
			if x <= -10{
				break
			}
			print("got an incorrect data point")
			toReturn.append((x, size))
			
		}
		return toReturn
	}
	
    
    var masteryLevel: Int {
        get {
			//get percentage in last 10 sessions.
			
			var correct = 0
			var incorrect = 0
			
			var sortedQuizzes = quizResults.sorted { (q1, q2) -> Bool in
				return q1.date.compare(q2.date) == .orderedAscending
			}
			
			for i in 0...9{
				if i >= sortedQuizzes.count{
					break
				}
				let quiz = sortedQuizzes[i]
				if quiz.correct{
					correct = correct + 1
				}else{
					incorrect = incorrect + 1
				}
			}
			let percent: CGFloat = CGFloat(correct/(correct+incorrect))
			
			if percent > 0.9{
				return 3
			}else if percent > 0.75{
				return 2
			}else if percent > 0.5{
				return 1
			}else{
				return 0
			}
        }
    }
}
