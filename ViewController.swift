//
//  ViewController.swift
//  CampusCoffee
//
//  Created by Platt, Daniel on 20/11/2019.
//  Copyright © 2019 Platt, Daniel. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

/**
 Shop annotation includes an id so that we can associate an id with a marker
 so that we can get the associated id when a marker is clicked
 */
class ShopAnnotation : MKPointAnnotation {
    var id: String?
}

class ViewController:
UIViewController,
UITableViewDataSource,
UITableViewDelegate,
MKMapViewDelegate,
CLLocationManagerDelegate,
UISearchBarDelegate,
UISearchControllerDelegate
{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    
    var locationManager = CLLocationManager()
    
    let searchController = UISearchController(searchResultsController: nil)
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext?
    
    struct coffeeShop: Decodable {
        let id: String
        let name: String
        let latitude: String
        let longitude: String
    }
    struct coffeeOnCampus: Decodable {
        var data: [coffeeShop]
        let code: Int
    }
    
    // The list of coffeeshops pulled from the API or from memory
    var coffeeShops: [coffeeShop]?
    // Filtered based on searchbar input
    var filteredCoffeeShops: [coffeeShop]?
    var locationsReceived = 0
    var mostRecentLocation: CLLocation?
    let shopsUrl = "https://dentistry.liverpool.ac.uk/_ajax/coffee/"
    
    // Used to pass shop to details page
    var selectedShopId = ""
    var selectedShopName = ""
    
    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return filteredCoffeeShops?.count ?? 0
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        // The table will display all
        // items in filteredCoffeeShops
        let cell = UITableViewCell(
            style: UITableViewCell.CellStyle.subtitle,
            reuseIdentifier: "myCell"
        )
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        
        guard let shop = filteredCoffeeShops?[indexPath.row] else {
            return cell
        }
        
        cell.textLabel?.text = shop.name
        
        // If the user's location is stored display
        // the shop's distance as a note
        if let userLoc = mostRecentLocation {
            let shopLocation = CLLocation(
                latitude: Double(shop.latitude) ?? 0,
                longitude: Double(shop.longitude) ?? 0
            )
            let distance = userLoc.distance(from: shopLocation)
            cell.detailTextLabel?.text = "\(Int(distance))m"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Selects the shop based on the id of the shop in the row selected
        if let selectedRowId = filteredCoffeeShops?[indexPath.row].id {
            selectShopById(id: selectedRowId)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Selects the shop correlating to the id attatched to the marker
        if let id = (view.annotation as? ShopAnnotation)?.id {
            selectShopById(id: id)
        }
        mapView.deselectAnnotation(view.annotation, animated: true)
    }
    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        mostRecentLocation = locations[0]
        if let userLocation = mostRecentLocation {
            // Order the filtered list of coffeeshops and reload the table
            if (filteredCoffeeShops != nil) {
                filteredCoffeeShops = orderShops(
                    shops: filteredCoffeeShops!,
                    userLocation: userLocation
                )
                tableView.reloadData()
            }
            // For the first 3 locations, centre on the location
            // so that the app startes centred on the user's
            // current location. 3 times allows for error
            if (locationsReceived < 3) {
                centreMapOnLocation(location: userLocation)
            }
            locationsReceived = locationsReceived + 1
        }
    }
    
    func searchBar(
        _ searchBar: UISearchBar,
        textDidChange searchText: String
    ) {
        guard let unorderedShops = coffeeShops else { return }
        guard let userLocation = mostRecentLocation else { return }
        // First get a ordered list of all the shops
        let orderedShops = orderShops(
            shops: unorderedShops,
            userLocation: userLocation
        )
        // Then filter this list to contain the search term
        filteredCoffeeShops = orderedShops.filter { shop in
            return (
                shop.name.lowercased().contains(searchText.lowercased()) ||
                searchText.lowercased().count == 0
            )
        }
        tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        guard let unorderedShops = coffeeShops else { return }
        // Set the filtered list back to the full ordered list of shops
        if let userLocation = mostRecentLocation {
            filteredCoffeeShops = orderShops(
                shops: unorderedShops,
                userLocation: userLocation
            )
            tableView.reloadData()
        }
    }
    
    /**
     Centres the map on the location passed
     - Parameter location: The location to centre the map on
     */
    func centreMapOnLocation(location: CLLocation) {
        let span = MKCoordinateSpan(
            latitudeDelta: 0.003,
            longitudeDelta: 0.003
        )
        let locationCoordinates = CLLocationCoordinate2D(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        let region = MKCoordinateRegion(center: locationCoordinates, span: span)
        self.mapView.setRegion(region, animated: true)
    }
    
    /**
     Opens a shop's details using it's id
     - Parameter id: The id of the shop to get more details about
     */
    func selectShopById(id: String) {
        for coffeeShop in coffeeShops ?? [] {
            if coffeeShop.id == id {
                showShopDetails(
                    id: coffeeShop.id,
                    name: coffeeShop.name
                )
                return
            }
        }
    }
    
    /**
     Performs a sugue to the shop details page using the id and name of a shop
     - Parameter id: The id that will be used to pull the shop information from the API
     - Parameter name: The name of the shop to display
     */
    func showShopDetails(id: String, name: String) {
        selectedShopId = id
        selectedShopName = name
        performSegue(withIdentifier: "toDetailsView", sender: nil)
    }
    
    /**
     Adds a marker to the map at the given coffeShop's location
     - Parameter shop: The shop to display on the map
     */
    func addShopToMap(shop: coffeeShop) {
        guard let latitude = Double(shop.latitude) else { return }
        guard let longitude = Double(shop.longitude) else { return }
        let coordinate = CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
        let annotation = ShopAnnotation()
        annotation.coordinate = coordinate
        annotation.title = shop.name
        annotation.id = shop.id
        self.mapView.addAnnotation(annotation)
    }
    
    /**
     Takes a list of shops and returns an ordered list
     of said shops based on the closest to the location passed
     - Parameter shops: The array of shops to order
     - Parameter userLocation: The position to order the shops based on
     - Returns: The list of shops ordered closest to furthest from the location
     */
    func orderShops(
        shops: [coffeeShop],
        userLocation: CLLocation
    ) -> [coffeeShop] {
        let orderedShops = shops.sorted(by: {
            let shop1Location = CLLocation(
                latitude: Double($0.latitude) ?? 0,
                longitude: Double($0.longitude) ?? 0
            )
            let shop2Location = CLLocation(
                latitude: Double($1.latitude) ?? 0,
                longitude: Double($1.longitude) ?? 0
            )
            let shop1DistanceFromUser = userLocation.distance(from: shop1Location)
            let shop2DistanceFromUser = userLocation.distance(from: shop2Location)
            return shop1DistanceFromUser < shop2DistanceFromUser
        })
        return orderedShops
    }
    
    /**
     Attempts to initialise coffeeShops and filteredCoffeeShops by loading
     the coffeeShops from the API, if it fails it will attempt to load them from memory,
     if it succeeds it will overwrite the coffeeshops in memory
     */
    func requestCoffeeShops() {
        if let url = URL(
            string: shopsUrl
        ) {
            let session = URLSession.shared
            session.dataTask(with: url) { (data, response, err) in
                guard let jsonData = data else {
                    print("error")
                    DispatchQueue.main.async {
                        self.getShopsFromMemory()
                    }
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let shops = try decoder.decode(
                        coffeeOnCampus.self,
                        from: jsonData
                    )
                    for shop in shops.data {
                        self.addShopToMap(shop: shop)
                    }
                    self.coffeeShops = shops.data
                    self.filteredCoffeeShops = shops.data
                    self.replaceShopsInMemory(newShops: shops.data)
                } catch let jsonErr {
                    print("Error decoding JSON", jsonErr)
                    DispatchQueue.main.async {
                        self.getShopsFromMemory()
                    }
                }
            }.resume()
        }
    }
    
    /**
     Stores or replaces the shop markers in memory with the new list
     - Parameter newShops: The new array of shops to store in memory
     */
    func replaceShopsInMemory(newShops: [coffeeShop]) {
        let request = NSFetchRequest<NSFetchRequestResult>(
            entityName: "CoffeeShopMarker"
        )
        let deleteRequest = NSBatchDeleteRequest(
            fetchRequest: request
        )
        do {
            try context?.execute(deleteRequest)
            print("previous shops deleted from memory")
            for shop in newShops {
                saveShopInMemory(shop: shop)
            }
        } catch {
            print("unable to delete entities")
        }
    }
    
    /**
     Stores the given shop in core data
     - Parameter shop: The shop to store in core data
     */
    func saveShopInMemory(shop: coffeeShop) {
        // Creating the object used to store in core data
        let newItem = NSEntityDescription.insertNewObject(forEntityName: "CoffeeShopMarker", into: context!) as! CoffeeShopMarker
        newItem.id = shop.id
        newItem.name = shop.name
        newItem.latitude = shop.latitude
        newItem.longitude = shop.longitude
        
        do {
            try context?.save()
            print("Shop: \(shop.name) saved to memory")
        } catch {
            print("Error: Unable to save \(shop.name)")
        }
    }
    
    /**
     Attempts to initialise coffeeShops and filteredCoffeeShops by loading
     the coffeeShops from memory
     */
    func getShopsFromMemory() {
        // Create the request
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CoffeeShopMarker")
        request.returnsObjectsAsFaults = false
        
        do {
            if let shopMarkerObjects = try context?.fetch(request) as? [CoffeeShopMarker] {
                coffeeShops = []
                for shopObject in shopMarkerObjects {
                    // Checking the object has each required value
                    if (
                        shopObject.id != nil &&
                        shopObject.name != nil &&
                        shopObject.latitude != nil &&
                        shopObject.longitude != nil
                    ) {
                        let shop = coffeeShop(
                            id: shopObject.id!,
                            name: shopObject.name!,
                            latitude: shopObject.latitude!,
                            longitude: shopObject.longitude!
                        )
                        // Add the shops to the array and the map
                        coffeeShops?.append(shop)
                        addShopToMap(shop: shop)
                    }
                }
                // Finally initialise filtered list too so it
                // can be displayed in the table
                filteredCoffeeShops = coffeeShops
            }
        } catch {
            print("Couldn't fetch results")
        }
    }
    
    // Pass required values to other view controller when segue occurs
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailsView" {
            let secondViewController = segue.destination as! DetailsViewController
            secondViewController.shopId = selectedShopId
            secondViewController.shopName = selectedShopName
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialise core data context
        context = appDelegate.persistentContainer.viewContext
        
        // Initialise locationManager
        locationManager.delegate = self as CLLocationManagerDelegate
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        // Initialise searchBar
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.delegate = self
        
        // Initialise coffeeShops
        requestCoffeeShops()
    }

}

