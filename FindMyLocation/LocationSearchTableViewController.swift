//
//  LocationSearchTableViewController.swift
//  FindMyLocation
//
//  Created by yading on 06/09/2020.
//  Copyright © 2020 yading. All rights reserved.
//

import UIKit
import MapKit

protocol LocationSearchTableDelegate : class {
    func selected(item: MKPlacemark)
}

class LocationSearchTableViewController : UITableViewController {
    
    var mapView: MKMapView? = nil
    var matchingItems:[MKMapItem] = []
    weak var delegate : LocationSearchTableDelegate?
    
    func parseAddress(selectedItem: MKPlacemark) -> String {
        // put a space between "4" and "Melrose Place"
        let firstSpace = (selectedItem.subThoroughfare != nil && selectedItem.thoroughfare != nil) ? " " : ""
        // put a comma between street and city/state
        let comma = (selectedItem.subThoroughfare != nil || selectedItem.thoroughfare != nil) && (selectedItem.subAdministrativeArea != nil || selectedItem.administrativeArea != nil) ? ", " : ""
        // put a space between "Washington" and "DC"
        let secondSpace = (selectedItem.subAdministrativeArea != nil && selectedItem.administrativeArea != nil) ? " " : ""
        let addressLine = String(
            format:"%@%@%@%@%@%@%@",
            // street number
            selectedItem.subThoroughfare ?? "",
            firstSpace,
            // street name
            selectedItem.thoroughfare ?? "",
            comma,
            // city
            selectedItem.locality ?? "",
            secondSpace,
            // state
            selectedItem.administrativeArea ?? ""
        )
        return addressLine
    }
}

extension LocationSearchTableViewController {
    
        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return matchingItems.count
        }
        
        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    //        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
            let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: nil)
            let selectedItem = matchingItems[indexPath.row].placemark
            cell.textLabel?.text = selectedItem.name
            cell.detailTextLabel?.text = self.parseAddress(selectedItem: selectedItem)
            return cell
        }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.selected(item: self.matchingItems[indexPath.row].placemark)
        dismiss(animated: true, completion: nil)
    }
}

extension LocationSearchTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let mapView = self.mapView,
            let searchBarText = searchController.searchBar.text else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let response = response else {
                return
            }
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
        }
    }
}
