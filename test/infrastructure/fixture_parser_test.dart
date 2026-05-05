import 'package:test/test.dart';
import 'models.dart';
import 'fixture_parser.dart';

void main() {
  test('parses simple fixture', () {
    final yaml = '''
name: "Test"
description: "Desc"
steps:
  - client_sends: [255, 253, 1]
  - expect_events:
      - type: "iac"
        bytes: [255, 253, 1]
''';
    final fixture = FixtureParser.parse(yaml);
    expect(fixture.name, "Test");
    expect(fixture.description, "Desc");
    expect(fixture.steps.length, 2);
    expect(fixture.steps[0].clientSends, [255, 253, 1]);
    expect(fixture.steps[1].expectEvents?.first.type, "iac");
    expect(fixture.steps[1].expectEvents?.first.bytes, [255, 253, 1]);
  });
}
