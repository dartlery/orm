import 'dart:async';
import 'package:meta/meta.dart';
import '../meta.dart';
import 'query.dart';
import 'dart:mirrors';

abstract class ADatabaseContext {
  ADatabaseContext() {

  }

  DbStorage getStorageMetadata(dynamic object) {
    InstanceMirror im = reflect(object);
    ClassMirror cm = im.type;
    return cm.metadata.firstWhere((InstanceMirror im) => im.type== reflectClass(DbStorage),
        orElse:()=>null)?.reflectee??
      new DbStorage(cm.qualifiedName.toString());
  }

  Future<dynamic> Add(dynamic data) async {
    DbStorage dbs = getStorageMetadata(data);
    return AddInternal(dbs, data);
  }

  @protected
  Future<dynamic> AddInternal(DbStorage storage, dynamic data);


  T GetByKey<T>(dynamic primaryKey) {

  }

  T GetByQuery<T>(Query query) {

  }

  @protected
  void IterateDbFields(dynamic object, statement(DbField dbField, String name, dynamic value)) {
    final InstanceMirror im = reflect(object);

    for(TypeVariableMirror vm in im.type.typeVariables) {
      final DbField metadata = vm.metadata.firstWhere((InstanceMirror im) => im.type==reflectClass(DbField))?.reflectee;
      if(metadata?.ignore??false)
        break;

      String name = vm.simpleName.toString();
      if((metadata?.name??"").isNotEmpty)
        name = metadata.name;

      statement(metadata, name, im.getField(vm.simpleName).reflectee);
    }
  }


}