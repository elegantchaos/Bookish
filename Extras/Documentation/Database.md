# BookishApp

This package contains the views and application-level controllers and logic.


## Records

All items are represented as `CDRecord` entities.

Each record has:

- some fixed properties
- some flexible properties
- contains/containedBy relationships with other records

### Fixed Properties

`id` is a string, and should be unique across all records. 

Typically this will be a UUID, but it can also be anything; for example, some global singleton records might have fixed ids, such as "root".

`name` is a string. This provides a label to use when displaying the record to the user. It does not have to be unique, and could be empty for a record which isn't intended to be user-viewable. 

`kind` is an enum, backed by an integer, used as a quick way to distinguish different kinds of records. In the core data record, the property name is actually `kindCode`, and it's an `Int16`.

`imageData` and `imageURL` represent an image for the record; both are optional. If `imageData` is present, it takes precedence. Othwerwise, if `imageURL` is present, it can be used to fetch an image. If neither property is present, the `kind` property can be used to supply a default image. 


### Flexible Properties

A one-to-one relationship to `CDProperty` entities is used to represent other properties.

Each property consists of a key, and a plist-encoded value.


### Connections

Records are linked to other records with relationships, and form a graph.

This is a many-to-many relationship, as a record be contained by more than one other record. Cycles are allowed.

The `contents` property represents the records that this record "contains".

The `containedBy` property represents the records that "contain" this record.

("contained" may be the wrong concept here - "linked" would be better).

Any record can only link to another record _once_. 
 
## Entities

Bookish has a small set of fundamental entities that the user interacts with. These are records with the following kind values: `book`, `person`, `organisation`, `series`, `list`.

Books are obviously key to the whole thing. 

People are used to represent authors, illustrators, etc. A person can have multiple roles for any given book, and a book can involve multiple people in multiple roles.  

Organisations are used to represent publishers. A book can have multiple publishers. A publisher can have multiple books.

Series are lists of books that are connected in an ordered sequence. Usually this is something that evolves: all the Game Of Thrones books, or all books involving Inspector Rebus, where the order relates to the publication date. Sometimes it's explicit, such as the Gollancz SF Masterworks series.

Lists are collections of books. Generally these are made by the user (although the Imports list is automatically maintained). 

## Links

Although the contains/containedBy relationship provides a low-level way to connect records, it does not provide any context about the purpose of the connection, or the ordering.

For this reason, high-level connections are represented using intermediate records, of type `link`.

A link record's `contains` relationship points to the records that are linked together. Optionally, the `containedBy` relationship points to a record of kind `role`, which attaches a semantic meaning to the link. If present, the `role` record indicates what kind of connection the link represents - for example a book and a person might be linked with the "author" role, to indicate that the person is the author of the book.  

These links can be viewed in either direction, and interpreted accordingly. Thus a book can list all the people linked to it, along with the roles: 'author', 'illustrator' etc, and a person can list all the books linked to it, along with the person's role for each one. 

Because a link us represented by a record, it can have properties associated with it. This can be used for a number of purposes; for example in a reading list, the link could have an associated date representing the time that the item was read.
 
## Lists

Lists are represented using links.

Each entry in the list has a link which connects it to an item.

### Simple Ordered List

In a simple list, each link record has an `index` property representing its order in the list (this index must be managed to ensure that the indexes are unique and consequetive).

These simple link records do not have a role associated with them.

Note that multiple links to the same target record an exist - allowing the same item to appear multiple times in a list. Ensuring that a record only appears once in a list needs to be managed explicitly if required. 

### Roles

Each role is represented by a record of kind `role`. There are a few predefined, but the user can add more.

Each of these contains a link record for every connection between things with that role. 

The items associated with a role are not inherently ordered, so the link records don't need an `index` property.

### Complex List

Some lists need to associate some other data with each entry, or may need multiple entries to the same record.

For example, a list of the user's reading history might want to associate a date with each entry, representing the date that the book was read. If the user read the book twice, there will be two entries. 

This is the same situation as a simple list, but using additional properties for each link record.
