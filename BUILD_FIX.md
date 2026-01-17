# Build Fix - ResNet50Large Model Conflict

## Issue
```
Multiple commands produce conflicting outputs
coremlc: error: Model does not exist at file:///Users/swastik/Developer/Greenify/ResNet50Large.mlmodel
```

## Root Cause
- Xcode project had the model referenced at root level
- Model was moved to Greenify subfolder
- Xcode build system had conflicting references

## Solution Applied ✅

1. **Moved model back to correct location**:
   - From: `/Users/swastik/Developer/Greenify/Greenify/ResNet50Large.mlmodel`
   - To: `/Users/swastik/Developer/Greenify/ResNet50Large.mlmodel` (root project directory)

2. **Updated code paths**:
   - ObjectClassificationService.swift now looks in the correct directory

## Steps to Build Successfully

### 1. Clean Build Folder
In Xcode:
- Press **Shift + Command + K** (⇧⌘K)
- Or: **Product → Clean Build Folder**

Wait for cleaning to complete.

### 2. Delete Derived Data (Optional but Recommended)
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Greenify-*
```

Or in Xcode:
- **Window → Organizer → Projects**
- Select "Greenify"
- Click "Delete Derived Data..."

### 3. Rebuild
- Press **Command + B** (⌘B)
- Or: **Product → Build**

### 4. Run
- Press **Command + R** (⌘R)
- Or: **Product → Run**

## Verification

After building, check Xcode console for:
```
🔍 Initializing ObjectClassificationService...
✅ Found ResNet50Large model at: ...
✅ MLModel loaded successfully
✅ VNCoreMLModel created successfully
🎉 ResNet50Large model is ready to use!
```

## Project Structure (Correct)

```
Greenify/
├── Greenify.xcodeproj/
├── ResNet50Large.mlmodel          ← Model file (98 MB)
├── Greenify/                       ← Source code folder
│   ├── ViewModels/
│   │   ├── ObjectClassificationService.swift
│   │   └── ...
│   └── ...
├── README.md
└── ...
```

**Note**: The model is at the ROOT level, alongside the Greenify folder, not inside it.

## Why This Structure?

When you add files to Xcode:
- Files can be in the project root OR in subfolders
- The Xcode project file (project.pbxproj) references their location
- The model was added at root level in the project hierarchy
- This is perfectly fine and actually cleaner for large binary files

## If Build Still Fails

### Check 1: Verify Model Location
```bash
ls -lh /Users/swastik/Developer/Greenify/ResNet50Large.mlmodel
```
Should show: `-rw-r--r--@ ... 98M ... ResNet50Large.mlmodel`

### Check 2: Check Target Membership
1. Select `ResNet50Large.mlmodel` in Xcode Project Navigator
2. Open File Inspector (right panel)
3. Under "Target Membership":
   - ✅ Greenify should be checked

### Check 3: Check Build Phases
1. Select project in Project Navigator
2. Select "Greenify" target
3. Go to "Build Phases" tab
4. Expand "Compile Sources"
5. Ensure `ResNet50Large.mlmodel` is listed

If not listed:
- Click the "+" button
- Add `ResNet50Large.mlmodel`

### Check 4: Remove Duplicate References
If you see ResNet50Large.mlmodel listed twice in Project Navigator:
1. Select the duplicate
2. Press Delete
3. Choose "Remove Reference" (not "Move to Trash")
4. Clean and rebuild

## Current Status

✅ Model file location: `/Users/swastik/Developer/Greenify/ResNet50Large.mlmodel`  
✅ Code updated to look in correct location  
✅ Build should now succeed after cleaning  

## Next Steps After Successful Build

1. Run the app
2. Go to "Scan Items" tab
3. Check Xcode console for model loading messages
4. Test scanning an item
5. Verify accuracy improvements are working

All the accuracy improvements (orientation fixing, preprocessing, logging) are still in place and will work once the build succeeds!
