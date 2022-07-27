

import UIKit
import MapKit

class EndingPoint: NSObject, MKAnnotation {
    var title: String? = "This is your ending point"
    var subtitle: String? = ""
    var coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
