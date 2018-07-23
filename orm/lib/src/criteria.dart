import 'enums.dart';

Query get select => new Query();
Criteria get where => new Criteria();

enum Actions { equals, or }

class Criterion {
  final Actions action;
  final String field;
  final dynamic value;
  List<Criteria> subCriteria;

  Criterion(this.action, {this.field, this.value, this.subCriteria});

  Criterion.copy(Criterion criterion)
      : this.action = criterion.action,
        this.field = criterion.field,
        this.value = criterion.value,
        this.subCriteria = criterion.subCriteria
            ?.map((Criteria criteria) => new Criteria.copy(criteria));
}

class Order {
  final String field;
  final Direction direction;
  Order(this.field, this.direction);
}

class Query extends Criteria {
  int limit = 0;
  int skip = 0;
  final List<Order> _order = <Order>[];

  Query();

  Query.copy(Query query) : super.copy(query) {
    this.limit = query.limit;
    this.skip = query.skip;
    this._order.addAll(query
        .getOrder()
        ?.map((Order order) => new Order(order.field, order.direction)));
  }

  Query.withCriteria(Criteria criteria) : super.copy(criteria);

  void sort(String field, {Direction direction = Direction.ascending}) {
    _order.add(new Order(field, direction));
  }

  List<Order> getOrder() => this._order;
  bool get hasOrders => this._order.isNotEmpty;
}

class Criteria {
  final List<Criterion> sequence = <Criterion>[];

  Criteria();

  Criteria.copy(Criteria criteria) {
    sequence.addAll(criteria.sequence
        ?.map((Criterion criterion) => new Criterion.copy(criterion)));
  }

  void equals(String fieldName, dynamic value) {
    sequence.add(new Criterion(Actions.equals, field: fieldName, value: value));
  }

  void or(List<Criteria> subCriteria) {
    sequence.add(new Criterion(Actions.or, subCriteria: subCriteria));
  }
}
