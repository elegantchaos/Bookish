# BookishCoding

`BookishCoding` implements JSON interchange coding for `BookishRecord`.

The package requires Swift 6.3 and macOS 26.

The package includes:

- `BookishInterchangeFile`, the top-level materialised record interchange file.
- `BookishInterchangeFormat`, the format identifier and version.
- `BookishInterchangeSchema`, reserved JSON key configuration.
- `BookishInterchangeCodec`, the custom JSON encoder and decoder.

The codec supports canonical typed record values and optional compact record
link shorthand such as `@record-id`.

Run the package tests from this directory with:

```sh
swift test
```
