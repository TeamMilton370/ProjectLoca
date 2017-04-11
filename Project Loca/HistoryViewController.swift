//
//  HistoryViewController.swift
//  Project Loca
//
//  Created by Tyler Angert on 4/4/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class HistoryViewController: UIViewController {
	
	var seenWords: Results<Word>?
	var recentImages: Results<RLMImage>?
	let historyDataManager = HistoryDataManager.sharedInstance
    
    let blue = UIColor.init(red: 135/255, green: 206/255, blue: 250/255, alpha: 0.8)

    
    //MARK: IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
	
    
    //MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsetsMake(10, 0, 0, 0)
        tableView.separatorStyle = .none
        
		loadWords()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showWordDetail" {
            let selectedCell = sender as! HistoryTableViewCell
            let destination = segue.destination as! WordDetailViewController
            
            destination.originalWord = selectedCell.originalWord.text!
            destination.translatedWord = selectedCell.translatedWord.text!
            
            destination.coordinates.removeAll()
            
            for coordinate in (selectedCell.wordData?.coordinates)! {
                print(coordinate)
                destination.coordinates.append(coordinate)
            }
        }
    }
    
	func loadWords(){
		do{
			let realm = try Realm()
			seenWords = realm.objects(Word.self)
			recentImages = realm.objects(RLMImage.self).sorted(byKeyPath: "dateAdded", ascending: false)
		}catch{
			print(error)
		}
	
	}
}

extension HistoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("called")
		guard let rowCount = seenWords?.count else{
			return 0
		}
        return rowCount
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("selected: \(indexPath)")
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:HistoryTableViewCell? = tableView.dequeueReusableCell(withIdentifier: "historyTCell") as! HistoryTableViewCell?
		
        //Data
        cell?.wordData = seenWords![indexPath.row]
		cell?.originalWord.text = seenWords![indexPath.row].word.capitalizingFirstLetter()
		cell?.translatedWord.text = seenWords![indexPath.row].translation?.capitalizingFirstLetter()
		cell?.seenCount.text = "\(seenWords![indexPath.row].timesSeen)"
        
        
        //Styling
        cell?.seenCount.textColor = UIColor.white
        cell?.seenCount.backgroundColor = blue
        cell?.seenCount.layer.cornerRadius = (cell?.seenCount.frame.width)!/2
        cell?.seenCount.clipsToBounds = true
        
        cell?.background.clipsToBounds = true
        cell?.background.layer.cornerRadius = 10
        
        cell?.background.layer.shadowColor = UIColor.black.cgColor
        cell?.background.layer.shadowOpacity = 0.2
        cell?.background.layer.shadowRadius = 5
        cell?.background.layer.shadowOffset = CGSize.zero
        
        cell?.layer.cornerRadius = 10
		
        return cell!
        
    }
}
