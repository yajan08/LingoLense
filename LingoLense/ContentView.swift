//
//  ContentView.swift
//  LingoLense
//
//  Created by SDC-USER on 09/02/26.
//

import SwiftUI

struct ContentView: View {
	var body: some View {
		NavigationStack {
			VStack(spacing: 24) {
				Spacer()
				
				Text("Lingo-Lens")
					.font(.system(size: 40, weight: .bold, design: .rounded))
				
				Text("Scan your surroundings and discover objects")
					.font(.subheadline)
					.foregroundColor(.secondary)
				
				Spacer()
				
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
						.padding(.horizontal, 32)
				}
				
				Spacer()
			}
		}
	}
}

#Preview {
    ContentView()
}
