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
    
    // MARK: - Helper Methods
    
    private func isAppInstalled(scheme: String) -> Bool {
        if let url = URL(string: scheme) {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
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
            result(FlutterError(code: "INSTAGRAM_NOT_INSTALLED", message: "Instagram is not installed", details: nil))
            return
        }
        
        // Prepare Pasteboard Items
        var pasteboardItems: [[String: Any]] = []
        
        if let stickerImage = UIImage(contentsOfFile: stickerPath) {
            pasteboardItems.append(["com.instagram.sharedSticker.stickerImage": stickerImage,
                                  "com.instagram.sharedSticker.backgroundImage": stickerImage])
        }
        
        if let bgPath = args["backgroundImagePath"] as? String,
           let bgImage = UIImage(contentsOfFile: bgPath) {
             if var item = pasteboardItems.first {
                item["com.instagram.sharedSticker.backgroundImage"] = bgImage
                pasteboardItems[0] = item
            }
        }
        
        if args["backgroundImagePath"] == nil,
           let topHex = args["backgroundTopColor"] as? String,
           let bottomHex = args["backgroundBottomColor"] as? String {
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
        guard let args = call.arguments as? [String: Any],
              let stickerPath = args["stickerPath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Sticker path is required", details: nil))
            return
        }
        
        guard let urlScheme = URL(string: "facebook-stories://share") else {
            result(FlutterError(code: "URL_ERROR", message: "Invalid URL scheme", details: nil))
            return
        }
        
        if !UIApplication.shared.canOpenURL(urlScheme) {
            result(FlutterError(code: "FACEBOOK_NOT_INSTALLED", message: "Facebook is not installed", details: nil))
            return
        }
        
        // Prepare Pasteboard Items
        var pasteboardItems: [[String: Any]] = []
        
        if let stickerImage = UIImage(contentsOfFile: stickerPath) {
            pasteboardItems.append(["com.facebook.sharedSticker.stickerImage": stickerImage,
                                  "com.facebook.sharedSticker.backgroundImage": stickerImage])
        }
        
        if let bgPath = args["backgroundImagePath"] as? String,
           let bgImage = UIImage(contentsOfFile: bgPath) {
             if var item = pasteboardItems.first {
                item["com.facebook.sharedSticker.backgroundImage"] = bgImage
                pasteboardItems[0] = item
            }
        }
        
        if args["backgroundImagePath"] == nil,
           let topHex = args["backgroundTopColor"] as? String,
           let bottomHex = args["backgroundBottomColor"] as? String {
             if var item = pasteboardItems.first {
                item["com.facebook.sharedSticker.backgroundTopColor"] = topHex
                item["com.facebook.sharedSticker.backgroundBottomColor"] = bottomHex
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
    
    // MARK: - WhatsApp
    private func shareToWhatsApp(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let imagePath = args["imagePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Image path is required", details: nil))
            return
        }
        
        guard let urlScheme = URL(string: "whatsapp://") else {
            result(FlutterError(code: "URL_ERROR", message: "Invalid URL scheme", details: nil))
            return
        }
        
        if !UIApplication.shared.canOpenURL(urlScheme) {
            result(FlutterError(code: "WHATSAPP_NOT_INSTALLED", message: "WhatsApp is not installed", details: nil))
            return
        }
        
        guard let controller = UIApplication.shared.delegate?.window??.rootViewController else {
            result(FlutterError(code: "VIEW_ERROR", message: "Unable to find root view controller", details: nil))
            return
        }
        
        let fileURL = URL(fileURLWithPath: imagePath)
        
        // Verify file exists
        guard FileManager.default.fileExists(atPath: imagePath) else {
            result(FlutterError(code: "FILE_ERROR", message: "Image file does not exist", details: nil))
            return
        }
        
        // Use UIDocumentInteractionController which shows apps that can handle the file
        // WhatsApp should appear as an option, and this is more direct than UIActivityViewController
        documentInteractionController = UIDocumentInteractionController(url: fileURL)
        documentInteractionController?.uti = "public.image" // Use generic image UTI
        documentInteractionController?.delegate = self
        
        // Use presentOpenInMenu which shows apps that can open the file
        // On most devices, WhatsApp will be one of the first options
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let success = documentInteractionController?.presentOpenInMenu(from: rect, in: controller.view, animated: true) ?? false
        
        if success {
            result(true)
        } else {
            result(FlutterError(code: "SHARE_FAILED", message: "Failed to present share options", details: nil))
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