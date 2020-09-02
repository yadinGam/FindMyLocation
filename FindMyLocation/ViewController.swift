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

class ViewController: UIViewController {
    let spanDelta = 0.01
    let locationManager = CLLocationManager()
    var previousLocation : CLLocation?
    
    @IBOutlet weak var map: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.map.delegate = self
        self.checkLocationServices()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)


    }
    
    private func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            self.setupLocationManager()
            self.checkLocationAuth()
        } else {
            //TODO:- present alert that tell them how to turn on location services
        }
    }
    
    private func setupLocationManager() {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    private func checkLocationAuth() {
        switch CLLocationManager.authorizationStatus() {
            
        case .authorizedWhenInUse:
            self.startTracking()
            break
            
        case .denied:
            //TODO:- present alert that tell them how to turn on location services
            break
            
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted:
            //something like parental restriction
            //TOD:- present alert that tell them that they are restricted for some reason
            break

        case .authorizedAlways:
            break
    
        }
    }
    
    private func startTracking() {
        self.map.showsUserLocation = true
        self.locationManager.startUpdatingLocation()
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
    
    private func checkArrival(_ location: CLLocation) {
        
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
}

extension ViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
            if location.horizontalAccuracy > 0 {
                self.locationManager.stopUpdatingLocation()
                self.render(CLLocation(latitude: location.coordinate.latitude , longitude: location.coordinate.longitude))
                self.checkArrival(location)
                
                guard let previousLocation = self.previousLocation else {
                    return
                }
                
//                if previousLocation.distance(from: location) > 50 {
                    print("we moved 50 meters from previous location")
                    self.getAdressFrom(location)
//                }
                
            }
        }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.checkLocationAuth()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location update failed, \(error)")
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
