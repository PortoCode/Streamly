//
//  VideoListView.swift
//  Streamly
//
//  Created by Rodrigo Porto on 18/10/25.
//

import SwiftUI

struct VideoListView: View {
    @StateObject private var viewModel = VideoListViewModel()
    @State private var selectedVideo: Video?
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Text("Error: \(error)")
                            .foregroundStyle(.red)
                            .padding()
                        Button("Retry") {
                            viewModel.fetchVideos()
                        }
                    }
                } else {
                    List(viewModel.videos) { video in
                        VideoRowView(video: video, onTap: {
                            selectedVideo = video
                        }, onFavorite: {
                            viewModel.toggleFavorite(video)
                        }, onDownload: {
                            viewModel.downloadVideo(video)
                        }, onRemoveDownload: {
                            viewModel.removeDownload(video)
                        })
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Streamly")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: viewModel.fetchVideos) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                viewModel.fetchVideos()
            }
            .sheet(item: $selectedVideo) { video in
                VideoPlayerContainer(video: video)
            }
        }
    }
}
