

import Foundation
import CoreLocation

protocol CustomUserLocationDelegate {
    func userLocationUpdated(location: CLLocation)
    func markRouteCoordinates(locations: [CLLocation])
}

class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()
    var locationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D?
    var customUserLocationDelegate: CustomUserLocationDelegate?

    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 50
        self.locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocation = manager.location?.coordinate
        
        if customUserLocationDelegate != nil {
            customUserLocationDelegate?.userLocationUpdated(location: locations.first!)
            customUserLocationDelegate?.markRouteCoordinates(locations: locations)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print (error.localizedDescription)
    }
}
