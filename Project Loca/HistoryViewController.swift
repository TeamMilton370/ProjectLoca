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
	
	
    //MARK: IBOutlets
    
    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var recentsCollectionView: UICollectionView!
    @IBOutlet weak var streaksCollectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
	
    
    //MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.recentsCollectionView.delegate = self
        self.recentsCollectionView.dataSource = self
        
        self.recentsCollectionView.tag = 0
        self.streaksCollectionView.tag = 1
		
		loadWords()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
        self.recentsCollectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
	func loadWords(){
		do{
			let realm = try Realm()
			seenWords = realm.objects(Word)
		}catch{
			print(error)
		}
	
	}
}

extension HistoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("called")
		//let rowCount = HistoryDataManager.sharedInstance.translationCountDictionary.count
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
        let data = Array(HistoryDataManager.sharedInstance.translationCountDictionary)
        print("Data from manager: \(data)\n")

		// cell?.originalWord.text = data[indexPath.row].key.word
		//cell?.translatedWord.text = data[indexPath.row].key.translation
		//cell?.seenCount.text = "\(data[indexPath.row].value)"
		
		cell?.originalWord.text = seenWords![indexPath.row].word
		cell?.translatedWord.text = seenWords![indexPath.row].translation
		cell?.seenCount.text = "\(seenWords![indexPath.row].timesSeen)"
		
        return cell!
        
    }
}

extension HistoryViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let rowCount = HistoryDataManager.sharedInstance.translationCountDictionary.count

        if rowCount < 5 {
            return rowCount
        } else {
            return 5
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        print("called")
        
        let data = Array(HistoryDataManager.sharedInstance.translationCountDictionary)
        let cell: HistoryCollectionViewCell! = collectionView.dequeueReusableCell(withReuseIdentifier: "historyCCell", for: indexPath) as! HistoryCollectionViewCell
        
        cell?.image.image = data[indexPath.row].key.image
        cell?.layer.cornerRadius = (cell?.frame.width)!/2
        cell?.clipsToBounds = true
        
        return cell!
        
    }
}

