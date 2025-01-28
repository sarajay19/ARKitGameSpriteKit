import UIKit
import CoreData
import CloudKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
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
    
    @objc func handlePersistentStoreRemoteChange(_ notification: Notification) {
        // Handle remote changes (e.g., refresh UI)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .leaderboardDataDidChange, object: nil)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle remote notifications for CoreData sync
        CoreDataStack.shared.persistentContainer.performBackgroundTask { context in
            completionHandler(.newData)
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, etc.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused while the application was inactive.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate.
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let leaderboardDataDidChange = Notification.Name("leaderboardDataDidChange")
}
