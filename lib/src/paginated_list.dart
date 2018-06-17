class PaginatedList<T> {
  final List<T> items;
  final int offset;
  final int total;
  PaginatedList(this.items, this.offset, this.total);

  int get count => items.length;
}
