import SwiftUI

@main struct YourFarmWithUnicornsApp: App {
    @StateObject private var controller = FarmController()
    @Environment(\.scenePhase) private var phase
    var body: some Scene {
        WindowGroup { FarmRootView().environmentObject(controller) }
            .onChange(of: phase) { value in
                if value == .active { controller.refreshDay() } else { controller.save() }
            }
    }
}
