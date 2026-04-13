import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaService {
  MediaService() : _picker = ImagePicker();

  final ImagePicker _picker;

  bool get supportsCameraSource => Platform.isAndroid || Platform.isIOS;

  Future<File?> pickImage({required ImageSource source}) async {
    if (source == ImageSource.camera && !supportsCameraSource) {
      throw UnsupportedError(
        'Camera capture is not available on this platform. Use gallery selection instead.',
      );
    }
    final image = await _picker.pickImage(source: source, imageQuality: 85);
    return image == null ? null : File(image.path);
  }

  Future<File> storeProgressPhoto(
    File original, {
    required String filenamePrefix,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final targetDir = Directory(p.join(directory.path, 'progress_photos'));
    await targetDir.create(recursive: true);
    final extension = p.extension(original.path).isEmpty
        ? '.jpg'
        : p.extension(original.path);
    final target = File(
      p.join(
        targetDir.path,
        '$filenamePrefix-${DateTime.now().microsecondsSinceEpoch}$extension',
      ),
    );
    return original.copy(target.path);
  }
}
