import SwiftUI
import UIKit

// MARK: - Profile Image Service
/// Handles loading, saving, and managing profile images
class ProfileImageService {

    // MARK: - Singleton
    static let shared = ProfileImageService()
    private init() {}

    // MARK: - Constants
    private let imageKey = "profileImageData"
    private let compressionQuality: CGFloat = 0.9  // Increased from 0.8 for better quality

    // MARK: - Load Image
    func loadImage() -> UIImage? {
        guard let imageData = UserDefaults.standard.data(forKey: imageKey),
              let image = UIImage(data: imageData) else {
            return nil
        }
        return image
    }

    // MARK: - Save Image
    func saveImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            return
        }

        UserDefaults.standard.set(imageData, forKey: imageKey)

        // Post notification to update profile image throughout the app
        NotificationCenter.default.post(name: Notification.Name("ProfileImageUpdated"), object: nil)
    }

    // MARK: - Remove Image
    func removeImage() {
        UserDefaults.standard.removeObject(forKey: imageKey)

        // Post notification
        NotificationCenter.default.post(name: Notification.Name("ProfileImageUpdated"), object: nil)
    }

    // MARK: - Image Processing
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }

        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

    func cropImageToSquare(_ image: UIImage) -> UIImage? {
        let originalWidth = image.size.width
        let originalHeight = image.size.height

        let smallerSize = min(originalWidth, originalHeight)

        let cropRect = CGRect(
            x: (originalWidth - smallerSize) / 2,
            y: (originalHeight - smallerSize) / 2,
            width: smallerSize,
            height: smallerSize
        )

        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            return nil
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
