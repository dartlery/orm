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

  ADatabaseContext();

  /// Adds an object to the database. Returns the internal ID of the object.
  @override
  Future<dynamic> add(OrmObject data) async {
    final DbStorage dbs = await _prepareTableForObject(data);

    final Map<String, dynamic> dataMap = await prepareDataMap(data);

    return data.ormInternalId = await addInternal(dbs, dataMap);
  }

  @protected
  Future<dynamic> addInternal(DbStorage storage, Map<String, dynamic> data);

  @override
  Future<Null> dropObjectStore(Type objectType) async {
    final DbStorage dbStorage = getStorageMetadataForType(objectType);
    await dropObjectStoreInternal(dbStorage);
  }
  @protected
  Future<Null> dropObjectStoreInternal(DbStorage dbs);

  Future<Null> applyIndex(DbStorage dbs, DbIndex index);

  @override
  Future<int> countByCriteria<T extends OrmObject>(Type type, Criteria criteria,
          {bool ignoreSkipAndLimit= false}) =>
      countInternal(
          getStorageMetadataForType(type), criteria);

  Future<int> countInternal(
      DbStorage dbStorage, Criteria criteria);

  Criteria createInternalIdCriteria(dynamic internalId) =>
      where..equals(internalIdField, validateInternalId(internalId));

  Query createInternalIdQuery(dynamic internalId) =>
      find..equals(internalIdField, validateInternalId(internalId))..limit=1;

  @override
  Future<Null> deleteByCriteria(Type type, Criteria criteria) {
    final DbStorage dbs = getStorageMetadataForType(type);
    return deleteFromDb(dbs, criteria);
  }

  @override
  Future<Null> deleteByInternalID(Type type, dynamic internalId) => deleteByCriteria(type, createInternalIdCriteria(internalId));

  @protected
  Future<Null> deleteFromDb(DbStorage dbStorage, Criteria criteria);

  Future<bool> exists(DbStorage dbs, Criteria criteria);

  @override
  Future<bool> existsByCriteria(Type type, Criteria criteria) {
    final DbStorage dbs = getStorageMetadataForType(type);
    return exists(dbs, criteria);
  }

  @override
  Future<bool> existsByInternalID(Type type, dynamic internalId) => existsByCriteria(type, createInternalIdCriteria(internalId));

  @override
  Future<List<T>> getAllByQuery<T extends OrmObject>(
          Type type, Query query) async =>
      (await streamAllByQuery<T>(type, query)).toList();

  @override
  Future<T> getByInternalID<T extends OrmObject>(
      Type type, dynamic internalId) => getOneByQuery<T>(type,  createInternalIdQuery(internalId));

  @override
  Future<T> getOneByQuery<T extends OrmObject>(
      Type type, Query query) async {
    final DbStorage dbs = getStorageMetadataForType(type);
    final Map<String, dynamic> data = await getOneFromDb(dbs, query);
    return await _convertDataMapToObject(type, data);
  }

  @protected
  Future<Map<String, dynamic>> getOneFromDb(
      DbStorage dbStorage, Query query);

  @override
  Future<PaginatedList<T>> getPaginatedByQuery<T extends OrmObject>(
      Type type, Query query) async {
    final int count =
        await countByCriteria<T>(type, query, ignoreSkipAndLimit: true);
    final List<T> data = await getAllByQuery<T>(type, query);
    return new PaginatedList<T>(data, query.limit, count);
  }

  DbStorage getStorageMetadataForClassMirrorType(ClassMirror cm) =>
    cm.metadata
            .firstWhere((InstanceMirror im) => im.type == dbStorageMirror,
                orElse: () => null)
            ?.reflectee ??
        new DbStorage(MirrorSystem.getName(cm.simpleName));

  DbStorage getStorageMetadataForObject(OrmObject object) =>
      getStorageMetadataForClassMirrorType(reflect(object).type);

  DbStorage getStorageMetadataForType(Type type) =>
      getStorageMetadataForClassMirrorType(reflectClass(type));

  @override
  Future<Stream<T>> streamAllByQuery<T extends OrmObject>(
      Type type, Query query) async {
    final DbStorage dbs = getStorageMetadataForType(type);

    final Stream<Map<String, dynamic>> str =
        await streamAllFromDb(dbs, query);

    return str.asyncMap<T>((Map<String, dynamic> data) async => await _convertDataMapToObject(type, data));
  }

  @protected
  Future<Stream<Map<String, dynamic>>> streamAllFromDb(
      DbStorage dbStorage, Query query);

  @override
  Future<Null> update(OrmObject data) async {
    validateInternalId(data.ormInternalId);

    final DbStorage dbs = await _prepareTableForObject(data);

    final Map<String, dynamic> dataMap = await prepareDataMap(data);

    await updateInternal(dbs, dataMap, createInternalIdCriteria(data.ormInternalId));
  }

  @protected
  Future<Null> updateInternal(DbStorage storage, Map<String, dynamic> data, Criteria criteria);

  dynamic validateInternalId(dynamic internalId);

  Future<OrmObject> _convertDataMapToObject(
      Type type, Map<String, dynamic> data) async {
    final ClassMirror cm = reflectClass(type);
    final InstanceMirror im = cm.newInstance(const Symbol(''), <dynamic>[]);

    final OrmObject output = im.reflectee;

    if (data.containsKey(internalIdField)) {
      output.ormInternalId = validateInternalId(data[internalIdField]);
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
    final ClassMirror cm = reflectClass(expectedType.reflectedType);
    final List<TypeMirror> typeArgs = cm.typeArguments;

    if (cm.isSubtypeOf(reflectClass(OrmObject))) {
      if (value?.toString()?.isNotEmpty??false) {
        final dynamic linkedObject =
            await this.getByInternalID(expectedType.reflectedType, value);
        return linkedObject;
      }
      return value;
    } else if (cm.isSubtypeOf(reflectClass(List))) {
      final TypeMirror listType = typeArgs.first;

      final List<dynamic> output = <dynamic>[];

      for (dynamic subValue in value) {
        output.add(await _convertDataMapValue(listType, subValue));
      }
      return output;
    } else if (cm.isSubtypeOf(reflectClass(Map))) {
      //TypeMirror keyType = typeArgs.first;
      final TypeMirror valueType = typeArgs[1];

      final Map<dynamic, dynamic> output = <dynamic,dynamic>{};
      for (dynamic key in value.keys) {
        output[key] = await _convertDataMapValue(valueType, value[key]);
      }
      return output;
    } else {
      return value;
    }
  }

  Future<Map<String, dynamic>> prepareDataMap(OrmObject object,
      [Map<String, dynamic> existingMap]) async {
      final Map<String, dynamic> output = existingMap ?? <String, dynamic>{};

      output["_id"] = object.ormInternalId;

    await ADatabaseContext.iterateDbFieldValues(object,
        (DbField dbField, String name, dynamic value) async {
          output[name] = await prepareDataMapValue(value);
    });
    if (output.isEmpty)
      throw new Exception("No database fields found in object");
    return output;
  }

  Future<dynamic> prepareDataMapValue(dynamic value) async {
    if (value is OrmObject) {
      if ((value.ormInternalId?.toString() ?? "").isEmpty) {
        await this.add(value);
      }
      return value.ormInternalId;
    } else if (value is List) {
      final List<dynamic> output = <dynamic>[];
      for (dynamic subValue in value) {
        output.add(await prepareDataMapValue(subValue));
      }
      return output;
    } else if (value is Map) {
      final Map<dynamic,dynamic> output = <dynamic,dynamic>{};
      for (dynamic key in value.keys) {
        output[key] = await prepareDataMapValue(value[key]);
      }
      return output;
    } else {
      return value;
    }
  }

  Future<DbStorage> _prepareTableForObject(OrmObject data) async {
    final DbStorage dbs = getStorageMetadataForObject(data);


    await createDataStore(dbs, reflectClass(data.runtimeType));

    if (!_preparedTables.contains(dbs.name)) {
      // Table preparation stuff
      final ClassMirror cm = reflect(data).type;
      for (InstanceMirror im in cm.metadata) {
        if(im.reflectee is DbIndex) {
          await applyIndex(dbs, im.reflectee);
        }
      }
    }

    return dbs;
  }

  @protected
  Future<Null> createDataStore(DbStorage storage, ClassMirror cm) async {

  }

  static Future<Null> iterateDbFields(ClassMirror cm,
      Future<Null> statement(VariableMirror vm, DbField dbField, String name)) async {
    for (DeclarationMirror dm in cm.declarations.values.where(
        (DeclarationMirror dm) => !dm.isPrivate && (dm is VariableMirror))) {
      final DbField metadata = dm.metadata
          .firstWhere((InstanceMirror im) => im.type == _dbFieldType,
              orElse: () => null)
          ?.reflectee;

      String name = MirrorSystem.getName(dm.simpleName);
      if ((metadata?.name ?? "").isNotEmpty)
        name = metadata.name;

      await statement(dm, metadata, name);
    }
  }

  @protected
  static Future<Null> iterateDbFieldValues(OrmObject object,
      Future<Null> statement(DbField dbField, String name, dynamic value)) async {
    final InstanceMirror im = reflect(object);
    final ClassMirror cm = im.type;

    await iterateDbFields(
        cm,
        (DeclarationMirror dm, DbField dbField, String name) =>
            statement(dbField, name, im.getField(dm.simpleName).reflectee));
  }
}
