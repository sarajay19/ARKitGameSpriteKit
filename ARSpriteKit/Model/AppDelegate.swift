//
//  AppDelegate.swift
//  ARSpriteKit
//
//  Class handling the application lifecycle and CloudKit integration.
//  Manages core app setup, remote notifications, and data synchronization.

import UIKit
import CoreData
import CloudKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    /** Handles the initialization of the application after launch.
    - Parameters:
    * -application: The singleton app object.
    * -launchOptions: A dictionary indicating the reason the app was launched (if any).
    * -Returns: `true` if the app launched successfully, otherwise `false`.
    */
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // clean records
//        CoreDataStack.shared.clearAllPlayerScores()

        application.registerForRemoteNotifications()

        // Configure CloudKit and Core Data
        let container = CoreDataStack.shared.persistentContainer
        
        // Subscribe to remote change notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePersistentStoreRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
        
        // Check CloudKit availability
        CoreDataStack.shared.checkCloudKitStatus { available in
            if available {
                print("CloudKit is ready")
            } else {
                print("CloudKit is not available")
            }
        }
        
        return true
    }
    
    /// Handles remote changes in the persistent store.
    /// - Parameter notification: The notification object containing information about the change.
    @objc func handlePersistentStoreRemoteChange(_ notification: Notification) {
        // Handle remote changes (e.g., refresh UI)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .leaderboardDataDidChange, object: nil)
        }
    }
    
/** Handles remote notifications for CoreData sync.
    - Parameters:
    * -application: The singleton app object.
    * -userInfo: A dictionary that contains information related to the remote notification.
    * -completionHandler: A block to execute when the fetch operation completes.
*/
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle remote notifications for CoreData sync
        CoreDataStack.shared.persistentContainer.performBackgroundTask { context in
            completionHandler(.newData)
        }
    }
    
    /// Sent when the application is about to move from active to inactive state.
    /// - Parameter application: The singleton app object.
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state.
    }

    /// Sent when the application enters the background.
    /// - Parameter application: The singleton app object.
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, etc.
    }

    /// Sent when the application is about to enter the foreground.
    /// - Parameter application: The singleton app object.
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state.
    }

    /// Sent when the application has become active.
    /// - Parameter application: The singleton app object.
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused while the application was inactive.
    }

    /// Sent when the application is about to terminate.
    /// - Parameter application: The singleton app object.
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate.
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let leaderboardDataDidChange = Notification.Name("leaderboardDataDidChange")
}
