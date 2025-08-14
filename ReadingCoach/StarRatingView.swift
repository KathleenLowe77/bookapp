import SwiftUI

struct StarRatingView: View {
    @Binding var rating: Int
    var max: Int = 5

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...max, id: \.self) { i in
                Image(systemName: i <= rating ? "star.fill" : "star")
                    .imageScale(.large)
                    .foregroundStyle(i <= rating ? .yellow : .secondary)
                    .onTapGesture { rating = i }
                    .onLongPressGesture { rating = 0 }
                    .accessibilityLabel("\(i) star")
            }
        }
    }
}
