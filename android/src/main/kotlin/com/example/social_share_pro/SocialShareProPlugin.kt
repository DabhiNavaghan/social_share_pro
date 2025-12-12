package com.example.social_share_pro

import android.app.Activity
import android.content.ComponentName
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream

class SocialShareProPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private lateinit var context: Context

    private val INSTAGRAM_PACKAGE = "com.instagram.android"
    private val FACEBOOK_PACKAGE = "com.facebook.katana"
    private val WHATSAPP_PACKAGE = "com.whatsapp"

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "social_share_pro")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "shareToInstagramStories" -> handleInstagramShare(call, result)
            "shareToFacebookStories" -> handleFacebookShare(call, result)
            "shareToWhatsAppStatus" -> shareToWhatsAppStatus(call, result)
            "saveToGallery" -> handleSaveToGallery(call, result)
            "isInstagramInstalled" -> result.success(isPackageInstalled(INSTAGRAM_PACKAGE))
            "isFacebookInstalled" -> result.success(isPackageInstalled(FACEBOOK_PACKAGE))
            "isWhatsAppInstalled" -> result.success(isPackageInstalled(WHATSAPP_PACKAGE))
            else -> result.notImplemented()
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            activity?.packageManager?.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    // --- INSTAGRAM ---
    private fun handleInstagramShare(call: MethodCall, result: Result) {
        if (!isPackageInstalled(INSTAGRAM_PACKAGE)) {
            result.error("INSTAGRAM_NOT_INSTALLED", "Instagram is not installed", null)
            return
        }

        val stickerPath = call.argument<String>("stickerPath")
        if (stickerPath == null) {
            result.error("INVALID_ARGUMENTS", "Sticker path is required", null)
            return
        }

        try {
            val stickerUri = getUriForFile(stickerPath)

            val intent = Intent("com.instagram.share.ADD_TO_STORY").apply {
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
                setPackage(INSTAGRAM_PACKAGE)
                putExtra("interactive_asset_uri", stickerUri)

                val backgroundImagePath = call.argument<String>("backgroundImagePath")
                if (backgroundImagePath != null) {
                    val backgroundUri = getUriForFile(backgroundImagePath)
                    setDataAndType(backgroundUri, "image/*")
                    activity?.grantUriPermission(INSTAGRAM_PACKAGE, backgroundUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                } else {
                    type = "image/*"
                    putExtra("top_background_color", call.argument<String>("backgroundTopColor") ?: "#FFFFFF")
                    putExtra("bottom_background_color", call.argument<String>("backgroundBottomColor") ?: "#FFFFFF")
                }
            }

            activity?.grantUriPermission(INSTAGRAM_PACKAGE, stickerUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            startActivity(intent, result)
        } catch (e: Exception) {
            result.error("SHARE_FAILED", e.message, null)
        }
    }

    // --- FACEBOOK ---
    private fun handleFacebookShare(call: MethodCall, result: Result) {
        if (!isPackageInstalled(FACEBOOK_PACKAGE)) {
            result.error("FACEBOOK_NOT_INSTALLED", "Facebook is not installed", null)
            return
        }

        val stickerPath = call.argument<String>("stickerPath")
        if (stickerPath == null) {
            result.error("INVALID_ARGUMENTS", "Sticker path is required", null)
            return
        }

        try {
            val stickerUri = getUriForFile(stickerPath)
            val appId = call.argument<String>("appId")

            val intent = Intent("com.facebook.stories.ADD_TO_STORY").apply {
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION
                setPackage(FACEBOOK_PACKAGE)
                putExtra("interactive_asset_uri", stickerUri)
                if (appId != null) putExtra("com.facebook.platform.extra.APPLICATION_ID", appId)

                val backgroundImagePath = call.argument<String>("backgroundImagePath")
                if (backgroundImagePath != null) {
                    val backgroundUri = getUriForFile(backgroundImagePath)
                    setDataAndType(backgroundUri, "image/*")
                    activity?.grantUriPermission(FACEBOOK_PACKAGE, backgroundUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
                } else {
                    type = "image/*"
                    putExtra("top_background_color", call.argument<String>("backgroundTopColor") ?: "#000000")
                    putExtra("bottom_background_color", call.argument<String>("backgroundBottomColor") ?: "#000000")
                }
            }

            activity?.grantUriPermission(FACEBOOK_PACKAGE, stickerUri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            startActivity(intent, result)
        } catch (e: Exception) {
            result.error("SHARE_FAILED", e.message, null)
        }
    }

    // --- WHATSAPP ---
    private fun shareToWhatsAppStatus(call: MethodCall, result: MethodChannel.Result) {
        val imagePath = call.argument<String>("imagePath")
        if (imagePath == null) {
            result.error("INVALID_ARGUMENTS", "Image path is required", null)
            return
        }

        if (!isPackageInstalled(WHATSAPP_PACKAGE)) {
            result.error("WHATSAPP_NOT_INSTALLED", "WhatsApp is not installed on this device", null)
            return
        }

        try {
            val imageFile = File(imagePath)
            if (!imageFile.exists()) {
                result.error("FILE_NOT_FOUND", "Image file does not exist", null)
                return
            }

            val imageUri: Uri = FileProvider.getUriForFile(
                activity!!,
                "${activity!!.packageName}.fileprovider",
                imageFile
            )

            activity!!.grantUriPermission(
                WHATSAPP_PACKAGE,
                imageUri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )

            // Try multiple approaches to share to WhatsApp Status
            // Approach 1: Use ContactPicker with status target
            try {
                val statusIntent = Intent().apply {
                    action = Intent.ACTION_SEND
                    type = "image/*"
                    flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK
                    putExtra(Intent.EXTRA_STREAM, imageUri)
                    putExtra("jid", "status@broadcast")
                    component = ComponentName(WHATSAPP_PACKAGE, "com.whatsapp.ContactPicker")
                }
                
                if (activity!!.packageManager.resolveActivity(statusIntent, 0) != null) {
                    activity!!.startActivity(statusIntent)
                    result.success(true)
                    return
                }
            } catch (e: Exception) {
                // Continue to next approach
            }

            // Approach 2: Try StatusRecorderActivity (if available)
            try {
                val statusRecorderIntent = Intent().apply {
                    action = Intent.ACTION_SEND
                    type = "image/*"
                    flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK
                    putExtra(Intent.EXTRA_STREAM, imageUri)
                    component = ComponentName(WHATSAPP_PACKAGE, "com.whatsapp.StatusRecorderActivity")
                }
                
                if (activity!!.packageManager.resolveActivity(statusRecorderIntent, 0) != null) {
                    activity!!.startActivity(statusRecorderIntent)
                    result.success(true)
                    return
                }
            } catch (e: Exception) {
                // Continue to next approach
            }

            // Approach 3: Use standard share with WhatsApp package (opens share sheet, user can select Status)
            val fallbackIntent = Intent().apply {
                action = Intent.ACTION_SEND
                type = "image/*"
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK
                setPackage(WHATSAPP_PACKAGE)
                putExtra(Intent.EXTRA_STREAM, imageUri)
            }
            
            activity!!.startActivity(fallbackIntent)
            result.success(true)

        } catch (e: Exception) {
            result.error("SHARE_FAILED", e.message ?: "Unknown error occurred", null)
        }
    }

    // --- SAVE TO GALLERY ---
    private fun handleSaveToGallery(call: MethodCall, result: Result) {
        val imageBytes = call.argument<ByteArray>("imageBytes")
        val fileName = call.argument<String>("fileName")

        if (imageBytes == null || fileName == null) {
            result.error("INVALID_ARGUMENTS", "Image bytes and filename required", null)
            return
        }

        try {
            val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val contentValues = ContentValues().apply {
                    put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
                    put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                    put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/SocialShare")
                    put(MediaStore.Images.Media.IS_PENDING, 1)
                }

                val resolver = activity?.contentResolver ?: return
                val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)

                if (uri != null) {
                    resolver.openOutputStream(uri)?.use { stream ->
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                    }
                    contentValues.clear()
                    contentValues.put(MediaStore.Images.Media.IS_PENDING, 0)
                    resolver.update(uri, contentValues, null, null)
                    result.success(true)
                } else {
                    result.error("SAVE_FAILED", "Failed to create MediaStore entry", null)
                }
            } else {
                val picturesDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES)
                val appDir = File(picturesDir, "SocialShare")
                if (!appDir.exists()) appDir.mkdirs()

                val file = File(appDir, fileName)
                FileOutputStream(file).use { stream ->
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                }

                // Scan file
                val scanIntent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                scanIntent.data = Uri.fromFile(file)
                activity?.sendBroadcast(scanIntent)
                result.success(true)
            }
            bitmap.recycle()
        } catch (e: Exception) {
            result.error("SAVE_FAILED", e.message, null)
        }
    }

    // --- HELPERS ---
    private fun getUriForFile(path: String): Uri {
        val file = File(path)
        return FileProvider.getUriForFile(activity!!, "${activity!!.packageName}.fileprovider", file)
    }

    private fun startActivity(intent: Intent, result: Result) {
        try {
            if (activity?.packageManager?.resolveActivity(intent, 0) != null) {
                activity?.startActivity(intent)
                result.success(true)
            } else {
                result.error("ACTIVITY_NOT_FOUND", "No suitable activity found", null)
            }
        } catch (e: Exception) {
            result.error("START_ACTIVITY_FAILED", e.message, null)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
