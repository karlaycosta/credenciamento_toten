import 'dart:ffi';

import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

class DatabaseSqlite {
  late final Database db;

  // TODO: Melhorar essa parte do código
  DatabaseSqlite._() {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('sqlite3.dll'),
    );
    db = sqlite3.open('data.db');
    // Habilita as restrições de chave estrangeira
    db.execute('PRAGMA foreign_keys = ON');
  }
  static final DatabaseSqlite instance = DatabaseSqlite._();
}
