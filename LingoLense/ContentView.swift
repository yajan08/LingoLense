import SwiftUI

	/// The landing page for LingoLens, designed for the Swift Student Challenge.
	/// Uses native navigation patterns and a modern floating action button.
@available(iOS 26.0, *)
struct ContentView: View {
	
		// MARK: - State
	
	@AppStorage("selected_language")
	private var selectedLanguageRaw = AppLanguage.french.rawValue
	
	private var selectedLanguage: AppLanguage {
		AppLanguage(rawValue: selectedLanguageRaw) ?? .french
	}
	
		// MARK: - Body
	
	var body: some View {
		NavigationStack {
			ZStack(alignment: .bottom) {
				ScrollView(showsIndicators: false) {
					VStack(spacing: 32) {
						descriptionHeader
						
						languagePicker
						
						instructionsSection
						
						securityPromise
						
							// Extra padding to ensure content clears the floating button
						Color.clear.frame(height: 100)
					}
					.padding(24)
				}
				
				floatingStartButton
			}
			.navigationTitle("LingoLens")
			.navigationBarTitleDisplayMode(.large)
			.background(Color(.systemGroupedBackground))
		}
	}
}

	// MARK: - UI Components

private extension ContentView {
	
		/// A subtle description that sits right under the large navigation title
	var descriptionHeader: some View {
		Text("Transform your surroundings into a language learning playground.")
			.font(.title3)
			.fontWeight(.medium)
			.foregroundColor(.secondary)
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.top, -10)
	}
	
	var languagePicker: some View {
		Menu {
			Picker("Select Language", selection: $selectedLanguageRaw) {
				ForEach(AppLanguage.allCases) { language in
					Text("\(language.flag) \(language.displayName)")
						.tag(language.rawValue)
				}
			}
		} label: {
			HStack(spacing: 12) {
				Text(selectedLanguage.flag)
					.font(.title2)
				
				Text("Learning \(selectedLanguage.displayName)")
					.font(.headline)
				
				Spacer()
				
				Image(systemName: "chevron.up.chevron.down")
					.font(.caption2.bold())
					.foregroundColor(.secondary)
			}
			.padding()
			.background(Color(.secondarySystemGroupedBackground))
			.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
			.foregroundColor(.primary)
		}
	}
	
		// MARK: - Refined Instructions Section
	
	var instructionsSection: some View {
		VStack(alignment: .leading, spacing: 20) {
			Text("Your Learning Journey")
				.font(.system(.headline, design: .rounded))
				.foregroundColor(.primary)
				.padding(.leading, 4)
			
			VStack(spacing: 0) {
				stepRow(
					icon: "camera.aperture",
					color: .blue,
					title: "Explore & Discover",
					text: "Wander through your space and scan everyday objects. Our on-device AI identifies items in real-time."
				)
				
				Divider().padding(.leading, 76)
				
				stepRow(
					icon: "sparkles.rectangle.stack",
					color: .purple,
					title: "Curate Vocabulary",
					text: "Apple Intelligence filters your scan to keep only useful vocabulary. Choose the words you want to master."
				)
				
				Divider().padding(.leading, 76)
				
				stepRow(
					icon: "target",
					color: .orange,
					title: "The Scavenger Hunt",
					text: "Test your memory by finding those same objects again—but this time, we'll only give you the name in \(selectedLanguage.displayName)."
				)
			}
			.background(Color(.secondarySystemGroupedBackground))
			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
			.shadow(color: .black.opacity(0.03), radius: 10, y: 5)
		}
	}
	
		// MARK: - Refined Step Row logic
	
	func stepRow(icon: String, color: Color, title: String, text: String) -> some View {
		HStack(spacing: 16) {
			ZStack {
				Circle()
					.fill(color.opacity(0.12))
					.frame(width: 48, height: 48)
				
				Image(systemName: icon)
					.font(.system(size: 22, weight: .semibold))
					.foregroundColor(color)
			}
			
			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.system(.subheadline, design: .rounded).bold())
					.foregroundColor(.primary)
				
				Text(text)
					.font(.caption)
					.foregroundColor(.secondary)
					.lineSpacing(2)
					.fixedSize(horizontal: false, vertical: true)
			}
			
			Spacer()
		}
		.padding(.vertical, 20)
		.padding(.horizontal, 16)
	}
		/// A more personal security statement
	var securityPromise: some View {
		VStack(spacing: 12) {
			Image(systemName: "lock.shield.fill")
				.font(.title)
				.foregroundStyle(.blue.gradient)
			
			VStack(spacing: 4) {
				Text("Your Privacy, My Priority")
					.font(.headline)
				
				Text("All object recognition happens locally on your device. I never collect your images or data—what you scan stays yours.")
					.font(.footnote)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 20)
			}
		}
		.padding(.vertical, 20)
	}
		/// Liquid Glass Floating Button
	var floatingStartButton: some View {
		NavigationLink {
			ScannerView()
		} label: {
			HStack(spacing: 12) {
				Text("Start Scanning")
					.font(.system(.title3, design: .rounded).bold())
				
				Image(systemName: "arrow.right.circle.fill")
					.font(.title2)
			}
			.foregroundColor(.white)
			.padding(.horizontal, 32)
			.padding(.vertical, 18)
			.background {
				ZStack {
						// The "Liquid" base
					Capsule()
						.fill(Color.blue.gradient)
					
						// The "Glass" shine
					Capsule()
						.strokeBorder(.white.opacity(0.2), lineWidth: 1)
				}
			}
			.shadow(color: .blue.opacity(0.3), radius: 15, y: 8)
		}
		.padding(.bottom, 30)
	}
}

	// MARK: - Preview
#Preview {
	ContentView()
}
