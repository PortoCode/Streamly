//
//  VideoRowView.swift
//  Streamly
//
//  Created by Rodrigo Porto on 18/10/25.
//

import SwiftUI

struct VideoRowView: View {
    let video: Video
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onDownload: () -> Void
    let onRemoveDownload: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            AsyncImage(url: video.image) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 120, height: 70)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 70)
                        .clipped()
                case .failure:
                    Color.gray
                        .frame(width: 120, height: 70)
                @unknown default:
                    EmptyView()
                }
            }
            
            VStack(alignment: .leading) {
                Text(video.user?.name ?? "Unknown")
                    .font(.headline)
                Text("\(video.duration ?? 0) sec")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Spacer()
                Button(action: {
                    if video.isDownloaded {
                        onRemoveDownload()
                    } else {
                        onDownload()
                    }
                }) {
                    Image(systemName: video.isDownloaded ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                
                Button(action: onFavorite) {
                    Image(systemName: video.isFavorite ? "heart.fill" : "heart")
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .onTapGesture(perform: onTap)
    }
}
