//
//  MainMapViewController.swift
//  FindMyLocation
//
//  Created by yading on 02/09/2020.
//  Copyright © 2020 yading. All rights reserved.
//

import UIKit

import UIKit
import CoreLocation
import MapKit

typealias CompletionHandler = (() -> Void)

class MainMapViewController: UIViewController {
    
    private let spanDelta = 0.01
    private let minimumDisatnce : CLLocationDistance = 5
    
    private var selectedPlaceMark: MKPlacemark?
    private var previousLocation : CLLocation?
    private var destinationLocation : CLLocation?
    
    private let locationManager = CLLocationManager()
    private var resultSearchController: UISearchController?
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var destinationLabel: UILabel!
    
    private var directionsArray : [MKDirections] = []
    
    private func getDirections() {
        guard let location = self.selectedPlaceMark?.location, let currentCoordinates = self.locationManager.location?.coordinate else {
            return
        }
        
        let request = createDirectionsRequest(from: currentCoordinates, to: location)
        let directions = MKDirections(request: request)
        self.resetMap(withNew: directions)
        
        
        directions.calculate {[weak self] (response, error) in
            guard let self = self else { return }
            guard let response = response else { return }
            for rout in response.routes {
                self.map.addOverlay(rout.polyline)
                self.map.setVisibleMapRect(rout.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    private func resetMap(withNew directions: MKDirections) {
        map.removeOverlays(map.overlays)
        self.directionsArray.append(directions)
        let _ = self.directionsArray.map { $0.cancel() }
    }
    
   private func createDirectionsRequest(from coordinate: CLLocationCoordinate2D, to location: CLLocation) -> MKDirections.Request {
        let startingLocation = MKPlacemark(coordinate: coordinate)
        let destinationCoordinate = location.coordinate
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destination)
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    private func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            self.setupLocationManager()
            self.handleAuthorizationStatus(locationManager: self.locationManager, status: CLLocationManager.authorizationStatus())
        } else {
            self.dispalySingleActionAlert(title: "Location Services", message: "you need to turn on location services in your device settings")
        }
    }
    
    private func setupLocationManager() {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func handleAuthorizationStatus(locationManager : CLLocationManager, status: CLAuthorizationStatus) {
        switch status {
            
        case .authorizedWhenInUse:
            self.locationManager.startUpdatingLocation()
            self.startTracking()
            break
            
        case .denied:
            self.dispalySingleActionAlert(title: "Location Services", message: "you have denied location services so you need to turn them on in your device settings")
            break
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted:
            //something like parental restriction
            self.dispalySingleActionAlert(title: "Location Services", message: "your location srvices is restricted")
            break
            
        case .authorizedAlways:
            break
            
        }
    }
    
    private func startTracking() {
        self.map.showsUserLocation = true
        self.previousLocation = self.locationManager.location
    }
    
    private func render(_ location: CLLocation) {
        let region = self.region(for: location)
        self.map.setRegion(region, animated: true)
    }
    
    private func region(for location: CLLocation) -> MKCoordinateRegion {
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: spanDelta, longitudeDelta: spanDelta)// how muc span i want to show
        let region = MKCoordinateRegion(center: coordinate, span: span)
        return region
    }
    
    private func addPin(in placemark: MKPlacemark) {
        self.map.removeAnnotations(map.annotations)
        let pin = MKPointAnnotation()
        pin.coordinate = placemark.coordinate
        pin.title = placemark.name
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            pin.subtitle = "\(city) \(state)"
        }
        self.map.addAnnotation(pin)
    }
    
    private func checkArrival(_ location: CLLocation) -> Bool {
        guard let destination = self.selectedPlaceMark?.location else {
            return false
        }
        return destination.distance(from: location) <= 5
    }
    
    private func getAdressFrom(_ location: CLLocation) {
        let geoCoder = CLGeocoder()
        
        geoCoder.reverseGeocodeLocation(location) {
            [weak self] (placemarks, error) in
            guard let _ = self else {
                assertionFailure()
                return
            }
            
            guard let placemark = placemarks?.first else {
                assertionFailure()
                return
            }
            
            print("\(placemark.thoroughfare ?? "") \(placemark.subThoroughfare ?? "") \(placemark.locality ?? "")")
        }
        
    }
    
    private func arrivedToDestination() {
        self.locationManager.stopUpdatingLocation()
        self.dispalySingleActionAlert(title: "Location Services", message: "you have arrived to you destination")
    }
    
    
    private func dispalySingleActionAlert(title: String, message: String, success: CompletionHandler? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                success?()
            })
            alert.addAction(okAction)
            self.present(alert, animated: true)
        }
    }
    
    private func searchAdress(from text: String) {
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(text) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            if let error = error {
                self.dispalySingleActionAlert(title: "address search", message: error.localizedDescription)
                return
            } else {
                if let placemarks = placemarks, let placemark = placemarks.first, let location = placemark.location {
                    self.addPin(in: MKPlacemark(placemark: placemark))
                    self.render(location)
                }
            }
        }
    }
    
    private func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        guard let searchText = searchBar.text else {
            return
        }
        self.searchAdress(from: searchText)
    }
    
}

extension MainMapViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        self.locationManager.stopUpdatingLocation()
        self.render(CLLocation(latitude: location.coordinate.latitude , longitude: location.coordinate.longitude))
        
        if self.checkArrival(location) {
            self.arrivedToDestination()
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.handleAuthorizationStatus(locationManager: manager, status: status)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.dispalySingleActionAlert(title: "Location Services", message: "Location update failed, \(error.localizedDescription)")
    }
    
}

extension MainMapViewController : LocationSearchTableDelegate {
    
    func selected(item: MKPlacemark) {
        self.selectedPlaceMark = item
        guard let placeMark = self.selectedPlaceMark else {
            return
        }
        
        if let location = placeMark.location {
            self.render(location)
        }
        
        self.addPin(in: placeMark)
        self.getDirections()
    }
}

extension MainMapViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.map.delegate = self
        
        let locationSearchTable = LocationSearchTableViewController()
        locationSearchTable.delegate = self
        self.resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        self.resultSearchController?.searchResultsUpdater = locationSearchTable
        locationSearchTable.mapView = self.map
        
        let searchBar = self.resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        self.navigationItem.titleView = self.resultSearchController?.searchBar
        
        self.resultSearchController?.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        
        self.checkLocationServices()
        
        self.destinationLabel.text = ""
    }
    
}

extension MainMapViewController : MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        return renderer
    }
    
    //    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    //
    //        for touch in touches {
    //
    //            if let x = touch.gestureRecognizers?.first(where: { $0 is UITapGestureRecognizer }) {
    //                print("asdasdasd")
    //            }
    //               let touchPoint = touch.location(in: map)
    //               let location = map.convert(touchPoint, toCoordinateFrom: map)
    //            addPin(in: location)
    //               print ("\(location.latitude), \(location.longitude)")
    //           }
    //    }
}
