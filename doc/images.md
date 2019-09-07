## Embedding Images

> Note that Image API is considered experimental and is likely to be
> changed in backward incompatible ways. If this happens all changes will be
> described in detail in the changelog to simplify upgrading.

Zefyr supports embedding images. In order to handle images in
your application you need to implement `ZefyrImageDelegate` interface which
looks like this:

```dart
abstract class ZefyrImageDelegate<S> {
  /// Unique key to identify camera source.
  S get cameraSource;

  /// Unique key to identify gallery source.
  S get gallerySource;

  /// Builds image widget for specified image [key].
  ///
  /// The [key] argument contains value which was previously returned from
  /// [pickImage].
  Widget buildImage(BuildContext context, String key);

  /// Picks an image from specified [source].
  ///
  /// Returns unique string key for the selected image. Returned key is stored
  /// in the document.
  ///
  /// Depending on your application returned key may represent a path to
  /// an image file on user's device, an HTTP link, or an identifier generated
  /// by a file hosting service like AWS S3 or Google Drive.
  Future<String> pickImage(S source);
}
```

There is no default implementation of this interface since resolving image
sources is always application-specific.

> Note that prior to 0.7.0 Zefyr did provide simple default implementation of
> `ZefyrImageDelegate` however it was removed as it introduced unnecessary
> dependency on `image_picker` plugin.

### Implementing ZefyrImageDelegate

For this example we will use [image_picker](https://pub.dev/packages/image_picker)
plugin which allows us to select images from device's camera or photo gallery.

Let's start from the `pickImage` method:

```dart
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
appropriate image widget.

It is up to the developer to define what this value represents.

In the above example we simply return a full path to the file on user's device,
e.g. `file:///Users/something/something/image.jpg`. Some other examples
may include a web link, `https://myapp.com/images/some.jpg` or an
arbitrary string like an identifier of an image in a cloud storage like AWS S3.

For instance, if you upload files to your server you can initiate this task
in `pickImage` as follows:

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
use this value to create a Flutter widget which renders the image. Normally
you would return the standard `Image` widget from this method, but it is not
a requirement. You are free to create a custom widget which, for instance,
shows progress of upload operation that you initiated in the `pickImage` call.

Assuming our first example where we returned full path to the image file on
user's device, our `buildImage` method can be as simple as following:

```dart
class MyAppZefyrImageDelegate implements ZefyrImageDelegate<ImageSource> {
  // ...

  @override
  Widget buildImage(BuildContext context, String key) {
    final file = File.fromUri(Uri.parse(key));
    /// Create standard [FileImage] provider. If [key] was an HTTP link
    /// we could use [NetworkImage] instead.
    final image = FileImage(file);
    return Image(image: image);
  }
}
```

There is two more overrides we need to implement which configure source types
used by Zefyr toolbar:

```dart
class MyAppZefyrImageDelegate implements ZefyrImageDelegate<ImageSource> {
  // ...
  @override
  ImageSource get cameraSource => ImageSource.camera;

  @override
  ImageSource get gallerySource => ImageSource.gallery;
}
```

Now our image delegate is ready to be used by Zefyr so the last step is to
pass it to Zefyr editor:

```dart
import 'package:zefyr/zefyr.dart'

class MyAppPageState extends State<MyAppPage> {
  FocueNode _focusNode = FocusNode();
  ZefyrController _controller;

  // ...

  @override
  Widget build(BuildContext context) {
    final editor = new ZefyrEditor(
      focusNode: _focusNode,
      controller: _controller,
      imageDelegate: MyAppZefyrImageDelegate(),
    );

    // ... do more with this page's layout

    return ZefyrScaffold(
      child: Container(
        // ... customize
        child: editor,
      )
    );
  }
}
```

When `imageDelegate` field is set to non-null value it automatically enables
image selection button in Zefyr's style toolbar.
