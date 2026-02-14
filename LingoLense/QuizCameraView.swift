	//
	//  QuizCameraView.swift
	//  LingoLense
	//

import SwiftUI
import Vision

@available(iOS 26.0, *)
struct QuizCameraView: View {
	
	let quizzes: [FoundationQuizGenerator.QuizResult]
	let onFinished: (Int) -> Void
	
	@StateObject private var cameraService = CameraService()
	@State private var detector = ObjectDetector()
	
	@State private var latestPixelBuffer: CVPixelBuffer?
	
	@State private var currentIndex = 0
	@State private var score = 0
	
	@State private var isDetecting = false
	@State private var isCorrect = false
	@State private var showAnswer = false
	
	@State private var detectionLocked = false
	
	private var currentQuiz: FoundationQuizGenerator.QuizResult {
		quizzes[currentIndex]
	}
	
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		
		GeometryReader { geometry in
			
			ZStack {
				
					// Fullscreen camera
				CameraPreview(session: cameraService.session)
					.ignoresSafeArea()
				
				VStack {
					
					topBar(safeAreaTop: geometry.safeAreaInsets.top)
						.padding(.horizontal)
					
					Spacer()
					
					bottomCard
				}
				
				if showAnswer {
					answerOverlay
						.transition(.opacity)
				}
				
				if isDetecting {
					detectingOverlay
				}
			}
			.ignoresSafeArea()
			.statusBarHidden()
			.onAppear { setupCamera() }
			.onDisappear { cameraService.stop() }
			.onTapGesture {
				attemptDetection()
			}
		}
	}
}

//
// MARK: Camera Setup
//
private extension QuizCameraView {
	func setupCamera() {
		cameraService.frameHandler = { pixelBuffer in
			latestPixelBuffer = pixelBuffer
		}
		cameraService.start()
	}
}

//
// MARK: Detection
//
private extension QuizCameraView {
	func attemptDetection() {
		
		guard !detectionLocked else { return }
		guard !isCorrect else { return }
		guard let pixelBuffer = latestPixelBuffer else { return }
		
		detectionLocked = true
		isDetecting = true
		
		detector.onPredictions = { results in
			DispatchQueue.main.async {
				defer {
					isDetecting = false
					detectionLocked = false
				}
				
				let identifiers = results.map { $0.identifier.lowercased() }
				
				if identifiers.contains(currentQuiz.correctEnglish.lowercased()) {
					isCorrect = true
					showAnswer = true
					score += 1
				}
			}
		}
		
		detector.detect(from: pixelBuffer)
	}
}

//
// MARK: Navigation
//
private extension QuizCameraView {
	func nextObject() {
		if currentIndex + 1 >= quizzes.count {
			onFinished(score)
			return
		}
		currentIndex += 1
		isCorrect = false
		showAnswer = false
		detectionLocked = false
	}
	
	func revealAnswer() {
		showAnswer = true
	}
}

//
// MARK: Top Bar (Floating Rounded Glass + End Quiz Button)
//
private extension QuizCameraView {
	
	func topBar(safeAreaTop: CGFloat) -> some View {
		HStack {
			
			VStack(alignment: .leading, spacing: 4) {
				Text("Find this object")
					.font(.subheadline)
					.foregroundStyle(.secondary)
				
				Text(currentQuiz.frenchWord.capitalized)
					.font(.largeTitle.weight(.bold))
					.foregroundStyle(.primary)
			}
			
			Spacer()
			
			VStack {
				Text("\(currentIndex + 1) / \(quizzes.count)")
					.font(.subheadline)
					.foregroundStyle(.secondary)
				
				Button {
					dismiss()
				} label: {
					Text("End Quiz")
						.font(.subheadline.weight(.semibold))
						.padding(6)
						.padding(.horizontal, 8)
						.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
						.foregroundStyle(.red)
				}
				
			}
		}
		.padding()
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 20))
		.shadow(radius: 4)
		.padding(.top, safeAreaTop + 8)
	}
}

//
// MARK: Bottom Card
//
private extension QuizCameraView {
	
	var bottomCard: some View {
		VStack(spacing: 18) {
			
			if !isCorrect {
				VStack(spacing: 6) {
					Label("Tap to detect", systemImage: "viewfinder")
						.font(.headline)
						.foregroundStyle(.secondary)
					
					Text("Try again if incorrect")
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
			}
			
			if !isCorrect {
				HStack(spacing: 12) {
					Button { revealAnswer() } label: {
						Text("Show Answer")
							.frame(maxWidth: .infinity)
							.padding()
							.background(.orange)
							.foregroundColor(.white)
							.cornerRadius(12)
					}
					
					Button { nextObject() } label: {
						Text("Next Word")
							.frame(maxWidth: .infinity)
							.padding()
							.background(.blue)
							.foregroundColor(.white)
							.cornerRadius(12)
					}
				}
			}
			
			if isCorrect {
				Label("Correct", systemImage: "checkmark.circle.fill")
					.font(.headline)
					.foregroundStyle(.green)
				
				Button { nextObject() } label: {
					Text("Next Word")
						.frame(maxWidth: .infinity)
						.padding()
						.background(.primary)
						.foregroundColor(.white)
						.cornerRadius(12)
				}
			}
		}
		.padding()
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 20))
		.padding(.horizontal)
		.padding(.bottom, 20)
	}
}

//
// MARK: Answer Overlay
//
private extension QuizCameraView {
	
	var answerOverlay: some View {
		VStack {
			Spacer()
			
			VStack(spacing: 10) {
				Text("Scan this object")
					.font(.subheadline)
					.foregroundStyle(.secondary)
				
				Text(currentQuiz.correctEnglish.capitalized)
					.font(.system(size: 42, weight: .bold))
					.multilineTextAlignment(.center)
			}
			.padding(20)
			.background(.ultraThinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 20))
			
			Spacer()
		}
		.padding()
	}
}

//
// MARK: Detecting Overlay
//
private extension QuizCameraView {
	
	var detectingOverlay: some View {
		ZStack {
			Color.black.opacity(0.3)
				.ignoresSafeArea()
			
			ProgressView()
				.scaleEffect(1.4)
				.padding(30)
				.background(.ultraThinMaterial)
				.clipShape(RoundedRectangle(cornerRadius: 16))
		}
	}
}
