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
    var allPins = [MKPinAnnotationView]()
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

        var dataEntriesCorrect: [BubbleChartDataEntry] = []
		var dataEntriesInCorrect: [BubbleChartDataEntry] = []

		for point in realmWord!.correctQuizDataPoints{
			dataEntriesCorrect.append(BubbleChartDataEntry(x: Double(point.x), y: 1, size: CGFloat(point.size)))
		}
        
		for point in realmWord!.inCorrectQuizDataPoints{
            dataEntriesInCorrect.append(BubbleChartDataEntry(x: Double(point.x), y: 2, size: CGFloat(point.size)))
		}
        
		for i in -5...0 {
			print("appending")
			dataEntriesInCorrect.append(BubbleChartDataEntry(x: Double(i*2), y: 2, size: CGFloat((i+10)*10)))
		}
		for i in -5...0 {
			print("appending")
			dataEntriesCorrect.append(BubbleChartDataEntry(x: Double(i*2+1), y: 1, size: CGFloat(i + 1)))
			
		}

        let chartDataSet1 = BubbleChartDataSet(values: dataEntriesCorrect, label: "Correct")
		let chartDataSet2 = BubbleChartDataSet(values: dataEntriesInCorrect, label: "Incorrect")
		chartDataSet2.colors = [UIColor.red.withAlphaComponent(0.7)]
		//chartDataSet2.va
		chartDataSet1.colors = [UIColor.green.withAlphaComponent(0.7)]
		
        let chartData = BubbleChartData(dataSets: [chartDataSet1, chartDataSet2])
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
		chart.xAxis.axisMinimum = -11
		chart.xAxis.axisMaximum = 1
		//chart.xAxis.labelPosition
        
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
                allPins.append(MKPinAnnotationView())
            }
            
            for i in 0..<(realmWord?.coordinates.count)! {
                let pin = allPins[i]
                let coord = self.coordinates[i].coordinate
                let annotation = MKPointAnnotation()
                
                annotation.coordinate = coord
                pin.annotation = annotation
                pin.animatesDrop = true
                
                self.map.addAnnotation(annotation)
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
        dateFormatter.dateFormat = "M/d"
		return dateFormatter.string(from: Date().back(thisManyDays: Int(value)))
		//return
    }
}
