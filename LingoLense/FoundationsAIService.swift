import Foundation
import FoundationModels
import SwiftUI
import Combine

	/// A unified service to handle Apple Intelligence tasks: Object Filtering and Quiz Generation.
@available(iOS 26.0, *)
final class FoundationAIService: ObservableObject {
	
	private let model = SystemLanguageModel.default
	
	@AppStorage("selected_language")
	private var selectedLanguageRaw = AppLanguage.french.rawValue
	
	struct QuizResult: Identifiable {
		let id = UUID()
		let translatedWord: String
		let correctEnglish: String
	}
	
		// MARK: - Object Filtering (FoundationObjectFilter Logic)
	
	func filterObjects(from predictions: [String]) async -> [String] {
		guard model.isAvailable else {
			print("❌ Foundation model not available")
			return []
		}
		
		let session = LanguageModelSession()
		
		let prompt = """
		From this list of detected items:
		\(predictions.joined(separator: ", "))
		
		Task: Identify objects or things and remove all generic terms that depict general categories.
		
		Strict Rules:
		1. Return ONLY the specific names of physical objects or things.
		2. If NO specific objects are found in the list, return the exact word: "NONE".
		3. NEVER return generic categories or environment descriptions such as: structure, system, machine, equipment, object, material, architecture, electronics, consumer_electronics, bathroom, interior, room, textile, adult, people, conveyance, elevator, appliance, health_club, hospital, outdoor, sky, wood_processsed, screenshot, portal, illustrations. Exclude all the words given above from the result.
		
		Output Format: A comma-separated list of objects, or the single word "NONE".
		"""
		
		do {
			let response = try await session.respond(to: prompt)
			let text = response.content.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
			
				// 1. Check for the fallback keyword
			if text == "none" || text.isEmpty {
				return []
			}
			
			let objects = text
				.replacingOccurrences(of: "\n", with: "")
				.split(separator: ",")
				.map { $0.trimmingCharacters(in: .whitespaces) }
				.filter { item in
						// Ensure the item is not empty
					!item.isEmpty
				}
			
			return objects
			
		} catch {
			print("❌ Model error:", error)
			return []
		}
	}
	
		// MARK: - Quiz Generation (FoundationQuizGenerator Logic)
	
	func generateQuizSession(from objects: [String]) async -> [QuizResult] {
		guard model.isAvailable else {
			print("❌ Model unavailable")
			return []
		}
		
		var results: [QuizResult] = []
		
		for object in objects {
			if let quiz = await translate(object) {
				results.append(quiz)
			}
		}
		
		return results.shuffled()
	}
	
		// MARK: - Translation Logic
	
	private func translate(_ object: String) async -> QuizResult? {
		
		let prompt = """
		You are a translation expert in all languages.
		Translate '\(object)' to \(selectedLanguageRaw).
		
		Return ONLY the translated word.
		"""
		
		do {
			let session = LanguageModelSession()
			let response = try await session.respond(to: prompt)
			
			let french = response.content
				.trimmingCharacters(in: .whitespacesAndNewlines)
				.lowercased()
			
			guard !french.isEmpty else { return nil }
			
			return QuizResult(
				translatedWord: french,
				correctEnglish: object
			)
			
		} catch {
			print("❌ Translation error:", error)
			return nil
		}
	}
}
