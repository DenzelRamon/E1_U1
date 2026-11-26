// Ejercicio 3.2 - Base de datos local con Drift (Flutter)
//
// pubspec.yaml:
//   dependencies:
//     drift: ^2.20.0
//     drift_flutter: ^0.2.0
//   dev_dependencies:
//     drift_dev: ^2.20.0
//     build_runner: ^2.4.0
//
// Generar código:  dart run build_runner build --delete-conflicting-outputs
// Guarda este archivo como lib/database.dart (el nombre del part debe coincidir).

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ---------------- Tablas ----------------

class Categorias extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text().withLength(min: 1, max: 50)();
  IntColumn get color => integer()(); // ARGB, p.ej. 0xFF2196F3
}

class Notas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get titulo => text().withLength(min: 1, max: 120)();
  TextColumn get contenido => text()();
  DateTimeColumn get fecha => dateTime().withDefault(currentDateAndTime)();
  IntColumn get categoriaId =>
      integer().references(Categorias, #id, onDelete: KeyAction.cascade)();
}

// ---------------- DAO ----------------

@DriftAccessor(tables: [Notas, Categorias])
class NotasDao extends DatabaseAccessor<AppDatabase> with _$NotasDaoMixin {
  NotasDao(super.db);

  /// Notas de una categoría, de la más reciente a la más antigua.
  Stream<List<Nota>> watchNotasPorCategoria(int categoriaId) {
    return (select(notas)
          ..where((n) => n.categoriaId.equals(categoriaId))
          ..orderBy([(n) => OrderingTerm.desc(n.fecha)]))
        .watch();
  }

  /// Versión de una sola lectura (Future).
  Future<List<Nota>> getNotasPorCategoria(int categoriaId) {
    return (select(notas)
          ..where((n) => n.categoriaId.equals(categoriaId))
          ..orderBy([(n) => OrderingTerm.desc(n.fecha)]))
        .get();
  }

  Future<int> insertarNota(NotasCompanion nota) => into(notas).insert(nota);
  Future<bool> actualizarNota(Nota nota) => update(notas).replace(nota);
  Future<int> eliminarNota(int id) =>
      (delete(notas)..where((n) => n.id.equals(id))).go();

  Future<int> insertarCategoria(CategoriasCompanion c) =>
      into(categorias).insert(c);
  Stream<List<Categoria>> watchCategorias() => select(categorias).watch();
}

// ---------------- Base de datos ----------------

@DriftDatabase(tables: [Notas, Categorias], daos: [NotasDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'notas_db'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

// ---------------- Ejemplo de uso ----------------
//
// final db = AppDatabase();
// final catId = await db.notasDao.insertarCategoria(
//   CategoriasCompanion.insert(nombre: 'Trabajo', color: 0xFF2196F3),
// );
// await db.notasDao.insertarNota(NotasCompanion.insert(
//   titulo: 'Reunión', contenido: 'Preparar demo', categoriaId: catId,
// ));
// db.notasDao.watchNotasPorCategoria(catId).listen(print);
//
// ---------------- Alternativa Kotlin (Room) ----------------
//
// @Entity(tableName = "categorias")
// data class Categoria(
//     @PrimaryKey(autoGenerate = true) val id: Long = 0,
//     val nombre: String,
//     val color: Int
// )
//
// @Entity(
//     tableName = "notas",
//     foreignKeys = [ForeignKey(Categoria::class, ["id"], ["categoriaId"], onDelete = ForeignKey.CASCADE)],
//     indices = [Index("categoriaId")]
// )
// data class Nota(
//     @PrimaryKey(autoGenerate = true) val id: Long = 0,
//     val titulo: String,
//     val contenido: String,
//     val fecha: Long,
//     val categoriaId: Long
// )
//
// @Dao
// interface NotaDao {
//     @Query("SELECT * FROM notas WHERE categoriaId = :categoriaId ORDER BY fecha DESC")
//     fun notasPorCategoria(categoriaId: Long): Flow<List<Nota>>
// }
