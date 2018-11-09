## Images

> Note that described API is considered experimental and is likely to be
> changed in backward incompatible ways. If this happens all changes will be
> described in detail in the changelog to simplify upgrading.

Zefyr (and Notus) supports embedded images. In order to handle images in
your application you need to implement `ZefyrImageDelegate` interface which
looks like this:

```dart
abstract class ZefyrImageDelegate<S> {
  /// Builds image widget for specified [imageSource] and [context].
  Widget buildImage(BuildContext context, String imageSource);

  /// Picks an image from specified [source].
  ///
  /// Returns unique string key for the selected image. Returned key is stored
  /// in the document.
  Future<String> pickImage(S source);
}
```

Zefyr comes with default implementation which exists mostly to provide an
example and a starting point for your own version.

It is recommended to always have your own implementation specific to your
application.

### Implementing ZefyrImageDelegate

Let's start from the `pickImage` method:

```dart
// Currently Zefyr depends on image_picker plugin to show camera or image gallery.
// (note that in future versions this may change so that users can choose their
// own plugin and define custom sources)
import 'package:image_picker/image_picker.dart';

class MyAppZefyrImageDelegate implements ZefyrImageDelegate<ImageSource> {
  @override
  Future<String> pickImage(ImageSource source) async {
    final file = await ImagePicker.pickImage(source: source);
    if (file == null) return null;
    // We simply return the absolute path to selected file.
    return file.uri.toString();
  }
}
```

This method is responsible for initiating image selection flow (either using
camera or gallery), handling result of selection and returning a string value
which essentially serves as an identifier for the image.

Returned value is stored in the document Delta and later on used to build the
appropriate `Widget`.

It is up to the developer to define what this value represents.

In the above example we simply return a full path to the file on user's device,
e.g. `file:///Users/something/something/image.jpg`. Some other examples
may include a web link, `https://myapp.com/images/some.jpg` or just some
arbitrary string like an ID.

For instance, if you upload files to your server you can initiate this task
in `pickImage`, for instance:

```dart
class MyAppZefyrImageDelegate implements ZefyrImageDelegate<ImageSource> {
  final MyFileStorage storage;
  MyAppZefyrImageDelegate(this.storage);

  @override
  Future<String> pickImage(ImageSource source) async {
    final file = await ImagePicker.pickImage(source: source);
    if (file == null) return null;
    // Use my storage service to upload selected file. The uploadImage method
    // returns unique ID of newly uploaded image on my server.
    final String imageId = await storage.uploadImage(file);
    return imageId;
  }
}
```

Next we need to implement `buildImage`. This method takes `imageSource` argument
which contains that same string you returned from `pickImage`. Here you can
use this value to create a Flutter `Widget` which renders the image. Normally
you would return the standard `Image` widget from this method, but it is not
a requirement. You are free to create a custom widget which, for instance,
shows progress of upload operation that you initiated in the `pickImage` call.

Assuming our first example where we returned full path to the image file on
user's device, our `buildImage` method can be as simple as following:

```dart
class MyAppZefyrImageDelegate implements ZefyrImageDelegate<ImageSource> {
  // ...

  @override
  Widget buildImage(BuildContext context, String imageSource) {
    final file = new File.fromUri(Uri.parse(imageSource));
    /// Create standard [FileImage] provider. If [imageSource] was an HTTP link
    /// we could use [NetworkImage] instead.
    final image = new FileImage(file);
    return new Image(image: image);
  }
}
```

### Previous

* [Heuristics][heuristics]

[heuristics]: /doc/heuristics.md