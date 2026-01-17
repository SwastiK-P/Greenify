//
//  ObjectClassificationService.swift
//  Greenify
//
//  Created by Swastik Patil on 17/01/26.
//

import Foundation
import Combine
import CoreML
import Vision
import UIKit

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
class ObjectClassificationService: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private var model: VNCoreMLModel?
    private var foundationModel: SystemLanguageModel?
    
    init() {
        loadFastViTModel()
        initializeFoundationModel()
    }
    
    // MARK: - FastViT Model Loading
    
    private func loadFastViTModel() {
        // Load FastViTMA36F16 model (highest accuracy - 88.3MB)
        // Try multiple paths to find the model
        var modelURL: URL?
        
        // Try 1: Direct resource lookup (standard way)
        modelURL = Bundle.main.url(forResource: "FastViTMA36F16", withExtension: "mlpackage")
        
        // Try 2: Look in main bundle with full path
        if modelURL == nil, let bundlePath = Bundle.main.resourcePath {
            let fullPath = (bundlePath as NSString).appendingPathComponent("FastViTMA36F16.mlpackage")
            if FileManager.default.fileExists(atPath: fullPath) {
                modelURL = URL(fileURLWithPath: fullPath)
            }
        }
        
        // Try 3: Look in Greenify subdirectory (if model is in source folder)
        if modelURL == nil, let bundlePath = Bundle.main.resourcePath {
            let fullPath = (bundlePath as NSString).appendingPathComponent("Greenify/FastViTMA36F16.mlpackage")
            if FileManager.default.fileExists(atPath: fullPath) {
                modelURL = URL(fileURLWithPath: fullPath)
            }
        }
        
        // Try 4: Look in the actual source directory (for development)
        if modelURL == nil {
            let sourcePath = "/Users/swastik/Developer/Greenify/Greenify/FastViTMA36F16.mlpackage"
            if FileManager.default.fileExists(atPath: sourcePath) {
                modelURL = URL(fileURLWithPath: sourcePath)
            }
        }
        
        guard let url = modelURL else {
            print("⚠️ FastViT model not found.")
            print("   Searched in:")
            print("   - Bundle resources")
            print("   - Bundle resource path")
            print("   - Greenify subdirectory")
            print("   Please ensure FastViTMA36F16.mlpackage is:")
            print("   1. Added to the Xcode project")
            print("   2. Included in the target membership")
            print("   3. Has 'Copy Bundle Resources' checked in Build Phases")
            // Fallback: Try smaller model
            if let fallbackURL = Bundle.main.url(forResource: "FastViTT8F16", withExtension: "mlpackage") {
                print("   Trying fallback model FastViTT8F16...")
                loadModel(from: fallbackURL)
            }
            return
        }
        
        print("✅ Found FastViT model at: \(url.path)")
        loadModel(from: url)
    }
    
    private func loadModel(from url: URL) {
        do {
            let mlModel = try MLModel(contentsOf: url)
            model = try VNCoreMLModel(for: mlModel)
            print("✅ FastViT model loaded successfully")
        } catch {
            print("❌ Failed to load FastViT model: \(error.localizedDescription)")
            errorMessage = "Failed to load classification model: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Apple Foundation Model
    
    private func initializeFoundationModel() {
        #if canImport(FoundationModels)
        foundationModel = SystemLanguageModel.default
        
        // Check availability
        switch foundationModel?.availability {
        case .available:
            print("✅ Apple Foundation Model is available")
        case .unavailable(let reason):
            print("⚠️ Apple Foundation Model unavailable: \(reason)")
        case .none:
            print("⚠️ Apple Foundation Model not initialized")
        }
        #else
        print("⚠️ FoundationModels framework not available (requires iOS 18+)")
        #endif
    }
    
    // MARK: - Classification
    
    func classifyImage(_ image: UIImage) async throws -> ClassificationResult {
        isProcessing = true
        defer { isProcessing = false }
        
        guard let model = model else {
            throw ClassificationError.modelNotLoaded
        }
        
        guard let cgImage = image.cgImage else {
            throw ClassificationError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                guard let self = self else { return }
                
                if let error = error {
                    continuation.resume(throwing: ClassificationError.classificationFailed(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: ClassificationError.invalidResults)
                    return
                }
                
                // Get top classification
                guard let topObservation = observations.first else {
                    continuation.resume(throwing: ClassificationError.noResults)
                    return
                }
                
                let result = ClassificationResult(
                    objectName: topObservation.identifier,
                    confidence: Double(topObservation.confidence),
                    allClassifications: observations.prefix(5).map { 
                        (identifier: $0.identifier, confidence: Double($0.confidence))
                    }
                )
                
                continuation.resume(returning: result)
            }
            
            request.imageCropAndScaleOption = .centerCrop
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ClassificationError.classificationFailed(error.localizedDescription))
            }
        }
    }
    
    // MARK: - Generate Recycling Instructions
    
    func generateRecyclingInstructions(for objectName: String) async throws -> RecyclingInstructions {
        #if canImport(FoundationModels)
        guard let foundationModel = foundationModel else {
            throw ClassificationError.foundationModelUnavailable()
        }
        
        switch foundationModel.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw ClassificationError.foundationModelUnavailable("Model unavailable: \(reason)")
        }
        
        let session = LanguageModelSession {
            """
            You are a recycling expert assistant. Provide clear, concise, and actionable recycling instructions.
            Always respond in a structured format with the following information:
            1. Whether the item is recyclable (yes/no)
            2. Material category (plastic, paper, glass, metal, electronics, organic, other)
            3. Step-by-step disposal instructions
            4. Environmental impact information
            5. Sustainable alternatives (2-3 suggestions)
            
            Keep responses concise and practical. Use bullet points where appropriate.
            """
        }
        
        let prompt = """
        Provide recycling information for: \(objectName)
        
        Format your response as:
        - Recyclable: [yes/no]
        - Category: [material type]
        - Instructions: [step-by-step]
        - Impact: [environmental information]
        - Alternatives: [sustainable options]
        """
        
        do {
            // LanguageModelSession.respond returns Response<String>
            // According to FoundationModels API, Response<String> has a 'content' property
            let response = try await session.respond(to: prompt)
            
            // Extract the content from Response<String>
            // Response<String> has a content property that contains the generated text
            let responseText: String
            #if canImport(FoundationModels)
            responseText = response.content
            #else
            responseText = String(describing: response)
            #endif
            
            return parseRecyclingResponse(responseText, objectName: objectName)
        } catch {
            throw ClassificationError.generationFailed(error.localizedDescription)
        }
        #else
        // Fallback if FoundationModels not available
        throw ClassificationError.foundationModelUnavailable("FoundationModels framework requires iOS 18+")
        #endif
    }
    
    private func parseRecyclingResponse(_ response: String, objectName: String) -> RecyclingInstructions {
        // Parse the foundation model response
        let lines = response.components(separatedBy: .newlines)
        
        var isRecyclable = false
        var category: RecyclableItem = .plastic // Default to plastic since .other doesn't exist
        var instructions = ""
        var impact = ""
        var alternatives: [String] = []
        
        var currentSection: String?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.lowercased().contains("recyclable:") {
                isRecyclable = trimmed.lowercased().contains("yes")
            } else if trimmed.lowercased().contains("category:") {
                let categoryText = trimmed.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
                category = mapCategory(categoryText)
            } else if trimmed.lowercased().contains("instructions:") {
                currentSection = "instructions"
                instructions = trimmed.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
            } else if trimmed.lowercased().contains("impact:") {
                currentSection = "impact"
                impact = trimmed.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
            } else if trimmed.lowercased().contains("alternatives:") {
                currentSection = "alternatives"
            } else if !trimmed.isEmpty {
                switch currentSection {
                case "instructions":
                    instructions += (instructions.isEmpty ? "" : "\n") + trimmed
                case "impact":
                    impact += (impact.isEmpty ? "" : "\n") + trimmed
                case "alternatives":
                    if trimmed.hasPrefix("-") || trimmed.hasPrefix("•") {
                        alternatives.append(trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "-• ")))
                    }
                default:
                    break
                }
            }
        }
        
        // Fallback defaults if parsing fails
        if instructions.isEmpty {
            instructions = "Please check local recycling guidelines for \(objectName)."
        }
        if impact.isEmpty {
            impact = "Proper disposal helps reduce environmental impact and supports circular economy."
        }
        if alternatives.isEmpty {
            alternatives = ["Consider reusable alternatives", "Reduce consumption", "Choose sustainable materials"]
        }
        
        return RecyclingInstructions(
            objectName: objectName,
            isRecyclable: isRecyclable,
            category: category,
            instructions: instructions,
            impact: impact,
            alternatives: alternatives
        )
    }
    
    private func mapCategory(_ text: String) -> RecyclableItem {
        let lowercased = text.lowercased()
        
        if lowercased.contains("plastic") {
            return .plastic
        } else if lowercased.contains("paper") || lowercased.contains("cardboard") {
            return .paper
        } else if lowercased.contains("glass") {
            return .glass
        } else if lowercased.contains("metal") || lowercased.contains("aluminum") {
            return .metal
        } else if lowercased.contains("electronic") || lowercased.contains("e-waste") {
            return .electronics
        } else if lowercased.contains("batter") {
            return .batteries
        } else if lowercased.contains("textile") || lowercased.contains("cloth") {
            return .textiles
        } else if lowercased.contains("organic") || lowercased.contains("food") || lowercased.contains("compost") {
            return .organic
        } else {
            // Default to plastic if category doesn't match
            return .plastic
        }
    }
}

// MARK: - Models

struct ClassificationResult {
    let objectName: String
    let confidence: Double
    let allClassifications: [(identifier: String, confidence: Double)]
}

struct RecyclingInstructions {
    let objectName: String
    let isRecyclable: Bool
    let category: RecyclableItem
    let instructions: String
    let impact: String
    let alternatives: [String]
}

enum ClassificationError: LocalizedError {
    case modelNotLoaded
    case invalidImage
    case classificationFailed(String)
    case invalidResults
    case noResults
    case foundationModelUnavailable(String? = nil)
    case generationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Classification model not loaded. Please add FastViT model to the project."
        case .invalidImage:
            return "Invalid image provided."
        case .classificationFailed(let message):
            return "Classification failed: \(message)"
        case .invalidResults:
            return "Invalid classification results."
        case .noResults:
            return "No classification results found."
        case .foundationModelUnavailable(let message):
            return message ?? "Apple Foundation Model is not available. Please enable Apple Intelligence in Settings."
        case .generationFailed(let message):
            return "Failed to generate instructions: \(message)"
        }
    }
}
