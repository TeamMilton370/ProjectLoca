//
//  HistoryTableViewCell.swift
//  Project Loca
//
//  Created by Tyler Angert on 4/4/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import UIKit
import Cosmos

class HistoryTableViewCell: UITableViewCell {

    var wordData: Word?
    
    @IBOutlet weak var lastSeenLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var originalWord: UILabel!
    @IBOutlet weak var translatedWord: UILabel!
    @IBOutlet weak var background: UIView!
    @IBOutlet weak var rating: CosmosView!
    
}
