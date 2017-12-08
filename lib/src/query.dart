Query get where => new Query();

enum _Actions {
  equals
}

class _QueryEntry {
  _Actions action;
  String field;
  dynamic value;
  Query subQuery;

  _QueryEntry(this.action, this.field, this.value);
}

class Query {
  final List<_QueryEntry> _sequence = <_QueryEntry>[];

  Query equals(String fieldName, dynamic value) {
    _sequence.add(new _QueryEntry(_Actions.equals, fieldName, value));
    return this;
  }
}