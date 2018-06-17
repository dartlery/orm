import 'dart:async';
import 'package:postgres/postgres.dart';

class PostgresDatabase extends PostgreSQLConnection {
  PostgresDatabase(String host, int port, String databaseName,
      {String username,
      String password,
      int timeoutInSeconds = 30,
      String timeZone = "UTC",
      bool useSSL= false})
      : super(host, port, databaseName,
            username: username,
            password: password,
            timeoutInSeconds: timeoutInSeconds,
            timeZone: timeZone,
            useSSL: useSSL);

  Future<Null> nukeDatabase() async {
    await this.execute("DROP DATABASE IF EXISTS \"$databaseName\"");
  }

  Future<Null> dropTable(String tableName) async {
    await this.execute("DROP TABLE IF EXISTS \"$tableName\"");
  }

//  Future<Null> startTransaction() async {
//    final mongo.DbCollection transactions = await getTransactionsCollection();
//    await transactions.findOne({"state": "initial"});
//  }

}
