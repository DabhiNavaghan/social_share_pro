import Flutter
import UIKit
import Photos

public class SocialShareProPlugin: NSObject, FlutterPlugin, UIDocumentInteractionControllerDelegate {
    
    var documentInteractionController: UIDocumentInteractionController?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "social_share_pro", binaryMessenger: registrar.messenger())
        let instance = SocialShareProPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "shareToInstagramStories":
            shareToInstagramStories(call: call, result: result)
        case "shareToFacebookStories":
            shareToFacebookStories(call: call, result: result)
        case "shareToWhatsAppStatus":
            shareToWhatsApp(call: call, result: result)
        case "saveToGallery":
            saveToGallery(call: call, result: result)
        case "isInstagramInstalled":
            result(isAppInstalled(scheme: "instagram-stories://"))
        case "isFacebookInstalled":
            result(isAppInstalled(scheme: "facebook-stories://"))
        case "isWhatsAppInstalled":
            result(isAppInstalled(scheme: "whatsapp://"))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - UIDocumentInteractionControllerDelegate
    
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return getTopViewController() ?? UIApplication.shared.delegate!.window!!.rootViewController!
    }
    
    public func documentInteractionControllerViewForPreview(_ controller: UIDocumentInteractionController) -> UIView? {
        return getTopViewController()?.view
    }
    
    public func documentInteractionControllerRectForPreview(_ controller: UIDocumentInteractionController) -> CGRect {
        return getTopViewController()?.view.bounds ?? CGRect.zero
    }

    // MARK: - Helper Methods
    
    private func getTopViewController() -> UIViewController? {
        var topController = UIApplication.shared.keyWindow?.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
    
    private func downscaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
    
    private func isAppInstalled(scheme: String) -> Bool {
        if let url = URL(string: scheme) {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }
    
    private func color(fromHexString hexString: String) -> UIColor? {
        var cString: String = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }
        
        if cString.count != 6 {
            return nil
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: 1.0
        )
    }
    
    // MARK: - Instagram
    
    private func shareToInstagramStories(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let stickerPath = args["stickerPath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Sticker path is required", details: nil))
            return
        }
        
        guard let urlScheme = URL(string: "instagram-stories://share?source_application=\(Bundle.main.bundleIdentifier ?? "")") else {
            result(FlutterError(code: "URL_ERROR", message: "Invalid URL scheme", details: nil))
            return
        }
        
        if !UIApplication.shared.canOpenURL(urlScheme) {
            result(FlutterError(code: "INSTAGRAM_NOT_INSTALLED", message: "Instagram is not installed or 'instagram-stories' is missing from Info.plist", details: nil))
            return
        }
        
        // Prepare Pasteboard Items
        var pasteboardItems: [[String: Any]] = []
        
        if let stickerImage = UIImage(contentsOfFile: stickerPath) {
            // Downscale sticker for Instagram too just in case
            let resizedSticker = downscaleImage(image: stickerImage, maxDimension: 640)
            
            if let stickerData = resizedSticker.pngData() {
                pasteboardItems.append(["com.instagram.sharedSticker.stickerImage": stickerData,
                                      "com.instagram.sharedSticker.backgroundImage": stickerData]) // Fallback if no bg
            }
        }
        
        // Background Image
        if let bgPath = args["backgroundImagePath"] as? String,
           let bgImage = UIImage(contentsOfFile: bgPath) {
            
            let resizedBg = downscaleImage(image: bgImage, maxDimension: 1080)
            
            if let bgData = resizedBg.pngData() {
                // Update the last item or create new
                 if var item = pasteboardItems.first {
                    item["com.instagram.sharedSticker.backgroundImage"] = bgData
                    pasteboardItems[0] = item
                }
            }
        }
        
        // Gradient Colors
        if args["backgroundImagePath"] == nil,
           let topHex = args["backgroundTopColor"] as? String,
           let bottomHex = args["backgroundBottomColor"] as? String {
             // Instagram expects hex strings strictly? Docs vary, but often they accept color objects too if serialized,
             // or specific keys. 'com.instagram.sharedSticker.backgroundTopColor' usually expects strings like "#FFFFFF"
             if var item = pasteboardItems.first {
                item["com.instagram.sharedSticker.backgroundTopColor"] = topHex
                item["com.instagram.sharedSticker.backgroundBottomColor"] = bottomHex
                pasteboardItems[0] = item
             }
        }
        
        let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(60 * 5)
        ]
        
        UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)
        
        UIApplication.shared.open(urlScheme, options: [:]) { success in
            result(success)
        }
    }
    
    // MARK: - Facebook
    
    private func shareToFacebookStories(call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("SocialShareProPlugin: shareToFacebookStories called")
        
        guard let args = call.arguments as? [String: Any],
              let stickerPath = args["stickerPath"] as? String,
              let appId = args["appId"] as? String else {
            print("SocialShareProPlugin: Invalid arguments - missing stickerPath or appId")
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Sticker path and App ID are required", details: nil))
            return
        }
        
        print("SocialShareProPlugin: stickerPath: \(stickerPath), appId: \(appId)")
        
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        guard let urlScheme = URL(string: "facebook-stories://share?source_application=\(bundleId)") else {
             print("SocialShareProPlugin: Invalid URL scheme")
             result(FlutterError(code: "URL_ERROR", message: "Invalid URL scheme", details: nil))
             return
        }
        
        if !UIApplication.shared.canOpenURL(urlScheme) {
            print("SocialShareProPlugin: Facebook is not installed or URL scheme not available")
            result(FlutterError(code: "FACEBOOK_NOT_INSTALLED", message: "Facebook is not installed or 'facebook-stories' is missing from Info.plist", details: nil))
            return
        }
        
        print("SocialShareProPlugin: Facebook URL scheme is available")
        
        // 1. Load the Sticker Image
        guard let stickerImage = UIImage(contentsOfFile: stickerPath) else {
             print("SocialShareProPlugin: Failed to load sticker image from path: \(stickerPath)")
             result(FlutterError(code: "IMAGE_LOAD_FAILED", message: "Failed to load sticker image", details: nil))
             return
        }
        
        print("SocialShareProPlugin: Sticker image loaded successfully, size: \(stickerImage.size)")
        
        // Downscale sticker to max 640px (Facebook recommendation)
        let resizedSticker = downscaleImage(image: stickerImage, maxDimension: 640)
        print("SocialShareProPlugin: Sticker resized to: \(resizedSticker.size)")
        
        // 2. Convert Sticker to Data (PNG for transparency)
        guard let stickerData = resizedSticker.pngData() else {
             print("SocialShareProPlugin: Failed to convert sticker image to PNG data")
             result(FlutterError(code: "IMAGE_CONVERSION_FAILED", message: "Failed to convert sticker image to data", details: nil))
             return
        }

        print("SocialShareProPlugin: Sticker converted to PNG data, size: \(stickerData.count) bytes")

        // 3. Create Pasteboard Item Dictionary
        var item: [String: Any] = [
            "com.facebook.sharedSticker.stickerImage": stickerData,
            "com.facebook.sharedSticker.appID": appId as NSString
        ]
        
        print("SocialShareProPlugin: Created pasteboard item with sticker and appID")
        
        // 4. Handle Background
        if let bgPath = args["backgroundImagePath"] as? String {
           print("SocialShareProPlugin: Processing background image from path: \(bgPath)")
           if let bgImage = UIImage(contentsOfFile: bgPath) {
               print("SocialShareProPlugin: Background image loaded, size: \(bgImage.size)")
               // Use 2048 to avoid downscaling HD backgrounds too much (1080w x 1920h fits within 2048h)
               let resizedBg = downscaleImage(image: bgImage, maxDimension: 2048)
               print("SocialShareProPlugin: Background image resized to: \(resizedBg.size)")
               
               // Facebook supports JPG for background, which is smaller/safer
               if let bgData = resizedBg.jpegData(compressionQuality: 0.9) {
                    print("SocialShareProPlugin: Background converted to JPEG, size: \(bgData.count) bytes")
                    item["com.facebook.sharedSticker.backgroundImage"] = bgData
               } else if let bgDataPNG = resizedBg.pngData() {
                    // Fallback to PNG if JPEG conversion fails (unlikely)
                    print("SocialShareProPlugin: Background converted to PNG (fallback), size: \(bgDataPNG.count) bytes")
                    item["com.facebook.sharedSticker.backgroundImage"] = bgDataPNG
               }
           } else {
               print("SocialShareProPlugin: Failed to load background image from path: \(bgPath)")
           }
        } else {
             // Colors
             if let topHex = args["backgroundTopColor"] as? String,
                let bottomHex = args["backgroundBottomColor"] as? String {
                 print("SocialShareProPlugin: Using gradient colors - top: \(topHex), bottom: \(bottomHex)")
                 item["com.facebook.sharedSticker.backgroundTopColor"] = topHex
                 item["com.facebook.sharedSticker.backgroundBottomColor"] = bottomHex
             } else {
                 print("SocialShareProPlugin: No background image or colors provided")
             }
        }
        
        // 5. Set Pasteboard
        // Try setting items directly to avoid any options issues
        UIPasteboard.general.items = [item]
        
        let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(60 * 5)
        ]
        UIPasteboard.general.setItems([item], options: pasteboardOptions)
        
        print("SocialShareProPlugin: Setting pasteboard with \(item.keys.count) keys: \(item.keys)")
        
        // 6. Open URL
        // Revert to simple URL scheme for now to rule out parameter issues
        guard let urlScheme = URL(string: "facebook-stories://share") else { return }
        print("SocialShareProPlugin: Opening Facebook Stories URL with scheme: \(urlScheme)")
        
        // Add a small delay to ensure pasteboard data is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("SocialShareProPlugin: Executing openURL now...")
            UIApplication.shared.open(urlScheme, options: [:]) { success in
                print("SocialShareProPlugin: Facebook Stories URL opened with success: \(success)")
                result(success)
            }
        }
    }
    // MARK: - WhatsApp
    
    private func shareToWhatsApp(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["imagePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Image path is required", details: nil))
            return
        }
        
        let urlScheme = URL(string: "whatsapp://app")!
        if !UIApplication.shared.canOpenURL(urlScheme) {
            result(FlutterError(code: "WHATSAPP_NOT_INSTALLED", message: "WhatsApp is not installed or 'whatsapp' is missing from Info.plist", details: nil))
            return
        }
        
        let fileURL = URL(fileURLWithPath: imagePath)
        
        documentInteractionController = UIDocumentInteractionController(url: fileURL)
        documentInteractionController?.uti = "net.whatsapp.image"
        documentInteractionController?.delegate = self
        
        // Present menu
        if let controller = getTopViewController() {
             let success = documentInteractionController?.presentOpenInMenu(from: CGRect.zero, in: controller.view, animated: true) ?? false
            if !success {
                 result(FlutterError(code: "PRESENTATION_FAILED", message: "Unable to present menu", details: nil))
            } else {
                 result(true)
            }
        } else {
            result(FlutterError(code: "VIEW_ERROR", message: "Unable to find root view controller", details: nil))
        }
    }   
    
    // MARK: - Save to Gallery
    
    private func saveToGallery(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let flutterData = args["imageBytes"] as? FlutterStandardTypedData else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Image bytes required", details: nil))
            return
        }
        
        let imageBytes = flutterData.data
        guard let image = UIImage(data: imageBytes) else {
             result(FlutterError(code: "IMAGE_ERROR", message: "Could not decode image", details: nil))
             return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    if success {
                        result(true)
                    } else {
                        result(FlutterError(code: "SAVE_FAILED", message: error?.localizedDescription, details: nil))
                    }
                }
            } else {
                result(FlutterError(code: "PERMISSION_DENIED", message: "Photo library permission denied", details: nil))
            }
        }
    }
}
