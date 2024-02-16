import 'package:isar/isar.dart';

part 'diary.g.dart';

@collection
class Settings {
  Id id = Isar.autoIncrement;
  bool onboard = false;
  String? theme = 'system';
  String timeformat = '24';
  bool materialColor = false;
  bool amoledTheme = false;
  String? language;
}
