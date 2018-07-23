/// Support for doing something awesome.
///
/// More dartdocs go here.
library orm;

export 'meta.dart';
export 'src/criteria.dart';
export 'src/database_context.dart';
export 'src/enums.dart' show Direction;
export 'src/exceptions/duplicate_item_exception.dart';
export 'src/exceptions/item_not_found_exception.dart';
export 'src/orm_object.dart';
export 'src/uuid.dart';
export 'src/paginated_list.dart';

List<String> specialCharacters = <String>["AND","OR",];
// TODO: Export any libraries intended for clients of this package.
