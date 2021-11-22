
## Database Design Notes

A `Book` has properties, and is a member of zero or more `List`s.
A `List` has properties, and contains `Book`s and other `List`s.

Properties are basic values like Strings, Numbers, Dates etc, and are used to describe things about a book or list, such as its title, publication date, and so on.


### People and Roles

A person is represented by a list, containing other lists which represent roles, each of which contain books.

List: name = Joe Bloggs
  List name = Author
    Book: name = First book written by Joe Bloggs
    Book: name = Second book written by Joe Bloggs
    etc...
  List name = Editor
    Book: name = Book that was edited by Joe Bloggs
  

### Publishers

A publisher is represented as a list, containing the books that they published.


### Series

A series is represented as a list, containing books.

As lists are unordered, a special property is added to each book, indicating that book's order in the series. The key for this property is derived from the uuid of the list representing the series: eg series-order-<uuid>.



 
