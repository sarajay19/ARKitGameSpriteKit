// CoreDataStack.swift

import CoreData
import CloudKit
import Foundation


public class CoreDataStack {
    static let shared = CoreDataStack()
    
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
    
    func savePlayerScore(name: String, email: String, score: Double, timeInSeconds: Double) {
        let context = persistentContainer.viewContext
        
        // Create new PlayerScore entity
        let playerScore = NSEntityDescription.insertNewObject(forEntityName: "PlayerScore", into: context) as! PlayerScore
        
        // Set properties
        playerScore.id = UUID()
        playerScore.name = name
        playerScore.email = email
        playerScore.score = score
        playerScore.timeInSeconds = timeInSeconds
        playerScore.date = Date()
        
        // Save context
        do {
            try context.save()
            print("Score saved successfully for player: \(name)")
        } catch {
            print("Failed to save score: \(error)")
        }
    }
    
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
    
}
