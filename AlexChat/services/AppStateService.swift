//
//  AppStateService.swift
//  AlexChat
//
//  Created by Alex Lee on 6/10/21.
//  Copyright © 2021 Alex Lee. All rights reserved.
//

import UIKit
import NotificationCenter

class AppStateService {
    var didBecomeActiveToken: NSObjectProtocol?
    var willResignActiveToken: NSObjectProtocol?
    var didEnterBackgroundToken: NSObjectProtocol?
    var willEnterForegroundToken: NSObjectProtocol?

    enum StateChange {
        case didBecomeActive
        case willResignActive
        case didEnterBackground
        case willEnterForeground
    }

    typealias Listener = (StateChange) -> Void

    var listener: Listener?

    private var center: NotificationCenter

    init(_ center: NotificationCenter = NotificationCenter.default) {
        self.center = center
    }

    func start() {
        if didBecomeActiveToken == nil {
            didBecomeActiveToken = center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] (_) in
                self?.listener?(.didBecomeActive)
            }
        }

        if willResignActiveToken == nil {
            willResignActiveToken = center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self]  (_) in
                self?.listener?(.willResignActive)
            }
        }

        if didEnterBackgroundToken == nil {
            didEnterBackgroundToken = center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self]  (_) in
                self?.listener?(.didEnterBackground)
            }
        }

        if willEnterForegroundToken == nil {
            willEnterForegroundToken = center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self]  (_) in
                self?.listener?(.willEnterForeground)
            }
        }
    }

    deinit {
        stop()
    }

    func stop() {
        if let didBecomeActive = didBecomeActiveToken {
            center.removeObserver(didBecomeActive)
        }
        if let willResignActive = willResignActiveToken {
            center.removeObserver(willResignActive)
        }
        if let didEnterBackground = didEnterBackgroundToken {
            center.removeObserver(didEnterBackground)
        }
        if let willEnterForeground = willEnterForegroundToken {
            center.removeObserver(willEnterForeground)
        }
    }
}
