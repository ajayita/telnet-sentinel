import 'package:yaml/yaml.dart';
import 'models.dart';

class FixtureParser {
  static TranscriptFixture parse(String yamlString) {
    final doc = loadYaml(yamlString);
    final steps = <TranscriptStep>[];
    
    for (var stepNode in doc['steps']) {
      if (stepNode.containsKey('client_sends')) {
        steps.add(TranscriptStep(
          clientSends: List<int>.from(stepNode['client_sends']),
        ));
      } else if (stepNode.containsKey('expect_events')) {
        final events = <ExpectedEvent>[];
        for (var eventNode in stepNode['expect_events']) {
          events.add(ExpectedEvent(
            type: eventNode['type'],
            bytes: List<int>.from(eventNode['bytes']),
          ));
        }
        steps.add(TranscriptStep(expectEvents: events));
      } else if (stepNode.containsKey('expect_state')) {
        steps.add(TranscriptStep(
          expectState: Map<String, dynamic>.from(stepNode['expect_state']),
        ));
      }
    }
    
    return TranscriptFixture(
      name: doc['name'],
      description: doc['description'],
      steps: steps,
    );
  }
}
