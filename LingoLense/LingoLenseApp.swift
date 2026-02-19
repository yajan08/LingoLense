import SwiftUI

@main
struct LingoLenseApp: App {
	
	init() {
		
		if #available(iOS 26.0, *) {
			
			Task.detached(priority: .utility) {
				FoundationAIService().prewarm()
			}
		}
	}
	
	var body: some Scene {
		WindowGroup {
			LaunchScreenView()
		}
	}
}

	////
////  LingoLenseApp.swift
////  LingoLense
////
////  Created by SDC-USER on 09/02/26.
////
//
//import SwiftUI
//
//@main
//struct LingoLenseApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}
