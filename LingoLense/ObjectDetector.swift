import Foundation
import Vision
import CoreML
import UIKit

final class ObjectDetector {
	private var visionModel: VNCoreMLModel?
	private var request: VNCoreMLRequest?
	
	private var lastDetectionTime = Date.distantPast
	private let detectionInterval: TimeInterval = 0.25
	
	private var detectionCounts: [String: Int] = [:]
	private let requiredCount = 3
	
		// Callback closure
	var onObjectFound: ((String) -> Void)?
	
	init() {
		setupModel()
	}
	
	private func setupModel() {
		do {
			let config = MLModelConfiguration()
			
				// ✅ CRITICAL FIX
			config.computeUnits = .all
			
			let model = try yolov8s(configuration: config)
			
			visionModel = try VNCoreMLModel(for: model.model)
			
			request = VNCoreMLRequest(model: visionModel!) { [weak self] request, error in
				
				if let error = error {
					print("❌ Vision error:", error)
					return
				}
				
				guard let results = request.results as? [VNRecognizedObjectObservation] else {
					print("❌ No observations")
					return
				}
				
				print("Detections count:", results.count)
				
				self?.handleDetections(results)
			}
			
			request?.imageCropAndScaleOption = .scaleFit
			
			print("✅ Model loaded successfully")
			
		} catch {
			print("❌ Failed to load YOLO model:", error)
		}
	}
	
	func detect(from pixelBuffer: CVPixelBuffer) {
		
		let now = Date()
		
		guard now.timeIntervalSince(lastDetectionTime) > detectionInterval else {
			return
		}
		
		lastDetectionTime = now
		
		guard let request = request else { return }
		
		let handler = VNImageRequestHandler(
			cvPixelBuffer: pixelBuffer,
			orientation: .right,
			options: [:]
		)
		
		try? handler.perform([request])
	}
	
//	func detect(from pixelBuffer: CVPixelBuffer) {
//		guard let request = request else {
//			print("❌ Request is nil")
//			return
//		}
//		
//		print("Frame received for detection")
//		
//		let handler = VNImageRequestHandler(
//			cvPixelBuffer: pixelBuffer,
//			orientation: .right,
//			options: [:]
//		)
//		
//		do {
//			try handler.perform([request])
//		} catch {
//			print("❌ Handler error:", error)
//		}
//	}
	
	private func handleDetections(_ observations: [VNRecognizedObjectObservation]) {
		
		for observation in observations {
			
			guard let label = observation.labels.first else { continue }
			
			let name = label.identifier
			let confidence = label.confidence
			
			guard confidence > 0.7 else { continue }
			
			detectionCounts[name, default: 0] += 1
			
			if detectionCounts[name] == requiredCount {
				
				DispatchQueue.main.async {
					print("✅ Stable detection:", name)
					self.onObjectFound?(name)
				}
			}
		}
	}
	
//	private func handleDetections(_ observations: [VNRecognizedObjectObservation]) {
//			// Find the best detection
//		if let topObservation = observations.first,
//		   let topLabel = topObservation.labels.first,
//		   topLabel.confidence > 0.5 {
//			
//				// ⚠️ CRITICAL: Move to Main Thread for SwiftUI
//			DispatchQueue.main.async {
//				self.onObjectFound?(topLabel.identifier)
//			}
//		}
//	}
	
}
