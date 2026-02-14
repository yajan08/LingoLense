import Foundation
import FoundationModels

@available(iOS 26.0, *)
final class FoundationQuizGenerator {
	
	private let model = SystemLanguageModel.default
	
	struct QuizResult: Identifiable {
		let id = UUID()
		let frenchWord: String
		let correctEnglish: String
	}
	
	
		// MARK: Generate full quiz session
	
	func generateQuizSession(from objects: [String]) async -> [QuizResult] {
		
		guard model.isAvailable else {
			print("❌ Model unavailable")
			return []
		}
		
		let cleaned = cleanObjects(objects)
		
		var results: [QuizResult] = []
		
		for object in cleaned {
			
			if let quiz = await translate(object) {
				results.append(quiz)
			}
		}
		
		return results.shuffled()
	}
	
	
		// MARK: Translate single object
	
	private func translate(_ object: String) async -> QuizResult? {
		
		let prompt = """
		Translate this everyday object to French.
		
		Object: \(object)
		
		Return ONLY the French word.
		"""
		
		do {
			
			let session = LanguageModelSession()
			
			let response = try await session.respond(to: prompt)
			
			let french = response.content
				.trimmingCharacters(in: .whitespacesAndNewlines)
				.lowercased()
			
			guard !french.isEmpty else { return nil }
			
			return QuizResult(
				frenchWord: french,
				correctEnglish: object
			)
			
		} catch {
			
			print("❌ Translation error:", error)
			return nil
		}
	}
	
	
		// MARK: Clean objects
	
	private func cleanObjects(_ objects: [String]) -> [String] {
		
		let blocked: Set<String> = [
			"consumer_electronics",
			"electronics",
			"device",
			"equipment",
			"machine",
			"system",
			"structure",
			"material",
			"object",
			"utensil",
			"furniture"
		]
		
		return Array(
			Set(
				objects
					.map { $0.lowercased() }
					.filter { !blocked.contains($0) }
			)
		)
	}
}
