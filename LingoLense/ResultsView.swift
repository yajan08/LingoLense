import SwiftUI

	/// A view that displays a list of detected objects and allows for manual additions.
	/// Users must have at least one object selected to proceed to the quiz session.
@available(iOS 26.0, *)
struct ResultsView: View {
	
		// MARK: - Properties
	
		/// The initial collection of objects detected by the scanner.
	let objects: [String]
	
	@Environment(\.dismiss) private var dismiss
	
	@State private var selectedObjects: Set<String> = []
	@State private var navigateToQuiz = false
	@State private var finalSelection: [String] = []
	@State private var isLoading = false
	
		/// Manual input state for user-defined objects.
	@State private var manualObjects: [String] = []
	@State private var newObjectText: String = ""
	
		/// A combined, sorted, and unique list of both detected and manually added objects.
	private var allObjects: [String] {
		Array(Set(objects + manualObjects)).sorted()
	}
	
		// MARK: - Body
	
	var body: some View {
		VStack(spacing: 0) {
			header
			
			ScrollView {
				LazyVStack(spacing: 12) {
						// Manual input row is always accessible to allow recovery from empty states.
					addObjectRow
						.padding(.bottom, 8)
					
					if !allObjects.isEmpty {
						ForEach(allObjects, id: \.self) { object in
							selectableRow(object)
						}
					} else {
						emptyStateContent
					}
				}
				.padding()
			}
			
			startButton
		}
		.navigationDestination(isPresented: $navigateToQuiz) {
			QuizSessionView(objects: finalSelection)
		}
		.onAppear {
			selectedObjects = Set(objects)
		}
	}
}

	// MARK: - UI Components

private extension ResultsView {
	
	var header: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text("Detected Objects")
				.font(.largeTitle.bold())
			
			Text("Select or add the objects you can see")
				.font(.subheadline)
				.foregroundColor(.secondary)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding()
	}
	
		/// A native-style input field for adding custom objects to the session.
	var addObjectRow: some View {
		HStack(spacing: 12) {
			HStack {
				Image(systemName: "plus.circle.fill")
					.foregroundColor(.blue)
					.font(.title3)
				
				TextField("Add object manually...", text: $newObjectText)
					.submitLabel(.done)
					.onSubmit {
						addManualObject()
					}
			}
			.padding()
			.background(
				RoundedRectangle(cornerRadius: 14)
					.fill(Color(.tertiarySystemBackground))
			)
			.overlay(
				RoundedRectangle(cornerRadius: 14)
					.stroke(Color.primary.opacity(0.05), lineWidth: 1)
			)
			
			if !newObjectText.trimmingCharacters(in: .whitespaces).isEmpty {
				Button {
					addManualObject()
				} label: {
					Text("Add")
						.fontWeight(.bold)
						.foregroundColor(.blue)
						.padding(.horizontal, 16)
						.padding(.vertical, 8)
						.background(Color.blue.opacity(0.1))
						.clipShape(Capsule())
				}
				.transition(.move(edge: .trailing).combined(with: .opacity))
			}
		}
		.animation(.spring(response: 0.3, dampingFraction: 0.7), value: newObjectText.isEmpty)
	}
	
	func selectableRow(_ object: String) -> some View {
		let isSelected = selectedObjects.contains(object)
		
		return Button {
			toggle(object)
		} label: {
			HStack(spacing: 16) {
				Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
					.font(.title2)
					.foregroundColor(isSelected ? .green : .secondary)
				
				Text(object.capitalized)
					.font(.body.weight(.medium))
					.foregroundColor(.primary)
				
				Spacer()
			}
			.padding()
			.background(
				RoundedRectangle(cornerRadius: 14)
					.fill(Color(.secondarySystemBackground))
			)
		}
		.buttonStyle(.plain)
		.animation(.easeInOut(duration: 0.15), value: isSelected)
	}
	
	var startButton: some View {
		Button {
			confirmSelection()
		} label: {
			HStack {
				if isLoading {
					ProgressView()
						.tint(.white)
				} else {
					Text("Start Quiz")
						.font(.headline)
				}
			}
			.frame(maxWidth: .infinity)
			.padding(.vertical, 16)
			.background(selectedObjects.isEmpty ? Color.gray : Color.blue)
			.foregroundColor(.white)
			.cornerRadius(14)
			.padding()
		}
		.disabled(selectedObjects.isEmpty || isLoading)
		.animation(.default, value: selectedObjects.isEmpty)
	}
	
		/// Displayed when no objects are detected or manually entered.
	var emptyStateContent: some View {
		VStack(spacing: 16) {
			Image(systemName: "viewfinder.circle")
				.font(.system(size: 60))
				.foregroundColor(.secondary)
				.padding(.top, 60)
			
			VStack(spacing: 8) {
				Text("No Objects Found")
					.font(.title3.bold())
				
				Text("Please go back and scan your surroundings again, or manually add objects using the field above to start the quiz.")
					.font(.body)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 32)
			}
			
			Button {
				dismiss()
			} label: {
				Label("Go Back to Scanner", systemImage: "arrow.left")
					.font(.headline)
					.foregroundColor(.blue)
			}
			.padding(.top, 8)
		}
	}
}

	// MARK: - Logic

private extension ResultsView {
	
	func toggle(_ object: String) {
		UIImpactFeedbackGenerator(style: .light).impactOccurred()
		if selectedObjects.contains(object) {
			selectedObjects.remove(object)
		} else {
			selectedObjects.insert(trimmed(object))
		}
	}
	
	func addManualObject() {
		let trimmedText = trimmed(newObjectText)
		
		guard !trimmedText.isEmpty else { return }
		
		if !allObjects.contains(trimmedText) {
			UINotificationFeedbackGenerator().notificationOccurred(.success)
			manualObjects.append(trimmedText)
			selectedObjects.insert(trimmedText)
		}
		
		newObjectText = ""
	}
	
	func confirmSelection() {
		finalSelection = Array(Set(selectedObjects))
		guard !finalSelection.isEmpty else { return }
		
		isLoading = true
		UIImpactFeedbackGenerator(style: .medium).impactOccurred()
		
			// Simulate network or processing delay
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			isLoading = false
			navigateToQuiz = true
		}
	}
	
	func trimmed(_ text: String) -> String {
		text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
	}
}
