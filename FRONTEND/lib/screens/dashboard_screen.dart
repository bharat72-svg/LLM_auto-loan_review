import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/contract_model.dart';
import 'results_screen.dart';
import 'history_screen.dart';
import 'comparison_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}


class _DashboardScreenState extends State<DashboardScreen> {
  final _vinController = TextEditingController();
  bool _uploading = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    _email = await StorageService.getEmail();
    setState(() {});
  }

  Future<void> _uploadAndAnalyze() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
      withData: true,
    );

    if (result != null && result.files.first.bytes != null) {
      final pickedFile = result.files.first;
      final bytes = pickedFile.bytes!;
      final filename = pickedFile.name;

      setState(() {
        _uploading = true;
      });

    // Show snackbar instead of blocking dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text('Analyzing $filename...'),
              ),
            ],
          ),
          duration: const Duration(minutes: 2),
          backgroundColor: Colors.blue[700],
        ),
      );

      try {
        // Upload file
        String text = await ApiService.uploadFile(bytes, filename);
      
        // Analyze contract (runs in background)
        Map<String, dynamic> analysis = await ApiService.analyzeContract(
          text,
          _vinController.text,
        );

        // Extract fairness score
        String fairnessScore = 'N/A';
        if (analysis.containsKey('fairness_score')) {
          var scoreData = analysis['fairness_score'];
          if (scoreData is Map && scoreData.containsKey('fairness_score')) {
            fairnessScore = scoreData['fairness_score'].toString();
          } else {
            fairnessScore = scoreData.toString();
          }
        }

        // Create contract
        ContractAnalysis contract = ContractAnalysis(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          filename: filename,
          slaAnalysis: analysis['sla_analysis'] ?? analysis['sla_extraction'] ?? {},
          vehicleDetails: analysis['vehicle_details'] ?? {},
          fairnessScore: fairnessScore,
          timestamp: DateTime.now(),
        );

        await StorageService.saveAnalysis(contract);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Analysis complete for $filename'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResultsScreen(contract: contract),
                    ),
                  );
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _uploading = false;
          });
        }
      }
    }
  }



  Future<void> _logout() async {
    await StorageService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare),
            tooltip: 'Compare Contracts',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ComparisonScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          PopupMenuButton(
            onSelected: (_) => _logout(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Welcome, ${_email ?? 'User'}!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text('Upload your lease contract for instant AI analysis'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _vinController,
                  decoration:  InputDecoration(
                    labelText: 'Vehicle VIN (Optional)',
                    hintText: 'Enter VIN for vehicle history lookup',
                    prefixIcon: const Icon(Icons.directions_car),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        if (_vinController.text.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('VIN ${_vinController.text} will be used in analysis'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      },
                    ),      
                  ),
                  maxLength: 17,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 60,
                  child: ElevatedButton.icon(
                    onPressed: _uploading ? null : _uploadAndAnalyze,
                    icon: _uploading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file, size: 28),
                    label: Text(
                      _uploading ? 'Analyzing...' : 'Upload & Analyze Contract',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 20),
                const Text(
                  'Features:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(Icons.analytics, 'SLA Analysis & Fairness Score'),
                _buildFeatureItem(Icons.chat, 'AI Negotiation Assistant'),
                _buildFeatureItem(Icons.compare_arrows, 'Multi-Contract Comparison'),
                _buildFeatureItem(Icons.history, 'Analysis History'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 16),
          Text(text),
        ],
      ),
    );
  }
}
