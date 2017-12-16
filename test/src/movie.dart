import 'director.dart';
import 'actor.dart';
import 'package:orm/meta.dart';
import 'package:orm/orm.dart';

@DbStorage("Movies")
class Movie extends OrmObject {
  @DbField()
  String title;
  @DbField()
  int year;
  @DbField()
  double runtime;
  @DbField()
  bool public;

  @DbField(ignore: true)
  String ignoredField;

  @DbField()
  Director director;

  //List<Actor> actors;

}