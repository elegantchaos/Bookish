# Direct Image Recognition Tool

## Finding

`DirectImageBookRecognition` attached Vision's `OCRTool` to a Foundation Models session. Apple's documentation says the tool is unavailable in Simulator, and the Xcode 27 iOS Simulator SDK does not contain the `_Vision_FoundationModels` overlay that declares it. The iOS device and macOS SDKs do declare the tool. Removing it outright would change recognition on those platforms by denying the model access to Vision text extraction.

## Change

- Kept `OCRTool` for device builds and omitted it when compiling for Simulator.
- The model still receives the image attachment on every platform. The separate OCR provider continues to use Vision text extraction followed by Foundation Models.

## Verification

- The Bookish workspace builds for iOS Simulator.
- `rt validate` passed formatting, lint, and generic iOS and macOS workspace builds.
- Live recognition on an iOS device remains unverified.
