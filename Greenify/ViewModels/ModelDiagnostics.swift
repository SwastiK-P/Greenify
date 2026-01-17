//
//  ModelDiagnostics.swift
//  Greenify
//
//  Created for debugging model loading issues
//

import Foundation
import CoreML
import Vision

class ModelDiagnostics {
    static func runDiagnostics() {
        print("\n========== MODEL DIAGNOSTICS ==========")
        
        // 1. Check Bundle Resources
        print("\n1️⃣ Checking Bundle Resources:")
        if let resourcePath = Bundle.main.resourcePath {
            print("   ✅ Bundle resource path: \(resourcePath)")
            
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                let mlFiles = contents.filter { $0.hasSuffix(".mlmodel") || $0.hasSuffix(".mlpackage") || $0.hasSuffix(".mlmodelc") }
                
                if mlFiles.isEmpty {
                    print("   ⚠️ No ML model files found in bundle resources")
                } else {
                    print("   ✅ Found ML files:")
                    for file in mlFiles {
                        print("      - \(file)")
                    }
                }
            } catch {
                print("   ❌ Error reading bundle contents: \(error)")
            }
        } else {
            print("   ❌ Bundle resource path is nil")
        }
        
        // 2. Check for MobileNet V3 Model specifically
        print("\n2️⃣ Checking for MobileNet V3 Model:")
        
        // Try .mlmodel
        if let mlmodelURL = Bundle.main.url(forResource: "MobileNet V3 Model", withExtension: "mlmodel") {
            print("   ✅ Found MobileNet V3 Model.mlmodel at: \(mlmodelURL.path)")
            checkModelFile(at: mlmodelURL)
        } else {
            print("   ⚠️ MobileNet V3 Model.mlmodel not found in bundle")
        }
        
        // Try .mlmodelc (compiled)
        if let mlmodelcURL = Bundle.main.url(forResource: "MobileNet V3 Model", withExtension: "mlmodelc") {
            print("   ✅ Found MobileNet V3 Model.mlmodelc at: \(mlmodelcURL.path)")
            checkModelFile(at: mlmodelcURL)
        } else {
            print("   ⚠️ MobileNet V3 Model.mlmodelc not found in bundle")
        }
        
        // Try .mlpackage
        if let mlpackageURL = Bundle.main.url(forResource: "MobileNet V3 Model", withExtension: "mlpackage") {
            print("   ✅ Found MobileNet V3 Model.mlpackage at: \(mlpackageURL.path)")
            checkModelFile(at: mlpackageURL)
        } else {
            print("   ⚠️ MobileNet V3 Model.mlpackage not found in bundle")
        }
        
        // 3. Try loading the model
        print("\n3️⃣ Attempting to load model:")
        attemptModelLoad()
        
        print("\n========== END DIAGNOSTICS ==========\n")
    }
    
    private static func checkModelFile(at url: URL) {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[.size] as? Int64 {
                let sizeInMB = Double(fileSize) / (1024.0 * 1024.0)
                print("      File size: \(String(format: "%.2f", sizeInMB)) MB")
            }
            
            let isReadable = FileManager.default.isReadableFile(atPath: url.path)
            print("      Readable: \(isReadable ? "✅" : "❌")")
            
        } catch {
            print("      ❌ Error checking file: \(error)")
        }
    }
    
    private static func attemptModelLoad() {
        // Try all possible extensions
        let extensions = ["mlmodel", "mlmodelc", "mlpackage"]
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: "MobileNet V3 Model", withExtension: ext) {
                print("   Trying to load from: \(url.lastPathComponent)")
                
                do {
                    let mlModel = try MLModel(contentsOf: url)
                    print("   ✅ Successfully loaded MLModel!")
                    
                    // Try to create Vision model
                    do {
                        let visionModel = try VNCoreMLModel(for: mlModel)
                        print("   ✅ Successfully created VNCoreMLModel!")
                        
                        // Print model details
                        print("   Model description: \(mlModel.modelDescription)")
                        
                        return
                    } catch {
                        print("   ❌ Failed to create VNCoreMLModel: \(error.localizedDescription)")
                    }
                } catch {
                    print("   ❌ Failed to load MLModel: \(error.localizedDescription)")
                }
            }
        }
        
        print("   ❌ Could not load MobileNet V3 Model with any extension")
    }
}
