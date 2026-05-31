import SwiftUI
import SwiftData

struct RootView: View {
    var body: some View {
        NavigationStack {
            MainView()
        }
        .modelContainer(for: Coupon.self)
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
