import SwiftUI

@main
struct FynbosBeeApp: App {
    @State private var showWelcome = true

    var body: some Scene {
        WindowGroup {
            if showWelcome {
                WelcomeView(onStart: {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        showWelcome = false
                    }
                })
            } else {
                ContentView()
            }
        }
    }
}
