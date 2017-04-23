//
//  ProgressViewController.swift
//  Project Loca
//
//  Created by Tyler Angert on 4/4/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import UIKit
import Charts

class ProgressViewController: UIViewController {

    
    @IBOutlet weak var lineChart: LineChartView!
    @IBOutlet weak var awardsView: UICollectionView!
    
    let sharedData = HistoryDataManager.sharedInstance
    let chartData = LineChartData()
    var formattedChartData: [ChartDataEntry]?
    var dataSet1: LineChartDataSet?
    
	
	//show number of words added over time
	//show quiz words correct and incorrect over time
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lineChart.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }

}

extension ProgressViewController: ChartViewDelegate {
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        
        print(entry)
    }
}
