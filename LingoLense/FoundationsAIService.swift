import Foundation
import FoundationModels
import SwiftUI
import Combine

@available(iOS 26.0, *)
final actor FoundationAIService: ObservableObject {
	
		// MARK: - Model
	private let model = SystemLanguageModel.default
	
	@AppStorage("selected_language")
	private var selectedLanguageRaw = AppLanguage.french.rawValue
	
		// Using a shared session for most tasks, but we'll use local ones for generation
		// to avoid "Context Contamination" which often triggers safety guardrails.
	private var sharedSession: LanguageModelSession?
	
		// MARK: - Models
	struct QuizResult: Identifiable, Sendable {
		let id = UUID()
		let translatedWord: String
		let correctEnglish: String
	}
	
	struct BilingualSentence: Sendable {
		let english: String
		let translated: String
	}
	
		// MARK: - PREWARM
	nonisolated func prewarm() {
		Task.detached(priority: .utility) {
			guard SystemLanguageModel.default.isAvailable else { return }
				// Warming up the system intelligence
			let _ = LanguageModelSession()
		}
	}
	
		// MARK: - Object Filtering
	func filterObjects(from predictions: [String]) async -> [String] {
		guard model.isAvailable else { return [] }
		
			// Safety-Hardened Prompt
		let prompt = """
		Analyze these labels: \(predictions.joined(separator: ", "))
		Extract only specific, concrete, physical objects.
		Remove all: environments, abstract concepts, and generic categories (like 'structure' or 'electronics').
		Output: Comma-separated list of nouns only. If none, return 'NONE'.
		"""
		
		do {
			let session = LanguageModelSession()
			let response = try await session.respond(to: prompt)
			let text = response.content.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
			
			if text.contains("none") || text.isEmpty { return [] }
			
			return text.components(separatedBy: ",")
				.map { $0.trimmingCharacters(in: .whitespaces) }
				.filter { !$0.isEmpty }
		} catch {
			return []
		}
	}
	
		// MARK: - Quiz Generation (Batched for Speed)
	func generateQuizSession(from objects: [String]) async -> [QuizResult] {
		guard !objects.isEmpty else { return [] }
		
			// We process these in a group to allow Apple Intelligence to optimize power usage
		return await withTaskGroup(of: QuizResult?.self) { group in
			for object in objects {
				group.addTask {
					await self.translate(object)
				}
			}
			
			var results: [QuizResult] = []
			for await result in group {
				if let result = result { results.append(result) }
			}
			return results.shuffled()
		}
	}
	
		// MARK: - Translation
	private func translate(_ object: String) async -> QuizResult? {
			// Shorter, instructional prompts trigger fewer safety guardrails
		let prompt = "Translate the English noun '\(object)' to \(selectedLanguageRaw). Return ONLY the translated word."
		
		do {
			let session = LanguageModelSession()
			let response = try await session.respond(to: prompt)
			let translated = response.content.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
			
			guard !translated.isEmpty else { return nil }
			return QuizResult(translatedWord: translated, correctEnglish: object)
		} catch {
			return nil
		}
	}
	
		// MARK: - Bilingual Sentence Generation (Safety Optimized)
	func generateBilingualSentence(for word: String) async -> BilingualSentence? {
		guard model.isAvailable else { return nil }
		
			// REFINEMENT: Explicitly telling the AI to be "Educational and Neutral"
			// helps bypass over-sensitive safety filters.
		let prompt = """
		Objective: Educational language example.
		Word: \(word)
		Language: \(selectedLanguageRaw)
		
		Task: Write a neutral, 5-word English sentence using '\(word)'. 
		Then translate it to \(selectedLanguageRaw).
		
		Format:
		E: [English]
		T: [Translation]
		"""
		
		do {
			let session = LanguageModelSession()
			let response = try await session.respond(to: prompt)
			
				// Refined parsing logic (more robust than component matching)
			let content = response.content
			let lines = content.components(separatedBy: .newlines)
			
			var english = ""
			var translated = ""
			
			for line in lines {
				if line.starts(with: "E:") {
					english = line.replacingOccurrences(of: "E:", with: "").trimmingCharacters(in: .whitespaces)
				} else if line.starts(with: "T:") {
					translated = line.replacingOccurrences(of: "T:", with: "").trimmingCharacters(in: .whitespaces)
				}
			}
			
				// Final safety check: If the model returned a "Safety" warning as text
			if english.lowercased().contains("guardrail") || english.isEmpty {
				return nil
			}
			
			return BilingualSentence(english: english, translated: translated)
			
		} catch {
			print("Safety or Model Error: \(error)")
			return nil
		}
	}
}

	//import Foundation
//import FoundationModels
//import SwiftUI
//import Combine
//
//@available(iOS 26.0, *)
//final actor FoundationAIService: ObservableObject {
//	
//		// MARK: - Model
//	
//	private let model = SystemLanguageModel.default
//	
//	@AppStorage("selected_language")
//	private var selectedLanguageRaw = AppLanguage.french.rawValue
//	
//		// reuse ONE session (huge performance improvement)
//	private lazy var session: LanguageModelSession = {
//		return LanguageModelSession(model: model)
//	}()
//	
//	
//		// MARK: - Concurrency control
//	
//		// prevents CPU / Neural Engine overload spikes
//	private let translationLimiter = AsyncSemaphore(value: 2)
//	
//	
//		// MARK: - Models
//	
//	struct QuizResult: Identifiable, Sendable {
//		let id = UUID()
//		let translatedWord: String
//		let correctEnglish: String
//	}
//	
//	
//		// MARK: - PREWARM
//	
//		/// Call once at app launch
//	nonisolated func prewarm() {
//		
//		Task.detached(priority: .utility) { [model] in
//			
//			guard model.isAvailable else { return }
//			
//			let session = LanguageModelSession(model: model)
//			
//			_ = try? await session.respond(
//				to: "Reply with the single word: ready"
//			)
//		}
//	}
//	
//	
//		// MARK: - Object Filtering
//	
//	func filterObjects(from predictions: [String]) async -> [String] {
//		
//		guard model.isAvailable else { return [] }
//		
//		let prompt = """
//  From this list of detected items:
//  \(predictions.joined(separator: ", "))
//  
//  Task: Identify objects and remove all generic terms that depict general categories.
//  
//  Strict Rules:
//  1. Return ONLY the specific names of physical objects.
//  2. If NO specific objects are found in the list, return the exact word: "NONE".
//  3. NEVER return generic categories or environment descriptions such as: structure, system, machine, equipment, object, material, architecture, electronics, consumer_electronics, bathroom, interior, room, textile, adult, people, conveyance, elevator, appliance, health_club, hospital, outdoor, sky, wood_processsed, screenshot, portal, illustrations. Exclude all the words given above from the result.
//  
//  Output Format: A comma-separated list of objects, or the single word "NONE".
//  """
//		
//		do {
//			
//			let response = try await session.respond(to: prompt)
//			
//			let text = response.content
//				.lowercased()
//				.trimmingCharacters(in: .whitespacesAndNewlines)
//			
//			guard text != "none", !text.isEmpty else {
//				return []
//			}
//			
//			return text
//				.split(separator: ",")
//				.map { $0.trimmingCharacters(in: .whitespaces) }
//			
//		} catch {
//			return []
//		}
//	}
//	
//	
//		// MARK: - Quiz Generation
//	
//	func generateQuizSession(from objects: [String]) async -> [QuizResult] {
//		
//		await withTaskGroup(of: QuizResult?.self) { group in
//			
//			for object in objects {
//				
//				group.addTask(priority: .utility) {
//					
//					await self.translationLimiter.wait()
//					
//					let result = await self.translate(object)
//					
//					await self.translationLimiter.signal()
//					
//					return result
//				}
//			}
//			
//			var results: [QuizResult] = []
//			
//			for await result in group {
//				if let result {
//					results.append(result)
//				}
//			}
//			
//			return results.shuffled()
//		}
//	}
//	
//	
//		// MARK: - Translation
//	
//	private func translate(_ object: String) async -> QuizResult? {
//		
//		let prompt = """
// You are an expert lanuage teacher. And can translate sigular plural and all words to any language. Translate '\(object)' to \(selectedLanguageRaw). Return ONLY the translated word.
//"""
//		
//		do {
//			
//			let response = try await session.respond(to: prompt)
//			
//			let translated = response.content
//				.trimmingCharacters(in: .whitespacesAndNewlines)
//				.lowercased()
//			
//			guard !translated.isEmpty else { return nil }
//			
//			return QuizResult(
//				translatedWord: translated,
//				correctEnglish: object
//			)
//			
//		} catch {
//			return nil
//		}
//	}
//	
//		// MARK: - Bilingual Sentence Generation
//	
//	struct BilingualSentence: Sendable {
//		let english: String
//		let translated: String
//	}
//	
//	func generateBilingualSentence(for word: String) async -> BilingualSentence? {
//		
//		guard model.isAvailable else { return nil }
//		
//		let prompt = """
//	Word: \(word)
//	Language: \(selectedLanguageRaw)
//	
//	Write one simple beginner sentence in English using the word above.
//	Then translate that exact sentence to \(selectedLanguageRaw).
//	Maximum 8 words per sentence.
//	
//	Respond in this exact format:
//	ENGLISH: <sentence>
//	TRANSLATED: <sentence>
//	"""
//		
//		do {
//			let localSession = LanguageModelSession(model: model)
//			let response = try await localSession.respond(to: prompt)
//			
//			let lines = response.content
//				.trimmingCharacters(in: .whitespacesAndNewlines)
//				.components(separatedBy: "\n")
//			
//			var english = ""
//			var translated = ""
//			
//			for line in lines {
//				if line.lowercased().hasPrefix("english:") {
//					english = line
//						.replacingOccurrences(of: "english:", with: "", options: .caseInsensitive)
//						.trimmingCharacters(in: .whitespaces)
//				}
//				if line.lowercased().hasPrefix("translated:") {
//					translated = line
//						.replacingOccurrences(of: "translated:", with: "", options: .caseInsensitive)
//						.trimmingCharacters(in: .whitespaces)
//				}
//			}
//			
//			guard !english.isEmpty, !translated.isEmpty else { return nil }
//			
//			return BilingualSentence(english: english, translated: translated)
//			
//		} catch {
//			return nil
//		}
//	}
//	
//}
//
//actor AsyncSemaphore {
//	
//	private var permits: Int
//	private var waiters: [CheckedContinuation<Void, Never>] = []
//	
//	init(value: Int) {
//		self.permits = value
//	}
//	
//	func wait() async {
//		
//		if permits > 0 {
//			permits -= 1
//			return
//		}
//		
//		await withCheckedContinuation {
//			waiters.append($0)
//		}
//	}
//	
//	func signal() {
//		
//		if waiters.isEmpty {
//			permits += 1
//		} else {
//			waiters.removeFirst().resume()
//		}
//	}
//}
//
//
//	//import Foundation
////import FoundationModels
////import SwiftUI
////import Combine
////
////	/// A unified service to handle Apple Intelligence tasks: Object Filtering and Quiz Generation.
////@available(iOS 26.0, *)
////final class FoundationAIService: ObservableObject {
////	
////	private lazy var model = SystemLanguageModel.default
////	
////	@AppStorage("selected_language")
////	private var selectedLanguageRaw = AppLanguage.french.rawValue
////	
////	struct QuizResult: Identifiable {
////		let id = UUID()
////		let translatedWord: String
////		let correctEnglish: String
////	}
////	
////		// MARK: - Object Filtering (FoundationObjectFilter Logic)
////	
////	func filterObjects(from predictions: [String]) async -> [String] {
////		guard model.isAvailable else {
////			print("❌ Foundation model not available")
////			return []
////		}
////		
////		let session = LanguageModelSession()
////		
////		let prompt = """
////		From this list of detected items:
////		\(predictions.joined(separator: ", "))
////		
////		Task: Identify objects or things and remove all generic terms that depict general categories.
////		
////		Strict Rules:
////		1. Return ONLY the specific names of physical objects or things.
////		2. If NO specific objects are found in the list, return the exact word: "NONE".
////		3. NEVER return generic categories or environment descriptions such as: structure, system, machine, equipment, object, material, architecture, electronics, consumer_electronics, bathroom, interior, room, textile, adult, people, conveyance, elevator, appliance, health_club, hospital, outdoor, sky, wood_processsed, screenshot, portal, illustrations. Exclude all the words given above from the result.
////		
////		Output Format: A comma-separated list of objects, or the single word "NONE".
////		"""
////		
////		do {
////			let response = try await session.respond(to: prompt)
////			let text = response.content.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
////			
////				// 1. Check for the fallback keyword
////			if text == "none" || text.isEmpty {
////				return []
////			}
////			
////			let objects = text
////				.replacingOccurrences(of: "\n", with: "")
////				.split(separator: ",")
////				.map { $0.trimmingCharacters(in: .whitespaces) }
////				.filter { item in
////						// Ensure the item is not empty
////					!item.isEmpty
////				}
////			
////			return objects
////			
////		} catch {
////			print("❌ Model error:", error)
////			return []
////		}
////	}
////	
////		// MARK: - Quiz Generation (FoundationQuizGenerator Logic)
////	func generateQuizSession(from objects: [String]) async -> [QuizResult] {
////		
////		await withTaskGroup(of: QuizResult?.self) { group in
////			
////			for object in objects {
////				group.addTask {
////					await self.translate(object)
////				}
////			}
////			
////			var results: [QuizResult] = []
////			
////			for await result in group {
////				if let result {
////					results.append(result)
////				}
////			}
////			
////			return results.shuffled()
////		}
////	}
////	
////		// MARK: - Translation Logic
////	
////	private func translate(_ object: String) async -> QuizResult? {
////		
////		let prompt = """
////		You are a translation expert in all languages.
////		Translate '\(object)' to \(selectedLanguageRaw).
////		
////		Return ONLY the translated word.
////		"""
////		
////		do {
////			let session = LanguageModelSession()
////			let response = try await session.respond(to: prompt)
////			
////			let french = response.content
////				.trimmingCharacters(in: .whitespacesAndNewlines)
////				.lowercased()
////			
////			guard !french.isEmpty else { return nil }
////			
////			return QuizResult(
////				translatedWord: french,
////				correctEnglish: object
////			)
////			
////		} catch {
////			print("❌ Translation error:", error)
////			return nil
////		}
////	}
////}
