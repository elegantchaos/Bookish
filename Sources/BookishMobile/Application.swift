// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import CoreData
import BookishModel
import BookishCore
import Logger
import Actions
import ActionsKit

let applicationChannel = Logger("Application")

@UIApplicationMain
class Application: UIResponder {
    var window: UIWindow? // required for storyboard support
    let actionManager = ActionManagerMobile()
    let imageCache = UIImageCache()
    let cloud = BookishCloud()
    @objc dynamic let viewModel = CollectionViewModel()
    var collectionController: CollectionController!
    lazy var collection: SyncedCollection = setupCollection()
    
    func setupCollection(usingSample: Bool = false) -> SyncedCollection {
        let collection = SyncedCollection(identifier: cloud.collectionIdentifier, usingSample: usingSample)
        return collection
    }
    
    func setupActions() {
        actionManager.register(ModelAction.standardActions())
        actionManager.installResponder()
    }
    
    func setupCloud() {
        let cloud = BookishCloud()
        cloud.setup(name: "mobile")
    }
}

// MARK: Application Delegate Support

extension Application: UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupActions()
        setupCloud()
        applicationChannel.log("did finish launching")
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        applicationChannel.log("will resign")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        applicationChannel.log("did enter background")
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        applicationChannel.log("will enter foreground")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        applicationChannel.log("did become active")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        applicationChannel.log("will terminate")
        collection.save()
    }

}

// MARK: Action Support

extension Application: ActionContextProvider {
    override var next: UIResponder? {
        return actionManager.responder
    }
    
    func provide(context: ActionContext) {
        context.info[ActionContext.modelKey] = collection.managedObjectContext
        context.info[ActionContext.viewModelKey] = viewModel
        context.info[ActionContext.rootKey] = collectionController
    }
}
