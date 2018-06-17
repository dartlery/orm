import 'dart:async';
import 'package:logging/logging.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:connection_pool/connection_pool.dart';
import 'package:orm_mongo/src/mongo_database.dart';
import 'package:orm/internal.dart';

class MongoDbConnectionPool extends ConnectionPool<MongoDatabase> {
  static final Logger _log = new Logger('_MongoDbConnectionPool');

  final String uri;

  MongoDbConnectionPool(this.uri, [int poolSize = 5]) : super(poolSize);

  @override
  void closeConnection(MongoDatabase db) {
    _log.info("Closing mongo connection");
    db.close();
  }

  @override
  Future<MongoDatabase> openNewConnection() async {
    _log.info("Opening mongo connection");
    final MongoDatabase conn = new MongoDatabase(uri);
    if (await conn.open())
      return conn;
    else
      throw new Exception("Could not open connection");
  }

  Future<T> databaseWrapper<T>(Future<T> statement(MongoDatabase db),
      {int retries= 5}) async {
    // The number of retries should be at least as much as the number of connections in the connection pool.
    // Otherwise it might run out of retries before invalidating every potentially disconnected connection in the pool.
    for (int i = 0; i <= retries; i++) {
      bool closeConnection = false;
      final ManagedConnection<MongoDatabase> conn = await _getConnection();

      try {
        return await statement(conn.conn);
      } on ConnectionException catch (e, st) {
        if (i >= retries) {
          _log.severe(
              "ConnectionException while operating on mongo database", e, st);
          rethrow;
        } else {
          _log.warning(
              "ConnectionException while operating on mongo database, retrying",
              e,
              st);
        }
        closeConnection = true;
      } catch (e, st) {
        _log.fine("Error while operating on mongo dataabase", e, st);
        if (e.toString().contains("duplicate key")) {
          throw new DuplicateItemException("Item already exists in database");
        }
        rethrow;
      } finally {
        this.releaseConnection(conn, markAsInvalid: closeConnection);
      }
    }
    throw new Exception("Reached unreachable code");
  }

  Future<ManagedConnection<MongoDatabase>> _getConnection() async {
    ManagedConnection<MongoDatabase> con = await this.getConnection();

    // Theoretically this should be able to catch closed connections, but it can't catch connections that were closed by the server without notifying the client, like when the server restarts.
    int i = 0;
    while (con?.conn == null || con.conn.state != State.OPEN) {
      if (i > 5) {
        throw new Exception(
            "Too many attempts to fetch a connection from the pool");
      }
      if (con != null) {
        _log.info(
            "Mongo database connection has issue, returning to pool and re-fetching");
        this.releaseConnection(con, markAsInvalid: true);
      }
      con = await this.getConnection();
      i++;
    }

    return con;
  }

  static Future<Null> testConnectionString(String connectionString) async {
    final MongoDbConnectionPool pool =
        new MongoDbConnectionPool(connectionString, 1);
    final ManagedConnection<MongoDatabase> con = await pool.getConnection();
    pool.releaseConnection(con);
    await pool.closeConnections();
  }
}
