import Foundation
import FoundationModels

@available(iOS 26.0, *)
final class FoundationObjectFilter {
	
	private let model = SystemLanguageModel.default
	
	func filterObjects(from predictions: [String]) async -> [String] {
		
		guard model.isAvailable else {
			print("❌ Foundation model not available")
			return []
		}
		
		let session = LanguageModelSession()
		
		let prompt = """
		From this list of detected items:
		
		\(predictions.joined(separator: ", "))
		
		Return ONLY items that are everyday household, office or daily usage objects or any type of objects or their names.
		
		Remove generic terms like:
		structure, system, machine, equipment, object, material, device, architecture, electronics, consumer_electronics, bathroom, interior, room, textile, material, adult, people, conveyence, elevator, appliance.
		
		Return only a comma-separated list of valid objects.
		"""
		
		do {
			
			let response = try await session.respond(to: prompt)
			
			let text = response.content.lowercased()
			
			let objects = text
				.replacingOccurrences(of: "\n", with: "")
				.split(separator: ",")
				.map { $0.trimmingCharacters(in: .whitespaces) }
				.filter { !$0.isEmpty }
			
			return objects
			
		} catch {
			
			print("❌ Model error:", error)
			return []
		}
	}
}
