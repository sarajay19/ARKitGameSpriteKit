//
//  PlayerScore.swift
//  ARSpriteKit
//
//  Created by Sara AlQuwaifli on 28/01/2025.
//
//  Core Data entity for storing player scores and game statistics.
//  Manages persistence of game results and leaderboard data.

import Foundation
import CoreData
import CloudKit

@objc(PlayerScore)
public class PlayerScore: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var name: String
    @NSManaged public var email: String
    @NSManaged public var score: Double
    @NSManaged public var timeInSeconds: Double
    @NSManaged public var date: Date?
}

extension PlayerScore {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlayerScore> {
        return NSFetchRequest<PlayerScore>(entityName: "PlayerScore")
    }
}
