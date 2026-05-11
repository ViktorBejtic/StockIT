
import SwiftUI

struct LaunchAnimationView: View {
    @State private var animate = false
    
    var body: some View {
        VStack {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 350, height: 350)
                .foregroundStyle(Color.fiitPrimary)
                .rotationEffect(.degrees(animate ? 360 : 0))
                .scaleEffect(animate ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animate)
        }
        .onAppear {
            animate = true
        }
    }
}
