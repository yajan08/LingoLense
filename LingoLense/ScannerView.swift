import SwiftUI
import Vision

struct ScannerView: View {
	
	@StateObject private var cameraService = CameraService()
	@State private var detector = ObjectDetector()
	
	private let objectFilter = FoundationObjectFilter()
	
		// navigation
	@State private var navigateToResults = false
	@State private var finalObjects: [String] = []
	
		// unique storage
	@State private var seenObjects: Set<String> = []
	@State private var uniquePredictions: [VNClassificationObservation] = []
	
	var body: some View {
		
		NavigationStack {
			
			ZStack {
				
				CameraPreview(session: cameraService.session)
					.ignoresSafeArea()
				
				overlayView
			}
			.navigationDestination(isPresented: $navigateToResults) {
				ResultsView(objects: finalObjects)
			}
		}
		.onAppear {
			startDetection()
		}
		.onDisappear {
			cameraService.stop()
		}
	}
}

	// MARK: UI Components
private extension ScannerView {
	
	var overlayView: some View {
		
		VStack {
			Spacer()
			
			VStack(spacing: 18) {
				
				liveTicker
				
				stopButton
			}
			.padding(.top, 18)
			.padding(.bottom, 24)
			.background(.ultraThinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 28))
			.padding(.horizontal)
			.padding(.bottom, 24)
		}
	}
	
	var liveTicker: some View {
		
		ScrollViewReader { proxy in
			
			ScrollView(.horizontal, showsIndicators: false) {
				
				HStack(spacing: 12) {
					
					ForEach(uniquePredictions, id: \.identifier) { prediction in
						objectChip(prediction)
							.id(prediction.identifier)
							.transition(.move(edge: .trailing).combined(with: .opacity))
					}
				}
				.padding(.horizontal)
				.animation(.easeOut(duration: 0.25), value: uniquePredictions)
			}
			.onChange(of: uniquePredictions) { _, newPredictions in
				guard let last = newPredictions.last else { return }
				
				withAnimation(.easeOut(duration: 0.25)) {
					proxy.scrollTo(last.identifier, anchor: .trailing)
				}
			}
		}
	}
	
	func objectChip(_ prediction: VNClassificationObservation) -> some View {
		
		VStack(spacing: 4) {
			
			Text(prediction.identifier.capitalized)
				.font(.subheadline.weight(.medium))
				.lineLimit(1)
			
			Text("\(Int(prediction.confidence * 100))%")
				.font(.caption)
				.foregroundColor(.secondary)
		}
		.padding(.horizontal, 14)
		.padding(.vertical, 10)
		.background(
			Capsule()
				.fill(Color(.secondarySystemBackground))
		)
	}
	
	var stopButton: some View {
		
		Button {
			
			stopScanAndFilter()
			
		} label: {
			
			Text("Stop Scanning")
				.font(.headline)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 18)
				.background(Color.red)
				.foregroundColor(.white)
				.clipShape(RoundedRectangle(cornerRadius: 18))
				.shadow(radius: 6)
				.padding(.horizontal)
		}
	}
}

	// MARK: Detection Logic
private extension ScannerView {
	
	func startDetection() {
		
		detector.onPredictions = { results in
			
			DispatchQueue.main.async {
				
				var newItems: [VNClassificationObservation] = []
				
				for observation in results {
					
					let id = observation.identifier
					
					if !seenObjects.contains(id) {
						
						seenObjects.insert(id)
						newItems.append(observation)
					}
				}
				
				uniquePredictions.append(contentsOf: newItems)
			}
		}
		
		cameraService.frameHandler = { pixelBuffer in
			detector.detect(from: pixelBuffer)
		}
		
		cameraService.start()
	}
	
	func stopScanAndFilter() {
		
		cameraService.stop()
		
		let identifiers = uniquePredictions.map { $0.identifier }
		
		Task {
			
			let filtered = await objectFilter.filterObjects(from: identifiers)
			
			await MainActor.run {
				
				finalObjects = filtered
				
				print("FINAL OBJECTS:")
				filtered.forEach { print($0) }
				
				navigateToResults = true
			}
		}
	}
}
