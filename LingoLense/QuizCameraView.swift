//
//  QuizCameraView.swift
//  LingoLense
//
//  Created by SDC-USER on 14/02/26.
//

import SwiftUI
import Vision

struct QuizCameraView: View {
	
	let expectedObject: String
	let onDetected: (Bool) -> Void
	
	
	@StateObject private var cameraService = CameraService()
	@State private var detector = ObjectDetector()
	
	@State private var latestPixelBuffer: CVPixelBuffer?
	
	@State private var isDetecting = false
	@State private var showResult = false
	@State private var isCorrect = false
	
	
	var body: some View {
		
		ZStack {
			
			CameraPreview(session: cameraService.session)
				.ignoresSafeArea()
				.onTapGesture {
					captureAndDetect()
				}
			
			
			overlay
			
		}
		.onAppear {
			setupCamera()
		}
		.onDisappear {
			cameraService.stop()
		}
	}
}

private extension QuizCameraView {
	
	func setupCamera() {
		
		cameraService.frameHandler = { pixelBuffer in
			
				// ONLY store latest frame
			latestPixelBuffer = pixelBuffer
		}
		
		cameraService.start()
	}
}

private extension QuizCameraView {
	
	func captureAndDetect() {
		
		guard !isDetecting else { return }
		
		guard let pixelBuffer = latestPixelBuffer else {
			return
		}
		
		isDetecting = true
		
		detector.onPredictions = { results in
			
			DispatchQueue.main.async {
				
				isDetecting = false
				
				let identifiers = results.map {
					$0.identifier.lowercased()
				}
				
				isCorrect = identifiers.contains(
					expectedObject.lowercased()
				)
				
				showResult = true
				
				onDetected(isCorrect)
			}
		}
		
		detector.detect(from: pixelBuffer)
	}
}

private extension QuizCameraView {
	
	var overlay: some View {
		
		VStack {
			
			Spacer()
			
			VStack(spacing: 10) {
				
				Text("Find this object")
					.foregroundColor(.secondary)
				
				Text(expectedObject.capitalized)
					.font(.largeTitle.bold())
				
				
				Text("Tap screen to detect")
					.font(.subheadline)
					.foregroundColor(.secondary)
				
				
				if showResult {
					
					Text(isCorrect ? "Correct" : "Incorrect")
						.font(.headline)
						.foregroundColor(isCorrect ? .green : .red)
				}
			}
			.padding()
			.background(.ultraThinMaterial)
			.cornerRadius(20)
			.padding(.bottom, 40)
		}
	}
}
