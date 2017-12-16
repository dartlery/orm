import 'director.dart';
import 'actor.dart';
import 'package:orm/meta.dart';
import 'package:orm/orm.dart';


@DbStorage("Directors")
class Director extends OrmObject {
  @DbField(primaryKey: true)
  String name;
}