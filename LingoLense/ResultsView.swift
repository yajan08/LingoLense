import SwiftUI

@available(iOS 26.0, *)
struct ResultsView: View {
	
	let objects: [String]
	
	@State private var selectedObjects: Set<String> = []
	@State private var navigateToQuiz = false
	@State private var finalSelection: [String] = []
	@State private var isLoading = false
	
	
	var body: some View {
		
		VStack(spacing: 0) {
			
			header
			
			ScrollView {
				LazyVStack(spacing: 12) {
					ForEach(objects, id: \.self) { object in
						selectableRow(object)
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

private extension ResultsView {
	
	var header: some View {
		
		VStack(alignment: .leading, spacing: 6) {
			
			Text("Detected Objects")
				.font(.largeTitle.bold())
			
			Text("Select the objects you can see")
				.font(.subheadline)
				.foregroundColor(.secondary)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding()
	}
	
	
	func selectableRow(_ object: String) -> some View {
		
		let isSelected = selectedObjects.contains(object)
		
		return Button {
			toggle(object)
		} label: {
			
			HStack(spacing: 16) {
				
				Image(systemName:
						isSelected
					  ? "checkmark.circle.fill"
					  : "circle")
				.font(.title2)
				.foregroundColor(isSelected ? .green : .gray)
				
				Text(object.capitalized)
					.font(.body)
				
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
			.padding()
			.background(Color.blue)
			.foregroundColor(.white)
			.cornerRadius(14)
			.padding()
		}
		.disabled(selectedObjects.isEmpty || isLoading)
		.opacity(selectedObjects.isEmpty ? 0.5 : 1)
	}
}

private extension ResultsView {
	
	func toggle(_ object: String) {
		
		if selectedObjects.contains(object) {
			selectedObjects.remove(object)
		} else {
			selectedObjects.insert(object)
		}
	}
	
	
	func confirmSelection() {
		
		finalSelection = Array(Set(selectedObjects))
		
		guard !finalSelection.isEmpty else { return }
		
		isLoading = true
		
			// small delay for UX polish
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			
			isLoading = false
			navigateToQuiz = true
		}
	}
}
