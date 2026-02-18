import SwiftUI

@available(iOS 26.0, *)
struct ContentView: View {
	
		// MARK: - State
	@AppStorage("selected_language")
	private var selectedLanguageRaw = AppLanguage.french.rawValue
	
		// Track which info type to show
	@State private var activeInfoType: InfoType?
	
	private var selectedLanguage: AppLanguage {
		AppLanguage(rawValue: selectedLanguageRaw) ?? .french
	}
	
		// MARK: - Body
	var body: some View {
		NavigationStack {
			ScrollView(showsIndicators: false) {
				VStack(spacing: 36) {
					descriptionHeader
					
					languagePicker
					
					instructionsSection
					
					modeSelectionArea
					
					privacySection
				}
				.padding(24)
			}
			.navigationTitle("LingoLens")
			.background(Color(.systemGroupedBackground))
			.sheet(item: $activeInfoType) { type in
				LingoInfoSheet(type: type, selectedLanguage: selectedLanguage)
			}
		}
	}
}

	// MARK: - Supporting Types
enum InfoType: String, Identifiable {
	case quickScan, scavengerHunt
	var id: String { self.rawValue }
}

	// MARK: - UI Components
private extension ContentView {
	
	var descriptionHeader: some View {
		Text("Transform your world into a living language laboratory.")
			.font(.system(.title3, design: .rounded))
			.fontWeight(.medium)
			.foregroundColor(.secondary)
			.frame(maxWidth: .infinity, alignment: .leading)
			.padding(.top, -10)
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
			HStack(spacing: 16) {
				Text(selectedLanguage.flag)
					.font(.system(size: 32))
					.shadow(radius: 2)
				
				VStack(alignment: .leading, spacing: 0) {
					Text("CURRENTLY LEARNING")
						.font(.system(size: 10, weight: .heavy))
					Text(selectedLanguage.displayName)
						.font(.title3.bold())
				}
				
				Spacer()
				
				Image(systemName: "chevron.up.chevron.down")
					.font(.caption.bold())
					.foregroundColor(.secondary)
			}
			.padding(.horizontal, 20)
			.padding(.vertical, 16)
			.background(Color(.secondarySystemGroupedBackground))
			.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
			.foregroundColor(.primary)
			.shadow(color: .black.opacity(0.05), radius: 10, y: 5)
		}
	}
	
	var instructionsSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text("Learning Modes")
				.font(.system(.headline, design: .rounded))
				.padding(.leading, 4)
			
			VStack(spacing: 0) {
				stepRow(
					icon: "sparkles",
					color: .blue,
					title: "Quick Scan",
					text: "Instant, real-time object labeling.",
					action: { activeInfoType = .quickScan }
				)
				
				Divider().padding(.leading, 72)
				
				stepRow(
					icon: "map.fill",
					color: .orange,
					title: "Scavenger Hunt",
					text: "Interactive recall & search missions.",
					action: { activeInfoType = .scavengerHunt }
				)
			}
			.background(Color(.secondarySystemGroupedBackground))
			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
		}
	}
	
	func stepRow(icon: String, color: Color, title: String, text: String, action: @escaping () -> Void) -> some View {
		Button(action: action) {
			HStack(spacing: 16) {
				ZStack {
					Circle()
						.fill(color.gradient.opacity(0.15))
						.frame(width: 44, height: 44)
					Image(systemName: icon)
						.font(.system(size: 18, weight: .bold))
						.foregroundColor(color)
				}
				
				VStack(alignment: .leading, spacing: 2) {
					Text(title)
						.font(.system(.subheadline, design: .rounded).bold())
						.foregroundColor(.primary)
					Text(text)
						.font(.caption)
						.foregroundColor(.secondary)
				}
				
				Spacer()
				
				Image(systemName: "info.circle.fill")
					.symbolRenderingMode(.hierarchical)
					.font(.title3)
					.foregroundStyle(color)
			}
			.padding(16)
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
	}
	
	var modeSelectionArea: some View {
		HStack(spacing: 16) {
			NavigationLink(destination: QuickScanView()) {
				Label("Quick Scan", systemImage: "bolt.fill")
					.font(.headline)
					.frame(maxWidth: .infinity)
					.frame(height: 60)
					.background(Color.blue.gradient)
					.foregroundColor(.white)
					.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
			}
			
			NavigationLink(destination: ScannerView()) {
				Label("Start Hunt", systemImage: "flag.checkered")
					.font(.headline)
					.frame(maxWidth: .infinity)
					.frame(height: 60)
					.background(Color.orange.gradient)
					.foregroundColor(.white)
					.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
			}
		}
	}
	
	var privacySection: some View {
		VStack(spacing: 16) {
				// Modern Shield Badge
			ZStack {
				Circle()
					.fill(Color.blue.opacity(0.1))
					.frame(width: 60, height: 60)
				
				Image(systemName: "lock.shield.fill")
					.font(.system(size: 28))
					.symbolRenderingMode(.hierarchical)
					.foregroundStyle(Color.blue)
			}
			
			VStack(spacing: 4) {
				Text("Your Privacy, Our Priority.")
					.font(.system(.subheadline, design: .rounded).bold())
				
				Text("LingoLens uses secure on-device intelligence to recognize your surroundings and translate the words. No data ever leaves your device.")
					.font(.caption)
					.foregroundColor(.secondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 20)
			}
		}
		.padding(.top, 24)
		.padding(.bottom, 12)
	}
}

	// MARK: - The Consolidated Info Sheet

struct LingoInfoSheet: View {
	@Environment(\.dismiss) private var dismiss
	let type: InfoType
	let selectedLanguage: AppLanguage
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .center, spacing: 32) {
						// Icon and Header Section
					VStack(spacing: 16) {
						ZStack {
							Circle()
								.fill((type == .quickScan ? Color.blue : Color.orange).gradient.opacity(0.1))
								.frame(width: 100, height: 100)
							
							Image(systemName: type == .quickScan ? "bolt.horizontal.circle.fill" : "flag.checkered.2.crossed")
								.font(.system(size: 50))
								.symbolRenderingMode(.hierarchical)
								.foregroundStyle(type == .quickScan ? Color.blue : Color.orange)
						}
						
						VStack(spacing: 8) {
							Text(type == .quickScan ? "Quick Scan" : "Scavenger Hunt")
								.font(.system(.title, design: .rounded).bold())
							
							Text(type == .quickScan ? "Identify and translate objects in your surroundings instantly on-device." : "Turn your room into an interactive puzzle. Scan, curate, and test your memory.")
								.font(.subheadline)
								.foregroundColor(.secondary)
								.multilineTextAlignment(.center)
								.padding(.horizontal, 16)
						}
					}
					
						// Instruction List
					VStack(spacing: 0) {
						if type == .quickScan {
							InstructionDetailRow(
								icon: "camera.viewfinder",
								color: .blue,
								title: "Explore Your Space",
								detail: "Point your camera at objects. LingoLens detects and labels items that are visible in the frame."
							)
							Divider().padding(.leading, 72)
							InstructionDetailRow(
								icon: "sparkles.rectangle.stack.fill",
								color: .blue,
								title: "Instant Vocabulary",
								detail: "Bridge the gap between seeing an object and knowing its name. Perfect for rapid-fire visual learning."
							)
						} else {
							InstructionDetailRow(
								icon: "dot.viewfinder",
								color: .orange,
								title: "1. Scan & Extract",
								detail: "Move around your environment. LingoLens intelligently identifies all visible objects."
							)
							Divider().padding(.leading, 72)
							InstructionDetailRow(
								icon: "slider.horizontal.3",
								color: .orange,
								title: "2. Refine Your List",
								detail: "Review extracted items. Manually remove objects or add custom challenges to tailor your experience."
							)
							Divider().padding(.leading, 72)
							InstructionDetailRow(
								icon: "character.bubble.fill",
								color: .orange,
								title: "3. The Language Test",
								detail: "The hunt begins! You'll be prompted with names in \(selectedLanguage.displayName). You must recall the object."
							)
							Divider().padding(.leading, 72)
							InstructionDetailRow(
								icon: "target",
								color: .orange,
								title: "4. Verify & Win",
								detail: "Physically find and scan the object. Once recognized, the challenge is complete!"
							)
						}
					}
					.background(Color(.secondarySystemGroupedBackground))
					.clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
				}
				.padding(.horizontal, 20)
			}
			.background(Color(.systemGroupedBackground))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button("Done") { dismiss() }
						.fontWeight(.bold)
				}
			}
		}
	}
}

struct InstructionDetailRow: View {
	let icon: String
	let color: Color
	let title: String
	let detail: String
	
	var body: some View {
		HStack(spacing: 20) {
			Image(systemName: icon)
				.symbolRenderingMode(.hierarchical)
				.font(.system(size: 28))
				.foregroundColor(color)
				.frame(width: 44)
			
			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.system(.subheadline, design: .rounded).bold())
					.foregroundColor(.primary)
				Text(detail)
					.font(.footnote)
					.foregroundColor(.secondary)
					.fixedSize(horizontal: false, vertical: true)
					.lineSpacing(2)
			}
			
			Spacer()
		}
		.padding(.vertical, 20)
		.padding(.horizontal, 20)
	}
}


	//import SwiftUI
//
//@available(iOS 26.0, *)
//struct ContentView: View {
//	
//		// MARK: - State
//	@AppStorage("selected_language")
//	private var selectedLanguageRaw = AppLanguage.french.rawValue
//	
//		// Track which info type to show
//	@State private var activeInfoType: InfoType?
//	
//	private var selectedLanguage: AppLanguage {
//		AppLanguage(rawValue: selectedLanguageRaw) ?? .french
//	}
//	
//		// MARK: - Body
//	var body: some View {
//		NavigationStack {
//			ScrollView(showsIndicators: false) {
//				VStack(spacing: 36) {
//					descriptionHeader
//					
//					languagePicker
//					
//					instructionsSection
//					
//					modeSelectionArea
//					
//					privacySection
//				}
//				.padding(24)
//			}
//			.navigationTitle("LingoLens")
//			.background(Color(.systemGroupedBackground))
//			.sheet(item: $activeInfoType) { type in
//				LingoInfoSheet(type: type, selectedLanguage: selectedLanguage)
//			}
//		}
//	}
//}
//
//	// MARK: - Supporting Types
//enum InfoType: String, Identifiable {
//	case quickScan, scavengerHunt
//	var id: String { self.rawValue }
//}
//
//	// MARK: - UI Components
//private extension ContentView {
//	
//	var descriptionHeader: some View {
//		Text("Transform your world into a living language laboratory.")
//			.font(.system(.title3, design: .rounded))
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
//			HStack(spacing: 16) {
//				Text(selectedLanguage.flag)
//					.font(.system(size: 32))
//					.shadow(radius: 2)
//				
//				VStack(alignment: .leading, spacing: 0) {
//					Text("CURRENTLY LEARNING")
//						.font(.system(size: 10, weight: .heavy))
//					Text(selectedLanguage.displayName)
//						.font(.title3.bold())
//				}
//				
//				Spacer()
//				
//				Image(systemName: "chevron.up.chevron.down")
//					.font(.caption.bold())
//					.foregroundColor(.secondary)
//			}
//			.padding(.horizontal, 20)
//			.padding(.vertical, 16)
//			.background(Color(.secondarySystemGroupedBackground))
//			.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//			.foregroundColor(.primary)
//			.shadow(color: .black.opacity(0.05), radius: 10, y: 5)
//		}
//	}
//	
//	var instructionsSection: some View {
//		VStack(alignment: .leading, spacing: 16) {
//			Text("Learning Modes")
//				.font(.system(.headline, design: .rounded))
//				.padding(.leading, 4)
//			
//			VStack(spacing: 0) {
//				stepRow(
//					icon: "sparkles",
//					color: .blue,
//					title: "Quick Scan",
//					text: "Instant, real-time object labeling.",
//					action: { activeInfoType = .quickScan }
//				)
//				
//				Divider().padding(.leading, 72)
//				
//				stepRow(
//					icon: "map.fill",
//					color: .orange,
//					title: "Scavenger Hunt",
//					text: "Interactive recall & search missions.",
//					action: { activeInfoType = .scavengerHunt }
//				)
//			}
//			.background(Color(.secondarySystemGroupedBackground))
//			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
//		}
//	}
//	
//	func stepRow(icon: String, color: Color, title: String, text: String, action: @escaping () -> Void) -> some View {
//		Button(action: action) {
//			HStack(spacing: 16) {
//				ZStack {
//					Circle()
//						.fill(color.gradient.opacity(0.15))
//						.frame(width: 44, height: 44)
//					Image(systemName: icon)
//						.font(.system(size: 18, weight: .bold))
//						.foregroundColor(color)
//				}
//				
//				VStack(alignment: .leading, spacing: 2) {
//					Text(title)
//						.font(.system(.subheadline, design: .rounded).bold())
//						.foregroundColor(.primary)
//					Text(text)
//						.font(.caption)
//						.foregroundColor(.secondary)
//				}
//				
//				Spacer()
//				
//				Image(systemName: "info.circle.fill")
//					.symbolRenderingMode(.hierarchical)
//					.font(.title3)
//					.foregroundStyle(color)
//			}
//			.padding(16)
//			.contentShape(Rectangle())
//		}
//		.buttonStyle(.plain)
//	}
//	
//	var modeSelectionArea: some View {
//		HStack(spacing: 16) {
//			NavigationLink(destination: QuickScanView()) {
//				Label("Quick Scan", systemImage: "bolt.fill")
//					.font(.headline)
//					.frame(maxWidth: .infinity)
//					.frame(height: 60)
//					.background(Color.blue.gradient)
//					.foregroundColor(.white)
//					.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
//			}
//			
//			NavigationLink(destination: ScannerView()) {
//				Label("Start Hunt", systemImage: "flag.checkered")
//					.font(.headline)
//					.frame(maxWidth: .infinity)
//					.frame(height: 60)
//					.background(Color.orange.gradient)
//					.foregroundColor(.white)
//					.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
//			}
//		}
//	}
//	
//	var privacySection: some View {
//		VStack(spacing: 12) {
//			Image(systemName: "hand.raised.badge.shield.fill")
//				.symbolRenderingMode(.multicolor)
//				.font(.system(size: 32))
//			
//			VStack(spacing: 4) {
//				Text("Your privacy is our priority.")
//					.font(.subheadline.bold())
//				
//				Text("LingoLens uses secure on-device intelligence to recognize your surroundings. No image data ever leaves this device.")
//					.font(.caption)
//					.foregroundColor(.secondary)
//					.multilineTextAlignment(.center)
//					.padding(.horizontal, 10)
//			}
//		}
//		.padding(.top, 20)
//	}
//}
//
//	// MARK: - The Consolidated Info Sheet
//
//struct LingoInfoSheet: View {
//	@Environment(\.dismiss) private var dismiss
//	let type: InfoType
//	let selectedLanguage: AppLanguage
//	
//	var body: some View {
//		NavigationStack {
//			ScrollView {
//				VStack(alignment: .leading, spacing: 32) {
//					if type == .quickScan {
//						ModalHeader(
//							title: "Quick Scan",
//							icon: "bolt.horizontal.circle.fill", // More modern symbol
//							color: .blue,
//							description: "Identify and translate objects in your surroundings instantly on-device."
//						)
//						
//						VStack(spacing: 0) {
//							InstructionDetailRow(
//								icon: "camera.viewfinder",
//								color: .blue,
//								title: "Explore Your Space",
//								detail: "Point your camera at objects. LingoLens detects and labels items that are visible in the frame."
//							)
//							Divider().padding(.leading, 56)
//							InstructionDetailRow(
//								icon: "sparkles.rectangle.stack.fill",
//								color: .blue,
//								title: "Instant Vocabulary",
//								detail: "Bridge the gap between seeing an object and knowing its name. Perfect for rapid-fire visual learning."
//							)
//						}
//						.background(Color(.secondarySystemGroupedBackground))
//						.clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
//						
//					} else {
//						ModalHeader(
//							title: "Scavenger Hunt",
//							icon: "flag.checkered.2.crossed", // Competitive/Game feel
//							color: .orange,
//							description: "Turn your room into an interactive puzzle. Scan, curate, and test your memory."
//						)
//						
//						VStack(spacing: 0) {
//							InstructionDetailRow(
//								icon: "dot.viewfinder",
//								color: .orange,
//								title: "1. Scan & Extract",
//								detail: "Move around your environment. LingoLens intelligently identifies and extracts a list of all visible objects."
//							)
//							Divider().padding(.leading, 56)
//							InstructionDetailRow(
//								icon: "slider.horizontal.3",
//								color: .orange,
//								title: "2. Refine Your List",
//								detail: "Review the extracted items. You can manually remove objects or add custom challenges to tailor the hunt to your level."
//							)
//							Divider().padding(.leading, 56)
//							InstructionDetailRow(
//								icon: "character.bubble.fill",
//								color: .orange,
//								title: "3. The Language Test",
//								detail: "The hunt begins! You'll be prompted with names only in \(selectedLanguage.displayName). You must recall what they are."
//							)
//							Divider().padding(.leading, 56)
//							InstructionDetailRow(
//								icon: "target",
//								color: .orange,
//								title: "4. Verify & Win",
//								detail: "Physically find the object and scan it. Once LingoLens recognizes the match, the challenge is complete!"
//							)
//						}
//						.background(Color(.secondarySystemGroupedBackground))
//						.clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
//					}
//				}
//				.padding(24)
//			}
//			.background(Color(.systemGroupedBackground))
//			.navigationBarTitleDisplayMode(.inline)
//			.toolbar {
//				ToolbarItem(placement: .confirmationAction) {
//					Button("Done") { dismiss() }
//						.fontWeight(.bold)
//				}
//			}
//		}
//	}
//}
//
//	// Ensure your InstructionDetailRow uses the hierarchical symbol rendering for extra polish
//struct InstructionDetailRow: View {
//	let icon: String
//	let color: Color
//	let title: String
//	let detail: String
//	
//	var body: some View {
//		HStack(spacing: 16) {
//			Image(systemName: icon)
//				.symbolRenderingMode(.hierarchical) // Makes icons look way more "iOS Native"
//				.font(.title2.bold())
//				.foregroundColor(color)
//				.frame(width: 40)
//			
//			VStack(alignment: .leading, spacing: 4) {
//				Text(title)
//					.font(.subheadline.bold())
//					.foregroundColor(.primary)
//				Text(detail)
//					.font(.caption)
//					.foregroundColor(.secondary)
//					.fixedSize(horizontal: false, vertical: true)
//			}
//		}
//		.padding(.vertical, 18)
//		.padding(.horizontal, 16)
//	}
//}
//
//
//	// MARK: - Shared UI Subcomponents
//
//struct ModalHeader: View {
//	let title: String
//	let icon: String
//	let color: Color
//	let description: String
//	
//	var body: some View {
//		VStack(alignment: .leading, spacing: 14) {
//			HStack(spacing: 12) {
//				Image(systemName: icon)
//					.font(.system(size: 34, weight: .bold))
//					.foregroundStyle(color.gradient)
//				Text(title)
//					.font(.system(.title, design: .rounded).bold())
//			}
//			Text(description)
//				.font(.callout)
//				.foregroundStyle(.secondary)
//				.lineSpacing(4)
//		}
//	}
//}
//struct LingoInfoSheet: View {
//	@Environment(\.dismiss) private var dismiss
//	let type: InfoType
//	let selectedLanguage: AppLanguage
//
//	var body: some View {
//		NavigationStack {
//			ScrollView {
//				VStack(alignment: .leading, spacing: 28) {
//					if type == .quickScan {
//						ModalHeader(
//							title: "Quick Scan",
//							icon: "bolt.circle.fill",
//							color: .blue,
//							description: "Identify the world around you in real-time using advanced Computer Vision."
//						)
//
//						VStack(spacing: 0) {
//							InstructionDetailRow(icon: "camera.viewfinder", color: .blue, title: "Point & Detect", detail: "Focus your camera on any object to see its name appear instantly.")
//							Divider().padding(.leading, 56)
//							InstructionDetailRow(icon: "speaker.wave.3.fill", color: .blue, title: "Audio Immersion", detail: "Tap labels to hear the correct pronunciation in \(selectedLanguage.displayName).")
//							Divider().padding(.leading, 56)
//							InstructionDetailRow(icon: "plus.circle.fill", color: .blue, title: "Build Vocabulary", detail: "Save discovered objects to your personal learning list for later review.")
//						}
//						.background(Color(.secondarySystemGroupedBackground))
//						.clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
//
//					} else {
//						ModalHeader(
//							title: "Scavenger Hunt",
//							icon: "flag.checkered.circle.fill",
//							color: .orange,
//							description: "Master new vocabulary by turning your physical space into an interactive game."
//						)
//
//						VStack(spacing: 0) {
//							InstructionDetailRow(icon: "video.badge.plus", color: .orange, title: "1. Map Your Arena", detail: "Walk around and scan several objects to define your game zone.")
//							Divider().padding(.leading, 56)
//							InstructionDetailRow(icon: "list.bullet.rectangle.stack", color: .orange, title: "2. Set the Challenge", detail: "Review detected items and confirm the ones you want to find.")
//							Divider().padding(.leading, 56)
//							InstructionDetailRow(icon: "brain.head.profile", color: .orange, title: "3. Active Recall", detail: "The app will prompt you with the \(selectedLanguage.displayName) name. You must find the match.")
//							Divider().padding(.leading, 56)
//							InstructionDetailRow(icon: "trophy.fill", color: .orange, title: "4. Complete & Conquer", detail: "Scan the correct object to verify your choice and win the round.")
//						}
//						.background(Color(.secondarySystemGroupedBackground))
//						.clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
//					}
//				}
//				.padding(24)
//			}
//			.background(Color(.systemGroupedBackground))
//			.navigationBarTitleDisplayMode(.inline)
//			.toolbar {
//				ToolbarItem(placement: .confirmationAction) {
//					Button("Done") { dismiss() }
//						.fontWeight(.bold)
//				}
//			}
//		}
//	}
//}

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
//				Text(detail)
//					.font(.caption)
//					.foregroundColor(.secondary)
//					.fixedSize(horizontal: false, vertical: true)
//			}
//		}
//		.padding(.vertical, 18)
//		.padding(.horizontal, 16)
//	}
//}
	//import SwiftUI
//
//@available(iOS 26.0, *)
//struct ContentView: View {
//	
//		// MARK: - State
//	@AppStorage("selected_language")
//	private var selectedLanguageRaw = AppLanguage.french.rawValue
//	
//	@State private var showQuickScanInfo = false
//	@State private var showHuntInfo = false
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
//					languagePicker
//					instructionsSection
//					modeSelectionArea
//					privacyStatement
//				}
//				.padding(24)
//			}
//			.navigationTitle("LingoLens")
//			.navigationBarTitleDisplayMode(.large)
//			.background(Color(.systemGroupedBackground))
//			
//				// Modern Modals
//			.sheet(isPresented: $showQuickScanInfo) {
//				QuickScanInfoSheet(selectedLanguage: selectedLanguage)
//					.presentationDetents([.medium, .large])
//					.presentationDragIndicator(.visible)
//			}
//			.sheet(isPresented: $showHuntInfo) {
//				ScavengerHuntInfoSheet(selectedLanguage: selectedLanguage)
//					.presentationDetents([.medium, .large])
//					.presentationDragIndicator(.visible)
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
//			.padding(.top, -20)
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
//	var modeSelectionArea: some View {
//		HStack(spacing: 12) {
//			NavigationLink {
//				QuickScanView()
//			} label: {
//				Label("Quick Scan", systemImage: "bolt.fill")
//					.font(.headline)
//					.frame(maxWidth: .infinity)
//					.frame(height: 56)
//					.background(Color.blue.gradient)
//					.foregroundColor(.white)
//					.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//			}
//			
//			NavigationLink {
//				ScannerView()
//			} label: {
//				Label("Start Hunt", systemImage: "flag.checkered.2.crossed")
//					.font(.headline)
//					.frame(maxWidth: .infinity)
//					.frame(height: 56)
//					.background(Color.orange.gradient)
//					.foregroundColor(.white)
//					.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
//			}
//		}
//	}
//	
//	var instructionsSection: some View {
//		VStack(alignment: .leading, spacing: 16) {
//			Text("Your Learning Journey")
//				.font(.system(.headline, design: .rounded))
//			
//			VStack(spacing: 0) {
//				stepRow(icon: "bolt.fill", color: .blue, title: "Quick Scan", text: "Instant recognition.", action: { showQuickScanInfo = true })
//				Divider().padding(.leading, 70)
//				stepRow(icon: "flag.checkered.2.crossed", color: .orange, title: "Scavenger Hunt", text: "Active recall challenge.", action: { showHuntInfo = true })
//			}
//			.background(Color(.secondarySystemGroupedBackground))
//			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
//		}
//	}
//	
//	func stepRow(icon: String, color: Color, title: String, text: String, action: @escaping () -> Void) -> some View {
//		Button(action: action) {
//			HStack(spacing: 16) {
//					// Icon Badge
//				Image(systemName: icon)
//					.font(.title3.bold())
//					.foregroundColor(color)
//					.frame(width: 44, height: 44)
//					.background(color.opacity(0.1))
//					.clipShape(Circle())
//				
//					// Text Content
//				VStack(alignment: .leading, spacing: 2) {
//					Text(title)
//						.font(.system(.subheadline, design: .rounded).bold())
//						.foregroundColor(.primary)
//					Text(text)
//						.font(.caption)
//						.foregroundColor(.secondary)
//				}
//				
//				Spacer()
//				
//					// The "i" Button replacing the chevron
//				Image(systemName: "info.circle")
//					.font(.title3)
//					.foregroundStyle(.tertiary) // Subtle grey look
//			}
//			.padding(16)
//			.contentShape(Rectangle()) // Makes the whole row tappable
//		}
//		.buttonStyle(.plain) // Prevents the whole row from turning blue/grey when tapped
//	}
//	
//	var privacyStatement: some View {
//		VStack(spacing: 8) {
//			Image(systemName: "lock.shield.fill")
//				.symbolRenderingMode(.hierarchical)
//				.font(.title2)
//				.foregroundStyle(.blue)
//			Text("All processing happens on-device.")
//				.font(.caption2)
//				.foregroundColor(.secondary)
//		}
//	}
//}
//
//	// MARK: - Reusable Modern Sheets
//
//struct QuickScanInfoSheet: View {
//	@Environment(\.dismiss) private var dismiss
//	let selectedLanguage: AppLanguage
//	
//	var body: some View {
//		NavigationStack {
//			ScrollView {
//				VStack(alignment: .leading, spacing: 24) {
//					ModalHeader(title: "Quick Scan", icon: "bolt.fill", color: .blue, description: "Instantly discover and learn words from objects around you.")
//					
//					VStack(spacing: 0) {
//						InstructionDetailRow(icon: "camera.viewfinder", color: .blue, title: "Point & Identify", detail: "The camera recognizes objects in real time using on-device intelligence.")
//						Divider().padding(.leading, 56)
//						InstructionDetailRow(icon: "speaker.wave.2.fill", color: .blue, title: "Visual & Audio", detail: "The word appears in \(selectedLanguage.displayName) with native pronunciation.")
//					}
//					.background(Color(.secondarySystemGroupedBackground))
//					.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//				}
//				.padding(24)
//			}
//			.navigationBarTitleDisplayMode(.inline)
//			.background(Color(.systemGroupedBackground))
//			.toolbar {
//				ToolbarItem(placement: .topBarTrailing) {
//					Button("Done") { dismiss() }.fontWeight(.semibold)
//				}
//			}
//		}
//	}
//}
//
//struct ScavengerHuntInfoSheet: View {
//	@Environment(\.dismiss) private var dismiss
//	let selectedLanguage: AppLanguage
//	
//	var body: some View {
//		NavigationStack {
//			ScrollView {
//				VStack(alignment: .leading, spacing: 24) {
//					ModalHeader(title: "Scavenger Hunt", icon: "target", color: .orange, description: "Scan objects, build a custom list, and test your memory through interaction.")
//					
//					VStack(spacing: 0) {
//						InstructionDetailRow(icon: "video.badge.plus", color: .orange, title: "1. Capture", detail: "Move through your room and scan everyday items.")
//						Divider().padding(.leading, 56)
//						InstructionDetailRow(icon: "checklist", color: .orange, title: "2. Curate", detail: "Review the objects and create your personalized challenge.")
//						Divider().padding(.leading, 56)
//						InstructionDetailRow(icon: "questionmark.circle", color: .orange, title: "3. Recall", detail: "Locate the objects using only their \(selectedLanguage.displayName) names.")
//					}
//					.background(Color(.secondarySystemGroupedBackground))
//					.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//				}
//				.padding(24)
//			}
//			.navigationBarTitleDisplayMode(.inline)
//			.background(Color(.systemGroupedBackground))
//			.toolbar {
//				ToolbarItem(placement: .topBarTrailing) {
//					Button("Done") { dismiss() }.fontWeight(.semibold)
//				}
//			}
//		}
//	}
//}
//
//	// MARK: - Shared UI Subcomponents
//
//struct ModalHeader: View {
//	let title: String
//	let icon: String
//	let color: Color
//	let description: String
//	
//	var body: some View {
//		VStack(alignment: .leading, spacing: 12) {
//			HStack(spacing: 12) {
//				Image(systemName: icon)
//					.font(.title2.bold())
//					.foregroundStyle(color)
//				Text(title)
//					.font(.title2.bold())
//			}
//			Text(description)
//				.font(.subheadline)
//				.foregroundStyle(.secondary)
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
//				Text(detail).font(.caption).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
//			}
//		}
//		.padding(16)
//	}
//}



	//import SwiftUI
//
//	/// The landing page for LingoLens, designed for the Swift Student Challenge.
//	/// Features a personalized onboarding experience and synchronized mode selection.
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
//			.padding(.top, -20)
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
//			
//			VStack(spacing: 0) {
//				stepRow(
//					icon: "bolt.fill",
//					color: .blue,
//					title: "Quick Scan",
//					text: "Scan objects and get their \(selectedLanguage.displayName) names instantly."
//				)
//				
//				Divider().padding(.leading, 72)
//				
//				stepRow(
//					icon: "flag.checkered.2.crossed",
//					color: .orange,
//					title: "Scavenger Hunt",
//					text: "Scan your surroundings to create a personalized list of objects, then hunt them using their \(selectedLanguage.displayName) names."
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
//				// QUICK SCAN: Updated from Button to NavigationLink
//			NavigationLink {
//				QuickScanView() // Navigates to the screen we just made
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
//			NavigationLink {
//				ScannerView()
//			} label: {
//				HStack(spacing: 8) {
//					Image(systemName: "flag.checkered.2.crossed")
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
//	// MARK: - Info Sheet
//struct InfoSheet: View {
//	
//	@Environment(\.dismiss) private var dismiss
//	let selectedLanguage: AppLanguage
//	
//	var body: some View {
//		NavigationStack {
//			ScrollView {
//				VStack(alignment: .leading, spacing: 32) {
//					
//						// MARK: Quick Scan
//					
//					VStack(alignment: .leading, spacing: 16) {
//						
//						headerLabel(
//							title: "Quick Scan",
//							icon: "bolt.fill",
//							color: .blue
//						)
//						
//						Text("Instantly discover and learn words from objects around you.")
//							.font(.subheadline)
//							.foregroundStyle(.secondary)
//						
//						VStack(spacing: 0) {
//							
//							InstructionDetailRow(
//								icon: "camera.viewfinder",
//								color: .blue,
//								title: "Point at an object",
//								detail: "The camera recognizes objects in real time using on-device intelligence."
//							)
//							
//							Divider()
//								.padding(.leading, 56)
//							
//							InstructionDetailRow(
//								icon: "speaker.wave.2.fill",
//								color: .blue,
//								title: "See and hear the word",
//								detail: "The object name appears in \(selectedLanguage.displayName), helping build fast recognition."
//							)
//						}
//						.background(Color(.secondarySystemGroupedBackground))
//						.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//					}
//					
//					
//						// MARK: Scavenger Hunt
//					
//					VStack(alignment: .leading, spacing: 16) {
//						
//						headerLabel(
//							title: "Scavenger Hunt",
//							icon: "target",
//							color: .orange
//						)
//						
//						Text("Scan objects, choose what to learn, and test memory through real-world interaction.")
//							.font(.subheadline)
//							.foregroundStyle(.secondary)
//						
//						VStack(spacing: 0) {
//							
//							InstructionDetailRow(
//								icon: "video.badge.plus",
//								color: .orange,
//								title: "Scan your surroundings",
//								detail: "Move around and capture different everyday objects."
//							)
//							
//							Divider()
//								.padding(.leading, 56)
//							
//							InstructionDetailRow(
//								icon: "checklist",
//								color: .orange,
//								title: "Review and select",
//								detail: "Keep useful objects, remove unwanted ones, or add custom items."
//							)
//							
//							Divider()
//								.padding(.leading, 56)
//							
//							InstructionDetailRow(
//								icon: "questionmark.circle",
//								color: .orange,
//								title: "Find them again",
//								detail: "Object names appear in \(selectedLanguage.displayName). Locate the correct object to reinforce memory."
//							)
//						}
//						.background(Color(.secondarySystemGroupedBackground))
//						.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
//					}
//				}
//				.padding(24)
//			}
//			.navigationTitle("How it works")
//			.navigationBarTitleDisplayMode(.inline)
//			.background(Color(.systemGroupedBackground))
//			.toolbar {
//				ToolbarItem(placement: .cancellationAction) {
//					Button {
//						dismiss()
//					} label: {
//						Image(systemName: "xmark")
//							.font(.body.weight(.semibold))
//					}
//				}
//			}
//		}
//	}
//	
//	
//		// MARK: Section Header
//	
//	private func headerLabel(
//		title: String,
//		icon: String,
//		color: Color
//	) -> some View {
//		
//		HStack(spacing: 12) {
//			
//			Image(systemName: icon)
//				.font(.headline)
//				.foregroundStyle(color)
//			
//			Text(title)
//				.font(.title3.weight(.semibold))
//				.foregroundStyle(.primary)
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
