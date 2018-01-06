import 'package:orm/orm.dart';
import 'package:test/test.dart';
import 'src/movie.dart';
import 'src/director.dart';
import 'src/actor.dart';
import 'dart:async';

void main() {
  group('Database tests', () {
    ADatabaseContext context;
    //final String serverUuid = generateUuid();
    String connectionString =
        "mongodb://10.0.0.5:27017/test_database";

    setUp(() async {
      context = new MongoDatabaseContext(connectionString);
      await context.nukeDatabase();
    });

    test('Add', () async {
      Director dir = new Director();
      dir.name = "unused director";

      dynamic result = await context.add(dir);
      expect(result, isNotNull);
    });


    test('Add linked', () async {
      Movie movie  = new Movie();
      movie.title = "movie with director";
      movie.year = 2012;
      movie.runtime =120.50;
      movie.public = false;
      Director dir = new Director();
      dir.name = "linked director";
      movie.director = dir;

      dynamic result = await context.add(movie);
      expect(result, isNotNull);
    });

    test("ExistsByInternalID", () async {
      Director dir = new Director();
      dir.name = "queryable director";

      dynamic internalId = await context.add(dir);
      expect(internalId, isNotNull);


      bool result = await context.existsByInternalID(Director,internalId);
      expect(result, true);
    });

    test("GetByInternalID", () async {
      Director dir = new Director();
      dir.name = "queryable director";

      dynamic result = await context.add(dir);
      expect(result, isNotNull);

      
      dir = await context.getByInternalID(Director,result);
      expect(dir, isNotNull);
      expect(dir.name, "queryable director");
      expect(dir.ormInternalId, result);
    });

    test("GetByInternalID - nested object", () async {
      Movie movie  = new Movie();
      movie.title = "movie with director";
      movie.year = 2012;
      movie.runtime =120.50;
      movie.public = false;
      Director dir = new Director();
      dir.name = "linked director";
      movie.director = dir;

      dynamic internalId = await context.add(movie);
      expect(internalId, isNotNull);

      movie= await context.getByInternalID(Movie, internalId);

      expect(movie, isNotNull);
      expect(movie.title, "movie with director");
      expect(movie.ormInternalId, internalId);

      expect(movie.director, isNotNull);
      expect(movie.director.name, "linked director");

      dir = await context.getByInternalID(Director, movie.director.ormInternalId);

      expect(dir, isNotNull);
      expect(dir.name, "linked director");
      expect(dir.ormInternalId, movie.director.ormInternalId);

    });

  });
}

Future<dynamic> createObjects() async {

}