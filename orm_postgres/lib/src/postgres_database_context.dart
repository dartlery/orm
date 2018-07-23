import 'dart:async';
import 'dart:mirrors';

import 'package:meta/meta.dart';
import 'package:orm/internal.dart' as orm;
import 'package:orm/meta.dart';
import 'package:orm_postgres/src/postgres_connection_pool.dart';
import 'package:orm_postgres/src/postgres_database.dart';
import 'package:uuid/uuid.dart' as uuid;

import 'postgres_command.dart';

class PostgresDatabaseContext extends orm.ADatabaseContext {
  final PostgresConnectionPool _connectionPool;

  PostgresDatabaseContext(String host, int port, String databaseName,
      {String username,
      String password,
      int timeoutInSeconds = 30,
      String timeZone = "UTC",
      bool useSSL = false})
      : this._connectionPool = new PostgresConnectionPool(
            host, port, databaseName,
            username: username,
            password: password,
            timeoutInSeconds: timeoutInSeconds,
            timeZone: timeZone,
            useSSL: useSSL);

  @override
  Future<orm.Uuid> addInternal(DbStorage storage, Map<String, dynamic> data) =>
      _connectionPool.databaseWrapper((PostgresDatabase db) async {
        final orm.Uuid output = generateInternalId();
        data["_id"] = output.toString(removeDashes: true);

        final StringBuffer statement =
            new StringBuffer("INSERT INTO \"${storage.name}\" (\"")
              ..write(data.keys.join("\", \""))
              ..write("\") VALUES (");

        final List<String> parameters = <String>[];
        for (String key in data.keys) {
          parameters.add("@$key");
        }

        statement..write(parameters.join(", "))..write(")");

        await db.execute(statement.toString(), substitutionValues: data);
        return output;
      });

  @override
  Future<Null> applyIndex(DbStorage dbs, DbIndex index) =>
      _connectionPool.databaseWrapper((PostgresDatabase db) async {
        final StringBuffer createStatement = new StringBuffer("CREATE ");
        if (index.unique) {
          createStatement.write("UNIQUE ");
        }

        createStatement.write(
            "INDEX IF NOT EXISTS \"${index.name}\" ON \"${dbs.name}\" (");

        final List<String> fields = <String>[];
        for (String key in index.fields.keys) {
          if (index.fields[key] == orm.Direction.ascending) {
            fields.add("\"$key\" ASC");
          } else {
            fields.add("\"$key\" DESC");
          }
        }

        createStatement..write(fields.join(", "))..write(")");
        await db.execute(createStatement.toString());
      });

  @override
  Future<int> countInternal(DbStorage dbStorage, orm.Criteria criteria) =>
      _connectionPool.databaseWrapper((PostgresDatabase db) async {
        final _CriteriaConversionResult result = _convertCriteria(criteria);
        final StringBuffer query =
            new StringBuffer("SELECT COUNT(*) FROM \"${dbStorage
            .name}\"");
        if (criteria?.sequence?.isNotEmpty ?? false) {
          query..write(" WHERE ")..write(result.text);
        }

        final List<List<dynamic>> data = await db.query(query.toString(),
            substitutionValues: result.parameters);
        return data[0][0];
      });

  @override
  Future<Null> createDataStore(DbStorage storage, ClassMirror cm) =>
      _connectionPool.databaseWrapper((PostgresDatabase db) async {
        final StringBuffer createStatement = new StringBuffer(
            "CREATE TABLE IF NOT EXISTS \"${storage.name}\" (");
        final List<String> fields = <String>["\"_id\" UUID PRIMARY KEY"];
        await orm.ADatabaseContext.iterateDbFields(cm,
            (VariableMirror vm, DbField dbField, String name) async {
          fields.add("\"$name\" ${_convertDataType(vm.type.reflectedType)} ");
        });

        createStatement..write(fields.join(","))..write(")");
        await db.execute(createStatement.toString());
      });

  @protected
  @override
  Future<Null> deleteFromDb(DbStorage dbStorage, orm.Criteria criteria) =>
      _connectionPool.databaseWrapper((PostgresDatabase db) async {
        final StringBuffer statement =
            new StringBuffer("DELETE FROM \"${dbStorage.name}\" ");
        if (criteria?.sequence?.isNotEmpty ?? false) {
          final _CriteriaConversionResult result = _convertCriteria(criteria);
          statement.write("WHERE ${result.text}");
          await db.execute(statement.toString(),
              substitutionValues: result.parameters);
        } else {
          await db.execute(statement.toString());
        }
      });

  @override
  Future<Null> dropObjectStoreInternal(DbStorage dbs) => _connectionPool
      .databaseWrapper((PostgresDatabase db) => db.dropTable(dbs.name));

  @protected
  @override
  Future<bool> exists(DbStorage dbs, orm.Criteria criteria) =>
      _connectionPool.databaseWrapper((PostgresDatabase db) async {
        final _CriteriaConversionResult result = _convertCriteria(criteria);

        final String sql =
            "SELECT EXISTS(SELECT 1 FROM \"${dbs.name}\" WHERE ${result.text})";

        final List<List<dynamic>> data =
            await db.query(sql, substitutionValues: result.parameters);

        return data[0][0];
      });

  @protected
  orm.Uuid generateInternalId() => new orm.Uuid();

  @override
  Future<Map<String, dynamic>> getOneFromDb(
          DbStorage dbStorage, orm.Query query) =>
      _connectionPool.databaseWrapper((PostgresDatabase db) async {
        final orm.Query limitedQuery = new orm.Query.copy(query)..limit = 1;

        final PostgresCommand cmd = _convertQuery(dbStorage, limitedQuery);

        final List<Map<String, Map<String, dynamic>>> data =
            await db.mappedResultsQuery(cmd.command,
                substitutionValues: cmd.parameters);

        if (data.isEmpty) {
          throw new orm.ItemNotFoundException("Item not found: ${cmd.command}");
        }

        return data.first[dbStorage.name];
      });

  @override
  Future<Null> nukeDatabase() => _connectionPool
      .databaseWrapper((PostgresDatabase db) => db.nukeDatabase());

  @override
  Future<dynamic> prepareDataMapValue(dynamic value) async {
    if (value is orm.Uuid) {
      return value.toString(removeDashes: true);
    }
    if (value is orm.OrmObject) {
      return (await super.prepareDataMapValue(value))
          .toString(removeDashes: true);
    }
    return super.prepareDataMapValue(value);
  }

  @protected
  @override
  Future<Stream<Map<String, dynamic>>> streamAllFromDb(
          DbStorage dbStorage, orm.Query query) {
    final PostgresCommand cmd = _convertQuery(dbStorage, query);
    return _streamFromDb(dbStorage.name, cmd);
  }

  Future<Stream<Map<String, dynamic>>> _streamFromDb(String tableName, PostgresCommand cmd) =>
      _connectionPool.databaseWrapper((PostgresDatabase db) async {
        final StreamController<Map<String, Map<String, dynamic>>> controller =
        new StreamController<Map<String, Map<String, dynamic>>>();

        db
            .mappedResultsQuery(cmd.command, substitutionValues: cmd.parameters)
            .then((List<Map<String, Map<String, dynamic>>> data) {
          try {
            data.forEach((Map data) => controller.add(data[tableName]));
          } on Exception catch (e, st) {
            controller.addError(e, st);
          } finally {
            controller.close();
          }
        });

        return controller.stream;
      });





  @override
  Future<Null> updateInternal(DbStorage storage, Map<String, dynamic> data,
          orm.Criteria criteria) =>
      _connectionPool.databaseWrapper((PostgresDatabase db) async {
        if (data.containsKey("_id")) {
          data.remove("_id");
        }
        final StringBuffer statement =
            new StringBuffer("UPDATE \"${storage.name}\" SET ");
        final List<String> fields = <String>[];
        final Map<String, dynamic> parameters = <String, dynamic>{};

        for (String key in data.keys) {
          final String fieldId = _generateFieldId();

          fields.add("\"$key\" = @$fieldId");
          parameters[fieldId] = data[key];
        }

        statement.write(fields.join(", "));

        final _CriteriaConversionResult result = _convertCriteria(criteria);
        parameters.addAll(result.parameters);

        statement.write(" WHERE ${result.text}");

        await db.execute(statement.toString(), substitutionValues: parameters);
      });

  @override
  orm.Uuid validateInternalId(dynamic internalId) {
    if (internalId == null) {
      throw new ArgumentError.notNull("internalId");
    } else if (internalId is orm.Uuid) {
      return internalId;
    } else {
      try {
        return new orm.Uuid.parse(internalId.toString());
      } on Exception {
        throw new ArgumentError.value(
            internalId, "internalId", "Must be an Uuid");
      }
    }
  }

  _CriteriaConversionResult _convertCriteria(orm.Criteria criteria) {
    final _CriteriaConversionResult output = new _CriteriaConversionResult();
    final StringBuffer sql = new StringBuffer();

    for (orm.Criterion entry in criteria.sequence) {
      String field = entry.field;
      if (entry.field == internalIdField) {
        field = "_id";
      }
      switch (entry.action) {
        case orm.Actions.equals:
          final String parameterId = new uuid.Uuid().v4().replaceAll("-", "");
          sql.write("\"$field\" = @$parameterId");
          output.parameters[parameterId] = _prepareCriteriaValue(entry.value);
          break;
        default:
          throw new Exception(
              "Query action not supported: ${entry.action.toString()}");
      }
    }
    output.text = sql.toString();
    return output;
  }

  String _convertDataType(Type t) {
    final TypeMirror tm = reflectType(t);
    if (tm.isSubtypeOf(orm.ormObjectTypeMirror)) return "uuid";

    switch (t) {
      case String:
        return "text";
      case orm.Uuid:
        return "uuid";
      case int:
        return "integer";
      case double:
        return "real";
      case bool:
        return "boolean";
    }

    throw new Exception("Data type not supported: $t");
  }

  String _convertDirection(orm.Direction dir) {
    switch (dir) {
      case orm.Direction.ascending:
        return "ASC";
      case orm.Direction.descending:
        return "DESC";
    }
    throw new Exception("Unsupported direction: $dir");
  }

  PostgresCommand _convertQuery(DbStorage dbs, orm.Query query) {
    final PostgresCommand output = new PostgresCommand();
    final StringBuffer sql = new StringBuffer("SELECT * FROM \"${dbs.name}\" ");
    if (query.sequence.isNotEmpty) {
      final _CriteriaConversionResult result = _convertCriteria(query);
      sql.write("WHERE (${result.text})");
      output.parameters.addAll(result.parameters);
    }

    if (query.hasOrders) {
      sql.write(
          " ORDER BY ${query.getOrder().map((orm.Order order) => "\"${order.field}\" ${_convertDirection(order.direction)}").join(", ")}");
    }

    if (query.limit > 0) {
      sql.write(" LIMIT ${query.limit}");
    }
    if (query.skip > 0) {
      sql.write(" OFFSET ${query.limit}");
    }
    output.command = sql.toString();
    return output;
  }

  String _generateFieldId() => new uuid.Uuid().v4().replaceAll("-", "");

  dynamic _prepareCriteriaValue(dynamic value) {
    if (value is orm.Uuid) {
      return value.toString(removeDashes: true);
    }
    return value;
  }

  @protected
  @override
  Future<Stream<Map<String, dynamic>>> searchInternal(
      DbStorage storage, List<DbIndex> searchIndexes, String searchTerm)  {
    if (searchIndexes?.isEmpty ?? true) {
      throw new ArgumentError(
          "searchIndexes must be a List with 1 or more values");
    }

    final StringBuffer sql =
        new StringBuffer("SELECT * FROM \"${storage.name}\" WHERE to_tsvector(")
          ..write("\"${searchIndexes.map(
            (DbIndex idx) => idx.fields.keys.join("\" || ' ' || \"")).join("\" || ' || \"")}\"")
          ..write(") @@ to_tsquery(@query)");

    return _streamFromDb(storage.name, new PostgresCommand(sql.toString(), <String, String>{"@query": searchTerm}));
  }
}

class _CriteriaConversionResult {
  String text;
  final Map<String, dynamic> parameters = <String, dynamic>{};
}
