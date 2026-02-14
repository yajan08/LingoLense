import SwiftUI

struct ContentView: View {
	
		// Persist language
	@AppStorage("selected_language")
	private var selectedLanguageRaw = AppLanguage.french.rawValue
	
	private var selectedLanguage: AppLanguage {
		AppLanguage(rawValue: selectedLanguageRaw) ?? .french
	}
	
	var body: some View {
		
		NavigationStack {
			
			VStack(spacing: 32) {
				
				Spacer()
				
				header
				
				languagePicker
				
				Spacer()
				
				startScanButton
				
				Spacer()
			}
			.padding(24)
		}
	}
}

#Preview {
	ContentView()
}


// MARK: Header

private extension ContentView {
	
	var header: some View {
		
		VStack(spacing: 10) {
			
			Text("LingoLens")
				.font(.system(size: 42, weight: .bold, design: .rounded))
			
			Text("Learn languages from real objects. Pick a language to learn")
				.font(.subheadline)
				.foregroundColor(.secondary)
		}
	}
}


// MARK: Native iOS Picker Sheet
private extension ContentView {
	
	var languagePicker: some View {
		
		HStack {
			
			Text("Language")
				.font(.headline)
			
			Spacer()
			
			Picker(selection: $selectedLanguageRaw) {
				
				ForEach(AppLanguage.allCases) { language in
					Text("\(language.flag) \(language.displayName)")
						.tag(language.rawValue)
				}
				
			} label: {
				
				HStack(spacing: 6) {
					Text(selectedLanguage.flag)
					Text(selectedLanguage.displayName)
				}
				.foregroundColor(.primary)
			}
			.pickerStyle(.menu)// native dropdown
		}
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 14)
				.fill(Color(.secondarySystemBackground))
		)
	}
}

// start scan button
private extension ContentView {
	
	var startScanButton: some View {
		
		NavigationLink {
			ScannerView()
		} label: {
			
			Text("Start Scan")
				.font(.headline)
				.foregroundColor(.white)
				.frame(maxWidth: .infinity)
				.padding()
				.background(Color.blue)
				.cornerRadius(14)
		}
	}
}

#Preview {
	ContentView()
}
