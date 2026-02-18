import SwiftUI

	/// The landing page for LingoLens, designed for the Swift Student Challenge.
	/// Features a personalized onboarding experience and synchronized mode selection.
@available(iOS 26.0, *)
struct ContentView: View {
	
		// MARK: - State
	@AppStorage("selected_language")
	private var selectedLanguageRaw = AppLanguage.french.rawValue
	
	@State private var showInfo = false
	
	private var selectedLanguage: AppLanguage {
		AppLanguage(rawValue: selectedLanguageRaw) ?? .french
	}
	
		// MARK: - Body
	var body: some View {
		NavigationStack {
			ScrollView(showsIndicators: false) {
				VStack(spacing: 32) {
					descriptionHeader
					
					languagePicker
					
					instructionsSection
					
					modeSelectionArea
					
					privacyStatement
				}
				.padding(24)
			}
			.navigationTitle("LingoLens")
			.navigationBarTitleDisplayMode(.large)
			.background(Color(.systemGroupedBackground))
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						showInfo = true
					} label: {
						Image(systemName: "info.circle")
							.font(.title3)
							.symbolRenderingMode(.hierarchical)
					}
				}
			}
			.sheet(isPresented: $showInfo) {
				InfoSheet(selectedLanguage: selectedLanguage)
			}
		}
	}
}

	// MARK: - UI Components
private extension ContentView {
	
	var descriptionHeader: some View {
		Text("Transform your space into a language learning playground.")
			.font(.title3)
			.fontWeight(.medium)
			.foregroundColor(.secondary)
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.top, -20)
	}
	
	var languagePicker: some View {
		Menu {
			Picker("Choose Language", selection: $selectedLanguageRaw) {
				ForEach(AppLanguage.allCases) { language in
					Text("\(language.flag) \(language.displayName)")
						.tag(language.rawValue)
				}
			}
		} label: {
			HStack(spacing: 12) {
				Text(selectedLanguage.flag)
					.font(.title2)
				
				VStack(alignment: .leading, spacing: 0) {
					Text("LEARNING")
						.font(.system(size: 10, weight: .black))
						.foregroundStyle(.secondary)
					Text(selectedLanguage.displayName)
						.font(.headline)
				}
				
				Spacer()
				
				Image(systemName: "chevron.up.chevron.down")
					.font(.caption2.bold())
					.foregroundColor(.secondary)
			}
			.padding()
			.background(Color(.secondarySystemGroupedBackground))
			.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
			.foregroundColor(.primary)
			.shadow(color: .black.opacity(0.04), radius: 8, y: 4)
		}
	}
	
	var instructionsSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text("Your Learning Journey")
				.font(.system(.headline, design: .rounded))
				.foregroundColor(.primary)
			
			VStack(spacing: 0) {
				stepRow(
					icon: "bolt.fill",
					color: .blue,
					title: "Quick Scan",
					text: "Scan objects and hear their \(selectedLanguage.displayName) names instantly."
				)
				
				Divider().padding(.leading, 72)
				
				stepRow(
					icon: "flag.checkered.2.crossed",
					color: .orange,
					title: "Scavenger Hunt",
					text: "Scan your surroundings to create a personalized list of objects, then hunt them using their \(selectedLanguage.displayName) names."
				)
			}
			.background(Color(.secondarySystemGroupedBackground))
			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
			.shadow(color: .black.opacity(0.03), radius: 10, y: 5)
		}
	}
	
	var modeSelectionArea: some View {
		HStack(spacing: 12) {
				// QUICK SCAN: Updated from Button to NavigationLink
			NavigationLink {
				QuickScanView() // Navigates to the screen we just made
			} label: {
				HStack(spacing: 8) {
					Image(systemName: "bolt.fill")
					Text("Quick Scan")
						.fontWeight(.bold)
				}
				.frame(maxWidth: .infinity)
				.frame(height: 56)
				.background(Color.blue.gradient)
				.foregroundColor(.white)
				.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
				.shadow(color: .blue.opacity(0.2), radius: 8, y: 4)
			}
			
			NavigationLink {
				ScannerView()
			} label: {
				HStack(spacing: 8) {
					Image(systemName: "target")
					Text("Start Hunt")
						.fontWeight(.bold)
				}
				.frame(maxWidth: .infinity)
				.frame(height: 56)
				.background(Color.orange.gradient)
				.foregroundColor(.white)
				.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
				.shadow(color: .orange.opacity(0.2), radius: 8, y: 4)
			}
		}
	}
	
	func stepRow(icon: String, color: Color, title: String, text: String) -> some View {
		HStack(spacing: 16) {
			ZStack {
				RoundedRectangle(cornerRadius: 12, style: .continuous)
					.fill(color.opacity(0.12))
					.frame(width: 44, height: 44)
				
				Image(systemName: icon)
					.font(.system(size: 20, weight: .semibold))
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
			}
			Spacer()
		}
		.padding(.vertical, 16)
		.padding(.horizontal, 16)
	}
	
	var privacyStatement: some View {
		VStack(spacing: 12) {
			Image(systemName: "lock.shield.fill")
				.font(.title2)
				.foregroundStyle(.blue.gradient)
			
			Text("Private & Secure\nAll processing happens on-device.")
				.font(.footnote)
				.foregroundColor(.secondary)
				.multilineTextAlignment(.center)
		}
		.padding(.top, 10)
	}
}

	// MARK: - Info Sheet
struct InfoSheet: View {
	@Environment(\.dismiss) var dismiss
	let selectedLanguage: AppLanguage
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 32) {
					
						// SECTION 1: QUICK SCAN
					VStack(alignment: .leading, spacing: 16) {
						headerLabel(title: "Quick Scan", icon: "bolt.fill", color: .blue)
						
						Text("I've designed this mode for instant curiosity. It's the fastest way to learn about your world.")
							.font(.subheadline)
							.foregroundColor(.secondary)
						
						VStack(spacing: 0) {
							InstructionDetailRow(
								icon: "camera.viewfinder",
								color: .blue,
								title: "1. Point & Detect",
								detail: "Aim your camera at any object. I'll use on-device intelligence to figure out what it is instantly."
							)
							
							Divider().padding(.leading, 56)
							
							InstructionDetailRow(
								icon: "speaker.wave.2.fill",
								color: .blue,
								title: "2. Hear the Translation",
								detail: "You'll see and hear the name in \(selectedLanguage.displayName), helping you build an immediate mental link."
							)
						}
						.background(Color(.secondarySystemGroupedBackground))
						.clipShape(RoundedRectangle(cornerRadius: 20))
					}
					
						// SECTION 2: SCAVENGER HUNT
					VStack(alignment: .leading, spacing: 16) {
						headerLabel(title: "Scavenger Hunt", icon: "target", color: .orange)
						
						Text("This is where you test your mastery. It's a three-step journey from discovery to memory.")
							.font(.subheadline)
							.foregroundColor(.secondary)
						
						VStack(spacing: 0) {
							InstructionDetailRow(
								icon: "video.badge.plus",
								color: .orange,
								title: "1. Environment Mapping",
								detail: "Wander around and scan multiple objects. Try different angles to help me lock onto their shapes."
							)
							
							Divider().padding(.leading, 56)
							
							InstructionDetailRow(
								icon: "text.badge.plus",
								color: .orange,
								title: "2. Curate Your Session",
								detail: "Review the items I found. You can keep my suggestions, remove what you don't like, or add your own."
							)
							
							Divider().padding(.leading, 56)
							
							InstructionDetailRow(
								icon: "questionmark.app.dashed",
								color: .orange,
								title: "3. The Memory Challenge",
								detail: "Now the real fun begins! I'll ask you to find those objects again using only their \(selectedLanguage.displayName) names."
							)
						}
						.background(Color(.secondarySystemGroupedBackground))
						.clipShape(RoundedRectangle(cornerRadius: 20))
					}
				}
				.padding(24)
			}
			.navigationTitle("How I'll help you learn")
			.navigationBarTitleDisplayMode(.inline)
			.background(Color(.systemGroupedBackground))
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button("Got it") { dismiss() }.fontWeight(.bold)
				}
			}
		}
	}
	
	private func headerLabel(title: String, icon: String, color: Color) -> some View {
		HStack(spacing: 12) {
			Image(systemName: icon)
				.font(.headline)
				.foregroundStyle(color)
			Text(title)
				.font(.title3.bold())
		}
	}
}

struct InstructionDetailRow: View {
	let icon: String
	let color: Color
	let title: String
	let detail: String
	
	var body: some View {
		HStack(spacing: 16) {
			Image(systemName: icon)
				.font(.title3.bold())
				.foregroundColor(color)
				.frame(width: 40)
			
			VStack(alignment: .leading, spacing: 4) {
				Text(title).font(.subheadline.bold())
				Text(detail).font(.caption).foregroundColor(.secondary)
			}
		}
		.padding(16)
	}
}




	//import SwiftUI
//
//	/// The landing page for LingoLens, designed for the Swift Student Challenge.
//	/// Features synchronized color coding and a detailed instructional guide.
//@available(iOS 26.0, *)
//struct ContentView: View {
//	
//		// MARK: - State
//	@AppStorage("selected_language")
//	private var selectedLanguageRaw = AppLanguage.french.rawValue
//	
//	@State private var showInfo = false
//	
//	private var selectedLanguage: AppLanguage {
//		AppLanguage(rawValue: selectedLanguageRaw) ?? .french
//	}
//	
//		// MARK: - Body
//	var body: some View {
//		NavigationStack {
//			ScrollView(showsIndicators: false) {
//				VStack(spacing: 32) {
//					descriptionHeader
//					
//					languagePicker
//					
//					instructionsSection
//					
//					modeSelectionArea
//					
//					privacyStatement
//				}
//				.padding(24)
//			}
//			.navigationTitle("LingoLens")
//			.navigationBarTitleDisplayMode(.large)
//			.background(Color(.systemGroupedBackground))
//			.toolbar {
//				ToolbarItem(placement: .topBarTrailing) {
//					Button {
//						showInfo = true
//					} label: {
//						Image(systemName: "info.circle")
//							.font(.title3)
//							.symbolRenderingMode(.hierarchical)
//					}
//				}
//			}
//			.sheet(isPresented: $showInfo) {
//				InfoSheet(selectedLanguage: selectedLanguage)
//			}
//		}
//	}
//}
//
//	// MARK: - UI Components
//private extension ContentView {
//	
//	var descriptionHeader: some View {
//		Text("Transform your space into a language learning playground.")
//			.font(.title3)
//			.fontWeight(.medium)
//			.foregroundColor(.secondary)
//			.frame(maxWidth: .infinity, alignment: .leading)
//			.padding(.top, -10)
//	}
//	
//	var languagePicker: some View {
//		Menu {
//			Picker("Choose Language", selection: $selectedLanguageRaw) {
//				ForEach(AppLanguage.allCases) { language in
//					Text("\(language.flag) \(language.displayName)")
//						.tag(language.rawValue)
//				}
//			}
//		} label: {
//			HStack(spacing: 12) {
//				Text(selectedLanguage.flag)
//					.font(.title2)
//				
//				VStack(alignment: .leading, spacing: 0) {
//					Text("LEARNING")
//						.font(.system(size: 10, weight: .black))
//						.foregroundStyle(.secondary)
//					Text(selectedLanguage.displayName)
//						.font(.headline)
//				}
//				
//				Spacer()
//				
//				Image(systemName: "chevron.up.chevron.down")
//					.font(.caption2.bold())
//					.foregroundColor(.secondary)
//			}
//			.padding()
//			.background(Color(.secondarySystemGroupedBackground))
//			.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//			.foregroundColor(.primary)
//			.shadow(color: .black.opacity(0.04), radius: 8, y: 4)
//		}
//	}
//	
//	var instructionsSection: some View {
//		VStack(alignment: .leading, spacing: 16) {
//			Text("Your Learning Journey")
//				.font(.system(.headline, design: .rounded))
//				.foregroundColor(.primary)
//				.padding(.leading, 4)
//			
//			VStack(spacing: 0) {
//				stepRow(
//					icon: "bolt.fill",
//					color: .blue,
//					title: "Quick Scan",
//					text: "Scan a object and get its \(selectedLanguage.displayName) translation instantly."
//				)
//				
//				Divider().padding(.leading, 72)
//				
//				stepRow(
//					icon: "flag.checkered.2.crossed",
//					color: .orange,
//					title: "Scavenger Hunt",
//					text: "Scan your room to create a custom quiz and find objects by their names in \(selectedLanguage.displayName)."
//				)
//			}
//			.background(Color(.secondarySystemGroupedBackground))
//			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
//			.shadow(color: .black.opacity(0.03), radius: 10, y: 5)
//		}
//	}
//	
//	var modeSelectionArea: some View {
//		HStack(spacing: 12) {
//				// Quick Learn Button
//			Button {
//					// Future Quick Learn Logic
//			} label: {
//				HStack(spacing: 8) {
//					Image(systemName: "bolt.fill")
//					Text("Quick Scan")
//						.fontWeight(.bold)
//				}
//				.frame(maxWidth: .infinity)
//				.frame(height: 56)
//				.background(Color.blue.gradient)
//				.foregroundColor(.white)
//				.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//				.shadow(color: .blue.opacity(0.2), radius: 8, y: 4)
//			}
//			
//				// Scavenger Hunt Button
//			NavigationLink {
//				ScannerView()
//			} label: {
//				HStack(spacing: 8) {
//					Image(systemName: "target")
//					Text("Start Hunt")
//						.fontWeight(.bold)
//				}
//				.frame(maxWidth: .infinity)
//				.frame(height: 56)
//				.background(Color.orange.gradient)
//				.foregroundColor(.white)
//				.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//				.shadow(color: .orange.opacity(0.2), radius: 8, y: 4)
//			}
//		}
//	}
//	
//	func stepRow(icon: String, color: Color, title: String, text: String) -> some View {
//		HStack(spacing: 16) {
//			ZStack {
//				RoundedRectangle(cornerRadius: 12, style: .continuous)
//					.fill(color.opacity(0.12))
//					.frame(width: 44, height: 44)
//				
//				Image(systemName: icon)
//					.font(.system(size: 20, weight: .semibold))
//					.foregroundColor(color)
//			}
//			
//			VStack(alignment: .leading, spacing: 4) {
//				Text(title)
//					.font(.system(.subheadline, design: .rounded).bold())
//					.foregroundColor(.primary)
//				
//				Text(text)
//					.font(.caption)
//					.foregroundColor(.secondary)
//					.lineSpacing(2)
//			}
//			Spacer()
//		}
//		.padding(.vertical, 16)
//		.padding(.horizontal, 16)
//	}
//	
//	var privacyStatement: some View {
//		VStack(spacing: 12) {
//			Image(systemName: "lock.shield.fill")
//				.font(.title2)
//				.foregroundStyle(.blue.gradient)
//			
//			Text("Private & Secure\nAll processing happens on-device.")
//				.font(.footnote)
//				.foregroundColor(.secondary)
//				.multilineTextAlignment(.center)
//		}
//		.padding(.top, 10)
//	}
//}
//
//	// MARK: - Info Sheet
//struct InfoSheet: View {
//	@Environment(\.dismiss) var dismiss
//	let selectedLanguage: AppLanguage
//	
//	var body: some View {
//		NavigationStack {
//			ScrollView {
//				VStack(alignment: .leading, spacing: 24) {
//					
//						// The Full Process Section
//					VStack(alignment: .leading, spacing: 16) {
//						Text("The Process")
//							.font(.title3.bold())
//						
//						VStack(spacing: 0) {
//							InstructionDetailRow(
//								icon: "camera.viewfinder",
//								color: .blue,
//								title: "1. Scan Your Space",
//								detail: "Move your phone to explore your surroundings. On-device AI identifies objects in real-time."
//							)
//							
//							Divider().padding(.leading, 56)
//							
//							InstructionDetailRow(
//								icon: "checklist",
//								color: .green,
//								title: "2. Build Your List",
//								detail: "Review what we found. Add items manually or remove categories you don't want to practice."
//							)
//							
//							Divider().padding(.leading, 56)
//							
//							InstructionDetailRow(
//								icon: "target",
//								color: .orange,
//								title: "3. The Scavenger Hunt",
//								detail: "Find those same objects again! We'll prompt you with names in \(selectedLanguage.displayName) to test your memory."
//							)
//						}
//						.background(Color(.secondarySystemGroupedBackground))
//						.clipShape(RoundedRectangle(cornerRadius: 20))
//					}
//					
//						// Modes Explanation
//					VStack(alignment: .leading, spacing: 12) {
//						Text("Learning Modes")
//							.font(.title3.bold())
//						
//						VStack(alignment: .leading, spacing: 16) {
//							HStack(alignment: .top, spacing: 12) {
//								Image(systemName: "bolt.fill").foregroundColor(.blue)
//								Text("**Quick Scan**: Ideal for rapid discovery. Tap an object to see its name instantly.")
//							}
//							HStack(alignment: .top, spacing: 12) {
//								Image(systemName: "flag.checkered.2.crossed").foregroundColor(.orange)
//								Text("**Start Hunt**: Scan multiple objects at once, then find randomly selected items to win.")
//							}
//						}
//						.font(.subheadline)
//						.padding()
//						.background(Color(.secondarySystemGroupedBackground))
//						.clipShape(RoundedRectangle(cornerRadius: 16))
//					}
//				}
//				.padding(24)
//			}
//			.navigationTitle("About LingoLens")
//			.navigationBarTitleDisplayMode(.inline)
//			.background(Color(.systemGroupedBackground))
//			.toolbar {
//				ToolbarItem(placement: .confirmationAction) {
//					Button("Done") { dismiss() }.fontWeight(.bold)
//				}
//			}
//		}
//	}
//}
//
//struct InstructionDetailRow: View {
//	let icon: String
//	let color: Color
//	let title: String
//	let detail: String
//	
//	var body: some View {
//		HStack(spacing: 16) {
//			Image(systemName: icon)
//				.font(.title3.bold())
//				.foregroundColor(color)
//				.frame(width: 40)
//			
//			VStack(alignment: .leading, spacing: 4) {
//				Text(title).font(.subheadline.bold())
//				Text(detail).font(.caption).foregroundColor(.secondary)
//			}
//		}
//		.padding(16)
//	}
//}


	//
//
//import SwiftUI
//
//	/// The landing page for LingoLens, designed for the Swift Student Challenge.
//	/// Uses native navigation patterns and a modern floating action button.
//@available(iOS 26.0, *)
//struct ContentView: View {
//	
//		// MARK: - State
//	
//	@AppStorage("selected_language")
//	private var selectedLanguageRaw = AppLanguage.french.rawValue
//	
//	private var selectedLanguage: AppLanguage {
//		AppLanguage(rawValue: selectedLanguageRaw) ?? .french
//	}
//	
//		// MARK: - Body
//	
//	var body: some View {
//		NavigationStack {
//			ZStack(alignment: .bottom) {
//				ScrollView(showsIndicators: false) {
//					VStack(spacing: 32) {
//						descriptionHeader
//						
//						languagePicker
//						
//						instructionsSection
//						
//						privacyStatement
//						
//							// Extra padding to ensure content clears the floating button
//						Color.clear.frame(height: 100)
//					}
//					.padding(24)
//				}
//				
//				floatingStartButton
//			}
//			.navigationTitle("LingoLens")
//			.navigationBarTitleDisplayMode(.large)
//			.background(Color(.systemGroupedBackground))
//		}
//	}
//}
//
//	// MARK: - UI Components
//
//private extension ContentView {
//	
//		/// A subtle description under the navigation title
//	var descriptionHeader: some View {
//		Text("Turn everyday surroundings into a playful language learning experience.")
//			.font(.title3)
//			.fontWeight(.medium)
//			.foregroundColor(.secondary)
//			.frame(maxWidth: .infinity, alignment: .leading)
//			.padding(.top, -10)
//	}
//	
//		/// Language selection menu
//	var languagePicker: some View {
//		Menu {
//			Picker("Choose a language", selection: $selectedLanguageRaw) {
//				ForEach(AppLanguage.allCases) { language in
//					Text("\(language.flag) \(language.displayName)")
//						.tag(language.rawValue)
//				}
//			}
//		} label: {
//			HStack(spacing: 12) {
//				Text(selectedLanguage.flag)
//					.font(.title2)
//				
//				Text("Learning \(selectedLanguage.displayName)")
//					.font(.headline)
//				
//				Spacer()
//				
//				Image(systemName: "chevron.up.chevron.down")
//					.font(.caption2.bold())
//					.foregroundColor(.secondary)
//			}
//			.padding()
//			.background(Color(.secondarySystemGroupedBackground))
//			.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//			.foregroundColor(.primary)
//		}
//	}
//	
//		// MARK: - Learning Journey Section
//	
//	var instructionsSection: some View {
//		VStack(alignment: .leading, spacing: 20) {
//			Text("Your Learning Journey")
//				.font(.system(.headline, design: .rounded))
//				.foregroundColor(.primary)
//				.padding(.leading, 4)
//			
//			VStack(spacing: 0) {
//				VStack(spacing: 0) {
//					stepRow(
//						icon: "camera.viewfinder",
//						color: .blue,
//						title: "Scan Your Space",
//						text: "Explore your surroundings and scan everyday objects using on-device AI."
//					)
//					
//					Divider().padding(.leading, 72)
//					
//					stepRow(
//						icon: "checklist",
//						color: .green,
//						title: "Build Your List",
//						text: "Review detected items, add your own, and choose the words you want to master."
//					)
//					
//					Divider().padding(.leading, 72)
//					
//					stepRow(
//						icon: "flag.checkered.2.crossed",
//						color: .red,
//						title: "The Scavenger Hunt",
//						text: "Test your memory by finding those same objects using only their \(selectedLanguage.displayName) names."
//					)
//				}
//			}
//			.background(Color(.secondarySystemGroupedBackground))
//			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
//			.shadow(color: .black.opacity(0.03), radius: 10, y: 5)
//		}
//	}
//	
//		/// Single instruction row
//	func stepRow(icon: String, color: Color, title: String, text: String) -> some View {
//		HStack(spacing: 16) {
//			ZStack {
//				Circle()
//					.fill(color.opacity(0.12))
//					.frame(width: 48, height: 48)
//				
//				Image(systemName: icon)
//					.font(.system(size: 22, weight: .semibold))
//					.foregroundColor(color)
//			}
//			
//			VStack(alignment: .leading, spacing: 4) {
//				Text(title)
//					.font(.system(.subheadline, design: .rounded).bold())
//					.foregroundColor(.primary)
//				
//				Text(text)
//					.font(.caption)
//					.foregroundColor(.secondary)
//					.lineSpacing(2)
//					.fixedSize(horizontal: false, vertical: true)
//			}
//			
//			Spacer()
//		}
//		.padding(.vertical, 20)
//		.padding(.horizontal, 16)
//	}
//	
//		// MARK: - Privacy Statement
//	
//	var privacyStatement: some View {
//		VStack(spacing: 12) {
//			Image(systemName: "lock.shield.fill")
//				.font(.title)
//				.foregroundStyle(.blue.gradient)
//			
//			VStack(spacing: 4) {
//				Text("Your Privacy, My Priority")
//					.font(.headline)
//				
//				Text("All the magic happens directly on your device. We never collect images or data—what you scan stays with you.")
//					.font(.footnote)
//					.foregroundColor(.secondary)
//					.multilineTextAlignment(.center)
//					.padding(.horizontal, 20)
//			}
//		}
//		.padding(.vertical, 20)
//	}
//	
//		// MARK: - Floating Start Button
//	
//	var floatingStartButton: some View {
//		NavigationLink {
//			ScannerView()
//		} label: {
//			HStack(spacing: 12) {
//				Text("Start Scanning")
//					.font(.system(.title3, design: .rounded).bold())
//				
//				Image(systemName: "arrow.right.circle.fill")
//					.font(.title2)
//			}
//			.foregroundColor(.white)
//			.padding(.horizontal, 32)
//			.padding(.vertical, 18)
//			.background {
//				ZStack {
//						// "Liquid" base
//					Capsule()
//						.fill(Color.blue.gradient)
//					
//						// Glass shine
//					Capsule()
//						.strokeBorder(.white.opacity(0.2), lineWidth: 1)
//				}
//			}
//			.shadow(color: .blue.opacity(0.3), radius: 15, y: 8)
//		}
//		.padding(.bottom, 30)
//	}
//}
//
//	// MARK: - Preview
//#Preview {
//	ContentView()
//}
