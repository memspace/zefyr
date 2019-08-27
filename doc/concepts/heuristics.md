## Heuristic rules

As it turns out, a good rich text editor not only allows the user to
manually apply different styles to text in a document. It can also
automatically apply certain styles based on the context of user
actions.

Some very common examples include autoformatting of links or inserting
a new list item when user presses `Enter` key.

In Notus (document model used by Zefyr editor), such rules are called
*heuristic rules*. There are two main purposes for heuristic rules:

1. User experience: rules like above-mentioned autoformatting of links are here to make editing a user friendly process.
2. Semantics preservation: this is mostly invisible for the user but is very important nevertheless. There is a set of rules to make sure that a document change conforms to the data format and model semantics.

Let's cover the second item in more detail.

### Example heuristic rule

Say, a user is editing following document (cursor position is indicated
by pipe `|` character):

> ### Document| title styled as h3 heading
> Regular paragraph with **bold** text.

User decides to change the first line style from `h3` to `h2`. If we
were to apply this change to the document in code it would look like
this:

```dart
var doc = getDocument();
var cursorPosition = 8; // after the word "Document"
var selectionLength = 0; // selection is collapsed.
var change = doc.format(
  cursorPosition, selectionLength, NotusAttribute.heading.level2);
```

If we try to apply this change as-is it would have no effect or, more
likely, result in an `AssertionError` because we are trying to apply line style
to a character in the middle of a line. This is why all methods in
`NotusDocument` have an extra step which applies heuristic rules to
the change (there is one method which skips this step, `compose`,
read more on it later) before actually composing it.

The `NotusDocument.format` method returns an instance of `Delta` which
was actually applied to the document. For the above scenario it would
look like this:

```json
[
  {"retain": 35},
  {"retain": 1, "attributes": {"heading": 2} }
]
```

The above change applies `h2` style to the 36th character in the
document, that's the *newline* character of the first line, exactly
what user intended to do.

There are more similar scenarios which are covered by heuristic rules
to ensure consistency with the document model and provide better UX.

### `NotusDocument.compose()` and skipping heuristic rules

The `compose()` method is the only method which skips the step of
applying heuristic rules and therefore **should be used with great
care** as it can result in corrupted document state.

Use this method when you are sure that the change you are about to compose
conforms to the document model and data format semantics.

This method exists mostly to enable following use cases:

* **Collaborative editing**, when a change came from a different site and has already been normalized by heuristic rules on that site. Care must be taken to ensure that this change is based on the same revision of the document, and if not, transformed against any local changes before composing.
* **Change history and revisioning**, when a change came from a revision history stored on a server or a database. Similarly, care must be taken to transform the change against any local (uncommitted) changes before composing.

When composing a change which came from a different site or server make
sure to use `ChangeSource.remote` when calling `compose()`. This allows
you to distinguish such changes from local changes made by the user
when listening on `NotusDocument.changes` stream.
