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
        // Run diagnostics first
        print("\n🔍 Initializing ObjectClassificationService...")
        ModelDiagnostics.runDiagnostics()
        
        loadMobileNetModel()
        initializeFoundationModel()
    }
    
    // MARK: - MobileNet V3 Model Loading
    
    private func loadMobileNetModel() {
        print("\n🤖 Loading MobileNet V3 Model...")
        
        // Try multiple extensions and paths
        let modelName = "MobileNet V3 Model"
        let extensions = ["mlmodelc", "mlmodel", "mlpackage"] // Try compiled first
        
        var modelURL: URL?
        var foundExtension: String?
        
        // Try each extension
        for ext in extensions {
            print("   Trying extension: .\(ext)")
            
            // Try 1: Direct resource lookup (standard way)
            if let url = Bundle.main.url(forResource: modelName, withExtension: ext) {
                print("   ✅ Found via Bundle.main.url")
                modelURL = url
                foundExtension = ext
                break
            }
            
            // Try 2: Look in main bundle with full path
            if let bundlePath = Bundle.main.resourcePath {
                let fullPath = (bundlePath as NSString).appendingPathComponent("\(modelName).\(ext)")
                if FileManager.default.fileExists(atPath: fullPath) {
                    print("   ✅ Found in bundle resource path")
                    modelURL = URL(fileURLWithPath: fullPath)
                    foundExtension = ext
                    break
                }
            }
            
            // Try 3: Look in Greenify subdirectory
            if let bundlePath = Bundle.main.resourcePath {
                let fullPath = (bundlePath as NSString).appendingPathComponent("Greenify/\(modelName).\(ext)")
                if FileManager.default.fileExists(atPath: fullPath) {
                    print("   ✅ Found in Greenify subdirectory")
                    modelURL = URL(fileURLWithPath: fullPath)
                    foundExtension = ext
                    break
                }
            }
        }
        
        // Try 4: Development path (root project directory)
        if modelURL == nil {
            let sourcePath = "/Users/swastik/Developer/Greenify/\(modelName).mlmodel"
            if FileManager.default.fileExists(atPath: sourcePath) {
                print("   ✅ Found in root project directory (development)")
                modelURL = URL(fileURLWithPath: sourcePath)
                foundExtension = "mlmodel"
            }
        }
        
        guard let url = modelURL else {
            let errorMsg = """
            
            ❌ MobileNet V3 model not found!
            
            Searched for extensions: \(extensions.joined(separator: ", "))
            
            SOLUTION:
            1. Open Xcode
            2. Select MobileNetV3.mlmodel in Project Navigator
            3. Check "Target Membership" → Greenify is checked
            4. Go to Build Phases → Copy Bundle Resources
            5. Ensure MobileNetV3.mlmodel is listed
            6. Clean Build Folder (Cmd+Shift+K)
            7. Rebuild the project
            
            """
            print(errorMsg)
            errorMessage = "Model not found. Please check Xcode project settings."
            return
        }
        
        print("   ✅ Found model at: \(url.path)")
        print("   Extension: .\(foundExtension ?? "unknown")")
        
        // Check file size
        if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let fileSize = attributes[.size] as? Int64 {
            let sizeInMB = Double(fileSize) / (1024.0 * 1024.0)
            print("   File size: \(String(format: "%.2f", sizeInMB)) MB")
            print("   📱 MobileNet V3: Optimized for mobile devices with high accuracy")
        }
        
        loadModel(from: url)
    }
    
    private func loadModel(from url: URL) {
        print("   📦 Loading MLModel from: \(url.lastPathComponent)")
        
        do {
            // Step 1: Load the Core ML model
            let mlModel = try MLModel(contentsOf: url)
            print("   ✅ MLModel loaded successfully")
            
            // Print model metadata
            let description = mlModel.modelDescription
            print("   Model metadata:")
            print("      - Input: \(description.inputDescriptionsByName.keys.joined(separator: ", "))")
            print("      - Output: \(description.outputDescriptionsByName.keys.joined(separator: ", "))")
            if let metadata = description.metadata[.description] as? String {
                print("      - Description: \(metadata)")
            }
            
            // Step 2: Create Vision model
            model = try VNCoreMLModel(for: mlModel)
            print("   ✅ VNCoreMLModel created successfully")
            print("   🎉 MobileNet V3 model is ready to use!")
            print("   📱 Optimized for mobile with high accuracy and fast inference\n")
            
        } catch let error as NSError {
            let errorMsg = """
            
            ❌ Failed to load MobileNet V3 model
            Error: \(error.localizedDescription)
            Domain: \(error.domain)
            Code: \(error.code)
            
            """
            print(errorMsg)
            
            if error.domain == "com.apple.CoreML" {
                print("   This is a CoreML error. Possible causes:")
                print("   - Model file is corrupted")
                print("   - Model format is incompatible")
                print("   - Model requires compilation")
                print("\n   Try:")
                print("   1. Re-export the model from your ML framework")
                print("   2. Ensure it's in CoreML format (.mlmodel)")
                print("   3. Let Xcode compile it automatically")
            }
            
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
        
        // Check image quality first
        print("📸 Preprocessing image for classification...")
        print("   Original size: \(image.size)")
        print("   Original orientation: \(image.imageOrientation.rawValue)")
        
        let qualityScore = assessImageQuality(image)
        print("   📊 Image quality score: \(String(format: "%.2f", qualityScore))")
        
        if qualityScore < 0.3 {
            print("   ⚠️ Warning: Low image quality detected")
        }
        
        guard let processedImage = preprocessImage(image) else {
            throw ClassificationError.invalidImage
        }
        
        guard let cgImage = processedImage.cgImage else {
            throw ClassificationError.invalidImage
        }
        
        print("   Processed size: \(processedImage.size)")
        print("   🔍 Running multi-scale classification...")
        
        // Run classification with multiple crop strategies for better accuracy
        let cropModes: [VNImageCropAndScaleOption] = [.scaleFill, .centerCrop, .scaleFit]
        var allResults: [[VNClassificationObservation]] = []
        
        for (index, cropMode) in cropModes.enumerated() {
            print("   🔎 Pass \(index + 1)/\(cropModes.count): \(cropMode)")
            
            let observations = try await performClassification(
                cgImage: cgImage,
                model: model,
                cropMode: cropMode
            )
            
            allResults.append(observations)
        }
        
        // Fuse results from all passes using weighted voting
        let fusedResults = fuseClassificationResults(allResults)
        
        // Log top 5 predictions
        print("   📊 Final Top 5 predictions (after fusion):")
        for (index, result) in fusedResults.prefix(5).enumerated() {
            print("      \(index + 1). \(result.identifier): \(String(format: "%.2f%%", result.confidence * 100))")
        }
        
        guard let topResult = fusedResults.first else {
            print("   ❌ No results after fusion")
            throw ClassificationError.noResults
        }
        
        // Quality check on confidence
        if topResult.confidence < 0.3 {
            print("   ⚠️ Warning: Low confidence (\(String(format: "%.2f%%", topResult.confidence * 100)))")
            print("   💡 Tip: Try better lighting or different angle")
        }
        
        print("   ✅ Classification complete: \(topResult.identifier) (\(String(format: "%.2f%%", topResult.confidence * 100)))")
        
        let result = ClassificationResult(
            objectName: topResult.identifier,
            confidence: Double(topResult.confidence),
            allClassifications: Array(fusedResults.prefix(5))
        )
        
        return result
    }
    
    private func performClassification(
        cgImage: CGImage,
        model: VNCoreMLModel,
        cropMode: VNImageCropAndScaleOption
    ) async throws -> [VNClassificationObservation] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    continuation.resume(throwing: ClassificationError.classificationFailed(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: ClassificationError.invalidResults)
                    return
                }
                
                continuation.resume(returning: observations)
            }
            
            request.imageCropAndScaleOption = cropMode
            
            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: .up,
                options: [.ciContext: CIContext(options: [.useSoftwareRenderer: false])]
            )
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ClassificationError.classificationFailed(error.localizedDescription))
            }
        }
    }
    
    private func fuseClassificationResults(_ results: [[VNClassificationObservation]]) -> [(identifier: String, confidence: Double)] {
        guard !results.isEmpty else { return [] }
        
        // Collect all unique identifiers with their confidence scores
        var identifierScores: [String: [Double]] = [:]
        
        for observations in results {
            for obs in observations {
                if identifierScores[obs.identifier] == nil {
                    identifierScores[obs.identifier] = []
                }
                identifierScores[obs.identifier]?.append(Double(obs.confidence))
            }
        }
        
        // Create fused observations using weighted average
        var fusedObservations: [(identifier: String, confidence: Double)] = []
        
        for (identifier, scores) in identifierScores {
            // Use geometric mean for better handling of low confidences
            let geometricMean = pow(scores.reduce(1.0, *), 1.0 / Double(scores.count))
            
            // Boost score if it appears in multiple passes with high confidence
            let consistencyBonus = scores.filter { $0 > 0.5 }.count > 1 ? 1.1 : 1.0
            
            let finalScore = geometricMean * consistencyBonus
            fusedObservations.append((identifier: identifier, confidence: finalScore))
        }
        
        // Sort by confidence
        fusedObservations.sort { $0.confidence > $1.confidence }
        
        // Normalize top scores to sum to reasonable values
        let maxScore = fusedObservations.first?.confidence ?? 1.0
        let normalized = fusedObservations.map { obs -> (identifier: String, confidence: Double) in
            let normalizedConfidence = min(obs.confidence / maxScore, 1.0)
            return (identifier: obs.identifier, confidence: normalizedConfidence)
        }
        
        return normalized
    }
    
    private func assessImageQuality(_ image: UIImage) -> Double {
        guard let ciImage = CIImage(image: image) else { return 0.5 }
        
        var qualityScore = 1.0
        
        // Check 1: Image size (prefer reasonable sizes)
        let imageSize = image.size
        let pixelCount = imageSize.width * imageSize.height
        
        if pixelCount < 100000 { // < 316x316
            qualityScore *= 0.6 // Too small
        } else if pixelCount > 10000000 { // > 3162x3162
            qualityScore *= 0.9 // Very large (good but may need processing)
        }
        
        // Check 2: Brightness using CIAreaAverage
        let context = CIContext(options: [.useSoftwareRenderer: false])
        let extent = ciImage.extent
        
        if let filter = CIFilter(name: "CIAreaAverage") {
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            filter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
            
            if let outputImage = filter.outputImage,
               let bitmap = context.createCGImage(outputImage, from: CGRect(x: 0, y: 0, width: 1, height: 1)) {
                
                let data = bitmap.dataProvider?.data
                let pointer = CFDataGetBytePtr(data)
                
                if let pointer = pointer {
                    let brightness = (Double(pointer[0]) + Double(pointer[1]) + Double(pointer[2])) / (3.0 * 255.0)
                    
                    // Penalize very dark or very bright images
                    if brightness < 0.2 || brightness > 0.9 {
                        qualityScore *= 0.7
                    }
                }
            }
        }
        
        return qualityScore
    }
    
    // MARK: - Image Preprocessing
    
    private func preprocessImage(_ image: UIImage) -> UIImage? {
        // Step 1: Fix orientation first - very important for camera images
        let orientationFixedImage = image.fixedOrientation()
        
        // Step 2: Apply advanced preprocessing for better accuracy
        guard let enhancedImage = enhanceImageQuality(orientationFixedImage) else {
            print("   ⚠️ Enhancement failed, using orientation-fixed image")
            return orientationFixedImage
        }
        
        // Step 3: Resize to optimal size for MobileNet V3
        // MobileNet V3 works best with 224x224 input (standard ImageNet size)
        // Using 512x512 for better quality, Vision will downscale appropriately
        let targetSize = CGSize(width: 512, height: 512)
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        enhancedImage.draw(in: CGRect(origin: .zero, size: targetSize))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func enhanceImageQuality(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return image }
        
        let context = CIContext(options: [.useSoftwareRenderer: false])
        
        // Apply enhancement filters for better recognition
        var outputImage = ciImage
        
        // 1. Auto-enhance: Automatically improves exposure, contrast, and saturation
        if let autoFilter = CIFilter(name: "CIColorControls") {
            autoFilter.setValue(outputImage, forKey: kCIInputImageKey)
            // Slightly increase contrast for better edge detection
            autoFilter.setValue(1.1, forKey: kCIInputContrastKey)
            // Slightly increase saturation
            autoFilter.setValue(1.05, forKey: kCIInputSaturationKey)
            
            if let enhanced = autoFilter.outputImage {
                outputImage = enhanced
            }
        }
        
        // 2. Sharpen the image for better detail recognition
        if let sharpenFilter = CIFilter(name: "CISharpenLuminance") {
            sharpenFilter.setValue(outputImage, forKey: kCIInputImageKey)
            sharpenFilter.setValue(0.4, forKey: kCIInputSharpnessKey)
            
            if let sharpened = sharpenFilter.outputImage {
                outputImage = sharpened
            }
        }
        
        // 3. Reduce noise if present
        if let noiseFilter = CIFilter(name: "CINoiseReduction") {
            noiseFilter.setValue(outputImage, forKey: kCIInputImageKey)
            noiseFilter.setValue(0.02, forKey: "inputNoiseLevel")
            noiseFilter.setValue(0.4, forKey: "inputSharpness")
            
            if let denoised = noiseFilter.outputImage {
                outputImage = denoised
            }
        }
        
        // Convert back to UIImage
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
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
            
            Keep responses concise and practical. Use bullet points with dashes (-).
            DO NOT use markdown formatting like ** or __ or # or ```
            Use plain text only with simple dashes for bullet points.
            """
        }
        
        let prompt = """
        Provide recycling information for: \(objectName)
        
        Format your response as plain text (NO markdown formatting):
        - Recyclable: [yes/no]
        - Category: [material type]
        - Instructions: [clear step-by-step instructions in plain text]
        - Impact: [environmental information in plain text]
        - Alternatives: [sustainable options as simple bullet points with dashes]
        
        Remember: Use plain text only, no ** or other markdown symbols.
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
        // Parse the foundation model response and clean markdown
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
                let content = trimmed.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
                instructions = cleanMarkdown(content)
            } else if trimmed.lowercased().contains("impact:") {
                currentSection = "impact"
                let content = trimmed.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
                impact = cleanMarkdown(content)
            } else if trimmed.lowercased().contains("alternatives:") {
                currentSection = "alternatives"
            } else if !trimmed.isEmpty {
                switch currentSection {
                case "instructions":
                    let cleanLine = cleanMarkdown(trimmed)
                    instructions += (instructions.isEmpty ? "" : "\n") + cleanLine
                case "impact":
                    let cleanLine = cleanMarkdown(trimmed)
                    impact += (impact.isEmpty ? "" : "\n") + cleanLine
                case "alternatives":
                    if trimmed.hasPrefix("-") || trimmed.hasPrefix("•") {
                        let cleanAlt = cleanMarkdown(trimmed.trimmingCharacters(in: CharacterSet(charactersIn: "-• ")))
                        alternatives.append(cleanAlt)
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
            instructions: cleanMarkdown(instructions),
            impact: cleanMarkdown(impact),
            alternatives: alternatives
        )
    }
    
    /// Cleans markdown formatting from text (removes **, __, etc.)
    private func cleanMarkdown(_ text: String) -> String {
        var cleaned = text
        
        // Remove bold markers (**text** or __text__)
        cleaned = cleaned.replacingOccurrences(of: "**", with: "")
        cleaned = cleaned.replacingOccurrences(of: "__", with: "")
        
        // Remove italic markers (*text* or _text_) but preserve bullet points
        // Only remove single asterisks not at the start of a line
        cleaned = cleaned.replacingOccurrences(of: #"(?<!^)(?<![\s\-])\*(?!\*)"#, with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"(?<!^)(?<![\s\-])_(?!_)"#, with: "", options: .regularExpression)
        
        // Remove code blocks (```text```)
        cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        cleaned = cleaned.replacingOccurrences(of: "`", with: "")
        
        // Remove headers (# text) - process line by line for multiline matching
        let headerPattern = try? NSRegularExpression(pattern: #"^#+\s+"#, options: .anchorsMatchLines)
        if let regex = headerPattern {
            let range = NSRange(cleaned.startIndex..., in: cleaned)
            cleaned = regex.stringByReplacingMatches(in: cleaned, range: range, withTemplate: "")
        }
        
        // Remove any remaining markdown links [text](url)
        cleaned = cleaned.replacingOccurrences(of: #"\[([^\]]+)\]\([^\)]+\)"#, with: "$1", options: .regularExpression)
        
        // Remove HTML tags if any
        cleaned = cleaned.replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
        
        // Clean up multiple consecutive spaces
        cleaned = cleaned.replacingOccurrences(of: #" +"#, with: " ", options: .regularExpression)
        
        // Clean up multiple consecutive newlines (but keep intentional line breaks)
        cleaned = cleaned.replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
        
        // Trim whitespace from each line while preserving structure
        let lines = cleaned.components(separatedBy: .newlines)
        cleaned = lines.map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "\n")
        
        // Final trim
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
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
            return "Classification model not loaded. Please add MobileNet V3 Model.mlmodel to the project."
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

// MARK: - UIImage Extension

extension UIImage {
    /// Fixes the orientation of the image to .up
    /// This is crucial for camera-captured images which often have wrong orientation metadata
    func fixedOrientation() -> UIImage {
        // If already in correct orientation, return as-is
        if imageOrientation == .up {
            return self
        }
        
        // Calculate the transformation needed to rotate the image
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
            
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
            
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
            
        case .up, .upMirrored:
            break
            
        @unknown default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        default:
            break
        }
        
        // Create a new context and apply the transformation
        guard let cgImage = cgImage,
              let colorSpace = cgImage.colorSpace,
              let context = CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: cgImage.bitsPerComponent,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: cgImage.bitmapInfo.rawValue
              ) else {
            return self
        }
        
        context.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
            
        default:
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        // Get the rotated image from the context
        guard let rotatedCGImage = context.makeImage() else {
            return self
        }
        
        return UIImage(cgImage: rotatedCGImage)
    }
}
