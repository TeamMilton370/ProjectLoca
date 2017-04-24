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
	
	var realmWord: Word?
    var originalWord: String?
    var translatedWord: String?
    var coordinates = [Location]()
    var allPins = [MKPointAnnotation]()
    let geoCoder = CLGeocoder()
    
    weak var axisFormatDelegate: IAxisValueFormatter?
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var translationLabel: UILabel!
    @IBOutlet weak var chart: BubbleChartView!
    
    @IBOutlet weak var rating: CosmosView! {
        didSet {
            rating.backgroundColor = UIColor.clear
            rating.settings.updateOnTouch = false
            rating.settings.starMargin = 5
            rating.isUserInteractionEnabled = false
        }
    }
    
    @IBOutlet weak var lastLocationLabel: UILabel! {
        didSet{
            formatLabel(label: lastLocationLabel)
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
		if translatedWord == nil{
			translatedWord = "no translation"
		}
        self.translationLabel.text = translatedWord!
        self.map.delegate = self
        self.map.layer.cornerRadius = 10
		
        //chart
        axisFormatDelegate = self
        chart.delegate = self
        chart.notifyDataSetChanged()
        updateChartWithData()
        formatChart()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.chart.animate(yAxisDuration: 0.5)
        updateChartWithData()
    }
    
    //Chart stuff
    func updateChartWithData() {
	
		if realmWord == nil{
			print("no realm word for chart. quitting")
			return
		}
        var dataEntries: [BubbleChartDataEntry] = []

		for point in realmWord!.correctQuizDataPoints{
			print("appending data point")
			dataEntries.append(BubbleChartDataEntry(x: Double(point.x), y: 1, size: CGFloat(point.size)))
		}
		for point in realmWord!.inCorrectQuizDataPoints{
			print("appending data point")
			dataEntries.append(BubbleChartDataEntry(x: Double(point.x), y: 2, size: CGFloat(point.size)))
		}
		
        let chartDataSet = BubbleChartDataSet(values: dataEntries, label: "Visitor count")
        let chartData = BubbleChartData(dataSet: chartDataSet)
        chart.data = chartData
        
        let xaxis = chart.xAxis
        xaxis.valueFormatter = axisFormatDelegate
    }
    
    enum quizResult {
        case correct
        case failure
    }
    
    func getResultCount(result: quizResult) {
    }
    
    func formatChart() {
        let font = setFont(name: "Avenir heavy", size: 10)
        
        chart.rightAxis.drawAxisLineEnabled = false
        chart.leftAxis.drawAxisLineEnabled = false
        chart.leftAxis.drawLabelsEnabled = false
        chart.rightAxis.drawLabelsEnabled = false
        
        chart.leftAxis.drawGridLinesEnabled = false
        chart.rightAxis.drawGridLinesEnabled = false
        
        chart.chartDescription?.text = ""
        //Font stuff
        chart.data?.setValueFont(font)
        chart.xAxis.labelFont = font
        chart.legend.font = font
        chart.noDataFont = font
        chart.data?.setValueTextColor(UIColor.white)
        
        chart.xAxis.drawAxisLineEnabled = false
        chart.legend.form = .circle
        chart.legend.horizontalAlignment = .center
        
        chart.leftAxis.axisMinimum = 0
        chart.leftAxis.axisMaximum = 3
        
        chart.backgroundColor = UIColor.clear
        chart.xAxis.gridColor = UIColor.lightGray.withAlphaComponent(0.3)
        
        chart.xAxis.labelPosition = .bottom
        chart.scaleXEnabled = false
        chart.scaleYEnabled = false
    }
    
    func setFont(name: String, size: CGFloat) -> NSUIFont {
        return NSUIFont(name: name, size: size)!
    }
}

extension WordDetailViewController: MKMapViewDelegate {
    
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
    
        if fullyRendered {
            allPins.removeAll()
            
            for _ in self.coordinates {
                allPins.append(MKPointAnnotation())
            }
            
            for i in 0..<self.coordinates.count {
                let pin = allPins[i]
                let coord = self.coordinates[i].coordinate
                pin.coordinate = coord
                self.map.addAnnotation(pin)
                print("COORDINATE: \(pin.coordinate)")
            }
        }
        
    }
}

extension WordDetailViewController: ChartViewDelegate {
    
    func chartValueSelected(chartView: ChartViewBase, entry: ChartDataEntry, dataSetIndex: Int, highlight: Highlight) {
        print("Data set index: \(dataSetIndex)")
    }
}
	

extension WordDetailViewController: IAxisValueFormatter {
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm.ss"
        return dateFormatter.string(from: Date(timeIntervalSince1970: value))
    }
}
