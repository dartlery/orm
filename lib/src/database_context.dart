import 'dart:async';
import 'dart:mirrors';

import 'package:meta/meta.dart';

import '../meta.dart';
import 'orm_object.dart';
import 'query.dart';

abstract class ADatabaseContext {
  static final ClassMirror _dbFieldType = reflectClass(DbField);

  static final ClassMirror _ormObjectType = reflectClass(OrmObject);
  static final VariableMirror _ormInternalIdField =
      _ormObjectType.declarations.values.firstWhere((DeclarationMirror dm) =>
          dm is VariableMirror &&
          MirrorSystem.getName(dm.simpleName) == "ormInternalId");

  ADatabaseContext() {}

  Future<dynamic> Add(OrmObject data) async {
    DbStorage dbs = await _PrepareTableForObject(data);

    Map<String, dynamic> dataMap = await _prepareDataMap(data);

    data.ormInternalId = await AddInternal(dbs, dataMap);
    return data.ormInternalId;
  }

  @protected
  Future<dynamic> AddInternal(DbStorage storage, Map<String, dynamic> data);

  final List<String> _preparedTables = <String>[];

  Future<DbStorage> _PrepareTableForObject(OrmObject data) async {
    DbStorage dbs = GetStorageMetadataForObject(data);

    if(!_preparedTables.contains(dbs.name)) {
      // Table preparation stuff
      asdas
    }

    return dbs;
  }

  Future<bool> ExistsByInternalID<T>(dynamic internalId) {
    DbStorage dbs = GetStorageMetadataForType(T);
    return InternalExistsByInternalID(dbs, internalId);
  }

  T GetByKey<T>(dynamic primaryKey) {}

  T GetByQuery<T>(Query query) {}

  DbStorage GetStorageMetadataForClassMirrorType(ClassMirror cm) {
    return cm.metadata
            .firstWhere(
                (InstanceMirror im) => im.type == reflectClass(DbStorage),
                orElse: () => null)
            ?.reflectee ??
        new DbStorage(MirrorSystem.getName(cm.simpleName));
  }

  DbStorage GetStorageMetadataForObject(OrmObject object) =>
      GetStorageMetadataForClassMirrorType(reflect(object).type);

  DbStorage GetStorageMetadataForType(Type type) =>
      GetStorageMetadataForClassMirrorType(reflectClass(type));

  @protected
  Future<bool> InternalExistsByInternalID(DbStorage dbs, dynamic internalId);
  Future<Null> NukeDatabase();

  Future<Map<String, dynamic>> _prepareDataMap(OrmObject object,
      [Map<String, dynamic> data = null]) async {
    if (data == null) {
      data = <String, dynamic>{};
    }
    data["_id"] = object.ormInternalId;

    await ADatabaseContext.IterateDbFields(object,
        (DbField dbField, String name, dynamic value) async {
      data[name] = await _prepareDataMapInternal(value);
    });
    if (data.isEmpty) throw new Exception("No database fields found in object");
    return data;
  }

  Future<dynamic> _prepareDataMapInternal(dynamic value) async {
    if (value is OrmObject) {
      if ((value.ormInternalId?.toString() ?? "").length == 0) {
        await this.Add(value);
      }
      return value.ormInternalId;
    } else if (value is List) {
      List output = [];
      for (dynamic subValue in value) {
        output.add(await _prepareDataMapInternal(subValue));
      }
      return output;
    } else if (value is Map) {
      Map output = {};
      for (dynamic key in value.keys) {
        output[key] = await _prepareDataMapInternal(value[key]);
      }
      return output;
    } else {
      return value;
    }
  }

  @protected
  static Future<Null> IterateDbFields(OrmObject object,
      Future statement(DbField dbField, String name, dynamic value)) async {
    final InstanceMirror im = reflect(object);
    final ClassMirror cm = im.type;

    for (DeclarationMirror dm in cm.declarations.values.where(
        (DeclarationMirror dm) => !dm.isPrivate && (dm is VariableMirror))) {
      final DbField metadata = dm.metadata
          .firstWhere((InstanceMirror im) => im.type == _dbFieldType,
              orElse: () => null)
          ?.reflectee;

      if (metadata?.ignore ?? false) continue;

      String name = MirrorSystem.getName(dm.simpleName);
      if ((metadata?.name ?? "").isNotEmpty) name = metadata.name;

      await statement(metadata, name, im.getField(dm.simpleName).reflectee);
    }
  }
}
