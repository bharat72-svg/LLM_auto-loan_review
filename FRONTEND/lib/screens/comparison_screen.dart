import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/contract_model.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  List<ContractAnalysis> _contracts = [];
  List<String> _selectedIds = [];

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    _contracts = await StorageService.getHistory();
    setState(() {});
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else if (_selectedIds.length < 3) {
        _selectedIds.add(id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 3 contracts for comparison')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _contracts.where((c) => _selectedIds.contains(c.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Compare Contracts', style: TextStyle(fontSize: 18)),
            Text(
              '${_selectedIds.length}/3 selected',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Selection List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _contracts.length,
              itemBuilder: (context, index) {
                final contract = _contracts[index];
                final isSelected = _selectedIds.contains(contract.id);

                return Card(
                  color: isSelected ? Colors.blue.shade50 : null,
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(contract.id),
                    title: Text(contract.filename),
                    subtitle: Text('Score: ${contract.fairnessScore}'),
                  ),
                );
              },
            ),
          ),

          // Comparison Table
          if (selected.length >= 2)
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      const DataColumn(label: Text('Metric')),
                      ...selected.map((c) => DataColumn(
                            label: Text(c.filename.split('.').first.substring(0, 10)),
                          )),
                    ],
                    rows: [
                      DataRow(cells: [
                        const DataCell(Text('Fairness Score')),
                        ...selected.map((c) => DataCell(Text(c.fairnessScore))),
                      ]),
                      DataRow(cells: [
                        const DataCell(Text('Interest Rate')),
                        ...selected.map((c) => DataCell(
                              Text(c.slaAnalysis['interest_rate']?.toString() ?? 'N/A'),
                            )),
                      ]),
                      DataRow(cells: [
                        const DataCell(Text('Down Payment')),
                        ...selected.map((c) => DataCell(
                              Text(c.slaAnalysis['down_payment']?.toString() ?? 'N/A'),
                            )),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
