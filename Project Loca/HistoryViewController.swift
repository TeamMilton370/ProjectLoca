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
import CoreLocation

class HistoryViewController: UIViewController {
	
	var seenWords: [Word]?
	var recentImages: Results<RLMImage>?
	let historyDataManager = HistoryDataManager.sharedInstance
    
    let geoCoder = CLGeocoder()
    
    //MARK: IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
	
    
    //MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
		
		searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsetsMake(10, 0, 0, 0)
        tableView.separatorStyle = .none
        
		loadWords(with: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		loadWords(with: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showWordDetail" {
            let selectedCell = sender as! HistoryTableViewCell
            let destination = segue.destination as! WordDetailViewController
            
            destination.originalWord = selectedCell.wordData?.word.capitalizingFirstLetter()
            destination.translatedWord = selectedCell.wordData?.translation?.capitalizingFirstLetter()
			destination.realmWord = selectedCell.wordData
			
            destination.coordinates.removeAll()
            
            for coordinate in (selectedCell.wordData?.coordinates)! {
                print(coordinate)
                destination.coordinates.append(coordinate)
            }
        }
    }
    
	func loadWords(with: NSPredicate?){
		do{
			let realm = try Realm()
			if let predicate = with{
				seenWords = realm.objects(Word.self).filter(predicate).sorted(by: { (w1, w2) -> Bool in
					let bool = w1.lastSeen.compare(w2.lastSeen) == .orderedDescending
					return bool
				})
			}else{
				seenWords = realm.objects(Word.self).sorted(by: { (w1, w2) -> Bool in
					let bool = w1.lastSeen.compare(w2.lastSeen) == .orderedDescending
					return bool
				})

			}
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
        return 115
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
        cell?.lastSeenLabel.text = seenWords![indexPath.row].lastSeen.toString()
        //Location
        let location = CLLocation(latitude: (seenWords![indexPath.row].coordinates.last?.coordinate.latitude)!, longitude: (seenWords![indexPath.row].coordinates.last?.coordinate.longitude)!)
        
        geoCoder.reverseGeocodeLocation(location, completionHandler: { placemarks, error in
            
            guard let addressDict = placemarks?.last?.addressDictionary else {
                print("no dictionary")
                return
            }
            
            guard let city = addressDict["City"] as? String else {
                print("couldn't get city")
                return
            }
            
            guard let state = addressDict["State"] as? String else {
                print("couldn't get state")
                return
            }
            
            DispatchQueue.main.async {
                cell?.locationLabel.text = "\(city), \(state)"
            }
        })
        
        //Styling
        cell?.rating.backgroundColor = UIColor.clear
        cell?.rating.isUserInteractionEnabled = false
        cell?.background.clipsToBounds = true
        cell?.background.layer.cornerRadius = 10
        
        cell?.background.layer.shadowColor = UIColor.black.cgColor
        cell?.background.layer.shadowOpacity = 0.2
        cell?.background.layer.shadowRadius = 5
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        cell?.backgroundView = blurEffectView

        
        cell?.layer.cornerRadius = 10
		
        return cell!
        
    }
}

extension HistoryViewController: UISearchBarDelegate{
	
	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
		searchBar.text = ""
		searchBar.showsCancelButton = true
		searchBar.placeholder = "Search by Word or Translation"
	}
	func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
	}
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		searchBar.showsCancelButton = false
		searchBar.resignFirstResponder()
		loadWords(with: nil)
		tableView.reloadData()
	}
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
		
		let wordContainPredicate = NSPredicate(format: "word CONTAINS[c] %@", searchText)
		let translationContainsPredicate = NSPredicate(format: "translation CONTAINS[c] %@", searchText)
		
		let compoundPredicate = NSCompoundPredicate(type: NSCompoundPredicate.LogicalType.or , subpredicates: [wordContainPredicate, translationContainsPredicate])
		
		loadWords(with: compoundPredicate)
		tableView.reloadData()
	}

	
}
