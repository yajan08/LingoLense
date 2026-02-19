import SwiftUI

struct LaunchScreenView: View {
	
		// MARK: Animation States
	
	@State private var isAnimating = false
	@State private var textVisible = false
	@State private var showContent = false
	@State private var heroBreath = false
	@State private var finalZoom = false // Trigger for the final sequence
	
	
		// Stable random symbol layout (prevents flicker)
	private let symbols = FloatingSymbolModel.generate(count: 24)
	
	
		// MARK: Body
	
	var body: some View {
		
		ZStack {
			
				// MARK: Main Content Layer
			
			if showContent {
				ContentView()
					.transition(
						.asymmetric(
							insertion: .opacity.combined(with: .scale(scale: 0.985)),
							removal: .opacity
						)
					)
			}
			
			
				// MARK: Launch Screen Layer
			
			if !showContent {
				
				ZStack {
					
					modernBackground
					
					floatingSymbols
					
					VStack(spacing: 34) {
						
						heroIcon // Parallax zoom handled inside this component
						
						brandTypography
							.opacity(finalZoom ? 0 : 1) // Fade text instead of zooming it
							.animation(.easeOut(duration: 0.4), value: finalZoom)
					}
				}
				.ignoresSafeArea()
				.transition(.opacity)
			}
		}
		.onAppear {
			startAnimationSequence()
		}
	}
}



	//
	// MARK: Background
	//

private extension LaunchScreenView {
	
	var modernBackground: some View {
		
		ZStack {
			
			Color(.systemBackground)
			
			
				// Bright orange glow
			RadialGradient(
				colors: [
					Color.orange.opacity(0.22),
					.clear
				],
				center: .topLeading,
				startRadius: 40,
				endRadius: 520
			)
			
			
				// Bright blue glow
			RadialGradient(
				colors: [
					Color.blue.opacity(0.22),
					.clear
				],
				center: .bottomTrailing,
				startRadius: 40,
				endRadius: 560
			)
			
			
				// Center depth vignette
			RadialGradient(
				colors: [
					.clear,
					Color(.systemBackground).opacity(0.35)
				],
				center: .center,
				startRadius: 180,
				endRadius: 460
			)
		}
	}
}



	//
	// MARK: Hero Icon (Refined for Parallax Zoom)
	//

private extension LaunchScreenView {
	
	var heroIcon: some View {
		
		ZStack {
			
				// Breathing glow (Stays or fades with zoom)
			Circle()
				.fill(
					LinearGradient(
						colors: [
							Color.orange.opacity(0.35),
							Color.blue.opacity(0.35)
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
				.frame(width: 150, height: 150)
				.blur(radius: 32)
				.scaleEffect(heroBreath ? 1.16 : 0.9)
				.opacity(finalZoom ? 0 : 1) // Fade out during portal transition
				.animation(
					.easeInOut(duration: 2.2)
					.repeatForever(autoreverses: true),
					value: heroBreath
				)
			
			
				// Glass plate / Content Group for Parallax
			ZStack {
					// Glass plate
				RoundedRectangle(cornerRadius: 32, style: .continuous)
					.fill(.ultraThinMaterial)
					.frame(width: 118, height: 118)
					.shadow(color: .black.opacity(0.08), radius: 25, y: 10)
					.opacity(finalZoom ? 0 : 1)
				
					// Magnifying glass (AGRESSIVE ZOOM)
				Image(systemName: "magnifyingglass")
					.font(.system(size: 92, weight: .light))
					.foregroundStyle(.primary.opacity(0.95))
					.symbolEffect(
						.rotate.counterClockwise.byLayer,
						options: .repeat(.periodic(delay: 1.3)),
						value: isAnimating
					)
					.scaleEffect(finalZoom ? 15 : 1.0) // Zoom through the lens
				
					// Translate symbol (SUBTLE ZOOM)
				Image(systemName: "translate")
					.font(.system(size: 40, weight: .semibold))
					.symbolRenderingMode(.palette)
					.foregroundStyle(.orange, .blue)
					.offset(x: -2, y: -2)
					.symbolEffect(
						.bounce,
						options: .repeat(.periodic(delay: 2.0)),
						value: isAnimating
					)
					.scaleEffect(finalZoom ? 4 : 1.0) // Less zoom than the glass for depth
					.opacity(finalZoom ? 0 : 1) // Disappear so content behind shows
			}
		}
			// Combined entrance spring
		.scaleEffect(isAnimating ? 1 : 0.86)
		.animation(.spring(response: 0.7, dampingFraction: 0.7), value: isAnimating)
			// Portal zoom animation
		.animation(.easeInOut(duration: 0.8), value: finalZoom)
	}
}



	//
	// MARK: Typography
	//

private extension LaunchScreenView {
	
	var brandTypography: some View {
		
		VStack(spacing: 8) {
			
			Text("LingoLens")
				.font(.system(size: 36, weight: .bold, design: .rounded))
				.foregroundStyle(
					LinearGradient(
						colors: [.orange, .blue],
						startPoint: .leading,
						endPoint: .trailing
					)
				)
			
			
			Text("See the world. Learn the words.")
				.font(.system(.subheadline, design: .rounded))
				.fontWeight(.medium)
				.foregroundStyle(.secondary)
		}
		.opacity(textVisible ? 1 : 0)
		.offset(y: textVisible ? 0 : 16)
		.animation(.easeOut(duration: 0.9).delay(0.25), value: textVisible)
	}
}



	//
	// MARK: Floating Symbols
	//

private extension LaunchScreenView {
	
	var floatingSymbols: some View {
		
		ZStack {
			
			ForEach(symbols) { symbol in
				
				Image(systemName: symbol.name)
					.font(.system(size: symbol.size, weight: .medium))
					.foregroundStyle(symbol.color.opacity(0.32))
					.offset(symbol.offset)
					.scaleEffect(isAnimating ? 1 : 0.5)
					.opacity(isAnimating ? (finalZoom ? 0 : 1) : 0) // Fade background symbols during zoom
					.animation(
						.easeInOut(duration: symbol.duration)
						.repeatForever(autoreverses: true)
						.delay(symbol.delay),
						value: isAnimating
					)
					.animation(.easeOut(duration: 0.4), value: finalZoom)
			}
		}
	}
}



	//
	// MARK: Animation Sequence
	//

private extension LaunchScreenView {
	
	func startAnimationSequence() {
		
		isAnimating = true
		heroBreath = true
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
			textVisible = true
		}
		
			// 1. Trigger the specific parallax zoom
		DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
			withAnimation {
				finalZoom = true
			}
		}
		
			// 2. Final handoff to ContentView
		DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
			withAnimation(.easeInOut(duration: 0.4)) {
				showContent = true
			}
		}
	}
}



	//
	// MARK: Floating Symbol Model
	//

private struct FloatingSymbolModel: Identifiable {
	
	let id = UUID()
	
	let name: String
	let offset: CGSize
	let size: CGFloat
	let delay: Double
	let duration: Double
	let color: Color
	
	
	static func generate(count: Int) -> [FloatingSymbolModel] {
		
		let names = [
			"globe", "character.bubble", "camera.viewfinder", "sparkles", "brain",
			"textformat.abc", "waveform", "eye", "mic", "ellipsis.bubble",
			"book", "quote.bubble", "text.magnifyingglass"
		]
		
		return (0..<count).map { i in
			FloatingSymbolModel(
				name: names[i % names.count],
				offset: CGSize(
					width: CGFloat.random(in: -180...180),
					height: CGFloat.random(in: -360...360)
				),
				size: CGFloat.random(in: 14...24),
				delay: Double.random(in: 0...0.8),
				duration: Double.random(in: 2.5...4.5),
				color: Bool.random() ? .orange : .blue
			)
		}
	}
}

#Preview {
	LaunchScreenView()
}























//	import SwiftUI
//
//struct LaunchScreenView: View {
//	
//		// MARK: Animation States
//	
//	@State private var isAnimating = false
//	@State private var textVisible = false
//	@State private var showContent = false
//	@State private var heroBreath = false
//	
//	
//		// MARK: Body
//	
//	var body: some View {
//		
//		ZStack {
//			
//				// MARK: Layer 1 — Content Reveal
//			
//			if showContent {
//				ContentView()
//					.transition(
//						.asymmetric(
//							insertion: .opacity.combined(with: .scale(scale: 0.985)),
//							removal: .opacity
//						)
//					)
//			}
//			
//			
//				// MARK: Layer 2 — Launch Screen
//			
//			if !showContent {
//				
//				ZStack {
//					
//					modernBackground
//					
//					floatingSymbols
//					
//					VStack(spacing: 34) {
//						
//						heroIcon
//						
//						brandTypography
//						
//					}
//				}
//				.ignoresSafeArea()
//				.transition(.opacity)
//			}
//		}
//		.onAppear {
//			startAnimationSequence()
//		}
//	}
//}
//
//
//
//	//
//	// MARK: Background
//	//
//
//private extension LaunchScreenView {
//	
//	var modernBackground: some View {
//		
//		ZStack {
//			
//			Color(.systemBackground)
//			
//			
//				// subtle orange glow
//			RadialGradient(
//				colors: [
//					Color.orange.opacity(0.18),
//					.clear
//				],
//				center: .topLeading,
//				startRadius: 40,
//				endRadius: 500
//			)
//			
//			
//				// subtle blue glow
//			RadialGradient(
//				colors: [
//					Color.blue.opacity(0.20),
//					.clear
//				],
//				center: .bottomTrailing,
//				startRadius: 40,
//				endRadius: 550
//			)
//		}
//	}
//}
//
//
//
//	//
//	// MARK: Hero Icon
//	//
//
//private extension LaunchScreenView {
//	
//	var heroIcon: some View {
//		
//		ZStack {
//			
//				// breathing glow
//			Circle()
//				.fill(
//					LinearGradient(
//						colors: [
//							Color.orange.opacity(0.25),
//							Color.blue.opacity(0.25)
//						],
//						startPoint: .topLeading,
//						endPoint: .bottomTrailing
//					)
//				)
//				.frame(width: 150, height: 150)
//				.blur(radius: 30)
//				.scaleEffect(heroBreath ? 1.15 : 0.9)
//				.animation(
//					.easeInOut(duration: 2.5)
//					.repeatForever(autoreverses: true),
//					value: heroBreath
//				)
//			
//			
//				// magnifying glass
//			Image(systemName: "magnifyingglass")
//				.font(.system(size: 100, weight: .light))
//				.foregroundStyle(.primary)
//				.symbolEffect(
//					.rotate.counterClockwise.byLayer,
//					options: .repeat(.periodic(delay: 1.4)),
//					value: isAnimating
//				)
//			
//			
//				// translate symbol (core intelligence visual)
//			Image(systemName: "translate")
//				.font(.system(size: 42, weight: .semibold))
//				.symbolRenderingMode(.palette)
//				.foregroundStyle(.orange, .blue)
//				.offset(x: -2, y: -2)
//				.symbolEffect(
//					.bounce,
//					options: .repeat(.periodic(delay: 2.2)),
//					value: isAnimating
//				)
//		}
//		.scaleEffect(isAnimating ? 1 : 0.88)
//		.animation(
//			.spring(response: 0.7, dampingFraction: 0.7),
//			value: isAnimating
//		)
//	}
//}
//
//
//
//	//
//	// MARK: Typography
//	//
//
//private extension LaunchScreenView {
//	
//	var brandTypography: some View {
//		
//		VStack(spacing: 8) {
//			
//			Text("LingoLens")
//				.font(.system(size: 36, weight: .bold, design: .rounded))
//				.foregroundStyle(
//					LinearGradient(
//						colors: [.orange, .blue],
//						startPoint: .leading,
//						endPoint: .trailing
//					)
//				)
//			
//			
//			Text("See the world. Learn the words.")
//				.font(.system(.subheadline, design: .rounded))
//				.fontWeight(.medium)
//				.foregroundStyle(.secondary)
//		}
//		.opacity(textVisible ? 1 : 0)
//		.offset(y: textVisible ? 0 : 14)
//		.animation(
//			.easeOut(duration: 0.9).delay(0.25),
//			value: textVisible
//		)
//	}
//}
//
//
//
//	//
//	// MARK: Floating Symbols
//	//
//
//private extension LaunchScreenView {
//	
//	var floatingSymbols: some View {
//		
//		ZStack {
//			
//			floatingSymbol("camera.viewfinder", -140, -260, .blue, 0)
//			floatingSymbol("sparkles", 130, -220, .orange, 0.2)
//			floatingSymbol("character.bubble", -150, 180, .blue, 0.4)
//			floatingSymbol("globe", 140, 260, .orange, 0.6)
//			floatingSymbol("textformat", -100, 320, .blue, 0.8)
//			floatingSymbol("mic", 160, 60, .orange, 1.0)
//			floatingSymbol("waveform", -170, -60, .blue, 1.2)
//			floatingSymbol("brain", 120, -40, .orange, 1.4)
//		}
//	}
//	
//	
//	func floatingSymbol(
//		_ name: String,
//		_ x: CGFloat,
//		_ y: CGFloat,
//		_ color: Color,
//		_ delay: Double
//	) -> some View {
//		
//		Image(systemName: name)
//			.font(.system(size: 22, weight: .semibold))
//			.foregroundStyle(color.opacity(0.35))
//			.offset(x: x, y: y)
//			.scaleEffect(isAnimating ? 1 : 0.6)
//			.opacity(isAnimating ? 1 : 0)
//			.animation(
//				.easeInOut(duration: 3.5)
//				.repeatForever(autoreverses: true)
//				.delay(delay),
//				value: isAnimating
//			)
//	}
//}
//
//
//
//	//
//	// MARK: Animation Sequence
//	//
//
//private extension LaunchScreenView {
//	
//	func startAnimationSequence() {
//		
//		isAnimating = true
//		textVisible = true
//		heroBreath = true
//		
//		
//			// transition to main app
//		DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
//			
//			withAnimation(.easeInOut(duration: 0.6)) {
//				showContent = true
//			}
//		}
//	}
//}
//
//
//
//#Preview {
//	LaunchScreenView()
//}
