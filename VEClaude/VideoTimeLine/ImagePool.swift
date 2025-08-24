//
//  ImagePool.swift
//  VideoTimelineView
//
//  Created by USER on 6/29/23.
//

import UIKit
import AVKit

class ImagePool {
    
    static let current = ImagePool()
    
    private var imageCache: [String: UIImage] = [:]
    
    func defaultPlaceholderImage(size: CGSize) -> UIImage? {
        let key = "\(size)"
        if let image = imageCache[key] {
            return image
        }
        
        let image = createImageViewPlaceHodlerImage(size: size)
        imageCache[key] = image
        
        return image
    }
    
    private func createImageViewPlaceHodlerImage(size: CGSize) -> UIImage? {
        let backgroundColor = UIColor.init(white: 1, alpha: 0.4)
        
        let ParagraphStyle = NSMutableParagraphStyle.init()
        ParagraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] =
            [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: size.width / 5),
                NSAttributedString.Key.foregroundColor: UIColor.init(white: 0.4, alpha: 1),
                NSAttributedString.Key.paragraphStyle: ParagraphStyle
        ]
        let string = NSMutableAttributedString.init(string: "IMAGE", attributes: attributes)
        
        return UIImage.createImage(string: string, size: size, backgroundColor: backgroundColor)
    }
}

extension UIImage {
    
    static func createImage(string: NSAttributedString, size: CGSize, backgroundColor: UIColor) -> UIImage? {
        if size.width == 0 || size.height == 0 || string.string.count == 0 {
            return nil
        }
        let stringBounds = string.boundingRect(with: size, options: [], context: nil)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        
        let rect = CGRect(origin: .zero, size: size)
        backgroundColor.setFill()
        context?.fill(rect)
        
        let point = CGPoint.init(x: (size.width - stringBounds.size.width) / 2, y: (size.height - stringBounds.size.height) / 2)
        string.draw(at: point)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
