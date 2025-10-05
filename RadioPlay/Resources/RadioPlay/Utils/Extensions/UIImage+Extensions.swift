//
//  UIImage+Extensions.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//

import UIKit

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func blurred(radius: CGFloat) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }

        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)

        guard let outputCIImage = filter?.outputImage else { return nil }

        let context = CIContext()
        guard let outputCGImage = context.createCGImage(outputCIImage, from: ciImage.extent) else { return nil }

        return UIImage(cgImage: outputCGImage)
    }
}
