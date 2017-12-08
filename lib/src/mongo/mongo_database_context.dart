import 'dart:async';
import '../database_context.dart';
import '../../meta.dart';
import 'mongo_db_connection_pool.dart';
import 'mongo_database.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoDatabaseContext extends ADatabaseContext {
  final MongoDbConnectionPool _connectionPool;

  MongoDatabaseContext(String connectionString)
      : this._connectionPool = new MongoDbConnectionPool(connectionString);

  @override
  Future<ObjectId> AddInternal(DbStorage storage, dynamic data) =>
      _connectionPool.databaseWrapper((MongoDatabase db) async {
        DbCollection col = db.collection(storage.name);

        Map<String,dynamic> preparedData = _prepareForDatabase(data);
        Map result = await col.insert(preparedData);
        return result["_id"];
      });

  Map<String, dynamic> _prepareForDatabase(dynamic object,
      [Map<String, dynamic> data = null]) {
    if(data==null){
      data = <String,dynamic>{};
    }
    this.IterateDbFields(object,
        (DbField dbField, String name, dynamic value) {
      data[name] = value;
    });
    if(data.isEmpty)
      throw new Exception("No database fields found in object");
    return data;
  }
}
