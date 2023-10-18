import 'package:isar/isar.dart';

part 'diary.g.dart';

@collection
class Settings {
  Id id = Isar.autoIncrement;
  bool onboard = false;
  String? theme = 'system';
  bool materialColor = false;
  bool amoledTheme = false;
  String? language;
}
