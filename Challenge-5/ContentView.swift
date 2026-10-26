import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        StoreSandboxView(looks: StoreSampleData.looks)
            .modelContainer(StoreSampleData.container)
    }
}

#Preview {
    ContentView()
}
