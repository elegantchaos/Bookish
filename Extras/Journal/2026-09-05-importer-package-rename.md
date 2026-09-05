# Importer Package Rename

The modern importer and cleanup packages no longer carry the temporary `Nu` suffix. Their directories are now `Dependencies/BookishImporter` and `Dependencies/BookishCleanup`.

`BookishImporter` now uses the same suffix-free package, product, target, and test-target name. `BookishApp`, the Xcode project, package dependencies, and current implementation documentation now refer to the renamed packages. Historical journal entries retain their original names as a record of the migration state at the time.
