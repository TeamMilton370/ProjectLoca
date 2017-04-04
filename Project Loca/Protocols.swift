//
//  Protocols.swift
//  Project Loca
//
//  Created by Tyler Angert on 2/17/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import UIKit

///*** for data transfer to progress and history view controllers ***///
protocol UpdateHistoryDelegate {
    func didReceiveData(word: String, translation: String, image: UIImage)
}
