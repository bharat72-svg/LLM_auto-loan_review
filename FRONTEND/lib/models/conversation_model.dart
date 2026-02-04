class Conversation {
  final String id;
  final String contractId;
  final String dealerName;
  final String dealerEmail;
  final List<Message> messages;
  final DateTime lastUpdated;
  final ConversationStatus status;
  final NegotiationContext? negotiationContext;

  Conversation({
    required this.id,
    required this.contractId,
    required this.dealerName,
    required this.dealerEmail,
    required this.messages,
    required this.lastUpdated,
    required this.status,
    this.negotiationContext,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'contractId': contractId,
        'dealerName': dealerName,
        'dealerEmail': dealerEmail,
        'messages': messages.map((m) => m.toJson()).toList(),
        'lastUpdated': lastUpdated.toIso8601String(),
        'status': status.toString(),
        'negotiationContext': negotiationContext?.toJson(),
      };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'],
        contractId: json['contractId'],
        dealerName: json['dealerName'],
        dealerEmail: json['dealerEmail'],
        messages: (json['messages'] as List)
            .map((m) => Message.fromJson(m))
            .toList(),
        lastUpdated: DateTime.parse(json['lastUpdated']),
        status: ConversationStatus.values.firstWhere(
          (e) => e.toString() == json['status'],
          orElse: () => ConversationStatus.active,
        ),
        negotiationContext: json['negotiationContext'] != null
            ? NegotiationContext.fromJson(json['negotiationContext'])
            : null,
      );
}

class Message {
  final String id;
  final String text;
  final bool isUser; // true = user, false = dealer
  final DateTime timestamp;
  final MessageType type;
  final Map<String, dynamic>? metadata; // For negotiation data

  Message({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'type': type.toString(),
        'metadata': metadata,
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'],
        text: json['text'],
        isUser: json['isUser'],
        timestamp: DateTime.parse(json['timestamp']),
        type: MessageType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => MessageType.text,
        ),
        metadata: json['metadata'],
      );
}

// Track negotiation progress
class NegotiationContext {
  final double originalMonthly;
  final double currentMonthly;
  final double originalInterest;
  final double currentInterest;
  final int negotiationRound; // How many counter-offers

  NegotiationContext({
    required this.originalMonthly,
    required this.currentMonthly,
    required this.originalInterest,
    required this.currentInterest,
    this.negotiationRound = 0,
  });

  Map<String, dynamic> toJson() => {
        'originalMonthly': originalMonthly,
        'currentMonthly': currentMonthly,
        'originalInterest': originalInterest,
        'currentInterest': currentInterest,
        'negotiationRound': negotiationRound,
      };

  factory NegotiationContext.fromJson(Map<String, dynamic> json) =>
      NegotiationContext(
        originalMonthly: json['originalMonthly'],
        currentMonthly: json['currentMonthly'],
        originalInterest: json['originalInterest'],
        currentInterest: json['currentInterest'],
        negotiationRound: json['negotiationRound'] ?? 0,
      );
}

enum MessageType {
  text,
  negotiationProposal,
  aiSuggestion, // AI guidance messages
  dealerCounterOffer,
  systemAlert,
}

enum ConversationStatus {
  active,
  negotiating,
  accepted,
  rejected,
  archived,
}

