//
//  BackgroundManager.swift
//  Background
//
//  Created by mayong on 2023/2/17.
//

import Foundation

public protocol MainRunloopEventHandlerProtocol: AnyObject {
    func mainRunloop(willWaiting runloop: RunLoop)
}

private final class MainRunloopEventHandler: MainRunloopEventHandlerProtocol {
    weak var target: MainRunloopEventHandlerProtocol?
    init(target: MainRunloopEventHandlerProtocol? = nil) {
        self.target = target
    }
    
    var isNil: Bool { target == nil }
    
    func mainRunloop(willWaiting runloop: RunLoop) {
        target?.mainRunloop(willWaiting: runloop)
    }
}

public final class MainRunloopObserver {
    public static let shared = MainRunloopObserver()
    
    private var observerList: [MainRunloopEventHandler] = []
    
    init() {
        addMainRunloopObserver()
    }
    
    public func addObserver(_ observer: MainRunloopEventHandlerProtocol) {
        filterNilObserver()
        observerList.append(MainRunloopEventHandler(target: observer))
    }
    
    public func removeObserver(_ observer: MainRunloopEventHandlerProtocol) {
        filterNilObserver()
        if let index = observerList.firstIndex(where: { $0 === observer }) {
            observerList.remove(at: index)
        }
    }
    
    private func filterNilObserver() {
        observerList.removeAll(where: { $0.isNil })
    }
    
    private lazy var runloopObserver: CFRunLoopObserver! = {
        let callout: @convention(c) (CFRunLoopObserver?, CFRunLoopActivity, UnsafeMutableRawPointer?) -> Void = { observer, activity, context in
            if let _context = context {
                let manager: MainRunloopObserver = Unmanaged.fromOpaque(_context).takeUnretainedValue()
                manager._runloopCallout(observer, activity)
            }
        }
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        var context = CFRunLoopObserverContext(version: 0, info: pointer, retain: nil, release: nil, copyDescription: nil)
        let observer = CFRunLoopObserverCreate(nil, CFRunLoopActivity.beforeWaiting.rawValue, true, 0, callout, &context)
        return observer
    }()
    
    private func addMainRunloopObserver() {
        let runloop = CFRunLoopGetMain()
        CFRunLoopAddObserver(runloop, runloopObserver, .commonModes)
    }
    
    private func removeMainRunloopObserver() {
        let runloop = CFRunLoopGetMain()
        CFRunLoopRemoveObserver(runloop, runloopObserver, .commonModes)
    }
    
    private func _runloopCallout(_ observer: CFRunLoopObserver!, _ activity: CFRunLoopActivity) {
        filterNilObserver()
        observerList.forEach { $0.mainRunloop(willWaiting: .main) }
    }
    
    deinit {
        removeMainRunloopObserver()
    }
}
