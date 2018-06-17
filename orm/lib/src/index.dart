class Index {
  final List<IndexField> fields = <IndexField>[];
  bool unique;
  bool sparse;

  void sort() {
    fields.sort((IndexField a, IndexField b) => a.order.compareTo(b.order));
  }
}

class IndexField {
  String name;
  bool ascending;
  int order;
}
