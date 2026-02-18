import SwiftUI
import Vision

@available(iOS 26.0, *)
struct QuizCameraView: View {
		// MARK: - Properties
	let quizzes: [FoundationAIService.QuizResult]
	let onFinished: (Int) -> Void
	
	@StateObject private var cameraService = CameraService()
	@State private var detector = ObjectDetector()
	
		// Core State
	@State private var latestPixelBuffer: CVPixelBuffer?
	@State private var currentIndex = 0
	@State private var score = 0
	
		// UI State
	@State private var isDetecting = false
	@State private var showAnswer = false
	@State private var showHelp = false
	@State private var detectionStatus: DetectionStatus = .ready
	@State private var detectionLocked = false
	@State private var pulseScale: CGFloat = 1.0
	
	enum DetectionStatus {
		case ready, detecting, success, failure
	}
	
	private var currentQuiz: FoundationAIService.QuizResult {
		quizzes[currentIndex]
	}
	
	@Environment(\.dismiss) private var dismiss
	private let impact = UIImpactFeedbackGenerator(style: .medium)
	private let notification = UINotificationFeedbackGenerator()
	
		// MARK: - Body
	var body: some View {
		NavigationStack {
			ZStack {
					// Layer 1: Immersive Camera Feed
				CameraPreview(session: cameraService.session)
					.ignoresSafeArea()
				
					// Layer 2: HUD & Feedback
				VStack(spacing: 0) {
						// Left-aligned Target Word Banner
					targetWordBanner
						.padding(.top, 12)
					
					Spacer()
					
					if showAnswer && detectionStatus != .success {
						revealedAnswerToast
							.transition(.move(edge: .top).combined(with: .opacity))
					}
					
					if detectionStatus == .failure {
						failureToast
							.transition(.move(edge: .top).combined(with: .opacity))
					}
					
					if detectionStatus == .success {
						successMatchCard
							.transition(.scale(scale: 0.9).combined(with: .opacity))
					}
					
						// Vertically Centered Detection Hint
					if detectionStatus == .ready && !isDetecting && !showAnswer {
						tapToDetectLabel
					}
					
					Spacer()
					
					bottomActionArea
						.padding(.horizontal, 20)
				}
				
					// Layer 3: Processing State
				if isDetecting {
					ZStack {
						Color.black.opacity(0.35).ignoresSafeArea()
						VStack(spacing: 16) {
							ProgressView()
								.controlSize(.large)
								.tint(.white)
							Text("Analyzing Environment...")
								.font(.headline)
								.foregroundStyle(.white)
						}
					}
				}
			}
			.navigationBarTitleDisplayMode(.inline)
			.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
			.toolbarColorScheme(.dark, for: .navigationBar)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button("End") { dismiss() }
						.foregroundStyle(.red)
						.fontWeight(.semibold)
				}
				
				ToolbarItem(placement: .principal) {
					Text("\(currentIndex + 1) of \(quizzes.count)")
						.font(.system(.subheadline, design: .monospaced).bold())
						.foregroundStyle(.white.opacity(0.8))
				}
				
				ToolbarItem(placement: .topBarTrailing) {
					Button { showHelp = true } label: {
						Image(systemName: "questionmark")
							.font(.title3)
							.symbolRenderingMode(.hierarchical)
					}
				}
			}
			.sheet(isPresented: $showHelp) {
				InstructionsSheet()
			}
			.onAppear {
				setupDetector()
				cameraService.start()
				impact.prepare()
				notification.prepare()
				withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
					pulseScale = 1.02
				}
			}
			.onDisappear { cameraService.stop() }
			.onTapGesture { attemptDetection() }
		}
	}
}

	// MARK: - Logic
private extension QuizCameraView {
	func setupDetector() {
		cameraService.frameHandler = { buffer in self.latestPixelBuffer = buffer }
		detector.onPredictions = { observations in
			guard isDetecting else { return }
			let labels = observations.map { $0.identifier.lowercased() }
			let target = currentQuiz.correctEnglish.lowercased()
			let isMatch = labels.contains { $0.contains(target) || target.contains($0) }
			finalizeDetection(isMatch: isMatch)
		}
	}
	
	func attemptDetection() {
		guard !detectionLocked, detectionStatus != .success, let buffer = latestPixelBuffer else { return }
		detectionLocked = true
		impact.impactOccurred(intensity: 0.8)
		withAnimation(.easeInOut(duration: 0.3)) {
			isDetecting = true
			detectionStatus = .detecting
			showAnswer = false
		}
		detector.detect(from: buffer)
	}
	
	func finalizeDetection(isMatch: Bool) {
		withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
			isDetecting = false
			if isMatch {
				detectionStatus = .success
				score += 1
				notification.notificationOccurred(.success)
			} else {
				detectionStatus = .failure
				notification.notificationOccurred(.error)
				DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
					withAnimation {
						if detectionStatus == .failure {
							detectionStatus = .ready
							detectionLocked = false
						}
					}
				}
			}
		}
	}
	
	func nextObject() {
		if currentIndex + 1 >= quizzes.count {
			onFinished(score)
		} else {
			withAnimation(.spring()) {
				currentIndex += 1
				detectionStatus = .ready
				showAnswer = false
				detectionLocked = false
			}
		}
	}
}

	// MARK: - UI Components
private extension QuizCameraView {
	
	var targetWordBanner: some View {
		HStack {
			VStack(alignment: .leading, spacing: 0) {
				Text("FIND THE OBJECT")
					.font(.system(size: 9, weight: .black))
					.foregroundStyle(.white.opacity(0.6))
					.tracking(1.0)
				
				Text(currentQuiz.translatedWord.uppercased())
					.font(.system(.title3, design: .rounded).bold())
					.foregroundStyle(.white)
			}
			Spacer()
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 10)
		.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
		.padding(.horizontal, 16)
		.shadow(color: .black.opacity(0.1), radius: 5)
	}
	
	var revealedAnswerToast: some View {
		HStack(spacing: 12) {
			Image(systemName: "eye.fill")
				.foregroundColor(.yellow)
			Text("Search for: **\(currentQuiz.correctEnglish.capitalized)**")
				.font(.subheadline.bold())
		}
		.padding(.horizontal, 20)
		.padding(.vertical, 12)
		.background(.ultraThinMaterial, in: Capsule())
		.foregroundStyle(.white)
	}
	
	var tapToDetectLabel: some View {
		HStack(spacing: 10) {
			Image(systemName: "hand.tap.fill")
				.font(.subheadline)
			Text("Tap anywhere to identify")
				.font(.subheadline.bold())
		}
		.foregroundColor(.white)
		.padding(.horizontal, 20)
		.padding(.vertical, 12)
		.background(.black.opacity(0.35), in: Capsule())
		.scaleEffect(pulseScale)
	}
	
	var failureToast: some View {
		HStack(spacing: 12) {
			Image(systemName: "xmark.circle.fill")
				.foregroundColor(.red)
			Text("No match found. Try again!")
				.font(.subheadline.bold())
		}
		.padding()
		.background(.ultraThinMaterial, in: Capsule())
		.foregroundStyle(.white)
	}
	
	var successMatchCard: some View {
		VStack(spacing: 12) {
			Image(systemName: "checkmark.seal.fill")
				.font(.system(size: 44))
				.foregroundStyle(.green)
			
			VStack(spacing: 2) {
				Text("Match Found!")
					.font(.caption.bold())
					.foregroundStyle(.secondary)
				
				HStack(spacing: 8) {
					Text(currentQuiz.correctEnglish.capitalized)
					Text("=")
						.foregroundStyle(.secondary)
					Text(currentQuiz.translatedWord)
						.foregroundColor(.yellow)
				}
				.font(.headline.bold())
			}
		}
		.padding(.vertical, 24)
		.padding(.horizontal, 32)
		.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
	}
	
	var bottomActionArea: some View {
		VStack(spacing: 16) {
			if detectionStatus == .success {
				Button(action: nextObject) {
					HStack {
						Text("Continue Hunt")
						Image(systemName: "arrow.right.circle.fill")
					}
					.font(.headline.bold())
					.frame(maxWidth: .infinity)
					.padding(.vertical, 20)
					.background(Color.blue.gradient, in: Capsule())
					.foregroundColor(.white)
				}
			} else {
				HStack(spacing: 12) {
					Button {
						withAnimation(.spring()) { showAnswer.toggle() }
						impact.impactOccurred()
					} label: {
						Label(showAnswer ? "Hide" : "Show Answer", systemImage: "lightbulb.fill")
							.font(.headline)
							.frame(maxWidth: .infinity)
							.padding(.vertical, 18)
							.background(showAnswer ? .yellow : .white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
							.foregroundColor(.black)
					}
					
					Button(action: nextObject) {
						Label("Skip", systemImage: "chevron.forward.circle")
							.font(.headline)
							.frame(maxWidth: .infinity)
							.padding(.vertical, 18)
							.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
							.foregroundColor(.white)
					}
				}
			}
		}
		.padding(.bottom, 30)
	}
}

	// MARK: - Instruction Sheet
struct InstructionsSheet: View {
	@Environment(\.dismiss) var dismiss
	var body: some View {
		NavigationStack {
			List {
				Section {
					InstructionRow(
						icon: "sun.max.fill",
						color: .orange,
						title: "1. Check Your Lighting",
						detail: "AI works best in bright, even lighting. Avoid dark rooms or heavy shadows for the best accuracy."
					)
					InstructionRow(
						icon: "arrow.up.and.down.and.arrow.left.and.right",
						color: .blue,
						title: "2. Adjust Your Distance",
						detail: "Try to keep the object centered and about 1-2 feet away. Too close or too far can make it harder to identify."
					)
					InstructionRow(
						icon: "camera.viewfinder",
						color: .purple,
						title: "3. Try Different Angles",
						detail: "If it's not working, move your phone! A top-down or side view might help the AI recognize the shape better."
					)
				} header: {
					Text("Optimization Tips")
				}
				
				Section {
					InstructionRow(
						icon: "hand.tap.fill",
						color: .green,
						title: "Verify Instantly",
						detail: "When you think you've found it, tap anywhere on the camera feed to start the analysis."
					)
					InstructionRow(
						icon: "forward.end.fill",
						color: .secondary,
						title: "When to Skip",
						detail: "Some complex objects are tricky for AI. If you're stuck, use Skip to move to the next word and stay in the game!"
					)
				} header: {
					Text("How to Play")
				}
			}
			.navigationTitle("Scavenger Guide")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button {
						dismiss()
					} label : {
						Image(systemName: "xmark")
					}
				}
			}
		}
	}
}
