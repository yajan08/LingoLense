import SwiftUI
import Vision
import CoreVideo

@available(iOS 26.0, *)
struct QuizCameraView: View {
		// MARK: - Properties
	let quizzes: [FoundationQuizGenerator.QuizResult]
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
	
	private var currentQuiz: FoundationQuizGenerator.QuizResult {
		quizzes[currentIndex]
	}
	
	@Environment(\.dismiss) private var dismiss
	
		// Native Haptic Generators
	private let impact = UIImpactFeedbackGenerator(style: .medium)
	private let notification = UINotificationFeedbackGenerator()
	
		// MARK: - Body
	var body: some View {
		NavigationStack {
			ZStack {
					// Layer 1: Fullscreen Camera
				CameraPreview(session: cameraService.session)
					.ignoresSafeArea()
				
					// Layer 2: Visual Guidance (Reticle)
				scanningReticle
				
					// Layer 3: Dynamic Overlays (Toasts & Cards)
				VStack {
					Spacer()
					
					statusToast
						.padding(.bottom, 12)
					
					bottomActionCard
				}
			}
				// Standard Navigation Setup
			.navigationBarTitleDisplayMode(.inline)
			.toolbarBackground(.ultraThinMaterial, for: .navigationBar)
			.toolbarColorScheme(.dark, for: .navigationBar)
			.toolbar {
					// Leading: Standard Exit Action
				ToolbarItem(placement: .topBarLeading) {
					Button("End", role: .destructive) {
						dismiss()
					}
					.fontWeight(.semibold)
				}
				
					// Principal: BOLDER, BIGGER WHITE TEXT
				ToolbarItem(placement: .principal) {
					VStack(spacing: 0) {
						Text("FIND THE OBJECT")
							.font(.system(size: 11, weight: .black))
							.foregroundStyle(.white.opacity(0.8))
							.tracking(1.0)
						
						Text(currentQuiz.frenchWord.uppercased())
							.font(.system(size: 20, weight: .bold, design: .rounded))
							.foregroundStyle(.white)
					}
				}
				
					// Trailing: Native Progress & Info
				ToolbarItem(placement: .topBarTrailing) {
					HStack(spacing: 12) {
						Text("\(currentIndex + 1)/\(quizzes.count)")
							.font(.system(size: 12, weight: .bold, design: .monospaced))
							.foregroundStyle(.secondary)
						
						Button {
							showHelp = true
						} label: {
							Image(systemName: "questionmark.circle.fill")
								.symbolRenderingMode(.hierarchical)
						}
					}
				}
			}
			.ignoresSafeArea(.all, edges: .bottom)
			.sheet(isPresented: $showHelp) {
				InstructionsSheet()
			}
			.onAppear {
				setupCamera()
				impact.prepare()
				notification.prepare()
				
				withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
					pulseScale = 1.05
				}
			}
			.onDisappear {
				cameraService.stop()
			}
			.onTapGesture {
				attemptDetection()
			}
		}
	}
}

	// MARK: - Logic & Detection
private extension QuizCameraView {
	func setupCamera() {
		cameraService.frameHandler = { pixelBuffer in
			self.latestPixelBuffer = pixelBuffer
		}
		cameraService.start()
	}
	
	func attemptDetection() {
		guard !detectionLocked, detectionStatus != .success, let pixelBuffer = latestPixelBuffer else { return }
		
		detectionLocked = true
		impact.impactOccurred(intensity: 0.7)
		
		withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
			isDetecting = true
			detectionStatus = .detecting
		}
		
		detector.onPredictions = { results in
			DispatchQueue.main.async {
				let identifiers = results.map { $0.identifier.lowercased() }
				let isMatch = identifiers.contains(currentQuiz.correctEnglish.lowercased())
				
				withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
					isDetecting = false
					if isMatch {
						detectionStatus = .success
						score += 1
						notification.notificationOccurred(.success)
					} else {
						detectionStatus = .failure
						notification.notificationOccurred(.error)
						
						DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
							if detectionStatus == .failure {
								withAnimation {
									detectionStatus = .ready
									detectionLocked = false
								}
							}
						}
					}
				}
				if isMatch { detectionLocked = true }
			}
		}
		detector.detect(from: pixelBuffer)
	}
	
	func nextObject() {
		withAnimation(.spring()) {
			if currentIndex + 1 >= quizzes.count {
				onFinished(score)
			} else {
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
	
	var scanningReticle: some View {
		ZStack {
			Color.black.opacity(isDetecting ? 0.4 : 0.15).ignoresSafeArea()
			
			VStack(spacing: 30) {
					// Focus Dotted Reticle
				RoundedRectangle(cornerRadius: 60, style: .continuous)
					.stroke(
						reticleColor,
						style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [14, 12])
					)
					.frame(width: 300, height: 300)
					.overlay {
						if isDetecting {
							ProgressView().controlSize(.large).tint(.white)
						}
						
						VStack(spacing: 12) {
							if detectionStatus == .success {
								Image(systemName: "checkmark.seal.fill")
									.font(.system(size: 60))
									.foregroundStyle(.green)
								Text(currentQuiz.correctEnglish.capitalized)
									.font(.title2.bold())
									.foregroundColor(.white)
							} else if detectionStatus == .failure {
								Image(systemName: "exclamationmark.triangle.fill")
									.font(.system(size: 60))
									.foregroundStyle(.red)
								Text("No Match Found")
									.font(.headline)
									.foregroundColor(.white)
							}
						}
					}
				
				if detectionStatus == .ready {
					VStack(spacing: 8) {
						Image(systemName: "hand.tap.fill")
							.font(.title3)
						Text("Tap to scan for the \(currentQuiz.frenchWord.lowercased())")
							.font(.system(.subheadline, design: .rounded).weight(.bold))
					}
					.foregroundColor(.white)
					.scaleEffect(pulseScale)
					.padding(.horizontal, 24)
					.padding(.vertical, 12)
					.background(.ultraThinMaterial, in: Capsule())
				}
			}
			.offset(y: -50)
		}
		.animation(.spring(response: 0.4, dampingFraction: 0.7), value: detectionStatus)
	}
	
	var reticleColor: Color {
		switch detectionStatus {
			case .success: return .green
			case .failure: return .red
			case .detecting: return .yellow
			default: return .white.opacity(0.8)
		}
	}
	
	var statusToast: some View {
		Group {
			if showAnswer {
				HStack(spacing: 12) {
					Image(systemName: "lightbulb.fill")
						.foregroundStyle(.orange)
					Text("\(currentQuiz.frenchWord.capitalized) = **\(currentQuiz.correctEnglish.lowercased())**")
						.font(.subheadline)
				}
				.padding(.horizontal, 20)
				.padding(.vertical, 12)
				.background(.ultraThinMaterial, in: Capsule())
				.shadow(color: .black.opacity(0.1), radius: 10)
				.transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity),
										removal: .opacity))
			}
		}
	}
	
	var bottomActionCard: some View {
		VStack(spacing: 24) {
			if detectionStatus == .success {
				nativeButton(title: "Continue", color: .blue) { nextObject() }
			} else {
				HStack(spacing: 16) {
					secondaryButton(title: "Hint", icon: "eye.fill") {
						withAnimation(.spring()) { showAnswer.toggle() }
					}
					
					secondaryButton(title: "Skip", icon: "chevron.right.2") {
						nextObject()
					}
				}
			}
		}
		.padding(.horizontal, 24)
		.padding(.top, 24)
		.padding(.bottom, 44)
		.background(.ultraThinMaterial)
		.clipShape(RoundedCorner(radius: 40, corners: [.topLeft, .topRight]))
	}
}

	// MARK: - Instruction Sheet
struct InstructionsSheet: View {
	@Environment(\.dismiss) var dismiss
	
	var body: some View {
		NavigationStack {
			List {
				Section("How to Scan") {
					InstructionRow(icon: "sun.max.fill", color: .orange, title: "Lighting", detail: "Bright, even lighting helps the camera identify objects clearly.")
					InstructionRow(icon: "viewfinder", color: .blue, title: "Alignment", detail: "Center the target object inside the dotted reticle.")
					InstructionRow(icon: "hand.tap.fill", color: .purple, title: "Action", detail: "Tap anywhere on the camera view to trigger a scan.")
				}
				
				Section("Stuck?") {
					InstructionRow(icon: "eye.fill", color: .indigo, title: "Hint", detail: "Tap Hint to see what the French word means in English.")
					InstructionRow(icon: "forward.end.fill", color: .secondary, title: "Skip", detail: "If the AI isn't picking up the object, you can skip to stay in the flow.")
				}
			}
			.navigationTitle("AI Guide")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button("Done") { dismiss() }.fontWeight(.bold)
				}
			}
		}
	}
}

struct InstructionRow: View {
	let icon: String; let color: Color; let title: String; let detail: String
	var body: some View {
		HStack(alignment: .top, spacing: 16) {
			Image(systemName: icon)
				.font(.title3)
				.foregroundStyle(.white)
				.frame(width: 36, height: 36)
				.background(color, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
			
			VStack(alignment: .leading, spacing: 2) {
				Text(title).font(.headline)
				Text(detail).font(.subheadline).foregroundStyle(.secondary)
			}
		}
		.padding(.vertical, 4)
	}
}

	// MARK: - Native Styled Components
func nativeButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
	Button(action: action) {
		Text(title)
			.font(.headline)
			.frame(maxWidth: .infinity)
			.padding(.vertical, 18)
			.background(color, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
			.foregroundColor(.white)
	}
	.buttonStyle(.plain)
}

func secondaryButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
	Button(action: action) {
		Label(title, systemImage: icon)
			.font(.subheadline.bold())
			.frame(maxWidth: .infinity)
			.padding(.vertical, 16)
			.background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
	}
	.buttonStyle(.plain)
}

struct RoundedCorner: Shape {
	var radius: CGFloat = .infinity
	var corners: UIRectCorner = .allCorners
	func path(in rect: CGRect) -> Path {
		let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
		return Path(path.cgPath)
	}
}
