class PostgresCommand {
  String command;
  Map<String, dynamic> parameters = <String, dynamic>{};
  PostgresCommand([this.command, this.parameters])
}
