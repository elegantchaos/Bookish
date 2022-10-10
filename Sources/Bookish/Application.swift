// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishApp
import Bundles
import CloudKit
import Combine
import Files
import Logger
import SwiftUI
import SheetController

let applicationChannel = Channel("Application")

@main
struct Application: App {
    @Environment(\.scenePhase) var scenePhase

    let modelController: ModelController
    let lookupController: LookupManager
    let appearanceController: AppearanceController
    let importController: ImportController
    let sheetController: SheetController
    let statusController: StatusController
    let linkController: LinkController
    let exportController: ExportController
    let filePickerController: FilePickerController
    let navigationController: NavigationController
    let info: BundleInfo
    
    init() {
        
        let undoManager = UndoManager()
        let stack = CoreDataStack(containerName: "BookishModel", undoManager: undoManager)
        self.info = BundleInfo(for: Bundle.main)
        self.modelController = ModelController(stack: stack)
        self.importController = ImportController(model: modelController)
        self.lookupController = LookupManager()
        self.sheetController = SheetController()
        self.appearanceController = AppearanceController()
        self.statusController = StatusController()
        self.linkController = LinkController()
        self.exportController = ExportController(model: modelController, info: info)
        self.filePickerController = FilePickerController()
        self.navigationController = NavigationController(context: stack.viewContext)

        if CommandLine.arguments.contains("--wipeAllData") {
            try? modelController.removeAllData()
            exit(0)
        }
        
        if CommandLine.arguments.contains("--standardData") {
            try? modelController.setupStandardData(using: importController)
        }
        
        setupLookup()
    }
    
    func setupLookup() {
        lookupController.register(service: GoogleLookupService(name: "Google"))
        lookupController.register(service: SelfLookupService(name: "Existing Collection", model: modelController))
    }
    
    
    var body: some Scene {
            return WindowGroup {
                RootView()
                    .environment(\.managedObjectContext, modelController.stack.viewContext)
                    .environmentObject(modelController)
                    .environmentObject(sheetController)
                    .environmentObject(lookupController)
                    .environmentObject(appearanceController)
                    .environmentObject(importController)
                    .environmentObject(statusController)
                    .environmentObject(linkController)
                    .environmentObject(filePickerController)
                    .environmentObject(exportController)
                    .environmentObject(navigationController)
                    .onReceive(
                        modelController.objectWillChange.debounce(for: .seconds(10), scheduler: RunLoop.main), perform: { _ in
                            applicationChannel.log("model changed")
                            modelController.save()
                    })
            }
            .handlesExternalEvents(matching: ["*"])
            .commands {
                CommandGroup(before: .importExport) {
                    Button(action: { applicationChannel.log("blah") }) {
                        Text("Command Test")
                    }

                }
//                ImportFromDevicesCommands()
//                Button(action: { print("blah") }) {
//                    Text("Command Test")
//                }
            }
            .onChange(of: scenePhase, perform: handlePhaseChanged)
    }
    
    func handlePhaseChanged(_ newPhase: ScenePhase) {
        switch newPhase {
            case .active:
                applicationChannel.log("App is active")
            case .inactive:
                applicationChannel.log("App is inactive")
            case .background:
                applicationChannel.log("App is in background")
                modelController.save()
                navigationController.save()
            @unknown default:
                applicationChannel.log("Oh - interesting: I received an unexpected new value.")
        }
    }
}
