# FastViT Model Setup Guide

## Model Selection

For **highest accuracy**, use:
- **FastViTMA36F16.mlpackage** (88.3MB) - Recommended ✅

For **smaller size** (lower accuracy):
- FastViTT8F16.mlpackage (8.2MB)

## Setup Steps

### 1. Download the Model

1. Download **FastViTMA36F16.mlpackage** (88.3MB)
2. Save it to your Downloads folder

### 2. Add Model to Xcode Project

1. Open your project in Xcode
2. Right-click on the **Greenify** folder in Project Navigator
3. Select **"Add Files to 'Greenify'..."**
4. Navigate to your Downloads folder
5. Select **FastViTMA36F16.mlpackage**
6. Ensure these options are checked:
   - ✅ **"Copy items if needed"**
   - ✅ **"Create groups"** (not folder references)
   - ✅ **"Add to targets: Greenify"**
7. Click **"Add"**

### 3. Verify Model is Added

1. In Project Navigator, you should see:
   ```
   Greenify/
     ├── FastViTMA36F16.mlpackage
     └── ...
   ```

2. Select the model file
3. In the File Inspector, verify:
   - Target Membership includes "Greenify"
   - Location is set correctly

### 4. Build and Test

1. Clean build folder: **Cmd+Shift+K**
2. Build project: **Cmd+B**
3. Run on device or simulator

## Model Information

- **Architecture**: FastViT (Vision Transformer)
- **Input**: RGB image (224x224 recommended)
- **Output**: Classification labels with confidence scores
- **Accuracy**: High (MA36 variant)
- **Size**: 88.3MB

## Troubleshooting

### "Model not found" Error
- ✅ Verify model file is in the project bundle
- ✅ Check Target Membership includes Greenify
- ✅ Clean and rebuild project
- ✅ Ensure file extension is `.mlpackage` (not `.mlmodel`)

### Model Too Large
- Use FastViTT8F16.mlpackage (8.2MB) instead
- Update `ObjectClassificationService.swift` to load T8 model

### Build Errors
- Ensure model is properly added to target
- Check file is not corrupted
- Try removing and re-adding the model

## Alternative: Use Headless Model

If you want to fine-tune the model:
- Use **FastViTMA36F16Headless.mlpackage** (85.8MB)
- Requires additional training setup

## Performance Notes

- First inference may be slower (model loading)
- Subsequent inferences are faster
- Consider preprocessing images to 224x224 for best performance
- Model works best on device (not simulator for performance)
