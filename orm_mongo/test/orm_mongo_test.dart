import 'package:orm_mongo/orm_mongo.dart';
import 'package:test/test.dart';
import 'package:orm/tests/tests.dart';

void main() {
  group('Mongo tests', () {
    setUp(() async {
      String connectionString = "mongodb://10.0.0.5:27017/test_database";
      testContext = new MongoDatabaseContext(connectionString);
      await testContext.nukeDatabase();
    });
    runTests();
  });
}
