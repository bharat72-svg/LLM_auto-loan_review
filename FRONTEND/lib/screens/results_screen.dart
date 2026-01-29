import 'package:flutter/material.dart';
import '../models/contract_model.dart';
import 'chatbot_screen.dart';
import 'package:intl/intl.dart';

class ResultsScreen extends StatelessWidget {
  final ContractAnalysis contract;

  const ResultsScreen({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(contract.filename),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble),
            tooltip: 'Negotiation Assistant',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatbotScreen(contract: contract),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fairness Score Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade700],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(blurRadius: 20, color: Colors.black26),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    contract.fairnessScore,
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Contract Fairness Score',
                    style: TextStyle(fontSize: 20, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM dd, yyyy HH:mm').format(contract.timestamp),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // SLA Analysis
            _buildSection(
              context,
              '📋 SLA Analysis',
              contract.slaAnalysis,
            ),
            const SizedBox(height: 24),

            // Vehicle Details
            _buildSection(
              context,
              '🚗 Vehicle Details',
              contract.vehicleDetails,
            ),
            const SizedBox(height: 32),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatbotScreen(contract: contract),
                  ),
                ),
                icon: const Icon(Icons.chat),
                label: const Text('Get Negotiation Advice'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: data.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 150,
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: Text(entry.value.toString()),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
