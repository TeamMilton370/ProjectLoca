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

class WordDetailViewController: UIViewController {
    
    var originalWord: String?
    var translatedWord: String?
    var coordinates = [Location]()
    var allPins = [MKPointAnnotation]()
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var translationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.wordLabel.text = originalWord!
        self.translationLabel.text = translatedWord!        
        self.map.delegate = self
        
        print("all coordinates: \(self.coordinates)")
    }
    
}

extension WordDetailViewController: MKMapViewDelegate {
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        
        allPins.removeAll()
        
        //adding
        for coord in self.coordinates {
            allPins.append(MKPointAnnotation())
        }
        
        for i in 0..<self.coordinates.count {
            let pin = allPins[i]
            pin.coordinate = self.coordinates[i].coordinate
            map.addAnnotation(pin)
        }
        
    }
}
