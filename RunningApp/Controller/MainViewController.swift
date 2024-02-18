

import UIKit
import MapKit

class MainViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var unitControl: UISegmentedControl!
    var routeCoordinates: [CLLocation] = []
    var routeOverlay: MKOverlay?
    var startingSpotAnnotation: StartingPoint?
    var endingSpotAnnotation: EndingPoint?
    var kilometers = 00.00
    var miles = 00.00
    let userDefaults = UserDefaults.standard
    var startTime:Date?
    var stopTime:Date?
    var timerCounting:Bool = false
    let START_TIME_KEY = "startTime"
    let STOP_TIME_KEY = "stopTime"
    let COUNTING_KEY = "countingKey"
    var scheduledTimer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        checkLocationAuthorizationStatus()
        initializeTimerDefaults()
        finishButton.isEnabled = false
        resetButton.isEnabled = false
        shareButton.isEnabled = false
        distanceLabel.text = "\(miles) mi"
    }
    
    //MARK: - Segmented Control
    @IBAction func unitDidChange(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            distanceLabel.text = "\(miles) mi"
        case 1:
            distanceLabel.text = "\(kilometers) km"
        default:
            break
        }
    }
    //MARK: - Start Button
    @IBAction func startButtonTapped(_ sender: UIButton) {
        if mapView.annotations.count == 1 {
            guard let coordinates = LocationService.shared.currentLocation else { return }
            setupStartingAnnotation(coordinate: coordinates)
            startButton.isEnabled = false
            finishButton.isEnabled = true
            setStartTime(date: Date())
            startTimer()
        }
    }
    //MARK: - Finish Button
    @IBAction func finishButtonTapped(_ sender: UIButton) {
        if mapView.annotations.count == 2 {
            guard let coordinates = LocationService.shared.currentLocation else { return }
            setupEndingAnnotation(coordinate: coordinates)
            drawRouteCoordinates(routeData: routeCoordinates)
            finishButton.isEnabled = false
            resetButton.isEnabled = true
            shareButton.isEnabled = true
            stopTimer()
        }
    }
    //MARK: - Reset Button
    @IBAction func resetButtonTapped(_ sender: UIButton) {
        guard let coordinates = LocationService.shared.currentLocation else { return }
        startButton.isEnabled = true
        resetButton.isEnabled = false
        shareButton.isEnabled = false
        startingSpotAnnotation = nil
        endingSpotAnnotation = nil
        removeOverlays()
        centerMapOnUserLocation(coordinates: coordinates)
        routeCoordinates.removeAll()
        kilometers = 00.00
        miles = 00.00
        setStopTime(date: nil)
        setStartTime(date: nil)
        timeLabel.text = makeTimeString(hour: 0, min: 0, sec: 0)
        
        if unitControl.selectedSegmentIndex == 0 {
            distanceLabel.text = "\(miles) mi"
        } else {
            distanceLabel.text = "\(kilometers) km"
        }
    }
    //MARK: - Share Button
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        guard let screenshot = self.view.screenShot() else { return }
        shareImage(screenshot: screenshot)
    }
    
    func shareImage(screenshot: UIImage) {
        DispatchQueue.main.async {
            let activityController = UIActivityViewController(
                activityItems: [screenshot],
                applicationActivities: nil)
            self.present(activityController, animated: true, completion: nil)
        }
    }
}
//MARK: - MKMapViewDelegate
extension MainViewController: MKMapViewDelegate {
    
    // Location Authorization Request
    func checkLocationAuthorizationStatus() {
        if LocationService.shared.locationManager.authorizationStatus == .authorizedWhenInUse {
            self.mapView.showsUserLocation = true
            LocationService.shared.customUserLocationDelegate = self
        } else {
            LocationService.shared.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    // Center Map
    func centerMapOnUserLocation(coordinates: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: 250, longitudinalMeters: 250)
        self.mapView.setRegion(region, animated: true)
    }
    
    // Set Starting Annotation
    func setupStartingAnnotation(coordinate: CLLocationCoordinate2D) {
        startingSpotAnnotation = StartingPoint(coordinate: coordinate)
        mapView.addAnnotation(startingSpotAnnotation!)
    }
    
    // Set Ending Annotation
    func setupEndingAnnotation(coordinate: CLLocationCoordinate2D) {
        endingSpotAnnotation = EndingPoint(coordinate: coordinate)
        mapView.addAnnotation(endingSpotAnnotation!)
    }
    
    // Display Annotations
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? StartingPoint {
            let id = "pin"
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.canShowCallout = true
            view.animatesDrop = true
            view.pinTintColor = .systemBlue
            view.calloutOffset = CGPoint(x: -10, y: -15)
            return view
        }
        
        if let annotation = annotation as? EndingPoint {
            let id = "pin"
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.canShowCallout = true
            view.animatesDrop = true
            view.pinTintColor = .systemOrange
            view.calloutOffset = CGPoint(x: -10, y: -15)
            return view
        }
        return nil
    }
}
//MARK: - CustomLocationDelegate
extension MainViewController: CustomUserLocationDelegate {
    
    func userLocationUpdated(location: CLLocation) {
        centerMapOnUserLocation(coordinates: location.coordinate)
    }
    
    func markRouteCoordinates(locations: [CLLocation]) {
        if finishButton.isEnabled == true {
            for coordinates in locations {
                let loc = CLLocation(
                    latitude: coordinates.coordinate.latitude,
                    longitude: coordinates.coordinate.longitude
                )
                routeCoordinates.append(loc)
            }
        }
    }
}
//MARK: - Route Path and Distance
extension MainViewController {
    
    // Draw Route
    func drawRouteCoordinates(routeData: [CLLocation]) {
        let coordinates = routeData.map { location -> CLLocationCoordinate2D in
            return location.coordinate
        }
        DispatchQueue.main.async { [unowned self] in
            self.routeOverlay = MKPolyline(coordinates: coordinates, count: coordinates.count)
            
            self.mapView.addOverlay(self.routeOverlay!, level: .aboveRoads)
            
            self.mapView.setVisibleMapRect(
                self.routeOverlay!.boundingMapRect,
                edgePadding: UIEdgeInsets(top: 200, left: 50, bottom: 50, right: 50),
                animated: true)
            
            if coordinates.count != 0 {
                calculateRouteDistance(startingCoordinates:  coordinates.first!, endingCoordinates: coordinates.last!)
            }
        }
    }
    
    // Calculate Distance
    func calculateRouteDistance(startingCoordinates: CLLocationCoordinate2D, endingCoordinates: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startingCoordinates))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endingCoordinates))
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        
        directions.calculate { [unowned self] (response, error) in
            guard let route =  response?.routes.first else { return }
            
            let distance = route.distance
            let distanceMeters = Measurement(value: distance, unit: UnitLength.meters)
            
            let distanceKilometers = distanceMeters.converted(to: UnitLength.kilometers)
            let distanceMiles = distanceMeters.converted(to: UnitLength.miles)
            
            let roundedKilometers = round(distanceKilometers.value * 100) / 100.0
            let roundedMiles = round(distanceMiles.value * 100) / 100.0
            
            kilometers = roundedKilometers
            miles = roundedMiles
            
            if unitControl.selectedSegmentIndex == 0 {
                distanceLabel.text = "\(miles) mi"
            } else {
                distanceLabel.text = "\(kilometers) km"
            }
        }
    }
    
    // Render Overlays
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let directionsRenderer = MKPolylineRenderer(polyline: overlay  as! MKPolyline)
        directionsRenderer.lineWidth = 5
        directionsRenderer.strokeColor = .systemBlue
        directionsRenderer.alpha = 0.75
        
        return directionsRenderer
    }
    
    // Remove Annotations and Overlays
    func removeOverlays() {
        self.mapView.removeAnnotations(mapView.annotations)
        self.mapView.overlays.forEach({self.mapView.removeOverlay($0) })
    }
}
// MARK: - Timer
extension MainViewController {
    
    func secondsToHoursMinutesSeconds(_ ms: Int) -> (Int, Int, Int) {
        let hour = ms / 3600
        let min = (ms % 3600) / 60
        let sec = (ms % 3600) % 60
        return (hour, min, sec)
    }
    
    func makeTimeString(hour: Int, min: Int, sec: Int) -> String {
        var timeString = ""
        timeString += String(format: "%02d", hour)
        timeString += ":"
        timeString += String(format: "%02d", min)
        timeString += ":"
        timeString += String(format: "%02d", sec)
        return timeString
    }
    
    func setTimeLabel(_ val: Int) {
        let time = secondsToHoursMinutesSeconds(val)
        let timeString = makeTimeString(hour: time.0, min: time.1, sec: time.2)
        timeLabel.text = timeString
    }
    
    func setStartTime(date: Date?) {
        startTime = date
        userDefaults.set(startTime, forKey: START_TIME_KEY)
    }
    
    func setStopTime(date: Date?) {
        stopTime = date
        userDefaults.set(stopTime, forKey: STOP_TIME_KEY)
    }
    
    func setTimerCounting(_ val: Bool) {
        timerCounting = val
        userDefaults.set(timerCounting, forKey: COUNTING_KEY)
    }
    
    func startTimer() {
        scheduledTimer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(refreshValue),
            userInfo: nil,
            repeats: true)
        setTimerCounting(true)
    }
    
    func stopTimer() {
        if scheduledTimer != nil {
            scheduledTimer.invalidate()
        }
        setTimerCounting(false)
    }
    
    func calcRestartTime(start: Date, stop: Date) -> Date {
        let diff = start.timeIntervalSince(stop)
        return Date().addingTimeInterval(diff)
    }
    
    @objc func refreshValue() {
        if let start = startTime {
            let diff = Date().timeIntervalSince(start)
            setTimeLabel(Int(diff))
        } else {
            stopTimer()
            setTimeLabel(0)
        }
    }
    
    func initializeTimerDefaults() {
        timeLabel.text = makeTimeString(hour: 0, min: 0, sec: 0)
        startTime = userDefaults.object(forKey: START_TIME_KEY) as? Date
        stopTime = userDefaults.object(forKey: STOP_TIME_KEY) as? Date
        timerCounting = userDefaults.bool(forKey: COUNTING_KEY)
        
        if timerCounting {
            startTimer()
        } else {
            stopTimer()
            if let start = startTime {
                if let stop = stopTime {
                    let time = calcRestartTime(start: start, stop: stop)
                    let diff = Date().timeIntervalSince(time)
                    setTimeLabel(Int(diff))
                }
            }
        }
    }
}
