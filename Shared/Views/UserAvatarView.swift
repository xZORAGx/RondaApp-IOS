
//
//  UserAvatarView.swift
//  RondaApp
//
//  Created by David on 21/7/25.
//

import SwiftUI

struct UserAvatarView: View {
    let user: User
    let size: CGFloat

    var body: some View {
        Group {
            if let photoURLString = user.photoURL, let url = URL(string: photoURLString) {
                AsyncImage(url: url) {
                    phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
    }

    private var placeholderImage: some View {
        Circle()
            .fill(Color.gray)
            .overlay(
                Text(user.username?.prefix(1).uppercased() ?? "?")
                    .font(.system(size: size * 0.5))
                    .foregroundColor(.white)
            )
    }
}

struct UserAvatarView_Previews: PreviewProvider {
    static var previews: some View {
        // Example with photoURL
        UserAvatarView(user: User(uid: "123", email: "test@example.com", photoURL: "https://via.placeholder.com/150", username: "John Doe"), size: 50)

        // Example without photoURL
        UserAvatarView(user: User(uid: "456", email: "test2@example.com", username: "Jane Doe"), size: 50)

        // Example with no username
        UserAvatarView(user: User(uid: "789", email: "test3@example.com"), size: 50)
    }
}
