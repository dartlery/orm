import 'dart:mirrors';

import 'orm.dart';

export 'orm.dart';
export 'src/a_database_context.dart';
export 'src/uuid.dart';

final TypeMirror ormObjectTypeMirror = reflectType(OrmObject);
