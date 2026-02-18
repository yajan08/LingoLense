import Foundation
import Vision
import UIKit

final class ObjectDetector {
	
	private var classificationRequest: VNClassifyImageRequest!
	
	private var lastDetectionTime = Date.distantPast
	private let detectionInterval: TimeInterval = 0.33
	
	var onPredictions: (([VNClassificationObservation]) -> Void)?
	
	init() {
		setupClassifier()
	}
	
	
	private func setupClassifier() {
		
		classificationRequest = VNClassifyImageRequest { [weak self] request, error in
			
			if let error = error {
				print("❌ Vision error:", error)
				return
			}
			
			guard let results = request.results as? [VNClassificationObservation] else {
				return
			}
			
			self?.handleClassifications(results)
		}
	}
	
	
	func detect(from pixelBuffer: CVPixelBuffer) {
		
		let now = Date()
		
		guard now.timeIntervalSince(lastDetectionTime) > detectionInterval else {
			return
		}
		
		lastDetectionTime = now
		
		let orientation = exifOrientationFromDeviceOrientation()
		
		DispatchQueue.global(qos: .userInitiated).async { [weak self] in
			
			guard let self else { return }
			
			let handler = VNImageRequestHandler(
				cvPixelBuffer: pixelBuffer,
				orientation: orientation
			)
			
			do {
				try handler.perform([self.classificationRequest])
			} catch {
				print("Vision perform failed:", error)
			}
		}
	}
	
	private func handleClassifications(_ results: [VNClassificationObservation]) {
		
		let filtered = results
			.filter { $0.confidence > 0.25 }
			.prefix(5)
		
		DispatchQueue.main.async {
			self.onPredictions?(Array(filtered))
		}
	}
	
	
	private func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
		
		switch UIDevice.current.orientation {
				
			case .portraitUpsideDown:
				return .left
				
			case .landscapeLeft:
				return .upMirrored
				
			case .landscapeRight:
				return .down
				
			default:
				return .up
		}
	}
}
