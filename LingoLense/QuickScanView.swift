import SwiftUI
import Vision

@available(iOS 26.0, *)
struct QuickScanView: View {
		// MARK: - Properties
	@StateObject private var cameraService = CameraService()
	@State private var detector = ObjectDetector()
	private let aiService = FoundationAIService()
	
		// Core State
	@State private var latestPixelBuffer: CVPixelBuffer?
	@State private var detectedResults: [FoundationAIService.QuizResult] = []
	
		// UI State
	@State private var isAnalyzing = false
	@State private var showHelp = false
	@State private var pulseScale: CGFloat = 1.0
	@State private var scanStatus: ScanStatus = .ready
	
	enum ScanStatus {
		case ready, processing, displaying, empty
	}
	
	@Environment(\.dismiss) private var dismiss
	private let impact = UIImpactFeedbackGenerator(style: .medium)
	private let notification = UINotificationFeedbackGenerator()
	
		// MARK: - Body
	var body: some View {
		ZStack {
			CameraPreview(session: cameraService.session)
				.ignoresSafeArea()
			
			if scanStatus == .displaying {
				VStack {
					Spacer()
					resultsCarousel
						.transition(.asymmetric(
							insertion: .move(edge: .bottom).combined(with: .opacity),
							removal: .opacity
						))
					Spacer().frame(height: 120)
				}
			}
			
			VStack {
				Spacer()
				if scanStatus == .ready && !isAnalyzing {
					tapToIdentifyHint
				}
				if scanStatus == .empty {
					emptyStateToast
				}
				Spacer()
				bottomActionArea
			}
			
			if isAnalyzing {
				analysisOverlay
			}
		}
		.navigationBarTitleDisplayMode(.inline)
		.toolbarBackground(.hidden, for: .navigationBar)
		.toolbar {
			ToolbarItem(placement: .principal) {
				Text("Quick Scan")
					.font(.system(.subheadline, design: .rounded).bold())
					.foregroundStyle(.white.opacity(0.9))
			}
			
			ToolbarItem(placement: .topBarTrailing) {
				Button { showHelp = true } label: {
					Image(systemName: "questionmark")
						.font(.title3)
						.symbolRenderingMode(.hierarchical)
						.foregroundStyle(.white)
				}
			}
		}
		.sheet(isPresented: $showHelp) {
			QuickScanInstructionsSheet()
		}
		.onAppear {
			setupDetector()
			cameraService.start()
			withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
				pulseScale = 1.04
			}
		}
		.onDisappear { cameraService.stop() }
		.onTapGesture { if scanStatus == .ready { performQuickScan() } }
	}
}

	// MARK: - UI Components
private extension QuickScanView {
	
	var resultsCarousel: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 12) {
				ForEach(detectedResults) { result in
					VStack(alignment: .leading, spacing: 6) {
						HStack(spacing: 4) {
							Image(systemName: "sparkles")
								.font(.system(size: 10))
							Text("DETECTED")
								.font(.system(size: 9, weight: .black))
						}
						.foregroundStyle(.blue)
						
						Text(result.translatedWord.capitalized)
							.font(.system(.title3, design: .rounded).bold())
							.foregroundStyle(.primary)
						
						Text(result.correctEnglish.uppercased())
							.font(.system(size: 10, weight: .bold, design: .monospaced))
							.foregroundStyle(.secondary)
					}
					.padding(.horizontal, 20)
					.padding(.vertical, 18)
					.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
				}
			}
			.padding(.horizontal, 20)
		}
	}
	
	var tapToIdentifyHint: some View {
		HStack(spacing: 10) {
			Image(systemName: "hand.tap.fill")
			Text("Tap to identify")
		}
		.font(.subheadline.bold())
		.foregroundColor(.white)
		.padding(.horizontal, 24)
		.padding(.vertical, 14)
		.background(.black.opacity(0.3), in: Capsule())
		.scaleEffect(pulseScale)
	}
	
	var emptyStateToast: some View {
		Text("No objects found. Try another angle.")
			.font(.caption.bold())
			.foregroundStyle(.white)
			.padding(.horizontal, 16)
			.padding(.vertical, 10)
			.background(.ultraThinMaterial, in: Capsule())
	}
	
	var bottomActionArea: some View {
		VStack {
			if scanStatus == .displaying {
				Button(action: resetScan) {
					HStack(spacing: 8) {
						Image(systemName: "arrow.clockwise")
						Text("New Scan")
					}
					.font(.headline.bold())
					.foregroundStyle(.black)
					.padding(.horizontal, 32)
					.padding(.vertical, 16)
					.background(.white, in: Capsule())
					.shadow(color: .black.opacity(0.15), radius: 10, y: 5)
				}
				.transition(.scale.combined(with: .opacity))
			}
		}
		.padding(.bottom, 40)
	}
	
	var analysisOverlay: some View {
		ZStack {
			Color.black.opacity(0.2).ignoresSafeArea()
			VStack(spacing: 16) {
				ProgressView()
					.tint(.white)
					.controlSize(.large)
				Text("Analyzing...")
					.font(.subheadline.bold())
					.foregroundStyle(.white)
			}
		}
	}
}

	// MARK: - Logic
private extension QuickScanView {
	func setupDetector() {
		cameraService.frameHandler = { buffer in self.latestPixelBuffer = buffer }
	}
	
	func performQuickScan() {
		guard let buffer = latestPixelBuffer else { return }
		
		impact.impactOccurred(intensity: 0.7)
		withAnimation(.easeInOut) {
			isAnalyzing = true
			scanStatus = .processing
		}
		
		detector.detect(from: buffer)
		detector.onPredictions = { observations in
				// Filter out generic labels manually before AI even sees them
				// This prevents AI from trying to "explain" generic categories in sentences
			let genericBlacklist = ["structure", "room", "indoor", "interior", "architecture", "machine", "object", "material"]
			
			let rawLabels = observations
				.map { $0.identifier.lowercased() }
				.filter { label in
					!genericBlacklist.contains(where: { label.contains($0) })
				}
			
			Task(priority: .userInitiated) {
					// If we pre-filtered everything out, don't waste AI resources
				guard !rawLabels.isEmpty else {
					await handleEmptyResult()
					return
				}
				
				let filtered = await aiService.filterObjects(from: rawLabels)
				
				if filtered.isEmpty {
					await handleEmptyResult()
					return
				}
				
				let results = await aiService.generateQuizSession(from: filtered)
				
				await MainActor.run {
					finalizeScan(with: results)
				}
			}
		}
	}
	
	func finalizeScan(with results: [FoundationAIService.QuizResult]) {
		withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
			isAnalyzing = false
			detectedResults = results
			scanStatus = .displaying
			notification.notificationOccurred(.success)
		}
	}
	
	@MainActor
	func handleEmptyResult() async {
		withAnimation(.spring()) {
			isAnalyzing = false
			scanStatus = .empty
			notification.notificationOccurred(.warning)
		}
		try? await Task.sleep(for: .seconds(2))
		withAnimation { scanStatus = .ready }
	}
	
	func resetScan() {
		impact.impactOccurred()
		withAnimation(.spring()) {
			detectedResults = []
			scanStatus = .ready
		}
	}
}

	// MARK: - Instructions
struct QuickScanInstructionsSheet: View {
	@Environment(\.dismiss) var dismiss
	var body: some View {
		NavigationStack {
			List {
				Section {
					InstructionRow(
						icon: "bolt.fill",
						color: .blue,
						title: "Instant Scan",
						detail: "Tap once to identify and translate everything in view."
					)
					InstructionRow(
						icon: "camera.viewfinder",
						color: .orange,
						title: "Best Results",
						detail: "Keep your phone 2-3 feet away and ensure good lighting."
					)
					InstructionRow(
						icon: "move.3d",
						color: .purple,
						title: "Angles Matter",
						detail: "Try a 45° angle rather than looking straight down."
					)
				}
			}
			.navigationTitle("Quick Scan Guide")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button {
						dismiss()
					} label: {
						Image(systemName: "xmark")
					}
				}
			}
		}
	}
}

	//import SwiftUI
//import Vision
//
//@available(iOS 26.0, *)
//struct QuickScanView: View {
//		// MARK: - Properties
//	@StateObject private var cameraService = CameraService()
//	@State private var detector = ObjectDetector()
//	private let aiService = FoundationAIService()
//	
//		// Core State
//	@State private var latestPixelBuffer: CVPixelBuffer?
//	@State private var detectedResults: [FoundationAIService.QuizResult] = []
//	
//		// UI State
//	@State private var isAnalyzing = false
//	@State private var showHelp = false
//	@State private var pulseScale: CGFloat = 1.0
//	@State private var scanStatus: ScanStatus = .ready
//	
//	enum ScanStatus {
//		case ready, processing, displaying, empty
//	}
//	
//	@Environment(\.dismiss) private var dismiss
//	private let impact = UIImpactFeedbackGenerator(style: .medium)
//	private let notification = UINotificationFeedbackGenerator()
//	
//		// MARK: - Body
//	var body: some View {
//		ZStack {
//				// Layer 1: Immersive Camera Feed
//			CameraPreview(session: cameraService.session)
//				.ignoresSafeArea()
//			
//				// Layer 2: Discovery Cards (Carousel)
//			if scanStatus == .displaying {
//				VStack {
//					Spacer()
//					resultsCarousel
//						.transition(.asymmetric(
//							insertion: .move(edge: .bottom).combined(with: .opacity),
//							removal: .opacity
//						))
//					Spacer().frame(height: 120)
//				}
//			}
//			
//				// Layer 3: HUD Elements
//			VStack {
//				Spacer()
//				
//				if scanStatus == .ready && !isAnalyzing {
//					tapToIdentifyHint
//				}
//				
//				if scanStatus == .empty {
//					emptyStateToast
//				}
//				
//				Spacer()
//				
//				bottomActionArea
//			}
//			
//				// Layer 4: Intelligence Processing
//			if isAnalyzing {
//				analysisOverlay
//			}
//		}
//		.navigationBarTitleDisplayMode(.inline)
//		.toolbarBackground(.hidden, for: .navigationBar)
//		.toolbar {
//			ToolbarItem(placement: .principal) {
//				Text("Quick Scan")
//					.font(.system(.subheadline, design: .rounded).bold())
//					.foregroundStyle(.white.opacity(0.9))
//			}
//			
//			ToolbarItem(placement: .topBarTrailing) {
//				Button { showHelp = true } label: {
//					Image(systemName: "info.circle.fill")
//						.font(.title3)
//						.symbolRenderingMode(.hierarchical)
//						.foregroundStyle(.white)
//				}
//			}
//		}
//		.sheet(isPresented: $showHelp) {
//			QuickScanInstructionsSheet()
//		}
//		.onAppear {
//			setupDetector()
//			cameraService.start()
//			withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
//				pulseScale = 1.04
//			}
//		}
//		.onDisappear { cameraService.stop() }
//		.onTapGesture { if scanStatus == .ready { performQuickScan() } }
//	}
//}
//
//	// MARK: - UI Components
//private extension QuickScanView {
//	
//	var resultsCarousel: some View {
//		ScrollView(.horizontal, showsIndicators: false) {
//			HStack(spacing: 12) {
//				ForEach(detectedResults) { result in
//					VStack(alignment: .leading, spacing: 6) {
//						HStack(spacing: 4) {
//							Image(systemName: "sparkles")
//								.font(.system(size: 10))
//							Text("DETECTED")
//								.font(.system(size: 9, weight: .black))
//						}
//						.foregroundStyle(.blue)
//						
//						Text(result.translatedWord.capitalized)
//							.font(.system(.title3, design: .rounded).bold())
//							.foregroundStyle(.primary)
//						
//						Text(result.correctEnglish.uppercased())
//							.font(.system(size: 10, weight: .bold, design: .monospaced))
//							.foregroundStyle(.secondary)
//					}
//					.padding(.horizontal, 20)
//					.padding(.vertical, 18)
//					.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
//				}
//			}
//			.padding(.horizontal, 20)
//		}
//	}
//	
//	var tapToIdentifyHint: some View {
//		HStack(spacing: 10) {
//			Image(systemName: "hand.tap.fill")
//			Text("Tap to identify")
//		}
//		.font(.subheadline.bold())
//		.foregroundColor(.white)
//		.padding(.horizontal, 24)
//		.padding(.vertical, 14)
//		.background(.black.opacity(0.3), in: Capsule())
//		.scaleEffect(pulseScale)
//	}
//	
//	var emptyStateToast: some View {
//		Text("No objects found. Try another angle.")
//			.font(.caption.bold())
//			.foregroundStyle(.white)
//			.padding(.horizontal, 16)
//			.padding(.vertical, 10)
//			.background(.ultraThinMaterial, in: Capsule())
//	}
//	
//	var bottomActionArea: some View {
//		VStack {
//			if scanStatus == .displaying {
//				Button(action: resetScan) {
//					HStack(spacing: 8) {
//						Image(systemName: "arrow.clockwise")
//						Text("New Scan")
//					}
//					.font(.headline.bold())
//					.foregroundStyle(.black)
//					.padding(.horizontal, 32)
//					.padding(.vertical, 16)
//					.background(.white, in: Capsule())
//					.shadow(color: .black.opacity(0.15), radius: 10, y: 5)
//				}
//				.transition(.scale.combined(with: .opacity))
//			}
//		}
//		.padding(.bottom, 40)
//	}
//	
//	var analysisOverlay: some View {
//		ZStack {
//			Color.black.opacity(0.2).ignoresSafeArea()
//			VStack(spacing: 16) {
//				ProgressView()
//					.tint(.white)
//					.controlSize(.large)
//				Text("Analyzing...")
//					.font(.subheadline.bold())
//					.foregroundStyle(.white)
//			}
//		}
//	}
//}
//
//	// MARK: - Logic
//private extension QuickScanView {
//	func setupDetector() {
//		cameraService.frameHandler = { buffer in self.latestPixelBuffer = buffer }
//	}
//	
//	func performQuickScan() {
//		guard let buffer = latestPixelBuffer else { return }
//		
//		impact.impactOccurred(intensity: 0.7)
//		withAnimation(.easeInOut) {
//			isAnalyzing = true
//			scanStatus = .processing
//		}
//		
//		detector.detect(from: buffer)
//		detector.onPredictions = { observations in
//			let rawLabels = observations.map { $0.identifier.lowercased() }
//			
//			Task(priority: .userInitiated) {
//				let filtered = await aiService.filterObjects(from: rawLabels)
//				
//				if filtered.isEmpty {
//					await handleEmptyResult()
//					return
//				}
//				
//				let results = await aiService.generateQuizSession(from: filtered)
//				
//				await MainActor.run {
//					finalizeScan(with: results)
//				}
//			}
//		}
//	}
//	
//	func finalizeScan(with results: [FoundationAIService.QuizResult]) {
//		withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
//			isAnalyzing = false
//			detectedResults = results
//			scanStatus = .displaying
//			notification.notificationOccurred(.success)
//		}
//	}
//	
//	@MainActor
//	func handleEmptyResult() async {
//		withAnimation(.spring()) {
//			isAnalyzing = false
//			scanStatus = .empty
//			notification.notificationOccurred(.warning)
//		}
//		try? await Task.sleep(for: .seconds(2))
//		withAnimation { scanStatus = .ready }
//	}
//	
//	func resetScan() {
//		impact.impactOccurred()
//		withAnimation(.spring()) {
//			detectedResults = []
//			scanStatus = .ready
//		}
//	}
//}
//
//	// MARK: - Instructions
//struct QuickScanInstructionsSheet: View {
//	@Environment(\.dismiss) var dismiss
//	var body: some View {
//		NavigationStack {
//			List {
//				Section {
//					InstructionRow(
//						icon: "bolt.fill",
//						color: .blue,
//						title: "Instant Scan",
//						detail: "Tap once to identify and translate everything in view."
//					)
//					InstructionRow(
//						icon: "camera.viewfinder",
//						color: .orange,
//						title: "Best Results",
//						detail: "Keep your phone 2-3 feet away and ensure good lighting."
//					)
//					InstructionRow(
//						icon: "move.3d",
//						color: .purple,
//						title: "Angles Matter",
//						detail: "Try a 45° angle rather than looking straight down."
//					)
//				}
//			}
//			.navigationTitle("Quick Scan Guide")
//			.navigationBarTitleDisplayMode(.inline)
//			.toolbar {
//				Button("Done") { dismiss() }.fontWeight(.bold)
//			}
//		}
//	}
//}
