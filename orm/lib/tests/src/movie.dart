import 'package:orm/meta.dart';
import 'package:orm/orm.dart';

import 'director.dart';

@DbStorage("Movies")
@DbIndex("MovieTitleIndex", const {"title": Direction.ascending}, unique: true)
@DbIndex("MovieYearIndex", const {"year": Direction.ascending}, sparse: true)
@DbIndex("MovieDirectorIndex", const {"director": Direction.ascending})
class Movie extends OrmObject {
  @DbField()
  String title;
  @DbField()
  int year;
  @DbField()
  double runtime;
  @DbField()
  bool public;

  String ignoredField;

  @DbField()
  Director director;

  //List<Actor> actors;

}
