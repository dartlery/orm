import 'src/actor.dart';
import 'src/director.dart';
import 'src/movie.dart';
import 'package:test/test.dart';
import 'package:orm/orm.dart';

export 'src/actor.dart';
export 'src/director.dart';
export 'src/movie.dart';

DatabaseContext testContext;

void runTests() {
  test('add', () async {
    Director dir = new Director();
    dir.name = "unused director";

    dynamic result = await testContext.add(dir);
    expect(result, isNotNull);
  });

  test('add linked', () async {
    Movie movie = new Movie();
    movie.title = "movie with director";
    movie.year = 2012;
    movie.runtime = 120.50;
    movie.public = false;
    Director dir = new Director();
    dir.name = "linked director";
    movie.director = dir;

    dynamic result = await testContext.add(movie);
    expect(result, isNotNull);
  });

  test("existsByInternalID", () async {
    Director dir = new Director();
    dir.name = "queryable director";

    dynamic internalId = await testContext.add(dir);
    expect(internalId, isNotNull);

    bool result = await testContext.existsByInternalID(Director, internalId);
    expect(result, true);
  });

  test("getByInternalID", () async {
    Director dir = new Director();
    dir.name = "queryable director";

    dynamic result = await testContext.add(dir);
    expect(result, isNotNull);

    dir = await testContext.getByInternalID(Director, result);
    expect(dir, isNotNull);
    expect(dir.name, "queryable director");
    expect(dir.ormInternalId, result);
  });

  test("getByInternalID - nested object", () async {
    Movie movie = new Movie();
    movie.title = "movie with director";
    movie.year = 2012;
    movie.runtime = 120.50;
    movie.public = false;
    Director dir = new Director();
    dir.name = "linked director";
    movie.director = dir;

    dynamic internalId = await testContext.add(movie);
    expect(internalId, isNotNull);

    movie = await testContext.getByInternalID(Movie, internalId);

    expect(movie, isNotNull);
    expect(movie.title, "movie with director");
    expect(movie.ormInternalId, internalId);

    expect(movie.director, isNotNull);
    expect(movie.director.name, "linked director");

    dir = await testContext.getByInternalID(
        Director, movie.director.ormInternalId);

    expect(dir, isNotNull);
    expect(dir.name, "linked director");
    expect(dir.ormInternalId, movie.director.ormInternalId);
  });

  test("update", () async {
    Director dir = new Director();
    dir.name = "queryable director";

    dynamic result = await testContext.add(dir);
    expect(result, isNotNull);

    dir = await testContext.getByInternalID(Director, result);
    expect(dir, isNotNull);
    expect(dir.name, "queryable director");
    expect(dir.ormInternalId, result);

    dir.name = "updated name";

    await testContext.update(dir);

    dir = await testContext.getByInternalID(Director, result);
    expect(dir, isNotNull);
    expect(dir.name, "updated name");
    expect(dir.ormInternalId, result);
  });

  test("update - nested object", () async {
    Movie movie = new Movie();
    movie.title = "movie with director";
    movie.year = 2012;
    movie.runtime = 120.50;
    movie.public = false;
    Director dir = new Director();
    dir.name = "linked director";
    movie.director = dir;

    dynamic internalId = await testContext.add(movie);
    expect(internalId, isNotNull);

    movie = await testContext.getByInternalID(Movie, internalId);

    movie.title = "different title";
    movie.director.name = "different name";

    dir = new Director();
    dir.name = "new director";
    movie.director = dir;

    await testContext.update(movie);

    movie = await testContext.getByInternalID(Movie, internalId);

    expect(movie.title, "different title");
    expect(movie.director.name, "new director");
  });

  test("deleteByInternalID", () async {
    Director dir = new Director();
    dir.name = "queryable director";

    dynamic internalId = await testContext.add(dir);
    expect(internalId, isNotNull);

    bool result = await testContext.existsByInternalID(Director, internalId);
    expect(result, true);

    await testContext.deleteByInternalID(Director, internalId);

    result = await testContext.existsByInternalID(Director, internalId);
    expect(result, false);

    expect(testContext.getByInternalID(Director, internalId),
        throwsA(new isInstanceOf<ItemNotFoundException>()));
  });

  test("countByCriteria", () async {
    Director dir = new Director();
    dir.name = "queryable director";

    dynamic internalId = await testContext.add(dir);
    expect(internalId, isNotNull);

    int result = await testContext.countByCriteria(Director, where);
    expect(result, 1);

    dir = new Director();
    dir.name = "countable director";

    internalId = await testContext.add(dir);
    expect(internalId, isNotNull);

    result = await testContext.countByCriteria(Director, where);
    expect(result, 2);

    await testContext.deleteByInternalID(Director, internalId);

    result = await testContext.countByCriteria(Director, where);
    expect(result, 1);
  });

  test("getPaginatedByCriteria", () async {
    Director dir = new Director();
    dir.name = "queryable director";

    await testContext.add(dir);

    dir = new Director();
    dir.name = "countable director";

    await testContext.add(dir);

    PaginatedList<Director> result =
        await testContext.getPaginatedByCriteria(Director, where.limit(1));

    expect(result, isNotNull);
    expect(result.count, 1);
    expect(result.total, 2);
    expect(result.offset, 0);
    expect(result.items[0], isNotNull);
    expect(result.items[0].name, "queryable director");

    result = await testContext.getPaginatedByCriteria(
        Director, where.limit(1).skip(1));

    expect(result, isNotNull);
    expect(result.count, 1);
    expect(result.total, 2);
    expect(result.offset, 1);
    expect(result.items[0], isNotNull);
    expect(result.items[0].name, "countable director");
  });
}
