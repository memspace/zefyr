# Release notes

Current version of Zefyr editor is `0.7` ([changelog](packages/zefyr/CHANGELOG.md)).

### 0.7

__This is a breaking change release.__

This version introduces first set of changes aimed at addressing some
common pain points reported by users of this library. In addition this release
is the first step towards making Zefyr easier to extend and customize.

This version of Zefyr also comes with revamped documentation website and
some of the articles completely rewritten to help new users to get started. More
articles and tutorials will be added in future releases.

Highlights of this release include:

* Zefyr no longer depends in `image_picker` package. This introduced breaking
  changes described in the changelog.
* Selection overlay has been refactored to enable customization work in
  follow up releases.
* Zefyr now supports selection-only workflow via new `ZefyrMode` object which
  replaces previous `enabled` field (breaking change).

For more details on breaking changes and upgrade instructions please read
[changelog](packages/zefyr/CHANGELOG.md).
