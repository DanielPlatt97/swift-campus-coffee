//
//  CoffeeShopDetails+CoreDataProperties.swift
//  CampusCoffee
//
//  Created by Platt, Daniel on 22/11/2019.
//  Copyright © 2019 Platt, Daniel. All rights reserved.
//
//

import Foundation
import CoreData


extension CoffeeShopDetails {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoffeeShopDetails> {
        return NSFetchRequest<CoffeeShopDetails>(entityName: "CoffeeShopDetails")
    }

    @NSManaged public var id: String?
    @NSManaged public var url: String?
    @NSManaged public var photo_url: String?
    @NSManaged public var phone_number: String?
    @NSManaged public var monday: String?
    @NSManaged public var tuesday: String?
    @NSManaged public var wednesday: String?
    @NSManaged public var thursday: String?
    @NSManaged public var friday: String?

}
