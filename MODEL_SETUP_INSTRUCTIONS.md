# ResNet50Large Model Setup Instructions

## Current Issue
The scanning feature captures images successfully, but the ResNet50Large model is not loading properly.

## Solution Steps

### 1. Verify Model File Location
The model file `ResNet50Large.mlmodel` (102.6 MB) is located at:
```
/Users/swastik/Developer/Greenify/Greenify/ResNet50Large.mlmodel
```

### 2. Add Model to Xcode Project

#### Option A: If model is NOT visible in Xcode Project Navigator
1. Open `Greenify.xcodeproj` in Xcode
2. Right-click on the `Greenify` folder in Project Navigator
3. Select "Add Files to Greenify..."
4. Navigate to `/Users/swastik/Developer/Greenify/Greenify/`
5. Select `ResNet50Large.mlmodel`
6. **IMPORTANT**: Check these options:
   - ✅ "Copy items if needed" (if not already in folder)
   - ✅ "Add to targets: Greenify"
7. Click "Add"

#### Option B: If model IS visible but not working
1. Select `ResNet50Large.mlmodel` in Project Navigator
2. Open the File Inspector (right panel, first tab)
3. Under "Target Membership":
   - ✅ Ensure "Greenify" is checked

### 3. Verify Build Phases

1. Select the project in Project Navigator (top item)
2. Select the "Greenify" target
3. Go to "Build Phases" tab
4. Expand "Copy Bundle Resources"
5. **Check if `ResNet50Large.mlmodel` is listed**
   - If NOT listed: Click the "+" button and add it
   - If listed: Good! Continue to next step

### 4. Clean and Rebuild

1. In Xcode menu: **Product → Clean Build Folder** (⇧⌘K)
2. Wait for cleaning to complete
3. **Product → Build** (⌘B)
4. Wait for build to complete
5. Check for any build errors in the Issue Navigator

### 5. Run the App

1. Select your target device/simulator
2. **Product → Run** (⌘R)
3. Check the Xcode console for diagnostic messages:
   - Look for "🔍 Initializing ObjectClassificationService..."
   - Look for "✅ Found model at: ..."
   - Look for "✅ MLModel loaded successfully"
   - Look for "🎉 ResNet50Large model is ready to use!"

### 6. Troubleshooting

#### If you see "❌ ResNet50Large model not found!"
- The model is not being copied to the app bundle
- Go back to Step 2 and 3 above
- Make sure Target Membership is checked
- Make sure it's in Copy Bundle Resources

#### If you see "❌ Failed to load ResNet50Large model"
Possible causes:
1. **Model file is corrupted**
   - Re-download or re-export the model
   - Verify file size is ~102 MB

2. **Model format is incompatible**
   - Ensure it's a valid CoreML model (.mlmodel)
   - Check the model was exported for iOS/macOS
   - Verify CoreML version compatibility

3. **Model requires specific iOS version**
   - Check model metadata for minimum iOS version
   - Update deployment target if needed

#### If model loads but classification fails
1. Check image preprocessing requirements
2. Verify input dimensions match model expectations
3. Check console for detailed error messages

### 7. Verify Model is Working

1. Open the app
2. Go to "Scan Items" tab
3. Tap "Start Scanning"
4. Point camera at an object
5. Tap the white capture button
6. You should see:
   - "Identifying object..." (processing stage)
   - "Generating instructions..." (if Foundation Model is available)
   - Results screen with identified object

## Diagnostic Output

The app now includes comprehensive diagnostics that run when the app starts. Check the Xcode console for:

```
========== MODEL DIAGNOSTICS ==========

1️⃣ Checking Bundle Resources:
   ✅ Bundle resource path: /path/to/bundle
   ✅ Found ML files:
      - ResNet50Large.mlmodelc (or .mlmodel)

2️⃣ Checking for ResNet50Large:
   ✅ Found ResNet50Large.mlmodel at: /path/to/model
      File size: 97.86 MB
      Readable: ✅

3️⃣ Attempting to load model:
   ✅ Successfully loaded MLModel!
   ✅ Successfully created VNCoreMLModel!

========== END DIAGNOSTICS ==========
```

## Model Details

- **Name**: ResNet50Large
- **Size**: 102.6 MB
- **Format**: CoreML (.mlmodel)
- **Purpose**: Image classification for recyclable items
- **Framework**: Vision + CoreML

## Code Changes Made

1. **ObjectClassificationService.swift**
   - Updated to use ResNet50Large instead of FastViT
   - Added comprehensive diagnostics
   - Tries multiple file extensions (.mlmodelc, .mlmodel, .mlpackage)
   - Better error messages and logging

2. **ModelDiagnostics.swift** (NEW)
   - Standalone diagnostics class
   - Runs on app initialization
   - Checks bundle resources
   - Attempts model loading with detailed feedback

3. **ScanView.swift**
   - Updated UI to show "Using ResNet50 model..."
   - Added error message display in main view
   - Better error feedback during scanning

## Next Steps

After following the steps above:
1. The model should load successfully
2. Check console for "🎉 ResNet50Large model is ready to use!"
3. Test scanning functionality
4. If issues persist, share the console output for further debugging

## Support

If you continue to have issues:
1. Copy the entire console output from app launch
2. Take a screenshot of:
   - File Inspector showing Target Membership
   - Build Phases → Copy Bundle Resources
3. Share these for further assistance
