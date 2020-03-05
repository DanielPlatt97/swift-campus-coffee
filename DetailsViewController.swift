//
//  DetailsViewController.swift
//  CampusCoffee
//
//  Created by Platt, Daniel on 20/11/2019.
//  Copyright © 2019 Platt, Daniel. All rights reserved.
//

import UIKit
import CoreData

class DetailsViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    
    // Shop id and name passed from the previous controller
    var shopId: String = ""
    var shopName: String = ""
    
    // The website URL returned from the API
    var shopWebsiteUrl: String?
    
    let shopDetailsUrl = "https://dentistry.liverpool.ac.uk/_ajax/coffee/info/?id="
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext?
    
    struct openingHours: Decodable {
        let monday: String?
        let tuesday: String?
        let wednesday: String?
        let thursday: String?
        let friday: String?
    }
    
    struct coffeeShop: Decodable {
        let url: String?
        let photo_url: String?
        let phone_number: String?
        let opening_hours: openingHours?
    }
    
    struct coffeeShopResponse: Decodable {
        var data: coffeeShop
        let code: Int
    }
    
    // Opens the website URL if one has been stored
    @IBAction func urlButtonClick(_ sender: Any) {
        if let urlString = shopWebsiteUrl {
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    // Just dismisses the page
    @IBAction func backButtonClick(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    /**
     Displays the details of the associated coffeeeShop on the page.
     Also displays the image and stores the website URL
     - Parameter shop: The shop containing the details to display
     */
    func displayShopDetails(shop: coffeeShop) {
        if let imageUrl = shop.photo_url {
            downloadImage(from: URL(string: imageUrl)!)
        }
        
        nameLabel.text = shopName
        shopWebsiteUrl = shop.url
        
        // Creating a large string to display the details in a single label
        var detailsString = ""
        if let phoneNumber = shop.phone_number {
            detailsString += "Phone: " + phoneNumber + "\n\n"
        }
        // Opening times for each day (allows a day to be null)
        if let openingHours = shop.opening_hours {
            detailsString += "Opening Hours:\n"
            detailsString += "Monday: "
            if let mondayTimes = openingHours.monday {
                detailsString += mondayTimes + "\n"
            }
            detailsString += "Tuesday: "
            if let tuesdayTimes = openingHours.tuesday {
                detailsString += tuesdayTimes + "\n"
            }
            detailsString += "Wednesday: "
            if let wednesdayTimes = openingHours.wednesday {
                detailsString += wednesdayTimes + "\n"
            }
            detailsString += "Thursday: "
            if let thursdayTimes = openingHours.thursday {
                detailsString += thursdayTimes + "\n"
            }
            detailsString += "Friday: "
            if let fridayTimes = openingHours.friday {
                detailsString += fridayTimes + "\n"
            }
        }
        
        detailsLabel.text = detailsString
    }
    
    /**
     Attempts to load the coffeeShop details from the API
     and then displays them, if it fails to load them from the API
     it will attempt to load them from memory, if it loads them from
     the API it will store or update the details about the shop in memory
     */
    func requestShopDetails() {
        if let url = URL(
            string: shopDetailsUrl + shopId
        ) {
            let session = URLSession.shared
            session.dataTask(with: url) { (data, response, err) in
                guard let jsonData = data else {
                    DispatchQueue.main.async {
                        self.getShopDetailsFromMemory()
                    }
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let details = try decoder.decode(
                        coffeeShopResponse.self,
                        from: jsonData
                    )
                    
                    DispatchQueue.main.async() {
                        self.displayShopDetails(shop: details.data)
                    }
                    self.updateShopDetailsInMemory(shopDetails: details.data)
                } catch let jsonErr {
                    print("Error decoding JSON: \n", jsonErr)
                    DispatchQueue.main.async {
                        self.getShopDetailsFromMemory()
                    }
                }
            }.resume()
        }
    }
    
    /**
     Stores the given shop details in core data
     Checks to see if the shop details are already stored in core data, if not
     the details are saved, if so the details are updated
     - Parameter shop: The shop to store in core data
     */
    func updateShopDetailsInMemory(shopDetails: coffeeShop) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CoffeeShopDetails")
        request.returnsObjectsAsFaults = false
        // Get shops with the same id as the shop we want to store
        request.predicate = NSPredicate(format: "id == %@", shopId)
        do {
            let shops = try context?.fetch(request)
            // If there is a shop returned, update it
            if let shopDetailsObject = shops?.first as? CoffeeShopDetails {
                print("updating \(shopName) in memory...")
                assignValuesToCoreDataShopDetailsObject(
                    shopDetailsObject: shopDetailsObject,
                    shopDetailsValues: shopDetails
                )
            } else {
                // If there is no shop returned, save it for the first time
                print("saving \(shopName) in memory...")
                let newItem = NSEntityDescription.insertNewObject(
                    forEntityName: "CoffeeShopDetails",
                    into: context!
                ) as! CoffeeShopDetails
                assignValuesToCoreDataShopDetailsObject(
                    shopDetailsObject: newItem,
                    shopDetailsValues: shopDetails
                )
            }
        } catch {
            print("Failed to fetch shop details from memory", error)
        }
        
        // The core data objects are updated/created but are not
        // saved in memory yet. We save them in memory here
        do {
           try context?.save()
        } catch {
           print("Failed to save shop details:", error)
        }
    }
    
    /**
     Given a shopDetails core data object and coffeeShop values, assign the values in coffeeShop to the core data object
     - Parameter shopDetailsObject: Core data object to assign values to
     - Parameter shopDetailsValues: Values to assign to the core data object
     */
    func assignValuesToCoreDataShopDetailsObject(
        shopDetailsObject: CoffeeShopDetails,
        shopDetailsValues: coffeeShop
    ) {
        shopDetailsObject.id = shopId
        shopDetailsObject.phone_number = shopDetailsValues.phone_number
        shopDetailsObject.url = shopDetailsValues.url
        shopDetailsObject.photo_url = shopDetailsValues.photo_url
        shopDetailsObject.monday = shopDetailsValues.opening_hours?.monday
        shopDetailsObject.tuesday = shopDetailsValues.opening_hours?.tuesday
        shopDetailsObject.wednesday = shopDetailsValues.opening_hours?.wednesday
        shopDetailsObject.thursday = shopDetailsValues.opening_hours?.thursday
        shopDetailsObject.friday = shopDetailsValues.opening_hours?.friday
    }
    
    /**
     Attempts to load the coffeeShop details from core data, if it loads them
     it will display the details on the page, if it fails it will display an error message
     */
    func getShopDetailsFromMemory() {
        let request = NSFetchRequest<NSFetchRequestResult>(
            entityName: "CoffeeShopDetails"
        )
        request.returnsObjectsAsFaults = false
        // Get shops with the same id as the shop we want to display
        request.predicate = NSPredicate(format: "id == %@", shopId)
        do {
            let shops = try context?.fetch(request)
            if let shopDetailsObject = shops?.first as? CoffeeShopDetails {
                print("Loading \(shopName) details from memory...")
                displayShopDetails(
                    shop: coffeeShop(
                        url: shopDetailsObject.url,
                        photo_url: shopDetailsObject.photo_url,
                        phone_number: shopDetailsObject.phone_number,
                        opening_hours: openingHours(
                            monday: shopDetailsObject.monday,
                            tuesday: shopDetailsObject.tuesday,
                            wednesday: shopDetailsObject.wednesday,
                            thursday: shopDetailsObject.thursday,
                            friday: shopDetailsObject.friday
                        )
                    )
                )
            } else {
                print("No details saved for this shop")
                displayNoDetailsError()
            }
        } catch {
            print("Couldn't fetch results")
            displayNoDetailsError()
        }
    }
    
    /**
     Displays an error message telling the user that it could not get info from the API or memory
     */
    func displayNoDetailsError() {
        detailsLabel.text = "Unable to load details: " +
                            "There was a communication error"
    }
    
    /**
     Given a URL to an image, it will attempt to download and display this image on the page
     - Parameter url: URL to an image on the internet
     */
    func downloadImage(from url: URL) {
        print("Downloading from '\(url)'")
        let session = URLSession.shared
        session.dataTask(with: url) { (data, response, err) in
            guard let data = data, err == nil else {
               return
            }
            DispatchQueue.main.async() {
                self.imageView.image = UIImage(data: data)
            }
       }.resume()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialise core data context
        context = appDelegate.persistentContainer.viewContext
        
        requestShopDetails()
    }

}
