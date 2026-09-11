# Scanning Candidate Addition

The scanning workflow now retains candidate selection in its application-owned recognition state. Candidates can be toggled individually, then added through `Add Selected` or `Add All` commands.

The command boundary vends the recognition workflow from `BookishEngine`. Image selection, the bundled example, recognition, and catalogue addition now enter that workflow via commands. Successful additions create `book` records with the recognised title, refresh the browser, report the result, and remove only the persisted candidates from the scanning list.

The provider picker now exposes OCR separately from direct-image On Device recognition. OCR remains available through Vision and Foundation Models; direct image recognition is explicitly unavailable until the required Foundation Models image-input API is available.

The candidate-list header now provides compact command-backed Select All and Deselect All controls.

The Fake recognition provider is now the default. It ignores its image input and returns a deterministic small candidate set for UI testing.

Candidate addition now uses one command. It is labelled Add Selected for partial selection and Add All when every candidate is selected.

Selecting or replacing an image now immediately starts recognition. Changing the recognizer repeats recognition for the selected image. The capture section displays a compact image preview and has no manual identify action.
