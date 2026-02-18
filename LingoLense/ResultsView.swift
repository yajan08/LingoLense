import SwiftUI

	/// The landing page for LingoLens, designed for the Swift Student Challenge.
	/// Uses native navigation patterns and a modern floating action button.
@available(iOS 26.0, *)
struct ResultsView: View {
	
		// MARK: - Properties
	
		/// Raw labels passed instantly from the ScannerView to avoid camera-to-result lag.
	let rawDetectedLabels: [String]
	private let aiService = FoundationAIService()
	
	@Environment(\.dismiss) private var dismiss
	
	@FocusState private var isTextFieldFocused: Bool
		// MARK: - State
	
	@State private var filteredObjects: [String] = []
	@State private var selectedObjects: Set<String> = []
	@State private var isFiltering = true
	@State private var navigateToResults = false
	@State private var navigateToQuiz = false
	@State private var newObjectText: String = ""
	@State private var showHelp = false
	
		// Combined list: ensures unique names and sorted order
	private var allObjects: [String] {
		Array(Set(filteredObjects + [newObjectText].filter { !$0.isEmpty })).sorted()
	}
	
		// MARK: - Body
	
	var body: some View {
		VStack(spacing: 0) {
			header
			
			ScrollView {
				LazyVStack(spacing: 12) {
					addObjectRow
						.padding(.bottom, 8)
					
					if isFiltering {
						loadingShimmer
					} else if filteredObjects.isEmpty && newObjectText.isEmpty {
						emptyStateContent
					} else {
							// Display the filtered list
						ForEach(filteredObjects, id: \.self) { object in
							selectableRow(object)
						}
					}
				}
				.padding()
			}
			
			startButton
		}
		.navigationTitle("Review Items")
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button {
					showHelp = true
				} label: {
					Image(systemName: "questionmark.circle.fill")
						.symbolRenderingMode(.hierarchical)
				}
			}
		}
		.navigationDestination(isPresented: $navigateToQuiz) {
				// Defer translation to the QuizSessionView to keep this view snappy
			QuizSessionView(objects: Array(selectedObjects))
		}
		.sheet(isPresented: $showHelp) {
			ResultsInstructionsSheet()
		}
		.onAppear {
			performFiltering()
		}
	}
}

	// MARK: - UI Components

private extension ResultsView {
	
	var header: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text("Detected Objects")
				.font(.system(.largeTitle, design: .rounded).bold())
			
			Text("Confirm the items you want to hunt for.")
				.font(.subheadline)
				.foregroundColor(.secondary)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding()
	}
	
	var loadingShimmer: some View {
		VStack(spacing: 12) {
			ForEach(0..<6, id: \.self) { _ in
				RoundedRectangle(cornerRadius: 14)
					.fill(Color.gray.opacity(0.15))
					.frame(height: 60)
					.overlay(
						HStack {
							Circle().fill(Color.gray.opacity(0.2)).frame(width: 24)
							Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 120, height: 12)
							Spacer()
						}
							.padding(.horizontal)
					)
			}
		}
		.opacity(0.6)
	}
	
	var addObjectRow: some View {
		HStack(spacing: 12) {
			HStack {
				Image(systemName: "plus.circle.fill")
					.foregroundColor(.blue)
				
				TextField("Add object manually...", text: $newObjectText)
					.submitLabel(.done)
					.onSubmit { addManualObject() }
			}
			.padding()
			.background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
				// Explicitly trigger focus when the background area is tapped
			.onTapGesture {
				isTextFieldFocused = true
			}
			
			if !newObjectText.isEmpty {
				Button("Add") { addManualObject() }
					.fontWeight(.bold)
				
			}
		}
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
			.background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
		}
		.buttonStyle(.plain)
	}
	
	var startButton: some View {
		Button {
			UIImpactFeedbackGenerator(style: .medium).impactOccurred()
			navigateToQuiz = true
		} label: {
			Text("Start Scavenger Hunt")
				.font(.headline)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 18)
				.background(selectedObjects.isEmpty || isFiltering ? Color.gray : Color.blue)
				.foregroundColor(.white)
				.clipShape(Capsule())
		}
		.disabled(selectedObjects.isEmpty || isFiltering)
		.padding()
		.background(.ultraThinMaterial)
	}
	
	var emptyStateContent: some View {
		VStack(spacing: 16) {
			Image(systemName: "viewfinder.circle")
				.font(.system(size: 60))
				.foregroundColor(.secondary)
				.padding(.top, 40)
			
			Text("No Specific Objects Found").font(.headline)
			Text("Try scanning again or add items manually.").font(.subheadline).foregroundColor(.secondary)
			
			Button("Go Back") { dismiss() }.font(.headline).padding(.top, 10)
		}
	}
}

	// MARK: - Logic

private extension ResultsView {
	
	func performFiltering() {
		guard !rawDetectedLabels.isEmpty else {
			isFiltering = false
			return
		}
		
		Task(priority: .userInitiated) {
			let cleaned = await aiService.filterObjects(from: rawDetectedLabels)
			
			await MainActor.run {
				withAnimation(.spring()) {
						// 1. Sanitize for duplicates/blanks first
					let sanitized = cleaned
						.map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
						.filter { !$0.isEmpty }
					
						// 2. Limit to a maximum of 10 AI-detected results
					let limitedResults = Array(Set(sanitized)).sorted().prefix(10)
					
						// 3. Update state
					self.filteredObjects = Array(limitedResults)
					self.selectedObjects = Set(limitedResults)
					self.isFiltering = false
				}
			}
		}
	}
	
//	func performFiltering() {
//		guard !rawDetectedLabels.isEmpty else {
//			isFiltering = false
//			return
//		}
//		
//			// Use .userInitiated or .utility to stay off the high-priority UI track
//		Task(priority: .userInitiated) {
//			let cleaned = await aiService.filterObjects(from: rawDetectedLabels)
//			
//				// ONLY jump back to MainActor for the final UI update
//			await MainActor.run {
//				withAnimation(.spring()) {
//					self.filteredObjects = cleaned.sorted()
//					self.selectedObjects = Set(cleaned)
//					self.isFiltering = false
//				}
//			}
//		}
//	}
	
	func toggle(_ object: String) {
		UIImpactFeedbackGenerator(style: .light).impactOccurred()
		if selectedObjects.contains(object) {
			selectedObjects.remove(object)
		} else {
			selectedObjects.insert(object)
		}
	}
	
	func addManualObject() {
		let text = newObjectText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
		guard !text.isEmpty else { return }
		
		isTextFieldFocused = false
		
		if !filteredObjects.contains(text) {
			withAnimation(.spring()) {
				filteredObjects.append(text) // Adds to the list regardless of the 10-count limit
				selectedObjects.insert(text)
			}
		}
		newObjectText = ""
	}}

	// MARK: - Instructions Subcomponent

struct ResultsInstructionsSheet: View {
	@Environment(\.dismiss) var dismiss
	
	var body: some View {
		NavigationStack {
			List {
				Section("Curating Your Session") {
					InstructionRow(
						icon: "checklist.checked",
						color: .green,
						title: "Refine Your List",
						detail: "Review the AI-detected labels and deselect any items that aren't actually in your surroundings."
					)
					InstructionRow(
						icon: "plus.viewfinder",
						color: .blue,
						title: "Add Missing Items",
						detail: "If the scanner missed an object, simply type its name in the 'Add manually' field to include it."
					)
					InstructionRow(
						icon: "hand.tap",
						color: .purple,
						title: "Confirm Selection",
						detail: "Ensure you only select objects you can physically reach, as you will need to find them again shortly."
					)
				}
				
				Section("Next Steps") {
					InstructionRow(
						icon: "flag.checkered.2.crossed",
						color: .red,
						title: "Begin the Hunt",
						detail: "Once satisfied with your list, tap 'Start Scavenger Hunt' to translate these items and begin the game!"
					)
				}
			}
			.navigationTitle("Review Guide")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button {
						dismiss()
					} label: {
						Image(systemName: "xmark.circle.fill")
							.symbolRenderingMode(.hierarchical)
							.foregroundStyle(.secondary)
							.font(.title3)
					}
				}
			}
		}
	}
}
	//	func performFiltering() {
	//		guard !rawDetectedLabels.isEmpty else {
	//			isFiltering = false
	//			return
	//		}
	//		
	//		Task {
	//			let cleaned = await aiService.filterObjects(from: rawDetectedLabels)
	//			
	//			await MainActor.run {
	//				withAnimation(.spring()) {
	//					self.filteredObjects = cleaned.sorted()
	//					self.selectedObjects = Set(cleaned)
	//					self.isFiltering = false
	//				}
	//			}
	//		}
	//	}
