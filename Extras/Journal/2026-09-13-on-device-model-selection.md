# On Device Model Selection

## Changes

- `OnDeviceBookRecognizer` explicitly selects `SystemLanguageModel.default` and uses that instance for both availability checking and direct-image recognition.
- The iOS 27 SDK declares `SystemLanguageModel`'s `LanguageModel` conformance, capabilities, and executor configuration. A custom model declaration is unnecessary; the generic `some LanguageModel` parameter cannot resolve an unqualified `.default`.
- Existing direct-image processing and platform availability checks are retained.

## Recognition Quality

- Apple's [WWDC26 Foundation Models session](https://developer.apple.com/videos/play/wwdc2026/241/) confirms on-device image input and introduces `OCRTool` and `BarcodeReaderTool` for model-driven text and barcode extraction. These are potential book-recognition enhancements to evaluate with sample photos.
- Declaring `LanguageModelCapabilities` describes an implementation's supported features; it does not add vision or reasoning to an existing model. The installed SDK exposes `.general` and `.contentTagging` system-model use cases; general-purpose generation fits structured book extraction.
- This build fix does not change prompts or tools. Recognition quality has not been measured.

## Validation

- Target build and all five tests pass using the Xcode 27 RC toolchain after the [session test update](2026-09-13-recognition-session-tests.md).
- Comprehensive `rt validate` passed formatting, lint, and the Bookish iOS and macOS builds. Live recognition remains unverified.
