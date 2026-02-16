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

		Task: Identify specific, namable everyday household, office, or daily usage objects.

		Strict Rules:
		1. Return ONLY the specific names of physical objects (e.g., 'cup', 'laptop', 'stapler').
		2. If NO specific objects are found in the list, return the exact word: "NONE".
		3. NEVER return generic categories or environment descriptions such as: structure, system, machine, equipment, object, material, device, architecture, electronics, consumer_electronics, bathroom, interior, room, textile, adult, people, conveyance, elevator, appliance, health_club, hospital, outdoor, sky.

		Output Format: A comma-separated list of objects, or the single word "NONE".
		"""
		
//		let prompt = """
//		From this list of detected items:
//		
//		\(predictions.joined(separator: ", "))
//		
//		Return ONLY items that are everyday household, office or daily usage objects or any type of objects or their names.
//		
//		Remove generic terms like:
//		structure, system, machine, equipment, object, material, device, architecture, electronics, consumer_electronics, bathroom, interior, room, textile, material, adult, people, conveyence, elevator, appliance, healt_club, hospital, outdoor, sky.
//		
//		Return only a comma-separated list of valid objects.
//		"""
		
		do {
			let response = try await session.respond(to: prompt)
			let text = response.content.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
			
				// 1. Check for the fallback keyword
			if text == "none" || text.isEmpty {
				return []
			}
			
				// 2. Define a local blacklist for double-verification
			let forbidden = ["structure", "system", "machine", "equipment", "object", "material", "device", "architecture", "electronics", "interior", "room", "textile", "adult", "people", "appliance", "outdoor", "sky"]
			
			let objects = text
				.replacingOccurrences(of: "\n", with: "")
				.split(separator: ",")
				.map { $0.trimmingCharacters(in: .whitespaces) }
				.filter { item in
						// Ensure the item is not empty AND not in our forbidden list
					!item.isEmpty && !forbidden.contains(where: { item.contains($0) })
				}
			
			return objects
			
		} catch {
			print("❌ Model error:", error)
			return []
		}
	}
}
