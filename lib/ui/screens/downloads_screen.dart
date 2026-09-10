import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/download_task.dart';
import '../../providers/download_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_download_dialog.dart';
import '../widgets/download_card.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _tabs = ['All', 'Active', 'Queued', 'Completed', 'Failed', 'Scheduled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DownloadProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(105),
          child: Column(
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => provider.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Search downloads...',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white38),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.black26,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),

              // Category filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip('All Categories', null, provider),
                    _buildFilterChip('Movies', DownloadCategory.video, provider),
                    _buildFilterChip('Music', DownloadCategory.music, provider),
                    _buildFilterChip('Documents', DownloadCategory.document, provider),
                    _buildFilterChip('Archives', DownloadCategory.archive, provider),
                    _buildFilterChip('Apps', DownloadCategory.app, provider),
                    _buildFilterChip('Images', DownloadCategory.image, provider),
                  ],
                ),
              ),

              // Status TabBar
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppTheme.primaryCyan,
                labelColor: AppTheme.primaryCyan,
                unselectedLabelColor: Colors.white54,
                tabAlignment: TabAlignment.start,
                tabs: _tabs.map((name) {
                  int count = 0;
                  if (name == 'All') count = provider.tasks.length;
                  if (name == 'Active') count = provider.activeCount;
                  if (name == 'Queued') count = provider.queuedCount;
                  if (name == 'Completed') count = provider.completedCount;
                  if (name == 'Failed') count = provider.failedCount;
                  if (name == 'Scheduled') {
                    count = provider.tasks.where((t) => t.isScheduled).length;
                  }

                  return Tab(text: '$name ($count)');
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tabName) {
          final tasks = _filterTasksForTab(provider.filteredTasks, tabName);

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 64, color: Colors.white24),
                  const SizedBox(height: 12),
                  Text(
                    'No $tabName Downloads',
                    style: const TextStyle(fontSize: 16, color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryCyan,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AddDownloadDialog(),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Download'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return DownloadCard(task: tasks[index]);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    DownloadCategory? category,
    DownloadProvider provider,
  ) {
    final isSelected = provider.selectedCategoryFilter == category;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white70)),
        selected: isSelected,
        selectedColor: AppTheme.primaryCyan,
        backgroundColor: const Color(0xFF1E283A),
        showCheckmark: false,
        onSelected: (_) => provider.setCategoryFilter(category),
      ),
    );
  }

  List<DownloadTask> _filterTasksForTab(List<DownloadTask> source, String tabName) {
    switch (tabName) {
      case 'Active':
        return source
            .where((t) => t.status == DownloadStatus.downloading || t.status == DownloadStatus.connecting)
            .toList();
      case 'Queued':
        return source.where((t) => t.status == DownloadStatus.queued).toList();
      case 'Completed':
        return source.where((t) => t.status == DownloadStatus.completed).toList();
      case 'Failed':
        return source.where((t) => t.status == DownloadStatus.failed).toList();
      case 'Scheduled':
        return source.where((t) => t.isScheduled).toList();
      case 'All':
      default:
        return source;
    }
  }
}
