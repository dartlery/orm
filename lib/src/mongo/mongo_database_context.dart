import 'dart:async';

import 'package:meta/meta.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:orm/meta.dart';

import '../database_context.dart';
import '../orm_object.dart';
import '../exceptions/item_not_found_exception.dart';
import 'package:orm/orm.dart' as orm;
import 'mongo_database.dart';
import 'mongo_db_connection_pool.dart';

class MongoDatabaseContext extends ADatabaseContext {
  final MongoDbConnectionPool _connectionPool;

  MongoDatabaseContext(String connectionString)
      : this._connectionPool = new MongoDbConnectionPool(connectionString);

  @override
  Future<ObjectId> addInternal(DbStorage storage, Map<String, dynamic> data) =>
      _connectionPool.databaseWrapper((MongoDatabase db) async {
        DbCollection col = db.collection(storage.name);
        data["_id"] = new ObjectId();
        await col.insert(data);
        return data["_id"];
      });

  @override
  Future<Null> applyIndex(DbStorage dbs, DbIndex index) =>
      _connectionPool.databaseWrapper<bool>((MongoDatabase db) async {
        Map<String, int> keys = <String, int>{};
        for (String key in index.fields.keys) {
          if (index.fields[key]) {
            keys[key] = 1;
          } else {
            keys[key] = -1;
          }
        }
        await db.createIndex(dbs.name,
            keys: keys,
            name: index.name,
            sparse: index.sparse,
            unique: index.unique);
      });

  @protected
  Future<bool> exists(DbStorage dbs, orm.Criteria query) =>
      _connectionPool.databaseWrapper<bool>((MongoDatabase db) async {
        SelectorBuilder sb = _convertQuery(query);

        DbCollection col = db.collection(dbs.name);
        return (await col.count(sb)) > 0;
      });

  @protected
  dynamic generateInternalId() => new ObjectId();

  @override
  Future<Map<String, dynamic>> getOneFromDb(
      DbStorage dbStorage, orm.Criteria query) async {
    List<Map> data = await getAllFromDb(dbStorage, query);

    if(data.isEmpty) {
      throw new ItemNotFoundException("Item Not Found: ${query.toString()}");
    } else {
      return data.first;
    }
  }
  @protected
  Future<List<Map<String, dynamic>>> getAllFromDb(DbStorage dbStorage, orm.Criteria query) async {
    SelectorBuilder sb = _convertQuery(query);
    List<Map> data = await _getFromDb(dbStorage.name, sb);
    return data;
  }



  @override
  Future<Null> nukeDatabase() =>
      _connectionPool.databaseWrapper((MongoDatabase db) => db.nukeDatabase());

  dynamic validateInternalId(dynamic internalId) {
    if (internalId == null) {
      throw new ArgumentError.notNull("internalId");
    } else if (internalId is ObjectId) {
      return internalId;
    } else {
      try {
        return ObjectId.parse(internalId.toString());
      } catch (e) {
        throw new ArgumentError.value(
            internalId, "internalId", "Must be an ObjectID");
      }
    }
  }

  SelectorBuilder _convertQuery(orm.Criteria query) {
    SelectorBuilder output = where;
    for (orm.QueryEntry entry in query.sequence) {
      String field = entry.field;
      if(entry.field==internalIdField) {
        field = "_id";
      }
      switch (entry.action) {
        case orm.Actions.equals:
          output = output.eq(field, entry.value);
          break;
        default:
          throw new Exception(
              "Query action not supported: " + entry.action.toString());
      }
    }
    return output;
  }

  Future<List<Map<String, dynamic>>> _getFromDb(
      String collection, SelectorBuilder sb) async {
    return _connectionPool.databaseWrapper<List<Map>>((MongoDatabase db) async {
      DbCollection col = db.collection(collection);
      return await col.find(sb).toList();
    });
  }
}
