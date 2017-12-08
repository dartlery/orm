import 'package:orm/orm.dart';
import 'package:test/test.dart';
import 'src/movie.dart';
import 'package:orm/orm.dart';

void main() {
  group('Database tests', () {
    ADatabaseContext context;
    //final String serverUuid = generateUuid();
    String connectionString =
        "mongodb://10.0.0.5:27017/test_database";

    setUp(() {
      context = new MongoDatabaseContext(connectionString);
    });

    test('First Test', () async {
      Movie movie  = new Movie();
      movie.title = "test title";
      await context.Add(movie);
    });
  });
}
