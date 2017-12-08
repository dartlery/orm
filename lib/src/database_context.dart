import 'package:meta/meta.dart';
import '../meta.dart';
import 'query.dart';
import 'dart:mirrors';
import 'package:connection_pool/connection_pool.dart';

abstract class ADatabaseContext<T> {
  ConnectionPool<T> _connectionPool;


  ADatabaseContext() {

  }

  DbStorage getStorageMetadata(dynamic object) {
    InstanceMirror im = reflect(object);
    ClassMirror cm = im.type;
    return cm.metadata.firstWhere((InstanceMirror im) => im.type== reflectClass(DbStorage))?.reflectee??
      new DbStorage(cm.qualifiedName.toString());
  }

  void Add(dynamic data) {
    DbStorage dbs = getStorageMetadata(data);
    AddInternal(dbs, data);
  }

  @protected
  void AddInternal(DbStorage storage, dynamic data);


  T GetByKey<T>(dynamic primaryKey) {

  }

  T GetByQuery<T>(Query query) {

  }



}