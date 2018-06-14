import 'dart:async';
import 'dart:mirrors';

import 'package:meta/meta.dart';

import '../meta.dart';
import 'criteria.dart';
import 'database_context.dart';
import 'orm_object.dart';
import 'paginated_list.dart';

abstract class ADatabaseContext implements DatabaseContext {
  static final ClassMirror _dbFieldType = reflectClass(DbField);

  static final ClassMirror _ormObjectType = reflectClass(OrmObject);
  static final VariableMirror _ormInternalIdField =
      _ormObjectType.declarations.values.firstWhere((DeclarationMirror dm) =>
          dm is VariableMirror &&
          MirrorSystem.getName(dm.simpleName) == "ormInternalId");

  static const int defaultPageLimit = 30;

  final List<String> _preparedTables = <String>[];

  String internalIdField = "_id";

  ADatabaseContext() {}

  /// Adds an object to the database. Returns the internal ID of the object.
  Future<dynamic> add(OrmObject data) async {
    DbStorage dbs = await _prepareTableForObject(data);

    Map<String, dynamic> dataMap = await _prepareDataMap(data);

    data.ormInternalId = await addInternal(dbs, dataMap);
    return data.ormInternalId;
  }

  @protected
  Future<dynamic> addInternal(DbStorage storage, Map<String, dynamic> data);

  @override
  Future<Null> dropObjectStore(Type objectType) async {
    DbStorage dbStorage = getStorageMetadataForType(objectType);
    await dropObjectStoreInternal(dbStorage);
  }
  @protected
  Future<Null> dropObjectStoreInternal(DbStorage dbs);

  Future<Null> applyIndex(DbStorage dbs, DbIndex index);

  Future<int> countByCriteria<T extends OrmObject>(Type type, Criteria criteria,
          {bool ignoreSkipAndLimit: false}) =>
      countInternal(
          getStorageMetadataForType(type), criteria, ignoreSkipAndLimit);

  Future<int> countInternal(
      DbStorage dbStorage, Criteria criteria, bool ignoreSkipAndLimit);

  Criteria createInternalIdQuery(dynamic internalId) =>
      where.equals(internalIdField, validateInternalId(internalId));

  Future<Null> deleteByCriteria(Type type, Criteria criteria) {
    DbStorage dbs = getStorageMetadataForType(type);
    return deleteFromDb(dbs, criteria);
  }

  Future<Null> deleteByInternalID(Type type, dynamic internalId) {
    return deleteByCriteria(type, createInternalIdQuery(internalId));
  }

  @protected
  Future<Null> deleteFromDb(DbStorage dbStorage, Criteria criteria);

  Future<bool> exists(DbStorage dbs, Criteria query);

  Future<bool> existsByCriteria(Type type, Criteria criteria) {
    DbStorage dbs = getStorageMetadataForType(type);
    return exists(dbs, criteria);
  }

  Future<bool> existsByInternalID(Type type, dynamic internalId) {
    return existsByCriteria(type, createInternalIdQuery(internalId));
  }

  Future<List<T>> getAllByCriteria<T extends OrmObject>(
          Type type, Criteria criteria) async =>
      (await streamAllByCriteria<T>(type, criteria)).toList();

  Future<T> getByInternalID<T extends OrmObject>(
      Type type, dynamic internalId) {
    return getOneByCriteria<T>(type, createInternalIdQuery(internalId));
  }

  Future<T> getOneByCriteria<T extends OrmObject>(
      Type type, Criteria criteria) async {
    DbStorage dbs = getStorageMetadataForType(type);
    Map<String, dynamic> data = await getOneFromDb(dbs, criteria);
    return await _convertDataMapToObject(type, data);
  }

  @protected
  Future<Map<String, dynamic>> getOneFromDb(
      DbStorage dbStorage, Criteria criteria);
  Future<PaginatedList<T>> getPaginatedByCriteria<T extends OrmObject>(
      Type type, Criteria criteria) async {
    int count =
        await countByCriteria<T>(type, criteria, ignoreSkipAndLimit: true);
    List<T> data = await getAllByCriteria<T>(type, criteria);
    return new PaginatedList<T>(data, criteria.getSkip(), count);
  }

  DbStorage getStorageMetadataForClassMirrorType(ClassMirror cm) {
    return cm.metadata
            .firstWhere((InstanceMirror im) => im.type == dbStorageMirror,
                orElse: () => null)
            ?.reflectee ??
        new DbStorage(MirrorSystem.getName(cm.simpleName));
  }

  DbStorage getStorageMetadataForObject(OrmObject object) =>
      getStorageMetadataForClassMirrorType(reflect(object).type);

  DbStorage getStorageMetadataForType(Type type) =>
      getStorageMetadataForClassMirrorType(reflectClass(type));

  Future<Stream<T>> streamAllByCriteria<T extends OrmObject>(
      Type type, Criteria criteria) async {
    DbStorage dbs = getStorageMetadataForType(type);

    final Stream<Map<String, dynamic>> str =
        await streamAllFromDb(dbs, criteria);

    return str.asyncMap<T>((Map<String, dynamic> data) async {
      return await _convertDataMapToObject(type, data);
    });
  }

  @protected
  Future<Stream<Map<String, dynamic>>> streamAllFromDb(
      DbStorage dbStorage, Criteria criteria);

  Future<Null> update(OrmObject data) async {
    validateInternalId(data.ormInternalId);

    DbStorage dbs = await _prepareTableForObject(data);

    Map<String, dynamic> dataMap = await _prepareDataMap(data);

    await updateInternal(dbs, dataMap);
  }

  @protected
  Future<Null> updateInternal(DbStorage storage, Map<String, dynamic> data);

  dynamic validateInternalId(dynamic internalId);

  Future<OrmObject> _convertDataMapToObject(
      Type type, Map<String, dynamic> data) async {
    ClassMirror cm = reflectClass(type);
    InstanceMirror im = cm.newInstance(const Symbol(''), []);

    OrmObject output = im.reflectee;

    if (data.containsKey(internalIdField)) {
      output.ormInternalId = data[internalIdField];
    }

    await iterateDbFields(cm,
        (VariableMirror vm, DbField dbField, String name) async {
      im.setField(
          vm.simpleName, await _convertDataMapValue(vm.type, data[name]));
    });

    return output;
  }

  Future<dynamic> _convertDataMapValue(
      TypeMirror expectedType, dynamic value) async {
    ClassMirror cm = reflectClass(expectedType.reflectedType);
    List<TypeMirror> typeArgs = cm.typeArguments;

    if (cm.isSubtypeOf(reflectClass(OrmObject))) {
      if ((value.toString() ?? "").length > 0) {
        dynamic linkedObject =
            await this.getByInternalID(expectedType.reflectedType, value);
        return linkedObject;
      }
      return value;
    } else if (cm.isSubtypeOf(reflectClass(List))) {
      TypeMirror listType = typeArgs.first;

      List output = [];

      for (dynamic subValue in value) {
        output.add(await _convertDataMapValue(listType, subValue));
      }
      return output;
    } else if (cm.isSubtypeOf(reflectClass(Map))) {
      //TypeMirror keyType = typeArgs.first;
      TypeMirror valueType = typeArgs[1];

      Map output = {};
      for (dynamic key in value.keys) {
        output[key] = await _convertDataMapValue(valueType, value[key]);
      }
      return output;
    } else {
      return value;
    }
  }

  Future<Map<String, dynamic>> _prepareDataMap(OrmObject object,
      [Map<String, dynamic> data = null]) async {
    if (data == null) {
      data = <String, dynamic>{};
    }
    data["_id"] = object.ormInternalId;

    await ADatabaseContext.iterateDbFieldValues(object,
        (DbField dbField, String name, dynamic value) async {
      data[name] = await _prepareDataMapInternal(value);
    });
    if (data.isEmpty) throw new Exception("No database fields found in object");
    return data;
  }

  Future<dynamic> _prepareDataMapInternal(dynamic value) async {
    if (value is OrmObject) {
      if ((value.ormInternalId?.toString() ?? "").length == 0) {
        await this.add(value);
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

  Future<DbStorage> _prepareTableForObject(OrmObject data) async {
    DbStorage dbs = getStorageMetadataForObject(data);


    await createDataStore(dbs, reflectClass(data.runtimeType));

    if (!_preparedTables.contains(dbs.name)) {
      // Table preparation stuff
      final ClassMirror cm = reflect(data).type;
      for (InstanceMirror im in cm.metadata
          .where((InstanceMirror im) => im.type == dbIndexMirror)) {
        await applyIndex(dbs, im.reflectee as DbIndex);
      }
    }

    return dbs;
  }

  @protected
  Future<Null> createDataStore(DbStorage storage, ClassMirror cm) async {

  }

  static Future<Null> iterateDbFields(ClassMirror cm,
      Future statement(VariableMirror vm, DbField dbField, String name)) async {
    for (DeclarationMirror dm in cm.declarations.values.where(
        (DeclarationMirror dm) => !dm.isPrivate && (dm is VariableMirror))) {
      final DbField metadata = dm.metadata
          .firstWhere((InstanceMirror im) => im.type == _dbFieldType,
              orElse: () => null)
          ?.reflectee;

      String name = MirrorSystem.getName(dm.simpleName);
      if ((metadata?.name ?? "").isNotEmpty) name = metadata.name;

      await statement(dm, metadata, name);
    }
  }

  @protected
  static Future<Null> iterateDbFieldValues(OrmObject object,
      Future statement(DbField dbField, String name, dynamic value)) async {
    final InstanceMirror im = reflect(object);
    final ClassMirror cm = im.type;

    await iterateDbFields(
        cm,
        (DeclarationMirror dm, DbField dbField, String name) =>
            statement(dbField, name, im.getField(dm.simpleName).reflectee));
  }
}
