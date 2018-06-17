import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

class MongoDatabase extends mongo.Db {
  MongoDatabase(String uriString) : super(uriString);
  Future<Null> nukeDatabase() async {
    final mongo.DbCommand cmd = mongo.DbCommand.createDropDatabaseCommand(this);
    await this.executeDbCommand(cmd);
  }

//  Future<Null> startTransaction() async {
//    final mongo.DbCollection transactions = await getTransactionsCollection();
//    await transactions.findOne({"state": "initial"});
//  }

}
