import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

class StorageService {
  SupabaseClient get _db => Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Lets the user pick a photo from the gallery, resized to keep uploads small.
  /// Returns null if they cancel.
  Future<XFile?> pickPhoto() =>
      _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);

  /// Uploads [file] into the user's own folder of [bucket] ('avatars' or
  /// 'event-images') and returns its public URL.
  Future<String> upload({required String bucket, required String kind, required XFile file}) async {
    final uid = _db.auth.currentUser!.id;
    final name = file.name.toLowerCase();
    final ext = name.endsWith('.png') ? 'png' : name.endsWith('.webp') ? 'webp' : 'jpg';
    final path = uploadPath(userId: uid, kind: kind, extension: ext);
    await _db.storage.from(bucket).uploadBinary(
          path,
          await file.readAsBytes(),
          fileOptions: FileOptions(contentType: ext == 'jpg' ? 'image/jpeg' : 'image/$ext'),
        );
    return _db.storage.from(bucket).getPublicUrl(path);
  }
}
