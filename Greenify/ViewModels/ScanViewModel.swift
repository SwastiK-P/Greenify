//
//  ScanViewModel.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import Foundation
import AVFoundation
import UIKit
import Combine
import SwiftUI

@MainActor
class ScanViewModel: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var scannedItem: ScannedItem?
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    @Published var scanHistory: [ScannedItem] = []
    @Published var isProcessing = false
    @Published var processingStage: ProcessingStage = .idle
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var cancellables = Set<AnyCancellable>()
    private let classificationService = ObjectClassificationService()
    
    enum ProcessingStage {
        case idle
        case classifying
        case generatingInstructions
        case complete
    }
    
    override init() {
        super.init()
        checkCameraPermission()
        loadScanHistory()
    }
    
    func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        if cameraPermissionStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.cameraPermissionStatus = granted ? .authorized : .denied
                }
            }
        }
    }
    
    func startScanning() {
        guard cameraPermissionStatus == .authorized else {
            errorMessage = "Camera permission is required to scan items."
            return
        }
        
        print("🔍 Starting scan...")
        setupCaptureSession()
        isScanning = true
        errorMessage = nil
        scannedItem = nil
        processingStage = .idle
        
        // Ensure session starts running
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            if let session = self?.captureSession, !session.isRunning {
                print("⚠️ Session not running, starting now...")
                DispatchQueue.global(qos: .userInitiated).async {
                    session.startRunning()
                }
            }
        }
    }
    
    func stopScanning() {
        isScanning = false
        captureSession?.stopRunning()
        processingStage = .idle
    }
    
    // MARK: - Camera Setup
    
    private func setupCaptureSession() {
        print("📷 Setting up capture session...")
        
        // Create session if it doesn't exist
        if captureSession == nil {
            let session = AVCaptureSession()
            session.sessionPreset = .photo
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                print("❌ Failed to get video device")
                errorMessage = "Failed to access camera device."
                return
            }
            
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                print("❌ Failed to create device input")
                errorMessage = "Failed to create camera input."
                return
            }
            
            guard session.canAddInput(videoDeviceInput) else {
                print("❌ Cannot add video input")
                errorMessage = "Cannot add camera input to session."
                return
            }
            
            session.addInput(videoDeviceInput)
            print("✅ Video input added")
            
            let output = AVCapturePhotoOutput()
            guard session.canAddOutput(output) else {
                print("❌ Cannot add photo output")
                errorMessage = "Cannot add photo output to session."
                return
            }
            
            session.addOutput(output)
            photoOutput = output
            print("✅ Photo output added")
            
            captureSession = session
            print("✅ Capture session created")
        }
        
        // Start session on background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let session = self.captureSession else {
                print("❌ Session is nil")
                return
            }
            
            print("📷 Starting capture session...")
            session.startRunning()
            
            DispatchQueue.main.async {
                if session.isRunning {
                    print("✅ Capture session is running")
                } else {
                    print("❌ Capture session failed to start")
                    self.errorMessage = "Camera failed to start. Please try again."
                }
            }
        }
    }
    
    func getCaptureSession() -> AVCaptureSession? {
        return captureSession
    }
    
    func startCameraSession() {
        guard cameraPermissionStatus == .authorized else {
            print("❌ Camera permission not authorized")
            return
        }
        
        if captureSession == nil {
            setupCaptureSession()
        }
        
        if let session = captureSession, !session.isRunning {
            print("📷 Starting camera session...")
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }
    
    func stopCameraSession() {
        if let session = captureSession, session.isRunning {
            print("📷 Stopping camera session...")
            DispatchQueue.global(qos: .userInitiated).async {
                session.stopRunning()
            }
        }
    }
    
    func capturePhoto(from image: UIImage) {
        Task {
            await processImage(image)
        }
    }
    
    // MARK: - Complete Processing Flow
    
    private func processImage(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        processingStage = .classifying
        
        do {
            // Step 1: Classify object using MobileNet V3
            print("\n🔍 Step 1: Classifying image with MobileNet V3...")
            let classification = try await classificationService.classifyImage(image)
            print("   ✅ Classification result: \(classification.objectName) (confidence: \(String(format: "%.2f%%", classification.confidence * 100)))")
            
            // Step 2: Generate instructions using Foundation Model
            print("\n🤖 Step 2: Generating recycling instructions...")
            processingStage = .generatingInstructions
            let instructions = try await classificationService.generateRecyclingInstructions(for: classification.objectName)
            
            // Step 3: Combine results
            let item = ScannedItem(
                name: classification.objectName,
                category: instructions.category,
                isRecyclable: instructions.isRecyclable,
                confidence: classification.confidence,
                disposalInstructions: instructions.instructions,
                environmentalImpact: instructions.impact,
                alternatives: instructions.alternatives
            )
            
            scannedItem = item
            addToHistory(item)
            processingStage = .complete
            isScanning = false
            
            print("   ✅ Processing complete!")
            print("   📦 Final result: \(item.name)")
            print("   ♻️ Recyclable: \(item.isRecyclable)")
            print("   📁 Category: \(item.category.rawValue)\n")
            
        } catch {
            print("   ❌ Error during processing: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            processingStage = .idle
            
            // Fallback: Use basic classification if Foundation Model fails
            print("   🔄 Attempting fallback classification...")
            await fallbackClassification(image)
        }
        
        isProcessing = false
    }
    
    private func fallbackClassification(_ image: UIImage) async {
        processingStage = .classifying
        
        do {
            // Try just classification without Foundation Model
            let classification = try await classificationService.classifyImage(image)
            
            // Create basic item with default instructions
            // Map category based on object name (fallback since Foundation Model failed)
            let category = inferCategory(from: classification.objectName)
            
            let item = ScannedItem(
                name: classification.objectName,
                category: category,
                isRecyclable: true,
                confidence: classification.confidence,
                disposalInstructions: "Please check local recycling guidelines for \(classification.objectName).",
                environmentalImpact: "Proper disposal helps reduce environmental impact.",
                alternatives: ["Consider reusable alternatives", "Reduce consumption"]
            )
            
            scannedItem = item
            addToHistory(item)
            processingStage = .complete
            isScanning = false
            
        } catch {
            errorMessage = "Failed to classify item: \(error.localizedDescription)"
            processingStage = .idle
        }
    }
    
    // MARK: - Helper Methods
    
    private func inferCategory(from objectName: String) -> RecyclableItem {
        let lowercased = objectName.lowercased()
        
        if lowercased.contains("plastic") || lowercased.contains("bottle") || lowercased.contains("container") {
            return .plastic
        } else if lowercased.contains("paper") || lowercased.contains("cardboard") || lowercased.contains("box") {
            return .paper
        } else if lowercased.contains("glass") || lowercased.contains("jar") {
            return .glass
        } else if lowercased.contains("metal") || lowercased.contains("aluminum") || lowercased.contains("can") {
            return .metal
        } else if lowercased.contains("electronic") || lowercased.contains("phone") || lowercased.contains("device") {
            return .electronics
        } else if lowercased.contains("batter") {
            return .batteries
        } else if lowercased.contains("textile") || lowercased.contains("cloth") || lowercased.contains("fabric") {
            return .textiles
        } else if lowercased.contains("organic") || lowercased.contains("food") || lowercased.contains("compost") {
            return .organic
        } else {
            // Default to plastic if we can't determine
            return .plastic
        }
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto() {
        print("📸 Capture button pressed")
        
        guard let photoOutput = photoOutput else {
            print("❌ Photo output is nil")
            errorMessage = "Camera output is not ready. Please try again."
            return
        }
        
        guard let captureSession = captureSession else {
            print("❌ Capture session is nil")
            errorMessage = "Camera session is not set up. Please try again."
            return
        }
        
        guard captureSession.isRunning else {
            print("❌ Capture session is not running")
            errorMessage = "Camera is not running. Please start scanning again."
            return
        }
        
        print("✅ All checks passed, capturing photo...")
        
        // Create photo settings
        let settings = AVCapturePhotoSettings()
        
        // Enable high-resolution photos if available
        if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            // HEVC will be used automatically if available
        }
        
        // Capture photo with delegate
        photoOutput.capturePhoto(with: settings, delegate: self)
        print("📸 Photo capture initiated")
    }
    
    private func simulateItemRecognition() {
        // Fallback simulation if camera capture not implemented
        let mockItems = [
            ScannedItem(
                name: "Plastic Water Bottle",
                category: .plastic,
                isRecyclable: true,
                confidence: 0.95,
                disposalInstructions: "Remove cap and label. Rinse clean. Place in recycling bin.",
                environmentalImpact: "Plastic bottles can take 450+ years to decompose. Recycling saves energy and reduces landfill waste.",
                alternatives: ["Reusable water bottle", "Glass bottle", "Stainless steel bottle"]
            )
        ]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.scannedItem = mockItems.randomElement()!
            self?.addToHistory(self!.scannedItem!)
            self?.isScanning = false
        }
    }
    
    private func addToHistory(_ item: ScannedItem) {
        scanHistory.insert(item, at: 0)
        
        // Keep only last 20 items
        if scanHistory.count > 20 {
            scanHistory = Array(scanHistory.prefix(20))
        }
        
        saveScanHistory()
    }
    
    func clearScanHistory() {
        scanHistory.removeAll()
        saveScanHistory()
    }
    
    func getRecyclableItemsCount() -> Int {
        return scanHistory.filter { $0.isRecyclable }.count
    }
    
    func getNonRecyclableItemsCount() -> Int {
        return scanHistory.filter { !$0.isRecyclable }.count
    }
    
    func getItemsByCategory() -> [RecyclableItem: Int] {
        let grouped = Dictionary(grouping: scanHistory) { $0.category }
        return grouped.mapValues { $0.count }
    }
    
    private func saveScanHistory() {
        // Save to UserDefaults
        if let encoded = try? JSONEncoder().encode(scanHistory) {
            UserDefaults.standard.set(encoded, forKey: "ScanHistory")
        }
    }
    
    private func loadScanHistory() {
        if let data = UserDefaults.standard.data(forKey: "ScanHistory"),
           let decoded = try? JSONDecoder().decode([ScannedItem].self, from: data) {
            scanHistory = decoded
        }
    }
}

// MARK: - Scanned Item Model

struct ScannedItem: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let category: RecyclableItem
    let isRecyclable: Bool
    let confidence: Double
    let disposalInstructions: String
    let environmentalImpact: String
    let alternatives: [String]
    let scannedDate: Date
    
    init(name: String, category: RecyclableItem, isRecyclable: Bool, confidence: Double, disposalInstructions: String, environmentalImpact: String, alternatives: [String]) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.isRecyclable = isRecyclable
        self.confidence = confidence
        self.disposalInstructions = disposalInstructions
        self.environmentalImpact = environmentalImpact
        self.alternatives = alternatives
        self.scannedDate = Date()
    }
    
    var confidencePercentage: String {
        return String(format: "%.0f%%", confidence * 100)
    }
    
    var recyclabilityStatus: String {
        return isRecyclable ? "Recyclable" : "Not Recyclable"
    }
    
    var statusColor: String {
        return isRecyclable ? "green" : "red"
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension ScanViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("📷 Photo capture delegate called")
        
        if let error = error {
            print("❌ Photo capture error: \(error.localizedDescription)")
            errorMessage = "Failed to capture photo: \(error.localizedDescription)"
            return
        }
        
        print("✅ Photo captured successfully")
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("❌ Failed to get image data")
            errorMessage = "Failed to get image data from photo."
            return
        }
        
        guard let image = UIImage(data: imageData) else {
            print("❌ Failed to create UIImage from data")
            errorMessage = "Failed to process captured image."
            return
        }
        
        print("✅ Image created, size: \(image.size)")
        
        // Process the captured image
        Task {
            await processImage(image)
        }
    }
    
    // Optional: Handle when capture starts
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureForFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        print("📷 Photo capture will begin")
    }
    
    // Optional: Handle when capture completes
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureForFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("❌ Photo capture finished with error: \(error.localizedDescription)")
        } else {
            print("✅ Photo capture finished successfully")
        }
    }
}
