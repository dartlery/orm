import 'dart:mirrors';

class DbStorage {
  final String name;
  const DbStorage(this.name);
}

final ClassMirror dbFieldMirror = reflectClass(DbField);
final ClassMirror dbStorageMirror = reflectClass(DbStorage);
final ClassMirror dbIndexMirror = reflectClass(DbIndex);

class DbField {
  final String name;
  final dynamic defaultValue;

  const DbField({this.name= "", this.defaultValue});
}

class DbIndex {
  final String name;
  final bool unique;
  final bool sparse;
  final bool text;
  final Map<String, bool> fields;
  const DbIndex(this.name, this.fields,
      {this.unique= false, this.sparse= false, this.text= false});
}

class DbLink {
  const DbLink();
}
