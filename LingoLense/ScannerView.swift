import SwiftUI
import Vision

@available(iOS 26.0, *)
struct ScannerView: View {
	@StateObject private var cameraService = CameraService()
	@State private var detector = ObjectDetector()
	private let objectFilter = FoundationObjectFilter()
	
	@State private var navigateToResults = false
	@State private var finalObjects: [String] = []
	@State private var seenObjects: Set<String> = []
	@State private var uniquePredictions: [VNClassificationObservation] = []
	@State private var showHelp = false
	
	var body: some View {
		NavigationStack {
			ZStack {
				CameraPreview(session: cameraService.session)
					.ignoresSafeArea()
				
				VStack {
					scanningGuidanceHUD
						.padding(.top, 12)
					Spacer()
					bottomActionCard
				}
			}
			.navigationTitle("Scanning")
			.navigationBarTitleDisplayMode(.inline)
			.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
			.toolbarColorScheme(.dark, for: .navigationBar)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button { showHelp = true } label: {
						Image(systemName: "questionmark.circle.fill")
							.symbolRenderingMode(.hierarchical)
					}
				}
			}
			.navigationDestination(isPresented: $navigateToResults) {
				ResultsView(objects: finalObjects)
			}
			.sheet(isPresented: $showHelp) {
				ScannerInstructionsSheet()
			}
		}
		.onAppear { startDetection() }
		.onDisappear { cameraService.stop() }
	}
}

	// MARK: - Instructions Sheet
struct ScannerInstructionsSheet: View {
	@Environment(\.dismiss) var dismiss
	
	var body: some View {
		NavigationStack {
			List {
				Section {
					VStack(alignment: .center, spacing: 16) {
						Image(systemName: "viewfinder.circle.fill")
							.font(.system(size: 64))
							.foregroundStyle(.blue)
						
						Text("Build Your Vocabulary")
							.font(.title2.bold())
						
						Text("Move your phone around to discover household items in the target language.")
							.font(.subheadline)
							.foregroundStyle(.secondary)
							.multilineTextAlignment(.center)
					}
					.frame(maxWidth: .infinity)
					.padding(.vertical)
				}
				
				Section("Tips for success") {
					InstructionRow(
						icon: "target",
						color: .blue,
						title: "Aim for Variety",
						detail: "Try to scan between 7-10 objects for a comprehensive quiz."
					)
					InstructionRow(
						icon: "sun.max.fill",
						color: .orange,
						title: "Check Lighting",
						detail: "Scan in well-lit areas for better accuracy."
					)
					InstructionRow(
						icon: "hand.raised.fill",
						color: .purple,
						title: "Stay Steady",
						detail: "Hold the camera steady for a second on each item."
					)
				}
				
				Section("Next Steps") {
					InstructionRow(
						icon: "checklist",
						color: .green,
						title: "Verify Objects",
						detail: "After scanning, you'll pick exactly which words you want to practice."
					)
				}
			}
			.navigationTitle("Scanner Guide")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button("Got it") { dismiss() }.fontWeight(.bold)
				}
			}
		}
	}
}

	// MARK: - UI & Logic (Preserved)
private extension ScannerView {
	var scanningGuidanceHUD: some View {
		HStack(spacing: 12) {
			ProgressView().tint(.white)
			VStack(alignment: .leading, spacing: 2) {
				Text(seenObjects.count < 10 ? "Analyzing Surroundings..." : "Ready to Quiz")
					.font(.subheadline.bold())
					.foregroundColor(.white)
				Text(seenObjects.count < 10 ? "Point your camera at various objects" : "You've found enough objects!")
					.font(.caption)
					.foregroundColor(.white.opacity(0.8))
			}
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 10)
		.background(.ultraThinMaterial, in: Capsule())
	}
	
	var bottomActionCard: some View {
		VStack(spacing: 20) {
			HStack(spacing: 8) {
				Image(systemName: "cube.box.fill").foregroundColor(.blue)
				Text("\(seenObjects.count) Objects Detected")
					.font(.system(.subheadline, design: .rounded).bold())
			}
			.padding(.horizontal, 16).padding(.vertical, 8)
			.background(.ultraThinMaterial, in: Capsule())
			
			Button(action: stopScanAndFilter) {
				HStack {
					Text("Finish Scanning")
						.font(.headline)
					Image(systemName: "stop.fill")
				}
				.frame(maxWidth: .infinity)
				.padding(.vertical, 18)
				.background(seenObjects.count >= 10 ? Color.blue : Color.red)
				.foregroundColor(.white)
				.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
			}
			.padding(.horizontal, 24)
		}
		.padding(.bottom, 34)
	}
	
	func startDetection() {
		detector.onPredictions = { results in
			DispatchQueue.main.async {
				for observation in results {
					if !seenObjects.contains(observation.identifier) {
						seenObjects.insert(observation.identifier)
						uniquePredictions.append(observation)
						UIImpactFeedbackGenerator(style: .light).impactOccurred()
					}
				}
			}
		}
		cameraService.frameHandler = { pixelBuffer in detector.detect(from: pixelBuffer) }
		cameraService.start()
	}
	
	func stopScanAndFilter() {
		UIImpactFeedbackGenerator(style: .medium).impactOccurred()
		cameraService.stop()
		let identifiers = uniquePredictions.map { $0.identifier }
		Task {
			let filtered = await objectFilter.filterObjects(from: identifiers)
			await MainActor.run {
				finalObjects = filtered
				navigateToResults = true
			}
		}
	}
}
