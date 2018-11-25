//
//  MapViewController.swift
//  WeiChat
//
//  Created by 刘铭 on 2018/11/24.
//  Copyright © 2018 刘铭. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class MapViewController: UIViewController {
  
  @IBOutlet weak var mapView: MKMapView!
  
  var location: CLLocation!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = "Map"
    
    setupUI()
    createRightButton()
  }
  
  //MARK: - Setup UI
  func setupUI() {
    var region = MKCoordinateRegion()
    region.center.latitude = location.coordinate.latitude
    region.center.longitude = location.coordinate.longitude
    
    region.span.latitudeDelta = 0.01
    region.span.longitudeDelta = 0.01
    
    mapView.setRegion(region, animated: false)
    mapView.showsUserLocation = true
    
    let annotation = MKPointAnnotation()
    annotation.coordinate = location.coordinate
    mapView.addAnnotation(annotation)
  }
  
  //MARK: - Open In Maps
  func createRightButton() {
    self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Open in Maps", style: .plain, target: self, action: #selector(self.openInMap))]
  }
  
  //MARK: - IBActions
  @objc func openInMap() {
    let regionDestination: CLLocationDistance = 1000
    let coordinates = location.coordinate
    let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDestination, longitudinalMeters: regionDestination)
    
    let options = [
      MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
      MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
    ]
    
    let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
    let mapItem = MKMapItem(placemark: placemark)
    mapItem.name = "User's Location"
    mapItem.openInMaps(launchOptions: options)
    
  }
}
