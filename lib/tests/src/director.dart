import 'package:orm/meta.dart';
import 'package:orm/orm.dart';

@DbStorage("Directors")
@DbIndex("DirectorNameIndex", const {"name": true}, unique: true)
class Director extends OrmObject {
  @DbField()
  String name;
}
