import 'package:orm/orm.dart';
import 'package:test/test.dart';
import 'src/movie.dart';
import 'src/director.dart';
import 'src/actor.dart';
import 'package:orm/orm.dart';

void main() {
  group('Database tests', () {
    ADatabaseContext context;
    //final String serverUuid = generateUuid();
    String connectionString =
        "mongodb://10.0.0.5:27017/test_database";

    setUp(() async {
      context = new MongoDatabaseContext(connectionString);
      await context.NukeDatabase();
    });

    test('First Test', () async {
      Movie movie  = new Movie();
      movie.title = "test title";
      movie.year = 2012;
      movie.runtime =120.50;
      movie.public = false;
      Director dir = new Director();
      dir.name = "test director";
      movie.director = dir;

      dynamic result = await context.Add(movie);
      expect(result, isNotNull);


    });
  });
}
