// ignore_for_file: experimental_member_access
import 'package:isar/isar.dart';

part 'cached_item_model.g.dart';

@collection
class CachedQuestion {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String questionId;

  late String title;
  late String filePath; // Local path
  late DateTime? expiresAt;
  late DateTime downloadedAt;

  CachedQuestion();
}
