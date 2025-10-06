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

    func resizedToSquare(size: CGFloat) -> UIImage {
        let squareSize = CGSize(width: size, height: size)

        UIGraphicsBeginImageContextWithOptions(squareSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            return self
        }

        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(origin: .zero, size: squareSize))

        let imageSize = self.size
        let aspectWidth = squareSize.width / imageSize.width
        let aspectHeight = squareSize.height / imageSize.height
        let aspectRatio = min(aspectWidth, aspectHeight)

        let scaledWidth = imageSize.width * aspectRatio
        let scaledHeight = imageSize.height * aspectRatio
        let x = (squareSize.width - scaledWidth) / 2.0
        let y = (squareSize.height - scaledHeight) / 2.0

        let drawRect = CGRect(x: x, y: y, width: scaledWidth, height: scaledHeight)
        self.draw(in: drawRect)

        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return self
        }

        return newImage
    }
}
