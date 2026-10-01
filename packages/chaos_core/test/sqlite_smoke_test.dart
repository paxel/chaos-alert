import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('the SQLite library loads and answers a query', () {
    final db = sqlite3.openInMemory();
    addTearDown(db.close);
    expect(db.select('select 1 + 1 as two').single['two'], 2);
  });
}
