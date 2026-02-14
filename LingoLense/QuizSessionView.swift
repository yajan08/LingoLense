	//
	//  QuizSessionView.swift
	//  LingoLense
	//

import SwiftUI
import Foundation

@available(iOS 26.0, *)
struct QuizSessionView: View {
	
	let objects: [String]
	
	@State private var quizzes: [FoundationQuizGenerator.QuizResult] = []
	@State private var score: Int = 0
	
	@State private var loading = true
	@State private var showCamera = false
	@State private var showCompletion = false
	
	private let generator = FoundationQuizGenerator()
	
	
	var body: some View {
		
		Group {
			
			if loading {
				loadingView
			}
			
			else if quizzes.isEmpty {
				emptyView
			}
			
			else if showCompletion {
				completionView
			}
			
			else {
				startView
			}
		}
		.task {
			await loadQuiz()
		}
		.fullScreenCover(isPresented: $showCamera) {
			
			QuizCameraView(quizzes: quizzes) { finalScore in
				
				score = finalScore
				showCompletion = true
				showCamera = false
			}
		}
	}
}

//
// MARK: Start View
//

private extension QuizSessionView {
	
	var startView: some View {
		
		VStack(spacing: 24) {
			
			Spacer()
			
			Image(systemName: "camera.viewfinder")
				.font(.system(size: 56))
				.foregroundColor(.secondary)
			
			Text("Object Quiz")
				.font(.title.bold())
			
			Text("\(quizzes.count) objects")
				.font(.subheadline)
				.foregroundColor(.secondary)
			
			Spacer()
			
			Button {
				showCamera = true
			} label: {
				
				Text("Start")
					.font(.headline)
					.frame(maxWidth: .infinity)
					.padding()
					.background(Color.blue)
					.foregroundColor(.white)
					.cornerRadius(12)
			}
		}
		.padding(24)
	}
}

//
// MARK: Loading
//

private extension QuizSessionView {
	
	var loadingView: some View {
		
		ProgressView("Preparing Quiz")
			.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

//
// MARK: Empty
//

private extension QuizSessionView {
	
	var emptyView: some View {
		
		VStack(spacing: 12) {
			
			Image(systemName: "tray")
				.font(.system(size: 40))
				.foregroundColor(.secondary)
			
			Text("No quiz available")
				.font(.headline)
			
			Text("Scan objects first")
				.font(.subheadline)
				.foregroundColor(.secondary)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

//
// MARK: Completion
//

private extension QuizSessionView {
	
	var completionView: some View {
		
		VStack(spacing: 24) {
			
			Spacer()
			
			Image(systemName: scoreIcon)
				.font(.system(size: 56))
				.foregroundColor(scoreColor)
			
			Text("Quiz Complete")
				.font(.title.bold())
			
			Text("\(score) / \(quizzes.count)")
				.font(.system(size: 44, weight: .bold))
			
			Spacer()
			
			Button {
				showCompletion = false
			} label: {
				
				Text("Done")
					.font(.headline)
					.frame(maxWidth: .infinity)
					.padding()
					.background(Color.primary)
					.foregroundColor(.white)
					.cornerRadius(12)
			}
		}
		.padding(24)
	}
}

//
// MARK: Score Helpers
//

private extension QuizSessionView {
	
	var scorePercent: Double {
		guard quizzes.count > 0 else { return 0 }
		return Double(score) / Double(quizzes.count)
	}
	
	var scoreIcon: String {
		
		if scorePercent == 1.0 {
			return "star.fill"
		}
		
		if scorePercent >= 0.7 {
			return "checkmark.circle.fill"
		}
		
		return "circle"
	}
	
	var scoreColor: Color {
		
		if scorePercent == 1.0 {
			return .yellow
		}
		
		if scorePercent >= 0.7 {
			return .green
		}
		
		return .secondary
	}
}

//
// MARK: Load Quiz
//

private extension QuizSessionView {
	
	func loadQuiz() async {
		
		loading = true
		
		let result = await generator.generateQuizSession(from: objects)
		
		await MainActor.run {
			
			quizzes = result
			score = 0
			loading = false
		}
	}
}
