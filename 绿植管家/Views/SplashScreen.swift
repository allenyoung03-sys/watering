import SwiftUI

struct SplashScreen: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "leaf.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.plantGreen)

                Text("植觉")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.plantGreen)

                Spacer()

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.8)
                    .padding(.bottom, 60)
            }
        }
    }
}
