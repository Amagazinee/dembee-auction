import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/submission.dart';

/// Локал хадгалалт (MVP). Дараа нь Firebase Storage + Firestore-оор солиход бэлэн.
class SubmitService {
  SubmitService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Future<Directory> _rootDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'submissions'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Submission> submit({
    required String lastName,
    required String firstName,
    required File imageFile,
  }) async {
    final id = _uuid.v4();
    final root = await _rootDir();
    final ext = p.extension(imageFile.path).isEmpty
        ? '.jpg'
        : p.extension(imageFile.path);
    final savedImage = File(p.join(root.path, '$id$ext'));
    await imageFile.copy(savedImage.path);

    final submission = Submission(
      id: id,
      lastName: lastName.trim(),
      firstName: firstName.trim(),
      imagePath: savedImage.path,
      submittedAt: DateTime.now().toUtc(),
    );

    final meta = File(p.join(root.path, '$id.json'));
    await meta.writeAsString(
      const JsonEncoder.withIndent('  ').convert(submission.toJson()),
    );

    return submission;
  }
}
