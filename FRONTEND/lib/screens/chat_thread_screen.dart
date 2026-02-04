import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../models/contract_model.dart';
import '../services/conversation_service.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class ChatThreadScreen extends StatefulWidget {
  final Conversation conversation;
  final ContractAnalysis contract;

  const ChatThreadScreen({
    super.key,
    required this.conversation,
    required this.contract,
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late Conversation _conversation;
  bool _waitingForDealer = false;
  bool _showAIGuidance = true;

  @override
  void initState() {
    super.initState();
    _conversation = widget.conversation;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Send message to dealer + get AI guidance
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String userMessage = _messageController.text.trim();
    _messageController.clear();

    // 1. Add user message
    final userMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: userMessage,
      isUser: true,
      timestamp: DateTime.now(),
    );

    await _addMessageToConversation(userMsg);

    setState(() {
      _waitingForDealer = true;
    });

    // 2. Send to dealer API
    try {
      String dealerResponse = await ApiService.sendDealerMessage(
        conversationId: _conversation.id,
        userMessage: userMessage,
        contractContext: widget.contract.toJson(),
        negotiationContext: _conversation.negotiationContext?.toJson() ?? {},
      );

      // 3. Add dealer response
      final dealerMsg = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: dealerResponse,
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.text,
      );

      await _addMessageToConversation(dealerMsg);

      // 4. Get real-time AI guidance
      if (_showAIGuidance) {
        await _getAIGuidance(userMessage, dealerResponse);
      }

      setState(() {
        _waitingForDealer = false;
      });
    } catch (e) {
      setState(() {
        _waitingForDealer = false;
      });
      _showError('Failed to send message: $e');
    }

    _scrollToBottom();
  }

  /// Get AI negotiation guidance based on dealer's response
  Future<void> _getAIGuidance(String userMsg, String dealerMsg) async {
    try {
      String guidance = await ApiService.getRealtimeNegotiationGuidance(
        userMessage: userMsg,
        dealerResponse: dealerMsg,
        contractContext: widget.contract.toJson(),
        negotiationContext: _conversation.negotiationContext?.toJson() ?? {},
      );

      // Add AI guidance as system message
      final aiMsg = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: guidance,
        isUser: true, // Show on user side but different style
        timestamp: DateTime.now(),
        type: MessageType.aiSuggestion,
      );

      await _addMessageToConversation(aiMsg);
    } catch (e) {
      print('AI guidance failed: $e');
    }
  }

  /// Send structured negotiation proposal
  Future<void> _sendNegotiationProposal() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _NegotiationProposalDialog(
        contract: widget.contract,
        currentContext: _conversation.negotiationContext,
      ),
    );

    if (result != null) {
      String proposalText = '''
🤝 **NEGOTIATION PROPOSAL**

Monthly Payment: ${result['monthly']}
Interest Rate: ${result['rate']}
Down Payment: ${result['down']}
Lease Term: ${result['term']}

Please review these terms.
''';

      final proposalMsg = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: proposalText,
        isUser: true,
        timestamp: DateTime.now(),
        type: MessageType.negotiationProposal,
        metadata: result,
      );

      await _addMessageToConversation(proposalMsg);

      // Update conversation status
      await _updateConversationStatus(ConversationStatus.negotiating);

      // Auto-send to dealer
      _sendMessage();
    }
  }

  Future<void> _addMessageToConversation(Message msg) async {
    await ConversationService.addMessage(_conversation.id, msg);
    
    final updated = await ConversationService.getConversationById(_conversation.id);
    if (updated != null) {
      setState(() {
        _conversation = updated;
      });
    }
  }

  Future<void> _updateConversationStatus(ConversationStatus newStatus) async {
    final updated = Conversation(
      id: _conversation.id,
      contractId: _conversation.contractId,
      dealerName: _conversation.dealerName,
      dealerEmail: _conversation.dealerEmail,
      messages: _conversation.messages,
      lastUpdated: DateTime.now(),
      status: newStatus,
      negotiationContext: _conversation.negotiationContext,
    );

    await ConversationService.updateConversation(updated);
    setState(() {
      _conversation = updated;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_conversation.dealerName),
            Text(
              _conversation.dealerEmail,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // AI Guidance Toggle
          IconButton(
            icon: Icon(_showAIGuidance ? Icons.psychology : Icons.psychology_outlined),
            tooltip: 'AI Guidance: ${_showAIGuidance ? "ON" : "OFF"}',
            onPressed: () {
              setState(() {
                _showAIGuidance = !_showAIGuidance;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'AI Guidance ${_showAIGuidance ? "Enabled" : "Disabled"}',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.archive, size: 20),
                    SizedBox(width: 8),
                    Text('Archive'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'delete') {
                await ConversationService.deleteConversation(_conversation.id);
                if (mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Contract Info Banner
          _buildContractBanner(),

          // Negotiation Progress (if negotiating)
          if (_conversation.negotiationContext != null)
            _buildNegotiationProgress(),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _conversation.messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_conversation.messages[index]);
              },
            ),
          ),

          // Waiting indicator
          if (_waitingForDealer)
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Dealer is typing...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildContractBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blue[50],
      child: Row(
        children: [
          Icon(Icons.description, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contract.filename,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Fairness: ${widget.contract.fairnessScore}/100',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNegotiationProgress() {
    final ctx = _conversation.negotiationContext!;
    double savingsPercent = 
        ((ctx.originalMonthly - ctx.currentMonthly) / ctx.originalMonthly) * 100;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_down, color: Colors.orange[700]),
              const SizedBox(width: 8),
              const Text(
                'Negotiation Progress',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Original', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text(
                    '₹${ctx.originalMonthly.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward, color: Colors.orange[700]),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Current Offer', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text(
                    '₹${ctx.currentMonthly.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (savingsPercent > 0)
            Text(
              '✓ ${savingsPercent.toStringAsFixed(1)}% reduction achieved',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.isUser;
    final isAI = message.type == MessageType.aiSuggestion;
    final isProposal = message.type == MessageType.negotiationProposal;

    Color bgColor;
    if (isAI) {
      bgColor = Colors.purple[50]!;
    } else if (isProposal) {
      bgColor = Colors.orange[100]!;
    } else if (isUser) {
      bgColor = Colors.blue[100]!;
    } else {
      bgColor = Colors.grey[200]!;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[100],
              child: Text(
                _conversation.dealerName[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.blue[800],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: isAI
                    ? Border.all(color: Colors.purple[300]!, width: 2)
                    : isProposal
                        ? Border.all(color: Colors.orange[300]!, width: 2)
                        : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAI)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.psychology, size: 16, color: Colors.purple[700]),
                          const SizedBox(width: 4),
                          Text(
                            'AI Guidance',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isProposal)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.handshake, size: 16, color: Colors.orange[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Your Proposal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    message.text,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('hh:mm a').format(message.timestamp),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          if (isUser && !isAI) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.handshake),
            tooltip: 'Send Proposal',
            color: Colors.orange,
            onPressed: _sendNegotiationProposal,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              enabled: !_waitingForDealer,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            color: Colors.blue,
            onPressed: _waitingForDealer ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

/// Negotiation Proposal Dialog
class _NegotiationProposalDialog extends StatefulWidget {
  final ContractAnalysis contract;
  final NegotiationContext? currentContext;

  const _NegotiationProposalDialog({
    required this.contract,
    this.currentContext,
  });

  @override
  State<_NegotiationProposalDialog> createState() =>
      _NegotiationProposalDialogState();
}

class _NegotiationProposalDialogState extends State<_NegotiationProposalDialog> {
  late TextEditingController _monthlyController;
  late TextEditingController _downController;
  late TextEditingController _rateController;
  late TextEditingController _termController;

  @override
  void initState() {
    super.initState();
    
    final sla = widget.contract.slaAnalysis;
    
    _monthlyController = TextEditingController(
      text: _extractValue(sla, 'emi_amount', 'monthly_payment'),
    );
    _downController = TextEditingController(
      text: _extractValue(sla, 'down_payment', 'advance'),
    );
    _rateController = TextEditingController(text: '7.5');
    _termController = TextEditingController(
      text: _extractValue(sla, 'lease_term', 'tenure'),
    );
  }

  String _extractValue(Map<String, dynamic> data, String key1, String key2) {
    for (String key in [key1, key2]) {
      if (data.containsKey(key)) {
        var value = data[key];
        if (value is Map && value.containsKey('value')) {
          return value['value'].toString().replaceAll(RegExp(r'[^\d.]'), '');
        }
        return value.toString().replaceAll(RegExp(r'[^\d.]'), '');
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Negotiation Proposal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _monthlyController,
              decoration: const InputDecoration(
                labelText: 'Monthly Payment',
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _downController,
              decoration: const InputDecoration(
                labelText: 'Down Payment',
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rateController,
              decoration: const InputDecoration(
                labelText: 'Interest Rate',
                suffixText: '%',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _termController,
              decoration: const InputDecoration(
                labelText: 'Lease Term',
                suffixText: 'months',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'monthly': '₹${_monthlyController.text}',
              'down': '₹${_downController.text}',
              'rate': '${_rateController.text}%',
              'term': '${_termController.text} months',
            });
          },
          child: const Text('Send Proposal'),
        ),
      ],
    );
  }
}

