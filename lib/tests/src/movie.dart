import 'director.dart';
import 'actor.dart';
import 'package:orm/meta.dart';
import 'package:orm/orm.dart';

@DbStorage("Movies")
@DbIndex("MovieTitleIndex", const {"title": true}, unique: true)
@DbIndex("MovieYearIndex", const {"year": true}, sparse: true)
@DbIndex("MovieDirectorIndex", const {"director": true})
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
