import 'package:test/test.dart';
import 'good_server.dart';
import 'broken_iac_server.dart';

void main() {
  test('Servers can bind to loopback', () async {
    final good = await GoodServer.bind();
    final broken = await BrokenIacServer.bind();

    expect(good.port, greaterThan(0));
    expect(broken.port, greaterThan(0));

    await good.close();
    await broken.close();
  });
}
