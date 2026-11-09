package com.maalam.egrado

import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TEXT_CHANNEL)
            .setMethodCallHandler { call, result ->
                val path = call.argument<String>("path")
                when {
                    call.method != "readLines" -> result.notImplemented()
                    path == null -> result.error("bad_args", "Missing photo path", null)
                    else -> readLines(path, result)
                }
            }
    }

    /** Reads every line of text in the photo with ML Kit, on the device. */
    private fun readLines(path: String, result: MethodChannel.Result) {
        val image = try {
            // Applies the photo's EXIF rotation.
            InputImage.fromFilePath(this, Uri.fromFile(File(path)))
        } catch (e: IOException) {
            result.error("unreadable_image", e.message, null)
            return
        }
        val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
        recognizer.process(image)
            .addOnSuccessListener { text ->
                val lines = text.textBlocks.flatMap { it.lines }.mapNotNull { line ->
                    val box = line.boundingBox ?: return@mapNotNull null
                    mapOf(
                        "text" to line.text,
                        "left" to box.left.toDouble(),
                        "top" to box.top.toDouble(),
                        "right" to box.right.toDouble(),
                        "bottom" to box.bottom.toDouble(),
                    )
                }
                result.success(lines)
            }
            .addOnFailureListener { e -> result.error("recognition_failed", e.message, null) }
            .addOnCompleteListener { recognizer.close() }
    }

    private companion object {
        const val TEXT_CHANNEL = "egrado/text_recognition"
    }
}
