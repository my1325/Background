//
//  NewImageDrawer.swift
//  Background
//
//  Created by mayong on 2023/2/17.
//

import UIKit

public struct ImageDrawer: BackgroundImageDrawerProtocol {
    public enum Content {
        public enum DirectionPoint {
            case leftTop
            case rightTop
            case leftBottom
            case rightBottom
            
            func pointWithSize(_ size: CGSize) -> CGPoint {
                switch self {
                case .leftTop:
                    return CGPoint(x: 0, y: 0)
                case .rightTop:
                    return CGPoint(x: size.width, y: 0)
                case .leftBottom:
                    return CGPoint(x: 0, y: size.height)
                case .rightBottom:
                    return CGPoint(x: size.width, y: size.height)
                }
            }
        }
        
        case color(UIColor)
        case gradientColor([UIColor], [CGFloat], DirectionPoint, DirectionPoint)
        case image(UIImage)
    }
    
    public enum Attributes {
        case borderColor(UIColor)
        case borderWidth(CGFloat)
        case cornerRadius(CGFloat)
        case roundCorners(UIRectCorner)
    }
    
    public let attributesStore: AttributesStore
    public let content: Content
    public init(content: Content) {
        self.attributesStore = AttributesStore(attribute: [])
        self.content = content
    }
    
    public final class AttributesStore {
        private(set) var attribute: [Attributes]
        init(attribute: [Attributes]) {
            self.attribute = attribute
        }
        
        private(set) var clip: Bool = false
        @discardableResult
        public func addClip() -> Self {
            clip = true
            return self
        }
        
        private(set) var border: Bool = false
        @discardableResult
        public func addBorder() -> Self {
            border = true
            return self
        }
        
        private(set) var contentCTX: Bool = false
        @discardableResult
        public func addContontCTX() -> AttributesStore {
            contentCTX = true
            return self
        }
        
        @discardableResult
        public func addAttributes(_ attributes: Attributes) -> Self {
            attribute.append(attributes)
            return self
        }
    }
    
    @discardableResult
    public func addAttributes(_ attributes: Attributes) -> AttributesStore {
        attributesStore.addAttributes(attributes)
    }
    
    @discardableResult
    public func addClip() -> AttributesStore {
        attributesStore.addClip()
    }
    
    @discardableResult
    public func addBorder() -> AttributesStore {
        attributesStore.addBorder()
    }
    
    @discardableResult
    public func addContontCTX() -> AttributesStore {
        attributesStore.addContontCTX()
    }
    
    public func imageWithContext(_ context: CGContext, size: CGSize) -> UIImage? {
        attributesStore.drawAttributesInContext(context, size: size)
        if attributesStore.contentCTX {
            context.translateBy(x: 0, y: size.height)
            context.scaleBy(x: 1, y: -1)
        }
        content.drawContentInContext(context, size: size)
        if let cgImage = context.makeImage() {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}

extension ImageDrawer.Content {
    func drawContentInContext(_ context: CGContext, size: CGSize) {
        switch self {
        case let .color(color):
            drawColorContentInContext(context, color: color, size: size)
        case let .gradientColor(colors, locations, startPoint, endPoint):
            drawGradientColorContentInContext(context, colors: colors, locations: locations, startPoint: startPoint, endPoint: endPoint, size: size)
        case let .image(image):
            drawImageInContext(image, context: context, size: size)
        }
    }
    
    func drawColorContentInContext(_ context: CGContext, color: UIColor, size: CGSize) {
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
    }
    
    func drawGradientColorContentInContext(_ context: CGContext,
                                           colors: [UIColor],
                                           locations: [CGFloat],
                                           startPoint: ImageDrawer.Content.DirectionPoint,
                                           endPoint: ImageDrawer.Content.DirectionPoint,
                                           size: CGSize)
    {
        var _locations = locations
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors.map { $0.cgColor } as CFArray, locations: &_locations) {
            context.drawLinearGradient(gradient, start: startPoint.pointWithSize(size), end: endPoint.pointWithSize(size), options: .drawsBeforeStartLocation)
        }
    }
    
    func drawImageInContext(_ image: UIImage, context: CGContext, size: CGSize) {
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
    }
}

extension ImageDrawer.AttributesStore {
    func attributePathWithRect(_ rect: CGRect, with context: CGContext) -> CGPath {
        var cornerRadius: CGFloat?
        var roundCorners: UIRectCorner?
        for attr in attribute {
            switch attr {
            case let .roundCorners(corners):
                roundCorners = corners
            case let .cornerRadius(radius):
                cornerRadius = radius
            case let .borderWidth(borderWidth):
                context.setLineWidth(borderWidth)
            case let .borderColor(color):
                context.setStrokeColor(color.cgColor)
            }
        }
        
        if let radius = cornerRadius, radius > 0, let corner = roundCorners, corner != .allCorners {
            return UIBezierPath(roundedRect: rect, byRoundingCorners: corner, cornerRadii: CGSize(width: radius, height: radius)).cgPath
        } else if let radius = cornerRadius, radius > 0 {
            return UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath
        } else if let corner = roundCorners, corner != .allCorners {
            return UIBezierPath(roundedRect: rect, byRoundingCorners: corner, cornerRadii: .zero).cgPath
        } else {
            return UIBezierPath(rect: rect).cgPath
        }
    }
    
    func drawAttributesInContext(_ context: CGContext, size: CGSize) {
        guard !attribute.isEmpty else { return }
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let path = attributePathWithRect(rect, with: context)
        if clip {
            context.addPath(path)
            context.clip()
        }
        
        if border {
            context.addPath(path)
            context.strokePath()
        }
    }
}
