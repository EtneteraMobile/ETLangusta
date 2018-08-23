//
//  Event.swift
//  ETLangusta
//
//  Created by Petr Urban on 24/08/2018.
//  Copyright © 2018 Etnetera a.s. All rights reserved.
//

import Foundation

public class Event {
    private var observers = [Observer]()

    public func observe(on observer: AnyObject, observerBlock: @escaping () -> Void) {
        self.observers.append(Observer(observer: observer, block: observerBlock))
    }

    public func remove(observer: AnyObject) {
        self.observers = self.observers.filter({ $0.observer !== observer })
    }

    public func trigger() {
        notifyObservers()
    }
}

private extension Event {
    private func notifyObservers() {
        for observer in self.observers {
            observer.block()
        }
    }

    private class Observer {
        typealias ObserverBlock = () -> Void

        weak var observer: AnyObject?
        let block: ObserverBlock

        init(observer: AnyObject, block: @escaping ObserverBlock) {
            self.observer = observer
            self.block = block
        }
    }
}
