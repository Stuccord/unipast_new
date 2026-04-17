import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unipast/features/admin/admin_service.dart';
import 'package:unipast/features/auth/profile_service.dart';
import 'package:go_router/go_router.dart';

class AdminManagementScreen extends ConsumerStatefulWidget {
  final String title;
  final String mode; // 'universities', 'faculties', 'programmes', 'reps', 'courses'
  final String? parentId; // University ID for faculties, Faculty ID for programmes, etc.

  const AdminManagementScreen({
    super.key,
    required this.title,
    required this.mode,
    this.parentId,
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

  void _loadData() async {
    final profile = ref.read(myProfileProvider).value;
    final isAdmin = profile?.isAdmin ?? false;
    final userUniId = profile?.universityId;

    setState(() {
      if (widget.mode == 'universities') {
        final future = ref.read(adminServiceProvider).getUniversities();
        _dataFuture = future.then((list) {
          if (isAdmin) return list;
          return list.where((u) => u['id'].toString() == userUniId).toList();
        });
      } else if (widget.mode == 'faculties') {
        _dataFuture = ref.read(adminServiceProvider).getFaculties(widget.parentId ?? '');
      } else if (widget.mode == 'programmes') {
        _dataFuture = ref.read(adminServiceProvider).getProgrammes(widget.parentId ?? '');
      } else if (widget.mode == 'courses') {
        _dataFuture = ref.read(adminServiceProvider).getCourses(widget.parentId ?? '');
      } else if (widget.mode == 'reps') {
         _dataFuture = Future.value([]); // Placeholder
      } else {
        _dataFuture = Future.value([]);
      }
    });
  }

  void _onSearch(String query) {
    setState(() {
      _filteredData = _allData.where((item) {
        final name = (item['name'] ?? item['code'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _showAddDialog() async {
    final profile = ref.read(myProfileProvider).value;
    final isAdmin = profile?.isAdmin ?? false;

    if (widget.mode == 'universities' && !isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only administrators can add universities.')),
      );
      return;
    }

    final nameController = TextEditingController();
    final extraController = TextEditingController(); // For category, duration, or code

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New ${widget.mode.substring(0, widget.mode.length - 1).toUpperCase()}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: widget.mode == 'courses' ? 'Course Name' : 'Name'),
            ),
            if (widget.mode == 'universities')
              TextField(
                controller: extraController,
                decoration: const InputDecoration(labelText: 'Category (e.g. Public)'),
              ),
            if (widget.mode == 'programmes')
              TextField(
                controller: extraController,
                decoration: const InputDecoration(labelText: 'Duration (Years)'),
                keyboardType: TextInputType.number,
              ),
            if (widget.mode == 'courses')
              TextField(
                controller: extraController,
                decoration: const InputDecoration(labelText: 'Course Code'),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final extra = extraController.text.trim();
              if (name.isEmpty) return;

              try {
                final service = ref.read(adminServiceProvider);
                if (widget.mode == 'universities') {
                  await service.addUniversity(name, extra.isEmpty ? 'General' : extra);
                } else if (widget.mode == 'faculties') {
                  if (widget.parentId == null) throw 'University ID is required';
                  await service.addFaculty(widget.parentId!, name);
                } else if (widget.mode == 'programmes') {
                  if (widget.parentId == null) throw 'Faculty ID is required';
                  await service.addProgramme(widget.parentId!, name, int.tryParse(extra) ?? 4);
                } else if (widget.mode == 'courses') {
                  if (widget.parentId == null) throw 'Programme ID is required';
                  await service.addCourse(widget.parentId!, extra.toUpperCase(), name);
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully added $name')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF05080F) : Colors.grey[50], // Darkened to match GOD MIND
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF00E5CC)),
            onPressed: _showAddDialog,
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
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00E5CC)),
                filled: true,
                fillColor: isDark ? const Color(0xFF111D35) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withAlpha(20)),
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
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5CC)));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
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
                      color: isDark ? const Color(0xFF111D35) : Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withAlpha(isDark ? 5 : 0)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF00E5CC).withAlpha(30),
                          child: Text(
                            (item['name'] ?? item['code'] ?? '?')[0].toUpperCase(),
                            style: const TextStyle(color: Color(0xFF00E5CC), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(item['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text(item['category'] ?? item['code'] ?? item['duration_years']?.toString() ?? '', style: const TextStyle(color: Colors.grey)),
                        trailing: IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF00E5CC)),
                          onPressed: () {
                             if (widget.mode == 'universities') {
                               context.push('/admin/manage', extra: {
                                 'title': 'Faculties of ${item['name']}',
                                 'mode': 'faculties',
                                 'parentId': item['id'].toString(),
                               });
                             } else if (widget.mode == 'faculties') {
                               context.push('/admin/manage', extra: {
                                 'title': 'Programmes of ${item['name']}',
                                 'mode': 'programmes',
                                 'parentId': item['id'].toString(),
                               });
                             } else if (widget.mode == 'programmes') {
                               context.push('/admin/manage', extra: {
                                 'title': 'Courses of ${item['name']}',
                                 'mode': 'courses',
                                 'parentId': item['id'].toString(),
                               });
                             }
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
