import 'package:orm_postgres/orm_postgres.dart';
import 'package:test/test.dart';
import 'package:orm/tests/tests.dart';

void main() {
  group('PostgreSql tests', () {
    setUp(() async {
      testContext = new PostgresDatabaseContext("127.0.0.1", 5432, "orm_test",
          username: "orm_test", password: "password");
      // Doesn't work so well with postgres
      //await testContext.nukeDatabase();
      await testContext.dropObjectStore(Movie);
      await testContext.dropObjectStore(Director);
    });
    runTests();
  });
}
