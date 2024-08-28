//
//  ContentView.swift
//  PlayBar-Test
//
//  Created by Helloyunho on 2024/8/28.
//

import AVFoundation
import SwiftUI

struct PlayBarModifier: ViewModifier {
    @Binding var offset: CGFloat
    @Binding var isPlaying: Bool
    var speed: Double
    let musicURL: URL?
    @State private var player: AVPlayer = .init()
    @State var error: Error?
    @State var showError = false

    init(offset: Binding<CGFloat>, isPlaying: Binding<Bool>, speed: Double, musicURL: URL?) {
        _offset = offset
        _isPlaying = isPlaying
        self.speed = speed
        self.musicURL = musicURL
    }

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onChange(of: isPlaying) {
                if isPlaying {
                    startAnimation()
                } else {
                    stopAnimation()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(error?.localizedDescription ?? "Unknown error has occurred.")
            }
            .onReceive(player.periodicTimePublisher()) { time in
                if time.seconds > player.currentItem?.duration.seconds ?? 0 {
                    self.isPlaying = false
                    self.offset = 0
                } else {
                    self.offset = timeToOffset(time.seconds * 1000, speed: self.speed)
                }
            }
    }

    func startAnimation() {
        do {
            let currPosToTime = offsetToTime(offset, speed: speed)
            #if os(iOS)
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            #endif
            if let musicURL, musicURL.startAccessingSecurityScopedResource() {
                player.replaceCurrentItem(with: AVPlayerItem(url: musicURL))
                player.seek(to: CMTime(seconds: currPosToTime / 1000, preferredTimescale: 1))
                player.play()
            }
        } catch {
            isPlaying = false
            self.error = error
            self.showError = true
        }
    }

    func stopAnimation() {
        player.pause()
        musicURL?.stopAccessingSecurityScopedResource()
    }
}

struct HorizontalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()

        return path
    }
}

struct ContentView: View {
    @State var speed: Double = 4
    @State var playBarOffset: CGFloat = 0.0
    @State var isPlaying = false
    @State var musicURL: URL?
    @State var showMusicImporter = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        ZStack(alignment: .topLeading) {
                            Spacer()  // Lane
                                .frame(height: timeToOffset(130000, speed: speed))
                            ForEach(0..<4000) { i in
                                HorizontalLine()
                                    .stroke(
                                        .blue,
                                        style: StrokeStyle(
                                            lineWidth: 4, lineCap: .round, lineJoin: .round)
                                    )
                                    .frame(height: 4)
                                    .offset(y: timeToOffset(Double(i * 50), speed: speed))
                            }
                        }
                        .overlay(
                            HorizontalLine()
                                .stroke(
                                    .green,
                                    style: StrokeStyle(
                                        lineWidth: 4, lineCap: .round, lineJoin: .round)
                                )
                                .frame(height: 4)
                                .offset(y: 2)
                                .modifier(
                                    PlayBarModifier(
                                        offset: $playBarOffset, isPlaying: $isPlaying, speed: speed,
                                        musicURL: musicURL)),
                            alignment: .topLeading)
                        Spacer()
                            .frame(height: geometry.size.height)
                    }
                    .rotation3DEffect(.degrees(180), axis: (x: 1, y: 0, z: 0))
                }
            }
            .fileImporter(isPresented: $showMusicImporter, allowedContentTypes: [.audio]) { result in
                switch result {
                case .success(let success):
                    musicURL = success
                case .failure(let failure):
                    print(failure)
                }
            }
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        showMusicImporter = true
                    } label: {
                        Label("Load Music", systemImage: "square.and.arrow.down")
                    }
                    if isPlaying {
                        Button {
                            isPlaying = false
                        } label: {
                            Label("Pause Music", systemImage: "pause.fill")
                        }
                    } else {
                        Button {
                            isPlaying = true
                        } label: {
                            Label("Play Music", systemImage: "play.fill")
                        }
                        .disabled(musicURL == nil)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
