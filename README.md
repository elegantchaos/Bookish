
# Bookish

Bookish is a book cataloguing app aimed at macOS and iOS.

## Key Features

- Flexible schema-less records with user-customisable fields
- Intelligent barcode and bookshelf scanning
- Metadata lookup and cleaning
- macOS and iOS clients with automatic data synchronisation
- clean and modern SwiftUI-based user interface
- user defined book lists (reading/loans/library/to-read/etc)

## Documentation

### Product

- [Specification](Extras/Documentation/Specification.md): purpose, product goals, and scope.
- [Catalogue Model](Extras/Documentation/Catalogue%20Model.md): the records, types, and relationships the app exposes.

### Data

- [Datastore Design](Extras/Documentation/Datastore%20Design.md): the record store, mutations, and sync design.
- [Datastore Implementation](Extras/Documentation/Datastore%20Implementation.md): build-time choices and work plan for the datastore.
- [Interchange Design](Extras/Documentation/Interchange%20Design.md): the JSON interchange format for import and export.
- [Data View Design](Extras/Documentation/Data%20View%20Design.md): how configuration records drive the user interface.
- [Data Cleanup](Extras/Documentation/Data%20Cleanup.md): reviewing and repairing inconsistent catalogue metadata.

### Application

- [Command and Environment Design](Extras/Documentation/Command%20and%20Environment%20Design.md): the engine, commands, services, and SwiftUI environment.
- [Application Services](Extras/Documentation/Application%20Services.md): each application service and its purpose.
- [Project Layout](Extras/Documentation/Project%20Layout.md): the package-based project structure.

### Background and records

- [Legacy Findings](Extras/Documentation/Legacy%20Findings.md): ideas worth keeping from earlier Bookish projects.
- [Decision log](Extras/Decisions/): decisions that later work must follow.
- [Development journal](Extras/Journal/index.md): work as it happened.
