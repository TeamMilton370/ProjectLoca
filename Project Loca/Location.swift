//
//  Location.swift
//  Project Loca
//
//  Created by Tyler Angert on 4/11/17.
//  Copyright © 2017 TeamMilton370. All rights reserved.
//

import Foundation
import CoreLocation
import RealmSwift

class Location: Object {
    
    dynamic var latitude = 0.0
    dynamic var longitude = 0.0
    
    /// Computed properties are ignored in Realm
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude)
    }
    
    convenience init(latitude: Double, longitude: Double ) {
        self.init()
        self.latitude = latitude
        self.longitude = longitude
    }
}
