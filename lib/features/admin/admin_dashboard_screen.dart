import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:unipast/core/theme.dart';
import 'package:unipast/features/admin/admin_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:unipast/features/admin/activity_service.dart';
import 'package:unipast/features/admin/activity_model.dart';


class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Console',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle:
              GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 13),
          indicatorColor: AppTheme.accentGold,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_rounded)),
            Tab(text: 'Upload', icon: Icon(Icons.cloud_upload_rounded)),
            Tab(text: 'Academic', icon: Icon(Icons.school_rounded)),
            Tab(text: 'Financials', icon: Icon(Icons.payments_rounded)),
            Tab(text: 'Activity Feed', icon: Icon(Icons.history_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _OverviewTab(),
          _UploadTab(),
          const _AcademicTab(),
          const _FinancialsTab(),
          const _ActivitiesTab(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Overview Tab
// ---------------------------------------------------------------------------
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return statsAsync.when(
      data: (stats) => RefreshIndicator(
        onRefresh: () => ref.refresh(adminStatsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatCard(
              label: 'Total Signups',
              value: stats['total_signups'].toString(),
              icon: Icons.people_alt_rounded,
              color: AppTheme.primaryTeal,
            ),
            _StatCard(
              label: 'Active Subscriptions',
              value: stats['active_subscriptions'].toString(),
              icon: Icons.star_rounded,
              color: AppTheme.accentGold,
            ),
            _StatCard(
              label: 'Total Revenue',
              value: 'GH₵ ${stats['total_revenue'].toStringAsFixed(2)}',
              icon: Icons.account_balance_wallet_rounded,
              color: Colors.green,
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading stats: $e')),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withAlpha(20), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
                Text(value,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Upload Tab
// ---------------------------------------------------------------------------
class _UploadTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends ConsumerState<_UploadTab> {
  String? _selectedCourseId;
  int _year = DateTime.now().year;
  int _semester = 1;
  PlatformFile? _pickedFile;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Upload Past Question',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Simplified Dropdowns (In real app, fetch from AdminService)
          _buildDropdown(
              'Course ID', (val) => setState(() => _selectedCourseId = val)),

          Row(
            children: [
              Expanded(
                  child: _buildDropdown(
                      'Year',
                      (val) =>
                          setState(() => _year = int.tryParse(val!) ?? 2024))),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildDropdown(
                      'Semester',
                      (val) =>
                          setState(() => _semester = int.tryParse(val!) ?? 1))),
            ],
          ),

          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.attach_file_rounded),
            label: Text(_pickedFile?.name ?? 'Select PDF File'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: (_pickedFile != null &&
                    _selectedCourseId != null &&
                    !_isUploading)
                ? _handleUpload
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isUploading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Start Upload',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        decoration: InputDecoration(
            labelText: label,
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) setState(() => _pickedFile = result.files.first);
  }

  Future<void> _handleUpload() async {
    setState(() => _isUploading = true);
    try {
      final bytes = await File(_pickedFile!.path!).readAsBytes();
      await ref.read(adminServiceProvider).uploadPastQuestion(
            courseId: _selectedCourseId!,
            year: _year,
            semester: _semester,
            fileName: _pickedFile!.name,
            fileBytes: bytes,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Upload successful!')));
        setState(() {
          _pickedFile = null;
          _isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        setState(() => _isUploading = false);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Academic Tab
// ---------------------------------------------------------------------------
class _AcademicTab extends ConsumerWidget {
  const _AcademicTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _ManagementTiles();
  }
}

class _ManagementTiles extends StatelessWidget {
  const _ManagementTiles();

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTile(
          context,
          icon: Icons.school_outlined,
          title: 'Manage Universities',
          subtitle: 'Update institutions and categories',
          color: AppTheme.primaryTeal,
          onTap: () => context.push(
            '/admin/manage',
            extra: {
              'title': 'Universities',
              'mode': 'universities',
            },
          ),
        ),
        _buildTile(
          context,
          icon: Icons.account_balance_outlined,
          title: 'Faculty & Department',
          subtitle: 'Organize academic hierarchy',
          color: Colors.blue,
          onTap: () => context.push(
            '/admin/manage',
            extra: {
              'title': 'Faculties',
              'mode': 'faculties',
            },
          ),
        ),
        _buildTile(
          context,
          icon: Icons.book_outlined,
          title: 'Programmes & Courses',
          subtitle: 'Curate academic content',
          color: Colors.orange,
          onTap: () => context.push(
            '/admin/manage',
            extra: {
              'title': 'Programmes',
              'mode': 'programmes',
            },
          ),
        ),
        _buildTile(
          context,
          title: 'Manage Reps',
          icon: Icons.person_add_rounded,
          subtitle: 'Add or remove representatives',
          color: AppTheme.primaryTeal,
          onTap: () => context.push(
            '/admin/manage',
            extra: {
              'title': 'Course Representatives',
              'mode': 'reps',
            },
          ),
        ),
      ],
    );
  }
}


// ---------------------------------------------------------------------------
// Financials Tab
// ---------------------------------------------------------------------------
class _FinancialsTab extends ConsumerWidget {
  const _FinancialsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(adminPaymentHistoryProvider);

    return historyAsync.when(
      data: (history) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (context, index) {
          final tx = history[index];
          final date =
              DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
          return Card(
            child: ListTile(
              leading: const Icon(Icons.payment_rounded, color: Colors.green),
              title: Text(tx['profiles']?['full_name'] ?? 'Unknown User'),
              subtitle: Text(DateFormat('MMM dd, yyyy • HH:mm').format(date)),
              trailing: Text('GH₵ ${tx['amount']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminServiceProvider).getStats();
});

final adminPaymentHistoryProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminServiceProvider).getPaymentHistory();
});

// ---------------------------------------------------------------------------
// Activity Feed Tab
// ---------------------------------------------------------------------------
class _ActivitiesTab extends ConsumerWidget {
  const _ActivitiesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesStreamProvider);

    return activitiesAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 64, color: Colors.grey.withAlpha(51)),
                const SizedBox(height: 16),
                Text(
                  'No activities recorded yet.',
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(recentActivitiesProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return _ActivityListItem(activity: activity);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _ActivityListItem extends StatelessWidget {
  final Activity activity;
  const _ActivityListItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final iconData = _getIcon(activity.eventType);
    final color = _getColor(activity.eventType);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withAlpha(51)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: color, size: 20),
        ),
        title: Text(
          activity.description,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'By: ${activity.userName ?? 'System'} • ${DateFormat('HH:mm, MMM dd').format(activity.createdAt)}',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'signup':
        return Icons.person_add_rounded;
      case 'payment':
        return Icons.payments_rounded;
      case 'upload':
        return Icons.cloud_upload_rounded;
      case 'view':
        return Icons.visibility_rounded;
      case 'update':
        return Icons.edit_rounded;
      case 'delete':
        return Icons.delete_forever_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type.toLowerCase()) {
      case 'signup':
        return AppTheme.primaryTeal;
      case 'payment':
        return Colors.green;
      case 'upload':
        return Colors.blue;
      case 'view':
        return AppTheme.accentGold;
      case 'update':
        return Colors.orange;
      case 'delete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
