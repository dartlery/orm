import 'dart:async';
import 'package:logging/logging.dart';
import 'package:connection_pool/connection_pool.dart';
import 'package:orm_postgres/src/postgres_database.dart';
import 'package:postgres/postgres.dart';
import 'package:orm/internal.dart';

class PostgresConnectionPool extends ConnectionPool<PostgresDatabase> {
  static final Logger _log = new Logger('PostgresConnectionPool');

  final String host;
  final int port;
  final String databaseName;
  final String username;
  final String password;
  final bool useSSL;
  final int timeoutInSeconds;
  final String timeZone;

  PostgresConnectionPool(this.host, this.port, this.databaseName,
      {this.username,
      this.password,
      this.timeoutInSeconds = 30,
      this.timeZone = "UTC",
      this.useSSL = false,
      int poolSize = 5})
      : super(poolSize);

  @override
  void closeConnection(PostgresDatabase db) {
    _log.info("Closing PostgreSQL connection");
    db.close();
  }

  @override
  Future<PostgresDatabase> openNewConnection() async {
    _log.info("Opening PostgreSQL connection");
    final PostgresDatabase conn = new PostgresDatabase(
        this.host, this.port, this.databaseName,
        username: this.username,
        password: this.password,
        timeoutInSeconds: this.timeoutInSeconds,
        timeZone: this.timeZone,
        useSSL: this.useSSL);
    await conn.open();
    return conn;
  }

  Future<T> databaseWrapper<T>(Future<T> statement(PostgresDatabase db),
      {int retries = 5}) async {
    // The number of retries should be at least as much as the number of connections in the connection pool.
    // Otherwise it might run out of retries before invalidating every potentially disconnected connection in the pool.
    for (int i = 1; i <= retries; i++) {
      bool closeConnection = false;
      ManagedConnection<PostgresDatabase> conn;
      try {
        conn = await _getConnection();
        return await statement(conn.conn);
      } on PostgreSQLException catch (e, st) {
        if (i >= retries) {
          _log.severe(
              "PostgreSQLException while operating on PostgreSQL database",
              e,
              st);
          rethrow;
        } else {
          _log.warning(
              "PostgreSQLException while operating on PostgreSQL database, retrying",
              e,
              st);
        }
        closeConnection = true;
      } catch (e, st) {
        _log.fine("Error while operating on PostgreSQL dataabase", e, st);
        // TODO: Update this properly for PostgreSQL
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

  Future<ManagedConnection<PostgresDatabase>> _getConnection() async {
    ManagedConnection<PostgresDatabase> con = await this.getConnection();

    // Theoretically this should be able to catch closed connections, but it can't catch connections that were closed by the server without notifying the client, like when the server restarts.
    int i = 0;
    while (con?.conn == null || con.conn.isClosed) {
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

  static Future<Null> testConnectionString(
      String host, int port, String databaseName,
      {String username,
      String password,
      int timeoutInSeconds = 30,
      String timeZone = "UTC",
      bool useSSL = false}) async {
    final PostgresConnectionPool pool = new PostgresConnectionPool(
        host, port, databaseName,
        username: username,
        password: password,
        timeoutInSeconds: timeoutInSeconds,
        timeZone: timeZone,
        useSSL: useSSL,
        poolSize: 1);
    final ManagedConnection<PostgresDatabase> con = await pool.getConnection();
    pool.releaseConnection(con);
    await pool.closeConnections();
  }
}
