class PaginatedList<T> {
  final List<T> items;
  final int offset;
  final int total;
  int get count => items.length;

  PaginatedList(this.items, this.offset, this.total);
}
