# 2026-09-09 Book Recognition Prototype

The Scanning workflow now provides an image-picker prototype backed by the
OpenAI Responses API. It sends the selected image only after explicit user
action, requests strict JSON candidate data, and presents the title, authors,
and model-reported confidence without creating catalogue records.

`OpenAIResponsesBookRecognizer` is an injectable boundary around the HTTP
request. The app reads its key from a Keychain internet-password item with
account `openai-api-key` and server `api.openai.com`, rather than persisting it
or reading it from the launch environment. The next phase can look up the
returned candidates in external book-information services before presenting
add-to-collection actions.

`Scripts/store-openai-api-key.sh` is the local setup helper. It accepts the
key with terminal echo disabled, then creates or replaces that exact Keychain
internet-password item using macOS's `security` command-line tool.

The Scanning screen also offers `Use Example Image`, which loads the bundled
`CaptureGoodExample.JPG` resource through the same selection state and
recognition path as user-picked images.

The recognition-provider picker now offers OpenAI, Apple on-device Foundation
Models, and Apple Private Cloud Compute. The on-device path first uses Vision
OCR, then asks Foundation Models for typed candidates; the framework in this
project's SDK exposes text prompting rather than direct image input. Private
Cloud Compute remains an explicit unavailable choice until its newer beta SDK
and entitlement are available, rather than silently falling back to another
service.
