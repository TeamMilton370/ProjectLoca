//
//  WordDetailViewController.swift
//  Project Loca
//
//  Created by Tyler Angert on 4/11/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Charts
import Cosmos

class WordDetailViewController: UIViewController {
    
    var originalWord: String?
    var translatedWord: String?
    var coordinates = [Location]()
    var allPins = [MKPointAnnotation]()
    let geoCoder = CLGeocoder()
    
    
    @IBOutlet weak var chart: CombinedChartView!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var translationLabel: UILabel!

    @IBOutlet weak var rating: CosmosView! {
        didSet {
            rating.backgroundColor = UIColor.clear
            rating.settings.updateOnTouch = false
            rating.settings.starMargin = 5

        }
    }
    
    @IBOutlet weak var lastLocationLabel: UILabel! {
        didSet{
            formatLabel(label: timesSeenLabel)
        }
    }
    @IBOutlet weak var timesSeenLabel: UILabel! {
        didSet{
            formatLabel(label: timesSeenLabel)
        }
    }
    @IBOutlet weak var percentCorrectLabel: UILabel! {
        didSet{
            formatLabel(label: percentCorrectLabel)
        }
    }
    
    func formatLabel(label: UILabel) {
        label.layer.borderColor = UIColor.lightGray.cgColor
        label.layer.borderWidth = 1
        label.layer.cornerRadius = 5
        label.textColor = UIColor.lightGray
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.wordLabel.text = originalWord!
        self.translationLabel.text = translatedWord!        
        self.map.delegate = self
        self.map.layer.cornerRadius = 10
        
        //chart
        chart.delegate = self
        chart.notifyDataSetChanged()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.chart.animate(yAxisDuration: 0.5)
    }
    
}

extension WordDetailViewController: MKMapViewDelegate {
    
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        allPins.removeAll()
        
        for _ in self.coordinates {
            allPins.append(MKPointAnnotation())
        }
        
        for i in 0..<self.coordinates.count {
            let pin = allPins[i]
            let coord = self.coordinates[i].coordinate
            pin.coordinate = coord
            self.map.addAnnotation(pin)
        }
        
    }
}

extension WordDetailViewController: ChartViewDelegate {
    
    func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: Highlight) {
        print("Data set index: \(dataSetIndex)")
    }
}
