import 'dart:async';

import 'package:meta/meta.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:orm/meta.dart';
import 'package:orm/internal.dart' as orm;

import 'package:orm_mongo/src/mongo_database.dart';
import 'package:orm_mongo/src/mongo_db_connection_pool.dart';

class MongoDatabaseContext extends orm.ADatabaseContext {
  final MongoDbConnectionPool _connectionPool;

  MongoDatabaseContext(String connectionString)
      : this._connectionPool = new MongoDbConnectionPool(connectionString);

  @override
  Future<Null> dropObjectStoreInternal(DbStorage dbs) => _connectionPool
      .databaseWrapper((MongoDatabase db) => db.dropCollection(dbs.name));

  @override
  Future<ObjectId> addInternal(DbStorage storage, Map<String, dynamic> data) =>
      _connectionPool.databaseWrapper((MongoDatabase db) async {
        DbCollection col = db.collection(storage.name);
        data["_id"] = generateInternalId();
        await col.insert(data);
        return data["_id"];
      });

  @override
  Future<Null> applyIndex(DbStorage dbs, DbIndex index) =>
      _connectionPool.databaseWrapper<bool>((MongoDatabase db) async {
        Map<String, int> keys = <String, int>{};
        for (String key in index.fields.keys) {
          if (index.fields[key]==orm.Direction.ascending) {
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

  @override
  Future<int> countInternal(DbStorage dbStorage, orm.Criteria criteria) {
    SelectorBuilder sb = _convertCriteria(criteria);
    return _countFromDb(dbStorage.name, sb);
  }

  @protected
  @override
  Future<Null> deleteFromDb(DbStorage dbStorage, orm.Criteria criteria) async {
    final SelectorBuilder sb = _convertCriteria(criteria);
    await _deleteFromDb(dbStorage.name, sb);
  }

  @protected
  @override
  Future<bool> exists(DbStorage dbs, orm.Criteria criteria) =>
      _connectionPool.databaseWrapper<bool>((MongoDatabase db) async {
        final SelectorBuilder sb = _convertCriteria(criteria);

        final DbCollection col = db.collection(dbs.name);
        return (await col.count(sb)) > 0;
      });

  @protected
  dynamic generateInternalId() => new ObjectId();

  @override
  Future<Map<String, dynamic>> getOneFromDb(
      DbStorage dbStorage, orm.Query query) async {
    final Map data = await _getOneFromDb(dbStorage.name, _convertQuery(query));

    if (data == null) {
      throw new orm.ItemNotFoundException(
          "Item Not Found: ${query.toString()}");
    } else {
      return data;
    }
  }

  @override
  Future<Null> nukeDatabase() =>
      _connectionPool.databaseWrapper((MongoDatabase db) => db.nukeDatabase());

  @protected
  @override
  Future<Stream<Map<String, dynamic>>> streamAllFromDb(
          DbStorage dbStorage, orm.Query query) =>
      _streamFromDb(dbStorage.name, _convertQuery(query));

  @override
  Future<Null> updateInternal(DbStorage storage, Map<String, dynamic> data, orm.Criteria criteria) =>
      _connectionPool.databaseWrapper((MongoDatabase db) async {
        if (!data.containsKey("_id")) {
          throw new Exception("_id must be set to update");
        }
        dynamic id = data["_id"];
        data.remove("_id");
        final DbCollection col = db.collection(storage.name);
        final SelectorBuilder where = _convertCriteria(criteria);
        await col.update(where, data);
      });

  @override
  ObjectId validateInternalId(dynamic internalId) {
    if (internalId == null) {
      throw new ArgumentError.notNull("internalId");
    } else if (internalId is ObjectId) {
      return internalId;
    } else {
      try {
        return ObjectId.parse(internalId.toString());
      } on Exception {
        throw new ArgumentError.value(
            internalId, "internalId", "Must be an ObjectID");
      }
    }
  }

  void _checkForErrors(Map data) {
    if (data?.containsKey("\$err") ?? false)
      throw new Exception("Database error: $data['\$err']");
  }

  SelectorBuilder _convertCriteria(orm.Criteria criteria) {
    SelectorBuilder output = where;
    for (orm.Criterion entry in criteria.sequence) {
      String field = entry.field;
      if (entry.field == internalIdField) {
        field = "_id";
      }
      switch (entry.action) {
        case orm.Actions.equals:
          output = output.eq(field, entry.value);
          break;
        default:
          throw new Exception(
              "Query action not supported: ${entry.action.toString()}");
      }
    }
    return output;

  }

  SelectorBuilder _convertQuery(orm.Query query) {
    final SelectorBuilder output = _convertCriteria(query);

    if(query.hasOrders) {
      for(orm.Order order in query.getOrder()) {
        output.sortBy(order.field,
            descending: order.direction == orm.Direction.descending);
      }
    }


      if (query.limit > 0) {
        output.limit(query.limit);
      }
      if (query.skip > 0) {
        output.skip(query.skip);
      }
    return output;
  }

  Future<int> _countFromDb(String collection, SelectorBuilder sb) =>
      _connectionPool.databaseWrapper<int>((MongoDatabase db) async {
        DbCollection col = db.collection(collection);
        return await col.count(sb);
      });

  Future<Null> _deleteFromDb(String collection, SelectorBuilder sb) =>
      _connectionPool.databaseWrapper<List<Map>>((MongoDatabase db) async {
        DbCollection col = db.collection(collection);
        Map data = await col.remove(sb);
        _checkForErrors(data);
        //return data;
      });

  Future<Map<String, dynamic>> _getOneFromDb(
          String collection, SelectorBuilder sb) =>
      _connectionPool.databaseWrapper<Map>((MongoDatabase db) async {
        DbCollection col = db.collection(collection);
        Map data = await col.findOne(sb);
        _checkForErrors(data);
        return data;
      });

  Future<Stream<Map<String, dynamic>>> _streamFromDb(
          String collection, SelectorBuilder sb) =>
      _connectionPool.databaseWrapper<Stream<Map>>((MongoDatabase db) async {
        DbCollection col = db.collection(collection);
        return col.find(sb).map((Map data) {
          _checkForErrors(data);
          return data;
        });
      });
}
