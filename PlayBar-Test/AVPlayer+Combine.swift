//
//  Publisher.swift
//  PlayBar-Test
//
//  Created by Helloyunho on 2024/8/28.
//


// from https://gist.github.com/kshivang/4c213ec85adf911d30f1305722e7129d
import AVFoundation
import Combine

// simply use
// player.periodicTimePublisher()
//   .receive(on: RunLoop.main)
//   .assign(to: \SomeClass.elapsedTime, on: someInstance)
//   .store(in: &cancelBag)


extension AVPlayer {
    func periodicTimePublisher(forInterval interval: CMTime = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))) -> AnyPublisher<CMTime, Never> {
        Publisher(self, forInterval: interval)
            .eraseToAnyPublisher()
    }
}

fileprivate extension AVPlayer {
    private struct Publisher: Combine.Publisher {
    
        typealias Output = CMTime
        typealias Failure = Never
    
        var player: AVPlayer
        var interval: CMTime

        init(_ player: AVPlayer, forInterval interval: CMTime) {
            self.player = player
            self.interval = interval
        }

        func receive<S: Sendable>(subscriber: S) where S : Subscriber, Publisher.Failure == S.Failure, Publisher.Output == S.Input {
            let subscription = CMTime.Subscription(subscriber: subscriber, player: player, forInterval: interval)
            subscriber.receive(subscription: subscription)
        }
    }
}

fileprivate extension CMTime {
    final class Subscription<SubscriberType: Subscriber & Sendable>: Combine.Subscription where SubscriberType.Input == CMTime, SubscriberType.Failure == Never {

        var player: AVPlayer? = nil
        var observer: Any? = nil

        init(subscriber: SubscriberType, player: AVPlayer, forInterval interval: CMTime) {
            self.player = player
            observer = player.addPeriodicTimeObserver(forInterval: interval, queue: nil) { time in
                _ = subscriber.receive(time)
            }
        }

        func request(_ demand: Subscribers.Demand) {
            // We do nothing here as we only want to send events when they occur.
            // See, for more info: https://developer.apple.com/documentation/combine/subscribers/demand
        }

        func cancel() {
            if let observer = observer {
                player?.removeTimeObserver(observer)
            }
            observer = nil
            player = nil
        }
    }
}
