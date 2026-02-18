
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
						
						privacyStatement
						
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
	
		/// A subtle description under the navigation title
	var descriptionHeader: some View {
		Text("Turn everyday surroundings into a playful language learning experience.")
			.font(.title3)
			.fontWeight(.medium)
			.foregroundColor(.secondary)
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.top, -10)
	}
	
		/// Language selection menu
	var languagePicker: some View {
		Menu {
			Picker("Choose a language", selection: $selectedLanguageRaw) {
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
	
		// MARK: - Learning Journey Section
	
	var instructionsSection: some View {
		VStack(alignment: .leading, spacing: 20) {
			Text("Your Learning Journey")
				.font(.system(.headline, design: .rounded))
				.foregroundColor(.primary)
				.padding(.leading, 4)
			
			VStack(spacing: 0) {
				VStack(spacing: 0) {
					stepRow(
						icon: "camera.viewfinder",
						color: .blue,
						title: "Scan Your Space",
						text: "Explore your room and capture everyday objects using on-device AI."
					)
					
					Divider().padding(.leading, 72)
					
					stepRow(
						icon: "checklist",
						color: .green,
						title: "Build Your List",
						text: "Review detected items, add your own, and choose the words you want to master."
					)
					
					Divider().padding(.leading, 72)
					
					stepRow(
						icon: "flag.checkered.2.crossed",
						color: .red,
						title: "The Scavenger Hunt",
						text: "Test your memory by finding those same objects using only their \(selectedLanguage.displayName) names."
					)
				}
			}
			.background(Color(.secondarySystemGroupedBackground))
			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
			.shadow(color: .black.opacity(0.03), radius: 10, y: 5)
		}
	}
	
		/// Single instruction row
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
	
		// MARK: - Privacy Statement
	
	var privacyStatement: some View {
		VStack(spacing: 12) {
			Image(systemName: "lock.shield.fill")
				.font(.title)
				.foregroundStyle(.blue.gradient)
			
			VStack(spacing: 4) {
				Text("Your Privacy, My Priority")
					.font(.headline)
				
				Text("All the magic happens directly on your device. We never collect images or data—what you scan stays with you.")
					.font(.footnote)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 20)
			}
		}
		.padding(.vertical, 20)
	}
	
		// MARK: - Floating Start Button
	
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
						// "Liquid" base
					Capsule()
						.fill(Color.blue.gradient)
					
						// Glass shine
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
