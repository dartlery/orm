import 'dart:async';

import 'criteria.dart';
import 'orm_object.dart';
import 'paginated_list.dart';

abstract class DatabaseContext {
  Future<dynamic> add(OrmObject data);
  Future<bool> existsByCriteria(Type type, Criteria criteria);
  Future<bool> existsByInternalID(Type type, dynamic internalId);

  Future<List<T>> getAllByCriteria<T extends OrmObject>(
      Type type, Criteria criteria);

  Future<Stream<T>> streamAllByCriteria<T extends OrmObject>(
      Type type, Criteria criteria);

  Future<int> countByCriteria<T extends OrmObject>(
      Type type, Criteria criteria);

  Future<PaginatedList<T>> getPaginatedByCriteria<T extends OrmObject>(
      Type type, Criteria criteria);

  Future<T> getByInternalID<T extends OrmObject>(Type type, dynamic internalId);
  Future<T> getOneByCriteria<T extends OrmObject>(Type type, Criteria criteria);

  Future<Null> nukeDatabase();

  Future<Null> dropObjectStore(Type objectType);

  Future<Null> update(OrmObject data);

  Future<Null> deleteByCriteria(Type type, Criteria criteria);
  Future<Null> deleteByInternalID(Type type, dynamic internalId);
}
