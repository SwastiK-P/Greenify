//
//  CameraPreviewView.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.setupPreviewLayer(with: session)
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Update frame when view bounds change
        uiView.updatePreviewLayerFrame()
    }
}

class CameraPreviewUIView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    func setupPreviewLayer(with session: AVCaptureSession) {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(layer)
        self.previewLayer = layer
        updatePreviewLayerFrame()
    }
    
    func updatePreviewLayerFrame() {
        previewLayer?.frame = bounds
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePreviewLayerFrame()
    }
}
