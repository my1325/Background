//
//  BackgroundButtonDrawer.swift
//  Background
//
//  Created by mayong on 2023/2/20.
//

import UIKit
#if canImport(MainRunloopObserver)
import MainRunloopObserver
#endif

public final class BackgroundButtonDrawer {
    
    /// if true it not redraw when new size and old size is equal
    public var isRedrawDistinctSize: Bool = true
    
    public var secheuleWhenDrawerSettled: Bool = true
    
    public private(set) var size: CGSize {
        didSet {
            if oldValue == size, isRedrawDistinctSize {
                return
            }
            stateImageCache.removeAll()
            redrawBackgroundForState(button.state)
        }
    }
    
    public class func drawerInButton(_ button: UIButton) -> BackgroundButtonDrawer {
        if let drawer = objc_getAssociatedObject(button, "com.ge.background.view.drawer") as? BackgroundButtonDrawer {
            return drawer
        }
        return BackgroundButtonDrawer(button: button)
    }
    
    private var state: UIControl.State {
        didSet {
            guard state != oldValue else { return }
            redrawBackgroundForState(state)
        }
    }
    weak var button: UIButton!
    public init(button: UIButton) {
        self.size = button.bounds.size
        self.button = button
        self.state = button.state
        self.button.addTarget(self, action: #selector(buttonTouchEvents), for: .allTouchEvents)
        objc_setAssociatedObject(button, "com.ge.background.view.drawer", self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        MainRunloopObserver.shared.addObserver(self)
    }
    
    private var stateDrawerCache: [UInt: BackgroundImageDrawerProtocol] = [:]
    private var stateImageCache: [UInt: UIImage] = [:]
    public func setBackground(_ imageDrawer: BackgroundImageDrawerProtocol, for state: UIControl.State) {
        stateDrawerCache[state.rawValue] = imageDrawer
        if secheuleWhenDrawerSettled {
            redrawBackgroundForState(state)
        }
    }
    
    public func redrawBackgroundForState(_ state: UIControl.State) {
        guard size.width != 0, size.height != 0,
              let imageDrawer = stateDrawerCache[state.rawValue] 
        else {
            return
        }

        if let image = stateImageCache[state.rawValue] {
            button.setBackgroundImage(image, for: state)
            return
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer {
            UIGraphicsEndImageContext()
        }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        if let image = imageDrawer.imageWithContext(context, size: size) {
            button.setBackgroundImage(image, for: state)
            stateImageCache[state.rawValue] = image
        }
    }
    
    @objc private func buttonTouchEvents() {
        redrawBackgroundForState(button.state)
    }
}

extension BackgroundButtonDrawer: MainRunloopEventHandlerProtocol {
    public func mainRunloop(willWaiting runloop: RunLoop) {
        size = button.bounds.size
        state = button.state
    }
}

public extension UIButton {
    func setBackgroundColor(_ color: UIColor?, with round: UIRectCorner = .allCorners, radius: CGFloat, for state: UIControl.State) {
        guard let _color = color else { return }
        let drawer = ImageDrawer(content: .color(_color))
        setImageDrawer(drawer, with: round, radius: radius, for: state)
    }
    
    func setBackgroundGradient(_ colors: [UIColor],
                               sPoint: ImageDrawer.Content.DirectionPoint = .leftTop,
                               ePoint: ImageDrawer.Content.DirectionPoint = .rightBottom,
                               locations: [CGFloat] = [0, 1],
                               with round: UIRectCorner = .allCorners,
                               radius: CGFloat,
                               for state: UIControl.State)
    {
        guard !colors.isEmpty else { return }
        let drawer = ImageDrawer(content: .gradientColor(colors, locations, sPoint, ePoint))
        setImageDrawer(drawer, with: round, radius: radius, for: state)
    }
    
    func setBackgroundImage(_ image: UIImage?, with round: UIRectCorner = .allCorners, radius: CGFloat, for state: UIControl.State) {
        guard let _image = image else { return }
        let drawer = ImageDrawer(content: .image(_image))
        drawer.addContontCTX()
        setImageDrawer(drawer, with: round, radius: radius, for: state)
    }
    
    func setImageDrawer(_ drawer: ImageDrawer, with round: UIRectCorner, radius: CGFloat, for state: UIControl.State) {
        drawer.addAttributes(.roundCorners(round))
        drawer.addAttributes(.cornerRadius(radius))
        drawer.addClip()
        BackgroundButtonDrawer.drawerInButton(self).setBackground(drawer, for: state)
    }
}
