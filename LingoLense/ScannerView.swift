import SwiftUI
import Vision

struct ScannerView: View {
	
	@StateObject private var cameraService = CameraService()
	@State private var detector = ObjectDetector()
	
	// ✅ Store top predictions
	@State private var predictions: [VNClassificationObservation] = []
	
	var body: some View {
		
		ZStack {
			
			CameraPreview(session: cameraService.session)
				.ignoresSafeArea()
			
			
			VStack(alignment: .leading, spacing: 8) {
				
				Text("Detected Objects")
					.font(.headline)
				
				ForEach(predictions, id: \.identifier) { prediction in
					
					HStack {
						Text(prediction.identifier.capitalized)
						
						Spacer()
						
						Text("\(Int(prediction.confidence * 100))%")
							.foregroundColor(.secondary)
					}
				}
				
				Spacer()
			}
			.padding()
			.background(.ultraThinMaterial)
			.cornerRadius(16)
			.padding(.top, 50)
			.padding(.horizontal)
		}
		.onAppear {
			
			detector.onPredictions = { results in
				self.predictions = results
			}
			
			cameraService.frameHandler = { pixelBuffer in
				detector.detect(from: pixelBuffer)
			}
			
			cameraService.start()
		}
		.onDisappear {
			cameraService.stop()
		}
	}
}

#Preview {
	ScannerView()
}


	//
//import SwiftUI
//import Combine
//import SwiftUI
//
//struct ScannerView: View {
//		// This now works because CameraService is an ObservableObject
//	@StateObject private var cameraService = CameraService()
//	
//		// We keep the detector in a @State so it isn't destroyed when the view refreshes
//	@State private var detector = ObjectDetector()
//	@State private var lastDetectedObject: String = "Scanning..."
//	
//	var body: some View {
//		ZStack {
//				// Live Feed
//			CameraPreview(session: cameraService.session)
//				.ignoresSafeArea()
//			
//				// Detection Overlay
//			VStack {
//				Text(lastDetectedObject.capitalized)
//					.font(.title).bold()
//					.padding()
//					.background(.ultraThinMaterial)
//					.cornerRadius(15)
//					.padding(.top, 50)
//				
//				Spacer()
//			}
//		}
//		.onAppear {
//				// 3. Connect the detector's callback to our UI state
//			detector.onObjectFound = { label in
//				self.lastDetectedObject = label
//			}
//			
//				// 4. Pass frames from camera to detector
//			cameraService.frameHandler = { pixelBuffer in
//				detector.detect(from: pixelBuffer)
//			}
//			
//			cameraService.start()
//		}
//		.onDisappear {
//			cameraService.stop()
//		}
//	}
//}
//#Preview {
//    ScannerView()
//}
