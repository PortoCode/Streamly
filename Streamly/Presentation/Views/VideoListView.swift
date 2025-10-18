//
//  VideoListView.swift
//  Streamly
//
//  Created by Rodrigo Porto on 18/10/25.
//

import SwiftUI

struct VideoListView: View {
    let videos = [
        Video(id: 1, width: 1920, height: 1080, duration: 120, image: nil, user: VideoUser(id: 1, name: "Yoda"), videoFiles: nil),
        Video(id: 2, width: 1280, height: 720, duration: 90, image: nil, user: VideoUser(id: 2, name: "Anakin"), videoFiles: nil),
        Video(id: 3, width: nil, height: nil, duration: nil, image: nil, user: nil, videoFiles: nil)
    ]

    var body: some View {
        NavigationView {
            List(videos) { video in
                VStack(alignment: .leading) {
                    Text("Video ID: \(video.id)")
                        .font(.headline)
                    if let duration = video.duration {
                        Text("Duration: \(duration) seconds")
                            .font(.subheadline)
                    }
                    if let userName = video.user?.name {
                        Text("User: \(userName)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Streamly")
        }
    }
}

#Preview {
    VideoListView()
}
