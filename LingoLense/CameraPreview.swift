//
//  CameraPreview.swift
//  LingoLense
//
//  Created by SDC-USER on 11/02/26.
//

import Foundation
import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
	
	let session: AVCaptureSession
	
	func makeUIView(context: Context) -> UIView {
		let view = UIView()
		let previewLayer = AVCaptureVideoPreviewLayer(session: session)
		previewLayer.videoGravity = .resizeAspectFill
		previewLayer.frame = UIScreen.main.bounds
		view.layer.addSublayer(previewLayer)
		return view
	}
	
	func updateUIView(_ uiView: UIView, context: Context) {}
}
