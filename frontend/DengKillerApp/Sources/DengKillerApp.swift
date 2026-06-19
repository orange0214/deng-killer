import DengKillerCore
import SwiftUI

@main
struct DengKillerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: ConversationViewModel(
                    verificationClient: MockVerificationClient()
                )
            )
        }
    }
}

