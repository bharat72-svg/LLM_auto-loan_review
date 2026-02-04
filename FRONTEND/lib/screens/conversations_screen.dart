import 'package:flutter/material.dart';
import '../models/conversation_model.dart';
import '../models/contract_model.dart';
import '../services/conversation_service.dart';
import 'chat_thread_screen.dart';

class ConversationsScreen extends StatefulWidget {
  final ContractAnalysis contract;

  const ConversationsScreen({super.key, required this.contract});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<Conversation> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final conversations = await ConversationService.getConversationsForContract(
      widget.contract.id,
    );
    setState(() {
      _conversations = conversations;
      _loading = false;
    });
  }

  Future<void> _startNewConversation() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _NewConversationDialog(),
    );

    if (result != null) {
      // Extract contract data for negotiation context
      final sla = widget.contract.slaAnalysis;
      double originalMonthly = _extractNumeric(sla, 'emi_amount') ?? 50000;
      double originalInterest = _extractNumeric(sla, 'interest_rate') ?? 8.0;

      final newConv = Conversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contractId: widget.contract.id,
        dealerName: result['name']!,
        dealerEmail: result['email']!,
        messages: [
          Message(
            id: '1',
            text: 'Hi ${result['name']}, I reviewed the lease contract and would like to discuss some terms.',
            isUser: true,
            timestamp: DateTime.now(),
          ),
        ],
        lastUpdated: DateTime.now(),
        status: ConversationStatus.active,
        negotiationContext: NegotiationContext(
          originalMonthly: originalMonthly,
          currentMonthly: originalMonthly,
          originalInterest: originalInterest,
          currentInterest: originalInterest,
        ),
      );

      await ConversationService.addConversation(newConv);
      _loadConversations();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatThreadScreen(
              conversation: newConv,
              contract: widget.contract,
            ),
          ),
        ).then((_) => _loadConversations());
      }
    }
  }

  double? _extractNumeric(Map<String, dynamic> data, String key) {
    if (data.containsKey(key)) {
      var value = data[key];
      if (value is Map && value.containsKey('value')) {
        value = value['value'];
      }
      String str = value.toString().replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(str);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dealer Conversations'),
            Text(
              widget.contract.filename,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _conversations.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    return _buildConversationCard(_conversations[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewConversation,
        icon: const Icon(Icons.add_comment),
        label: const Text('New Conversation'),
      ),
    );
  }

  Widget _buildConversationCard(Conversation conv) {
    final lastMsg = conv.messages.isNotEmpty ? conv.messages.last : null;
    Color statusColor = _getStatusColor(conv.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatThreadScreen(
                conversation: conv,
                contract: widget.contract,
              ),
            ),
          ).then((_) => _loadConversations());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      conv.dealerName[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conv.dealerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          conv.dealerEmail,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(conv.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (lastMsg != null) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      lastMsg.isUser ? Icons.send : Icons.reply,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lastMsg.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(conv.lastUpdated),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startNewConversation,
            icon: const Icon(Icons.add_comment),
            label: const Text('Start Conversation'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ConversationStatus status) {
    switch (status) {
      case ConversationStatus.active:
        return Colors.blue;
      case ConversationStatus.negotiating:
        return Colors.orange;
      case ConversationStatus.accepted:
        return Colors.green;
      case ConversationStatus.rejected:
        return Colors.red;
      case ConversationStatus.archived:
        return Colors.grey;
    }
  }

  String _getStatusText(ConversationStatus status) {
    switch (status) {
      case ConversationStatus.active:
        return 'Active';
      case ConversationStatus.negotiating:
        return 'Negotiating';
      case ConversationStatus.accepted:
        return 'Accepted';
      case ConversationStatus.rejected:
        return 'Rejected';
      case ConversationStatus.archived:
        return 'Archived';
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _NewConversationDialog extends StatefulWidget {
  @override
  State<_NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<_NewConversationDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start Dealer Conversation'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Dealer Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Dealer Email',
                prefixIcon: Icon(Icons.email),
              ),
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Required';
                if (!v!.contains('@')) return 'Invalid email';
                return null;
              },
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
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'email': _emailController.text,
              });
            }
          },
          child: const Text('Start'),
        ),
      ],
    );
  }
}

