import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unipast/core/theme.dart';
import 'package:unipast/features/admin/admin_service.dart';

class AdminManagementScreen extends ConsumerStatefulWidget {
  final String title;
  final String mode; // 'universities', 'faculties', 'programmes', 'reps'

  const AdminManagementScreen({
    super.key,
    required this.title,
    required this.mode,
  });

  @override
  ConsumerState<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends ConsumerState<AdminManagementScreen> {
  late Future<List<Map<String, dynamic>>> _dataFuture;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      if (widget.mode == 'universities') {
        _dataFuture = ref.read(adminServiceProvider).getUniversities();
      } else if (widget.mode == 'reps') {
         // This would ideally be a query for is_rep = true
         _dataFuture = Future.value([]); // Placeholder for reps management
      } else {
        _dataFuture = Future.value([]); // Faculties/Programmes need parent IDs in this service
      }
    });
  }

  void _onSearch(String query) {
    setState(() {
      _filteredData = _allData.where((item) {
        final name = item['name']?.toString().toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: () {
              // Show Add Dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Adding new records is available in the Web Portal.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search ${widget.title.toLowerCase()}...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                _allData = snapshot.data ?? [];
                if (_searchController.text.isEmpty) {
                  _filteredData = _allData;
                }

                if (_filteredData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open_rounded, size: 64, color: Colors.grey.withAlpha(100)),
                        const SizedBox(height: 16),
                        Text('No ${widget.title.toLowerCase()} found', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredData.length,
                  itemBuilder: (context, index) {
                    final item = _filteredData[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryTeal.withAlpha(30),
                          child: Text(
                            (item['name'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(item['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item['category'] ?? item['code'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () {
                             // Drill down logic here if needed
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
