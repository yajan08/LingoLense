
import SwiftUI
import Combine
import SwiftUI

struct ScannerView: View {
		// This now works because CameraService is an ObservableObject
	@StateObject private var cameraService = CameraService()
	
		// We keep the detector in a @State so it isn't destroyed when the view refreshes
	@State private var detector = ObjectDetector()
	@State private var lastDetectedObject: String = "Scanning..."
	
	var body: some View {
		ZStack {
				// Live Feed
			CameraPreview(session: cameraService.session)
				.ignoresSafeArea()
			
				// Detection Overlay
			VStack {
				Text(lastDetectedObject.capitalized)
					.font(.title).bold()
					.padding()
					.background(.ultraThinMaterial)
					.cornerRadius(15)
					.padding(.top, 50)
				
				Spacer()
			}
		}
		.onAppear {
				// 3. Connect the detector's callback to our UI state
			detector.onObjectFound = { label in
				self.lastDetectedObject = label
			}
			
				// 4. Pass frames from camera to detector
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
