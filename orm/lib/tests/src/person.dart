import 'package:orm/orm.dart';

class Person extends OrmObject {
  @DbField()
  String name;

}