//
//  CoreTextChunk+CoreDataClass.swift
//  Cozy
//
//  Created by Uladzislau Volchyk on 8/15/20.
//  Copyright © 2020 Uladzislau Volchyk. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CoreTextChunk)
public class CoreTextChunk: NSManagedObject {

    var selfChunk: TextChunk {
        TextChunk(text: text as! NSAttributedString, index: Int(index))
    }
    
}
