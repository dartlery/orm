Criteria get where => new Criteria();


enum Actions {
  equals,
  or
}

class QueryEntry {
  final Actions action;
  final String field;
  final dynamic value;
  List<Criteria> subQueries;

  QueryEntry(this.action, {this.field, this.value, this.subQueries});
}

class Criteria {
  final List<QueryEntry> sequence = <QueryEntry>[];

  Criteria equals(String fieldName, dynamic value) {
    sequence.add(new QueryEntry(Actions.equals, field: fieldName, value: value));
    return this;
  }

  Criteria or(List<Criteria> subStatements) {
    sequence.add(new QueryEntry(Actions.equals, subQueries: subStatements));
    return this;
  }
}