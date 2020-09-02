//
//  ViewController.swift
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

class ViewController: UIViewController {
    let spanDelta = 0.01
    let locationManager = CLLocationManager()
    var previousLocation : CLLocation?
    var destinationLocation : CLLocation?
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var locationSearchBar: UISearchBar!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.map.delegate = self
        self.locationSearchBar.delegate = self
        
        self.checkLocationServices()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.destinationLabel.text = ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
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
    
    private func addPin(in coordinate: CLLocationCoordinate2D) {
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        self.map.addAnnotation(pin)
    }
    
    private func checkArrival(_ location: CLLocation) -> Bool {
        guard let destinationLocation = self.destinationLocation else {
            return false
        }
        return destinationLocation.distance(from: location) <= 5
    }
    
    private func getAdressFrom(_ location: CLLocation) {
        let geoCoder = CLGeocoder()
        
        geoCoder.reverseGeocodeLocation(location) {
            [weak self] (placemarks, error) in
            guard let self = self else {
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
    
    
    func dispalySingleActionAlert(title: String, message: String, success: CompletionHandler? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                success?()
            })
            alert.addAction(okAction)
            self.present(alert, animated: true)
        }
    }
    
   
}

extension ViewController : CLLocationManagerDelegate {
    
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
        self.dispalySingleActionAlert(title: "Location Services", message: "Location update failed, \(error)")
    }
    
    
    
}

extension ViewController : MKMapViewDelegate {
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

extension ViewController : UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchText)
    }
}
