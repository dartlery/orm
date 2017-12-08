import 'dart:mirrors';

class DbStorage {
  final String name;
  const DbStorage(this.name);
}

final ClassMirror dbFieldMirror = reflectClass(DbField);

class DbField {
  final String name;
  final bool ignore;
  final bool primaryKey;
  final dynamic defaultValue;
  const DbField({this.name: "", this.ignore: false, this.defaultValue: null, this.primaryKey: false});
}

class DbIndex {
  final String name;
  final bool unique;
  final bool ascending;
  final bool sparse;
  final bool text;
  final int order;
  const DbIndex(this.name, {this.unique: false, this.ascending: true, this.sparse: false, this.order: 0, this.text: false});
}

class DbLink {
  const DbLink();
}