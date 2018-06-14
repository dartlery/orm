Criteria get where => new Criteria();

enum Actions { equals, or, sort }
enum Direction { ascending, descending }

class QueryEntry {
  final Actions action;
  final String field;
  final Direction direction;
  final dynamic value;
  List<Criteria> subQueries;

  QueryEntry(this.action,
      {this.field,
      this.value,
      this.subQueries,
      this.direction: Direction.ascending});
}

class Criteria {
  int _limit = 0;
  int _skip = 0;
  final List<QueryEntry> sequence = <QueryEntry>[];

  Criteria equals(String fieldName, dynamic value) {
    sequence
        .add(new QueryEntry(Actions.equals, field: fieldName, value: value));
    return this;
  }

  Criteria or(List<Criteria> subStatements) {
    sequence.add(new QueryEntry(Actions.equals, subQueries: subStatements));
    return this;
  }

  Criteria limit(int limit) {
    this._limit = limit;
    return this;
  }

  Criteria sort(String field, {Direction direction: Direction.ascending}) {
    sequence
        .add(new QueryEntry(Actions.sort, field: field, direction: direction));
    return this;
  }

  Criteria skip(int skip) {
    this._skip = skip;
    return this;
  }

  int getLimit() => this._limit;
  int getSkip() => this._skip;
}
