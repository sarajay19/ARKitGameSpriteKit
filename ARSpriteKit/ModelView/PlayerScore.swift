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

/**
 * Core Data entity representing a player's game score and related information.
 *
 * Properties:
 * - Unique identifier
 * - Player name and email
 * - Game score and completion time
 * - Timestamp of score
 *
 * Note:
 * - Integrates with CloudKit for sync
 * - Used for leaderboard functionality
 * - Supports persistent storage of game results
 */
@objc(PlayerScore)
public class PlayerScore: NSManagedObject {
    /**
     * Unique identifier for the score record.
     *
     * Type: UUID?
     *
     * Note: Optional to support CoreData's creation process
     */
    @NSManaged public var id: UUID?
    /**
     * Player's display name.
     *
     * Type: String
     *
     * Note: Used for leaderboard display and player identification
     */
    @NSManaged public var name: String
    /**
     * Player's email address.
     *
     * Type: String
     *
     * Note: Used for player identification and potential future features
     */
    @NSManaged public var email: String
    /**
     * Player's game score.
     *
     * Type: Double
     *
     * Note:
     * - Represents points earned during gameplay
     * - Used for leaderboard ranking
     */
    @NSManaged public var score: Double
    /**
     * Time taken to complete the game.
     *
     * Type: Double
     *
     * Note:
     * - Stored in seconds
     * - Used as secondary sorting criteria for leaderboard
     */
    @NSManaged public var timeInSeconds: Double
    /**
     * Timestamp when the score was recorded.
     *
     * Type: Date?
     *
     * Note: Optional to support CoreData's creation process
     */
    @NSManaged public var date: Date?
}
/**
 * Extension providing fetch request functionality for PlayerScore entities.
 */
extension PlayerScore {
    /**
     * Creates a typed fetch request for PlayerScore entities.
     *
     * Returns: NSFetchRequest<PlayerScore>
     *
     * Note: Used for fetching PlayerScore records from CoreData
     */
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlayerScore> {
        return NSFetchRequest<PlayerScore>(entityName: "PlayerScore")
    }
}
