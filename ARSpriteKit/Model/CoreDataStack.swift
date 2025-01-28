//
//  CoreDataStack.swift
//  ARSpriteKit
//
//  Created by Sara AlQuwaifli on 28/01/2025.
//
//  Singleton managing Core Data and CloudKit integration.
//  Handles data persistence, synchronization, and CloudKit operations.

import CoreData
import CloudKit
import Foundation

/**
 * Core Data Stack implementation with CloudKit integration.
 *
 * Note: Singleton class that manages:
 * - Core Data persistence
 * - CloudKit synchronization
 * - Data operations and fetch requests
 * - iCloud connectivity status
 */
public class CoreDataStack {
    /**
     * Shared singleton instance of CoreDataStack.
     *
     * Note: Provides global access point to CoreData functionality
     */
    static let shared = CoreDataStack()
    
    /**
     * Lazy-loaded persistent container with CloudKit integration.
     *
     * Note:
     * - Initializes NSPersistentCloudKitContainer
     * - Configures CloudKit sync options
     * - Sets up persistent store
     * - Handles error management
     *
     * Throws: Fatal error if store description cannot be retrieved or stores fail to load
     */
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "CoreDataModel")
        
        // Configure store description for CloudKit
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve store description")
        }
        
        // Enable CloudKit
        let storeURL = description.url
        let cloudKitOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.AIGameNec")
        description.cloudKitContainerOptions = cloudKitOptions
        
        // Enable history tracking and remote notifications
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Load the persistent stores
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Failed to load persistent stores: \(error), \(error.userInfo)")
            }
        }
        
        // Configure container
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Set up sync policies
        do {
            try container.initializeCloudKitSchema()
        } catch {
            print("Failed to initialize CloudKit schema: \(error)")
        }
        
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Core Data Saving
    /**
      * Saves the current Core Data context if it has changes.
      *
      * Parameters: None
      *
      * Note:
      * - Checks for unsaved changes
      * - Attempts to save the context
      * - Prints success or failure message
      */
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("Context saved successfully")
            } catch {
                let nserror = error as NSError
                print("Failed to save context: \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Score Management
    /**
     * Saves a player's score to Core Data.
     *
     * Parameters:
     * - name: Player's display name
     * - email: Player's email address
     * - score: Player's game score
     * - timeInSeconds: Time taken to complete the game
     *
     * Note:
     * - Creates new PlayerScore entity
     * - Sets all required properties
     * - Saves to persistent store
     * - Prints debug information
     */
    func savePlayerScore(name: String, email: String, score: Double, timeInSeconds: Double) {
        let context = persistentContainer.viewContext
        
        // Create new PlayerScore entity
        let PlayerScore = NSEntityDescription.insertNewObject(forEntityName: "PlayerScore", into: context) as! PlayerScore
        
        // Set properties
        PlayerScore.id = UUID()
        PlayerScore.name = name
        PlayerScore.email = email
        PlayerScore.score = score
        PlayerScore.timeInSeconds = timeInSeconds
        PlayerScore.date = Date()
        
        // Debugging output
            print("Saving PlayerScore: \(PlayerScore.name), Email: \(PlayerScore.email), Score: \(PlayerScore.score), Time: \(PlayerScore.timeInSeconds)")
        
        // Save context
        do {
            try context.save()
            print("Score saved successfully for player: \(name)")
        } catch {
            print("Failed to save score: \(error.localizedDescription)")
        }
    }
    
    /**
     * Fetches all player scores for the leaderboard.
     *
     * Parameters:
     * - completion: Closure that receives array of PlayerScore objects
     *
     * Note:
     * - Sorts scores by points (descending) and time (ascending)
     * - Executes fetch on background context
     * - Returns empty array on error
     */
    func fetchLeaderboardScores(completion: @escaping ([PlayerScore]) -> Void) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<PlayerScore> = PlayerScore.fetchRequest()
        
        // Sort by score (descending) and time (ascending)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "score", ascending: false),
            NSSortDescriptor(key: "timeInSeconds", ascending: true)
        ]
        
        context.perform {
            do {
                let scores = try context.fetch(fetchRequest)
                completion(scores)
                print("Successfully fetched \(scores.count) scores")
            } catch {
                print("Error fetching scores: \(error)")
                completion([])
            }
        }
    }
    
    // MARK: - iCloud Sync Status
    /**
     * Checks availability of CloudKit services.
     *
     * Parameters:
     * - completion: Closure that receives boolean indicating CloudKit availability
     *
     * Note:
     * - Verifies iCloud account status
     * - Handles various account states
     * - Executes completion on main thread
     */
    public func checkCloudKitStatus(completion: @escaping (Bool) -> Void) {
        CKContainer(identifier: "iCloud.AIGameNec").accountStatus { status, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CloudKit account status error: \(error)")
                    completion(false)
                    return
                }
                
                switch status {
                case .available:
                    print("CloudKit is available")
                    completion(true)
                default:
                    print("CloudKit is not available: \(status)")
                    completion(false)
                }
            }
        }
    }
    
    /**
     * Clears all player scores from Core Data.
     *
     * Parameters: None
     *
     * Note:
     * - Currently commented out for safety
     * - Uses batch delete request
     * - Prints debug information about deletion
     * - Resets context after deletion
     */
    
//    func clearAllPlayerScores() {
//        let context = persistentContainer.viewContext
//        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = PlayerScore.fetchRequest()
//        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
//
//        do {
//            let countBefore = try context.count(for: fetchRequest)
//            print("Records before deletion: \(countBefore)")
//            
//            try context.execute(deleteRequest)
//            print("All PlayerScore records deleted successfully.")
//            
//            let countAfter = try context.count(for: fetchRequest)
//            print("Records after deletion: \(countAfter)")
//            
//            context.reset()
//            
//        } catch {
//            print("Failed to delete PlayerScore records: \(error)")
//        }
//    }

}
