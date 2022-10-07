# BookishViews

A description of this package.


## Records

All items are represented as `CDRecord` entities.

Each record has:

- some fixed properties
- some flexible properties
- parent/child relationships with other records

### Fixed Properties

`id` is a string, and should be unique across all records. 

Typically this will be a UUID, but it can also be anything; for example, some global singleton records might have fixed ids, such as "root".

`name` is a string. This provides a label to use when displaying the record to the user. It does not have to be unique, and could be empty for a record which isn't intended to be user-viewable. 

`kind` is an enum, backed by an integer, used as a quick way to distinguish different kinds of records. In the core data record, the property name is actually `kindCode`, and it's an `Int16`.

`imageData` and `imageURL` represent an image for the record; both are optional. If `imageData` is present, it takes precedence. Othwerwise, if `imageURL` is present, it can be used to fetch an image. If neither property is present, the `kind` property can be used to supply a default image. 


### Flexible Properties

A one-to-one relationship to `CDProperty` entities is used to represent other properties.

Each property consists of a key, and a jsonEncoded value.

### Relationships

Records are linked to other records with relationships, and form a graph.

This is a many-to-many relationship, as a record be contained by more than one other record. Cycles are allowed.

The `contents` property represents the records that this record "contains".

The `containedBy` property represents the records that "contain" this record.

("contained" may be the wrong concept here - "linked" would be better).

Any record can only link to another record _once_. 
 
## Representing Relationships

These primitves can be used to represent different kinds of relationships.


### Simple List

As an example, the "People" list contains all person records. Each person only needs to appear once, and there is no ordering needed, so the `contents` relationship is fine for this.

### Semantic Link

A book is linked to other records, but each link is associated with a role. Examples of roles are "Author", "Illustrator", "Publisher", "Series", and so on.

This can be achieved using an intermediate Record for each role:

```
Book Record
  Role Record "Author"
    Person Record 1
    Person Record 2
  Role Record "Illustrator"
    Person Record 3
  Role Record "Publisher"
    Publisher Record
```

### Complex List

Some lists need to associate some data with each entry, or may need multiple entries to the same record.

For example, a Reading List needs to associate a date with each book, and might contain the same book twice if the user has read it twice.

This can be achieved using an intermediate Record for each entry.

```
Reading List Record
  Entry Record 1(date: 12/10/21)
    Book Record 1
  Entry Record 2 (date: 14/02/22)
    Book Record 2
  Entry Record 3 (date: 05/04/22)
    Book Record 1
```




