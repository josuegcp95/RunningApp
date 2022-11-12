

import UIKit
import MapKit

class StartingPoint: NSObject, MKAnnotation {
    var title: String? = "This is your starting point"
    var subtitle: String? = ""
    var coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
