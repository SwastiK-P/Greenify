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

@MainActor
class ScanViewModel: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var scannedItem: ScannedItem?
    @Published var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    @Published var scanHistory: [ScannedItem] = []
    
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var cancellables = Set<AnyCancellable>()
    
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
        
        isScanning = true
        errorMessage = nil
    }
    
    func stopScanning() {
        isScanning = false
        captureSession?.stopRunning()
    }
    
    func capturePhoto() {
        // Simulate photo capture and analysis
        simulateItemRecognition()
    }
    
    private func simulateItemRecognition() {
        // In a real app, this would use CoreML or a vision framework
        let mockItems = [
            ScannedItem(
                name: "Plastic Water Bottle",
                category: .plastic,
                isRecyclable: true,
                confidence: 0.95,
                disposalInstructions: "Remove cap and label. Rinse clean. Place in recycling bin.",
                environmentalImpact: "Plastic bottles can take 450+ years to decompose. Recycling saves energy and reduces landfill waste.",
                alternatives: ["Reusable water bottle", "Glass bottle", "Stainless steel bottle"]
            ),
            ScannedItem(
                name: "Pizza Box",
                category: .paper,
                isRecyclable: false,
                confidence: 0.88,
                disposalInstructions: "Remove any leftover food. Grease-stained cardboard cannot be recycled. Compost if possible, otherwise dispose in regular trash.",
                environmentalImpact: "Grease contamination makes paper unrecyclable. Clean cardboard can be recycled up to 7 times.",
                alternatives: ["Reusable containers for takeout", "Compostable packaging"]
            ),
            ScannedItem(
                name: "Glass Jar",
                category: .glass,
                isRecyclable: true,
                confidence: 0.92,
                disposalInstructions: "Remove lid and labels. Rinse clean. Place in glass recycling bin.",
                environmentalImpact: "Glass is 100% recyclable and can be recycled endlessly without loss of quality.",
                alternatives: ["Reuse for storage", "Return to manufacturer if returnable"]
            ),
            ScannedItem(
                name: "Aluminum Can",
                category: .metal,
                isRecyclable: true,
                confidence: 0.97,
                disposalInstructions: "Rinse clean. No need to remove labels. Place in metal recycling bin.",
                environmentalImpact: "Aluminum cans can be recycled infinitely. Recycling saves 95% of the energy needed to make new cans.",
                alternatives: ["Reusable containers", "Glass bottles"]
            ),
            ScannedItem(
                name: "Smartphone",
                category: .electronics,
                isRecyclable: true,
                confidence: 0.85,
                disposalInstructions: "Remove personal data. Take to certified e-waste recycling center. Do not put in regular trash.",
                environmentalImpact: "Contains valuable metals and hazardous materials. Proper recycling recovers materials and prevents pollution.",
                alternatives: ["Donate if working", "Trade-in programs", "Repair instead of replace"]
            )
        ]
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            let randomItem = mockItems.randomElement()!
            self?.scannedItem = randomItem
            self?.addToHistory(randomItem)
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
        // In a real app, this would save to Core Data or UserDefaults
        // For now, we'll just keep it in memory
    }
    
    private func loadScanHistory() {
        // In a real app, this would load from persistent storage
        // For now, start with empty history
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