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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.wordLabel.text = originalWord!
        self.translationLabel.text = translatedWord!        
        self.map.delegate = self
        self.map.layer.cornerRadius = 10
        
        print("all coordinates: \(self.coordinates)")
    }
    
}

extension WordDetailViewController: MKMapViewDelegate {
    
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        allPins.removeAll()
        
        //adding
        for coord in self.coordinates {
            allPins.append(MKPointAnnotation())
        }
        
        for i in 0..<self.coordinates.count {
            let pin = allPins[i]
            let coord = self.coordinates[i].coordinate
            pin.coordinate = coord
            
            let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            
            var pinCity: String?
            var pinState: String?
            
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
                
                print("\(i) \(city)")

                pinCity = city
                pinState = state
            })
            
//            
//            pin.title = "\(pinCity)"
//            pin.subtitle = "\(pinState)"
            print(pinState ?? "")
            print(pinCity ?? "")
            self.map.addAnnotation(pin)

        }
        
    }
}
