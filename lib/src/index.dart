class Index {
  final List<IndexField> fields = <IndexField>[];
  bool unique;
  bool sparse;

  void sort() {
    fields.sort((a,b) => a.order.compareTo(b.order));
  }
}
class IndexField {
  String name;
  bool ascending;
  int order;
}
