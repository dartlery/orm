import 'package:orm/meta.dart';
import 'package:orm/orm.dart';
import 'person.dart';

@DbStorage("Directors")
@DbIndex("DirectorNameIndex", const {"name": Direction.ascending}, unique: true)
class Director extends Person  {
  @DbField()
  int movieCount;

}
