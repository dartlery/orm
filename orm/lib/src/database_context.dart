import 'dart:async';

import 'criteria.dart';
import 'orm_object.dart';
import 'paginated_list.dart';

abstract class DatabaseContext {
  Future<dynamic> add(OrmObject data);
  Future<bool> existsByCriteria(Type type, Criteria criteria);
  Future<bool> existsByInternalID(Type type, dynamic internalId);

  Future<List<T>> getAllByQuery<T extends OrmObject>(Type type, Query query);

  Future<Stream<T>> streamAllByQuery<T extends OrmObject>(
      Type type, Query query);

  Future<int> countByCriteria<T extends OrmObject>(
      Type type, Criteria criteria);

  Future<PaginatedList<T>> getPaginatedByQuery<T extends OrmObject>(
      Type type, Query query);

  Future<T> getByInternalID<T extends OrmObject>(Type type, dynamic internalId);
  Future<T> getOneByQuery<T extends OrmObject>(Type type, Query query);

  Future<Null> nukeDatabase();

  Future<Null> dropObjectStore(Type objectType);

  Future<Null> update(OrmObject data);

  Future<Null> deleteByCriteria(Type type, Criteria criteria);
  Future<Null> deleteByInternalID(Type type, dynamic internalId);

  Future<List<T>> search<T extends OrmObject>(Type t, String searchTerm);
}
