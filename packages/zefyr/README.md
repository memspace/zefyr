# Zefyr [![Build Status](https://travis-ci.com/memspace/zefyr.svg?branch=master)](https://travis-ci.com/memspace/zefyr) [![codecov](https://codecov.io/gh/memspace/zefyr/branch/master/graph/badge.svg)](https://codecov.io/gh/memspace/zefyr)

*Soft and gentle rich text editing for Flutter applications.*

Zefyr is currently in **early preview**. If you have a feature
request or found a bug, please file it at the [issue tracker][].

[issue tracker]: https://github.com/memspace/zefyr/issues

For documentation see [https://github.com/memspace/zefyr](https://github.com/memspace/zefyr).

![zefyr screenshot](https://github.com/memspace/zefyr/raw/master/packages/zefyr/zefyr.png)

## Installation

Official releases of Zefyr can be installed from Dart's Pub package repository.

> Note that versions from Pub track stable channel of Flutter. If you are on master channel
> check out instructions below in this document.


To install Zefyr from Pub add `zefyr` package as a dependency to your `pubspec.yaml`:

```yaml
dependencies:
  zefyr: [latest_version]
```

And run `flutter packages get`.

#### Installing version of Zefyr compatible with master channel of Flutter.

You need to add git dependency to your pubspec.yaml that points to `flutter-master` branch:

```yaml
dependencies:
  zefyr:
    git:
      url: https://github.com/memspace/zefyr.git
      ref: flutter-master
      path: packages/zefyr
```

And run `flutter packages get`.

Continue to [https://github.com/memspace/zefyr/blob/master/doc/quick_start.md](documentation) to
learn more about Zefyr and how to use it in your projects.
