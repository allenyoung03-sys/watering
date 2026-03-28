//
//  WateringRecord.swift
//  绿植管家
//

import CoreData
import SwiftUI

@objc(WateringRecord)
public class WateringRecord: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var plantId: UUID
    @NSManaged public var date: Date
    @NSManaged public var note: String?
    
    @NSManaged public var plant: Plant?
}

extension WateringRecord {
    static func create(
        context: NSManagedObjectContext,
        plant: Plant,
        note: String? = nil
    ) -> WateringRecord {
        let record = WateringRecord(context: context)
        record.id = UUID()
        record.plantId = plant.id
        record.date = Date()
        record.note = note
        record.plant = plant
        return record
    }
}

extension WateringRecord {
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
    
    var relativeTime: String {
        date.relativeTimeString
    }
}
