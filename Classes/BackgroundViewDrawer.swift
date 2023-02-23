//
//  NewBackground.swift
//  Background
//
//  Created by mayong on 2023/2/17.
//

import UIKit
#if canImport(MainRunloopObserver)
import MainRunloopObserver
#endif

public protocol BackgroundImageDrawerProtocol {
    func imageWithContext(_ context: CGContext, size: CGSize) -> UIImage?
}

struct NoneImageDrawer: BackgroundImageDrawerProtocol {
    func imageWithContext(_ context: CGContext, size: CGSize) -> UIImage? {
        nil
    }
}

public final class BackgroundViewDrawer {
    public private(set) var size: CGSize {
        didSet {
            if oldValue == size, isRedrawDistinctSize {
                return
            }
            imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            view.sendSubviewToBack(imageView)
            redrawBackground()
        }
    }
    
    private let imageView: UIImageView = .init()
    
    public class func drawerInView(_ view: UIView) -> BackgroundViewDrawer {
        if let drawer = objc_getAssociatedObject(view, "com.ge.background.view.drawer") as? BackgroundViewDrawer {
            return drawer
        }
        return BackgroundViewDrawer(view: view)
    }
    
    public private(set) weak var view: UIView!
    init(view: UIView) {
        self.size = view.bounds.size
        self.view = view
        self.view.addSubview(imageView)
        objc_setAssociatedObject(view, "com.ge.background.view.drawer", self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        MainRunloopObserver.shared.addObserver(self)
    }
        
    /// if true it not redraw when new size and old size is equal
    public var isRedrawDistinctSize: Bool = true
    
    public var secheuleWhenDrawerSettled: Bool = true
    
    private(set) var imageDrawer: BackgroundImageDrawerProtocol = NoneImageDrawer()
    public func setBackground(_ imageDrawer: BackgroundImageDrawerProtocol) {
        precondition(Thread.isMainThread)
        self.imageDrawer = imageDrawer
        if secheuleWhenDrawerSettled {
            redrawBackground()
        }
    }
    
    private func redrawBackground() {
        guard size != .zero else { return }
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        defer {
            UIGraphicsEndImageContext()
        }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        if let image = imageDrawer.imageWithContext(context, size: size) {
            imageView.image = image
        }
    }
    
    deinit {
        MainRunloopObserver.shared.removeObserver(self)
    }
}

extension BackgroundViewDrawer: MainRunloopEventHandlerProtocol {
    public func mainRunloop(willWaiting runloop: RunLoop) {
        size = view.bounds.size
    }
}

public extension UIView {
    func setBackgroundColor(_ color: UIColor?, with round: UIRectCorner = .allCorners, radius: CGFloat) {
        guard let _color = color else { return }
        let drawer = ImageDrawer(content: .color(_color))
        setImageDrawer(drawer, with: round, radius: radius)
    }
    
    func setBackgroundGradient(_ colors: [UIColor],
                               sPoint: ImageDrawer.Content.DirectionPoint = .leftTop,
                               ePoint: ImageDrawer.Content.DirectionPoint = .rightBottom,
                               locations: [CGFloat] = [0, 1],
                               with round: UIRectCorner = .allCorners,
                               radius: CGFloat)
    {
        guard !colors.isEmpty else { return }
        let drawer = ImageDrawer(content: .gradientColor(colors, locations, sPoint, ePoint))
        setImageDrawer(drawer, with: round, radius: radius)
    }
    
    func setBackgroundImage(_ image: UIImage?, with round: UIRectCorner = .allCorners, radius: CGFloat) {
        guard let _image = image else { return }
        let drawer = ImageDrawer(content: .image(_image))
        drawer.addContontCTX()
        setImageDrawer(drawer, with: round, radius: radius)
    }
    
    func setImageDrawer(_ drawer: ImageDrawer, with round: UIRectCorner, radius: CGFloat) {
        drawer.addAttributes(.roundCorners(round))
        drawer.addAttributes(.cornerRadius(radius))
        drawer.addClip()
        BackgroundViewDrawer.drawerInView(self).setBackground(drawer)
    }
}
