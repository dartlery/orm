import 'package:uuid/uuid.dart' as uuid;

class Uuid {
  static final uuid.Uuid _uuid = new uuid.Uuid();
  final List<int> _bytes = new List<int>(16);

  Uuid() {
    _uuid.v4(buffer: this._bytes);
  }
  Uuid.parse(String value) {
    _uuid.parse(value, buffer: this._bytes);
  }

  @override
  int get hashCode => this._bytes.hashCode;

  @override
  bool operator ==(dynamic o) {
    if (o is Uuid) {
      for (int i = 0; i < 16; i++) {
        if (o._bytes[i] != this._bytes[i]) return false;
        return true;
      }
    }
    return false;
  }

  @override
  String toString({bool removeDashes = false}) {
    if (removeDashes) {
      return _uuid.unparse(this._bytes).replaceAll("-", "");
    } else {
      return _uuid.unparse(this._bytes);
    }
  }
}
