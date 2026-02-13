import Foundation
import AVFoundation
import Combine

	// 1. Add ObservableObject conformance here
final class CameraService: NSObject, ObservableObject {
	
	let session = AVCaptureSession()
	var frameHandler: ((CVPixelBuffer) -> Void)?
	
	private let videoDataOutput = AVCaptureVideoDataOutput()
	private let videoQueue = DispatchQueue(label: "VideoDataOutputQueue")
	
	override init() {
		super.init()
		configureSession()
	}
	
	private func configureSession() {
		session.beginConfiguration()
		session.sessionPreset = .vga640x480
		
		guard
			let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
			let input = try? AVCaptureDeviceInput(device: device),
			session.canAddInput(input)
		else {
			print("❌ Failed to setup camera input")
			session.commitConfiguration()
			return
		}
		
		session.addInput(input)
		
		if session.canAddOutput(videoDataOutput) {
			videoDataOutput.alwaysDiscardsLateVideoFrames = true
			videoDataOutput.setSampleBufferDelegate(self, queue: videoQueue)
			session.addOutput(videoDataOutput)
			
				// 2. Ensure the video orientation is correct for portrait
			if let connection = videoDataOutput.connection(with: .video) {
				connection.videoOrientation = .portrait
				connection.isEnabled = true
			}
		}
		
		session.commitConfiguration()
	}
	
	func start() {
		guard !session.isRunning else { return }
		DispatchQueue.global(qos: .userInitiated).async {
			self.session.startRunning()
		}
	}
	
	func stop() {
		guard session.isRunning else { return }
		session.stopRunning()
	}
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
		frameHandler?(pixelBuffer)
	}
}
