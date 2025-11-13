import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/main_layout.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _projects = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      await _apiService.initialize();
      final response = await _apiService.getProjects();
      
      if (response.statusCode == 200) {
        setState(() {
          _projects = List<Map<String, dynamic>>.from(response.data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load projects';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'PLANNING':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return MainLayout(
      title: 'Projects & Sites',
      subtitle: 'Manage all projects and site locations',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProjects,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats Cards
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Total Projects',
                              value: '${_projects.length}',
                              icon: Icons.folder,
                              color: AppTheme.accentPurple,
                            ).animate().fadeIn(duration: 300.ms),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              label: 'Active Projects',
                              value: '${_projects.where((p) => p['status'] == 'IN_PROGRESS').length}',
                              icon: Icons.play_circle,
                              color: Colors.blue,
                            ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              label: 'Total PO Value',
                              value: '\$${_projects.fold<double>(0, (sum, p) => sum + (p['poValue'] ?? 0.0)).toStringAsFixed(0)}',
                              icon: Icons.attach_money,
                              color: Colors.green,
                            ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Projects List
                      Text(
                        'All Projects',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _projects.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(48.0),
                                child: Column(
                                  children: [
                                    Icon(Icons.folder_open, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No projects yet',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _projects.length,
                              itemBuilder: (context, index) {
                                final project = _projects[index];
                                return _ProjectCard(
                                  project: project,
                                  onTap: () {
                                    _showProjectDetails(project);
                                  },
                                )
                                    .animate()
                                    .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                                    .slideX(begin: -0.1, end: 0, duration: 300.ms, delay: (index * 50).ms);
                              },
                            ),
                    ],
                  ),
                ),
    );
  }

  void _showProjectDetails(Map<String, dynamic> project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(project['name'] ?? 'Project'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (project['description'] != null) ...[
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(project['description']),
                const SizedBox(height: 16),
              ],
              if (project['poNumber'] != null)
                Text('PO Number: ${project['poNumber']}'),
              if (project['poValue'] != null)
                Text('PO Value: \$${project['poValue']}'),
              Text('Status: ${project['status']}'),
              if (project['startDate'] != null)
                Text('Start Date: ${project['startDate']}'),
              if (project['endDate'] != null)
                Text('End Date: ${project['endDate']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium,
                ),
                Icon(icon, color: color, size: 28),
              ],
            ),
            Text(
              value,
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback onTap;

  const _ProjectCard({
    required this.project,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'PLANNING':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = project['status'] ?? 'UNKNOWN';
    final statusColor = _getStatusColor(status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project['name'] ?? 'Unnamed Project',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (project['poNumber'] != null)
                          Text(
                            'PO: ${project['poNumber']}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.replaceAll('_', ' '),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ProjectMetric(
                      label: 'PO Value',
                      value: '\$${(project['poValue'] ?? 0.0).toStringAsFixed(0)}',
                    ),
                  ),
                  Expanded(
                    child: _ProjectMetric(
                      label: 'Sites',
                      value: '${project['sites']?.length ?? 0}',
                    ),
                  ),
                  Expanded(
                    child: _ProjectMetric(
                      label: 'Team',
                      value: '${project['teamMembers']?.length ?? 0}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ProjectMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}