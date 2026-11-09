import Flutter
import UIKit
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "EgradoTextRecognition") as FlutterPluginRegistrar?
    {
      TextRecognitionChannel.register(with: registrar)
    }
  }
}

/// Reads lines of text from a photo with Apple's Vision framework, on the
/// device. Answers "readLines" on the "egrado/text_recognition" channel.
enum TextRecognitionChannel {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "egrado/text_recognition", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "readLines" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
        let path = args["path"] as? String
      else {
        result(FlutterError(code: "bad_args", message: "Missing photo path", details: nil))
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let reply = readLines(path: path)
        DispatchQueue.main.async { result(reply) }
      }
    }
  }

  private static func readLines(path: String) -> Any {
    guard let image = UIImage(contentsOfFile: path), let cgImage = image.cgImage else {
      return FlutterError(
        code: "unreadable_image", message: "The photo could not be opened.", details: nil)
    }
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    // Names are not dictionary words; correction would "fix" them.
    request.usesLanguageCorrection = false
    let handler = VNImageRequestHandler(
      cgImage: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation))
    do {
      try handler.perform([request])
    } catch {
      return FlutterError(
        code: "recognition_failed", message: error.localizedDescription, details: nil)
    }
    // Vision boxes are 0–1 with the origin at the bottom left; convert to
    // pixels from the top left of the upright photo.
    let width = Double(image.size.width)
    let height = Double(image.size.height)
    return (request.results ?? []).compactMap { observation -> [String: Any]? in
      guard let text = observation.topCandidates(1).first?.string else { return nil }
      let box = observation.boundingBox
      return [
        "text": text,
        "left": Double(box.minX) * width,
        "right": Double(box.maxX) * width,
        "top": (1 - Double(box.maxY)) * height,
        "bottom": (1 - Double(box.minY)) * height,
      ]
    }
  }
}

extension CGImagePropertyOrientation {
  init(_ orientation: UIImage.Orientation) {
    switch orientation {
    case .up: self = .up
    case .upMirrored: self = .upMirrored
    case .down: self = .down
    case .downMirrored: self = .downMirrored
    case .left: self = .left
    case .leftMirrored: self = .leftMirrored
    case .right: self = .right
    case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}
