class ExpectedEvent {
  final String type;
  final List<int> bytes;
  ExpectedEvent({required this.type, required this.bytes});
}

class TranscriptStep {
  final List<int>? clientSends;
  final List<ExpectedEvent>? expectEvents;
  final Map<String, dynamic>? expectState;

  TranscriptStep({this.clientSends, this.expectEvents, this.expectState});
}

class TranscriptFixture {
  final String name;
  final String description;
  final List<TranscriptStep> steps;

  TranscriptFixture({
    required this.name,
    required this.description,
    required this.steps,
  });
}
