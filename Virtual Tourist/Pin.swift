//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Ramiro H. Lopez on 7/27/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import Foundation
import CoreData


class Pin: NSManagedObject {

    convenience init(latitude: Double, longitutde: Double, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) {
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            self.latitude = latitude
            self.longitude = longitutde
        } else {
            fatalError("Unable to find entity name!")
        }
    }
}
