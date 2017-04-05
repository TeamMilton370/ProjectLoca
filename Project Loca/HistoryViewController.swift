//
//  HistoryViewController.swift
//  Project Loca
//
//  Created by Tyler Angert on 4/4/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import UIKit

class HistoryViewController: UIViewController {
    
    //MARK: IBOutlets
    
    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var recentsCollectionView: UICollectionView!
    @IBOutlet weak var streaksCollectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let blue = UIColor.init(red: 135/255, green: 206/255, blue: 250/255, alpha: 0.8)

    
    //MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.languageLabel.addTextSpacing(spacing: 5)
        self.languageLabel.textColor = UIColor.lightGray
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.separatorStyle = .none
        self.tableView.contentInset = UIEdgeInsetsMake(10, 0, 0, 0)
        
        self.recentsCollectionView.delegate = self
        self.recentsCollectionView.dataSource = self
        
        self.streaksCollectionView.delegate = self
        self.streaksCollectionView.dataSource = self
        self.streaksCollectionView.contentInset = UIEdgeInsetsMake(0, 5, 0, 0)
        
        self.recentsCollectionView.tag = 0
        self.streaksCollectionView.tag = 1
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
        self.recentsCollectionView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
}

extension HistoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("called")
        let rowCount = HistoryDataManager.sharedInstance.translationCountDictionary.count
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

        cell?.originalWord.text = data[indexPath.row].key.word.capitalizingFirstLetter()
        cell?.translatedWord.text = data[indexPath.row].key.translation.capitalizingFirstLetter()
        
        cell?.seenCount.text = "\(data[indexPath.row].value)"
        cell?.seenCount.textColor = UIColor.white
        cell?.seenCount.backgroundColor = blue
        cell?.seenCount.layer.cornerRadius = (cell?.seenCount.frame.width)!/2
        cell?.seenCount.clipsToBounds = true
        
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = (cell?.background.bounds)!
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        cell?.background.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        cell?.background.addSubview(blurEffectView)
        
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

extension HistoryViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let translationCount = HistoryDataManager.sharedInstance.translationCountDictionary.count
        var rowCount: Int?
        
        switch(collectionView.tag) {
        case 0:
            if translationCount < 5 {
                rowCount = translationCount
            } else {
                rowCount = 5
            }
        case 1:
            rowCount = 7 //7 days of the week
        default:
            break
        }
        
        return rowCount!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let data = Array(HistoryDataManager.sharedInstance.translationCountDictionary)
        
        if collectionView == self.recentsCollectionView {
            let cell: HistoryCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "historyCCell", for: indexPath) as! HistoryCollectionViewCell
            cell.image.image = data[indexPath.row].key.image
            cell.image.transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
            cell.layer.cornerRadius = (cell.frame.width)/2
            cell.clipsToBounds = true
            
            return cell
        } else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "streakCCell", for: indexPath) as! StreakCollectionViewCell
            
            let font = UIFont.init(name: "Avenir", size: 10.5)
            cell.dayLabel.font = font
            cell.dayLabel.textColor = UIColor.lightGray
            
            switch(indexPath.row) {
            case 0:
                cell.dayLabel.text = "Mon"
            case 1:
                cell.dayLabel.text = "Tue"
            case 2:
                cell.dayLabel.text = "Wed"
            case 3:
                cell.dayLabel.text = "Thu"
            case 4:
                cell.dayLabel.text = "Fri"
            case 5:
                cell.dayLabel.text = "Sat"
            case 6:
                cell.dayLabel.text = "Sun"
            default:
                print("day")
                break
            }
            
            cell.streakCircle.layer.cornerRadius = cell.streakCircle.frame.width/2
            cell.streakCircle.layer.borderColor = UIColor.lightGray.cgColor
            cell.streakCircle.layer.borderWidth = 1
            
            return cell
        }
        
    }
    
}
