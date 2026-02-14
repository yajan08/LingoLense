import SwiftUI
import Foundation

@available(iOS 26.0, *)
struct QuizSessionView: View {
	
	let objects: [String]
	
	@State private var quizzes: [FoundationQuizGenerator.QuizResult] = []
	@State private var currentIndex: Int = 0
	@State private var score: Int = 0
	@State private var loading: Bool = true
	
	private let generator = FoundationQuizGenerator()
	
	
	var body: some View {
		
		Group {
			
			if loading {
				loadingView
			}
			
			else if quizzes.isEmpty {
				emptyView
			}
			
			else if currentIndex >= quizzes.count {
				completionView
			}
			
			else {
				QuizQuestionCard(
					quiz: quizzes[currentIndex],
					questionNumber: currentIndex + 1,
					totalQuestions: quizzes.count
				) { correct in
					
					handleAnswer(correct)
				}
				.id(currentIndex) // forces fresh view every question
				.transition(.opacity)
			}
		}
		.animation(.easeInOut(duration: 0.25), value: currentIndex)
		.padding(24)
		.task {
			await loadQuiz()
		}
	}
}

private extension QuizSessionView {
	
	var loadingView: some View {
		
		VStack(spacing: 18) {
			
			ProgressView()
				.scaleEffect(1.4)
			
			Text("Preparing quiz...")
				.font(.headline)
				.foregroundColor(.secondary)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

private extension QuizSessionView {
	
	var emptyView: some View {
		
		VStack(spacing: 12) {
			
			Image(systemName: "exclamationmark.circle")
				.font(.system(size: 40))
				.foregroundColor(.secondary)
			
			Text("No quiz available")
				.font(.headline)
			
			Text("Try scanning more objects")
				.foregroundColor(.secondary)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

private extension QuizSessionView {
	
	var completionView: some View {
		
		VStack(spacing: 24) {
			
			Spacer()
			
			Image(systemName: completionIcon)
				.font(.system(size: 60))
				.foregroundColor(completionColor)
			
			Text("Quiz Complete")
				.font(.largeTitle.bold())
			
			Text("\(score) / \(quizzes.count)")
				.font(.system(size: 48, weight: .bold))
			
			Text(scoreText)
				.font(.headline)
				.foregroundColor(.secondary)
			
			Spacer()
		}
		.frame(maxWidth: .infinity)
	}
	
	
	var scoreText: String {
		
		guard quizzes.count > 0 else { return "" }
		
		let percent = Double(score) / Double(quizzes.count)
		
		switch percent {
				
			case 1.0:
				return "Perfect"
				
			case 0.7...:
				return "Great job"
				
			case 0.4...:
				return "Good effort"
				
			default:
				return "Keep practicing"
		}
	}
	
	
	var completionIcon: String {
		
		guard quizzes.count > 0 else { return "circle" }
		
		let percent = Double(score) / Double(quizzes.count)
		
		switch percent {
				
			case 1.0:
				return "star.fill"
				
			case 0.7...:
				return "checkmark.circle.fill"
				
			default:
				return "circle"
		}
	}
	
	
	var completionColor: Color {
		
		guard quizzes.count > 0 else { return .secondary }
		
		let percent = Double(score) / Double(quizzes.count)
		
		switch percent {
				
			case 1.0:
				return .yellow
				
			case 0.7...:
				return .green
				
			default:
				return .secondary
		}
	}
}

private extension QuizSessionView {
	
	func handleAnswer(_ correct: Bool) {
		
		if correct {
			score += 1
		}
		
		currentIndex += 1
	}
	
	
	func loadQuiz() async {
		
		loading = true
		
		let result = await generator.generateQuizSession(from: objects)
		
		await MainActor.run {
			
			quizzes = result
			currentIndex = 0
			score = 0
			loading = false
		}
	}
}


	//import SwiftUI
//import Foundation
//
//@available(iOS 26.0, *)
//struct QuizSessionView: View {
//	
//	let objects: [String]
//	
//	@State private var quizzes: [FoundationQuizGenerator.QuizResult] = []
//	@State private var currentIndex = 0
//	@State private var score = 0
//	@State private var loading = true
//	
//	private let generator = FoundationQuizGenerator()
//	
//	
//	var body: some View {
//		
//		Group {
//			
//			if loading {
//				loadingView
//			}
//			
//			else if currentIndex >= quizzes.count {
//				completionView
//			}
//			
//			else {
//				QuizQuestionCard(
//					quiz: quizzes[currentIndex],
//					allObjects: objects,
//					questionNumber: currentIndex + 1,
//					totalQuestions: quizzes.count
//				) { correct in
//					
//					if correct {
//						score += 1
//					}
//					
//					withAnimation(.easeInOut(duration: 0.25)) {
//						currentIndex += 1
//					}
//				}
//				.id(currentIndex) // ✅ CRITICAL FIX
//			}
//		}
//		.padding(24)
//		.task {
//			await loadQuiz()
//		}
//	}
//}
//private extension QuizSessionView {
//	
//	var loadingView: some View {
//		
//		VStack(spacing: 16) {
//			
//			ProgressView()
//				.scaleEffect(1.4)
//			
//			Text("Preparing quiz...")
//				.foregroundColor(.secondary)
//		}
//	}
//}
//private extension QuizSessionView {
//	
//	var completionView: some View {
//		
//		VStack(spacing: 20) {
//			
//			Text("Quiz Complete")
//				.font(.largeTitle.bold())
//			
//			Text("\(score) / \(quizzes.count)")
//				.font(.system(size: 42, weight: .bold))
//			
//			Text(scoreText)
//				.foregroundColor(.secondary)
//		}
//	}
//	
//	
//	var scoreText: String {
//		
//		let percent = Double(score) / Double(quizzes.count)
//		
//		switch percent {
//			case 1.0: return "Perfect"
//			case 0.7...: return "Great job"
//			case 0.4...: return "Good effort"
//			default: return "Keep practicing"
//		}
//	}
//}
//private extension QuizSessionView {
//	
//	func loadQuiz() async {
//		
//		quizzes = await generator.generateQuizSession(from: objects)
//		
//		await MainActor.run {
//			loading = false
//		}
//	}
//}
//
