//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Ramiro H. Lopez on 7/27/16.
//  Copyright © 2016 Ramiro H. Lopez. All rights reserved.
//

import Foundation
import CoreData


class Photo: NSManagedObject {

    convenience init(imageURL: String, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) {
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            self.imageURL = imageURL
        } else {
            fatalError("Unable to find entity name!")
        }
    }

}
