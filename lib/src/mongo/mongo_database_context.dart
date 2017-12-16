import 'dart:async';
import '../database_context.dart';
import 'package:orm/meta.dart';
import 'mongo_db_connection_pool.dart';
import 'mongo_database.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../orm_object.dart';
import 'package:meta/meta.dart';

class MongoDatabaseContext extends ADatabaseContext {
  final MongoDbConnectionPool _connectionPool;

  MongoDatabaseContext(String connectionString)
      : this._connectionPool = new MongoDbConnectionPool(connectionString);

  @override
  Future<Null> NukeDatabase() =>
      _connectionPool.databaseWrapper((MongoDatabase db) => db.nukeDatabase());

  @override
  Future<ObjectId> AddInternal(DbStorage storage, Map<String, dynamic> data) =>
      _connectionPool.databaseWrapper((MongoDatabase db) async {
        DbCollection col = db.collection(storage.name);
        data["_id"] = new ObjectId();
        await col.insert(data);
        return data["_id"];
      });

  @protected
  dynamic GenerateInternalId() => new ObjectId();

  @protected
  Future<bool> InternalExistsByInternalID(DbStorage dbs, dynamic internalId) =>
      _connectionPool.databaseWrapper<bool>((MongoDatabase db) async {
        DbCollection col = db.collection(dbs.name);
        return (await col.count(where.id(internalId))) > 0;
      });
}
