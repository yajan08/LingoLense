import SwiftUI

@available(iOS 26.0, *)
struct QuizQuestionCard: View {
	
	let quiz: FoundationQuizGenerator.QuizResult
	let questionNumber: Int
	let totalQuestions: Int
	
	let onAnswered: (Bool) -> Void
	
	
	@State private var showCamera = false
	@State private var detectedCorrect = false
	@State private var hasAnswered = false
	
	
	var body: some View {
		
		VStack(spacing: 32) {
			
			header
			
			Spacer()
			
			question
			
			Spacer()
			
			detectButton
			
			if hasAnswered {
				
				resultView
				
				nextButton
					.transition(.opacity)
			}
			
			Spacer()
		}
		.padding(24)
		.fullScreenCover(isPresented: $showCamera) {
			
			QuizCameraView(
				expectedObject: quiz.correctEnglish
			) { correct in
				
				detectedCorrect = correct
				hasAnswered = true
				showCamera = false
			}
		}
	}
}

private extension QuizQuestionCard {
	
	var header: some View {
		
		HStack {
			
			Text("Question \(questionNumber)")
				.font(.subheadline)
				.foregroundColor(.secondary)
			
			Spacer()
			
			Text("\(questionNumber)/\(totalQuestions)")
				.font(.subheadline)
				.foregroundColor(.secondary)
		}
	}
}

private extension QuizQuestionCard {
	
	var question: some View {
		
		VStack(spacing: 12) {
			
			Text("Find this object")
				.font(.headline)
				.foregroundColor(.secondary)
			
			Text(quiz.frenchWord.capitalized)
				.font(.system(size: 44, weight: .bold))
				.multilineTextAlignment(.center)
		}
	}
}

private extension QuizQuestionCard {
	
	var detectButton: some View {
		
		Button {
			showCamera = true
		} label: {
			
			HStack {
				
				Image(systemName: "camera.fill")
				
				Text("Open Camera")
					.fontWeight(.semibold)
			}
			.frame(maxWidth: .infinity)
			.padding()
			.background(Color.blue)
			.foregroundColor(.white)
			.cornerRadius(14)
		}
	}
}

private extension QuizQuestionCard {
	
	var resultView: some View {
		
		HStack(spacing: 8) {
			
			Image(systemName:
					detectedCorrect
				  ? "checkmark.circle.fill"
				  : "xmark.circle.fill"
			)
			
			Text(
				detectedCorrect
				? "Correct"
				: "Not detected"
			)
			.fontWeight(.semibold)
			
		}
		.foregroundColor(
			detectedCorrect
			? .green
			: .red
		)
		.font(.headline)
	}
}

private extension QuizQuestionCard {
	
	var nextButton: some View {
		
		Button {
			
			onAnswered(detectedCorrect)
			
		} label: {
			
			Text("Next")
				.font(.headline)
				.frame(maxWidth: .infinity)
				.padding()
				.background(Color.blue)
				.foregroundColor(.white)
				.cornerRadius(14)
		}
	}
}
