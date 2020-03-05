//
//  CoffeeShopMarker+CoreDataProperties.swift
//  CampusCoffee
//
//  Created by Platt, Daniel on 22/11/2019.
//  Copyright © 2019 Platt, Daniel. All rights reserved.
//
//

import Foundation
import CoreData


extension CoffeeShopMarker {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoffeeShopMarker> {
        return NSFetchRequest<CoffeeShopMarker>(entityName: "CoffeeShopMarker")
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var longitude: String?
    @NSManaged public var latitude: String?

}
