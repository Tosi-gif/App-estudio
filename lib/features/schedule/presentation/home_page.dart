import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/app_settings.dart';
import '../../auth/data/auth_repository.dart';
import '../../settings/presentation/settings_page.dart';
import '../data/schedule_repository.dart';
import 'schedule_controller.dart';
import 'widgets/add_schedule_dialog.dart';
import 'widgets/schedule_list.dart';

enum _ProfileMenuAction { signOut }

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.user,
    required this.authRepository,
    required this.scheduleRepository,
    required this.settings,
    required this.onSettingsChanged,
  });

  final User user;
  final AuthRepository authRepository;
  final ScheduleRepository scheduleRepository;
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ScheduleController _controller;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _showFeedback(
    String message, {
    bool isError = false,
    Color? backgroundColor,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, topInset + 12, 16, 0),
          backgroundColor:
              backgroundColor ??
              (isError ? Colors.red.shade700 : Colors.green.shade700),
        ),
      );
  }

  @override
  void initState() {
    super.initState();
    _controller = ScheduleController(
      widget.scheduleRepository,
      notificationsEnabled: widget.settings.notificationsEnabled,
    );
    _controller.load();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.notificationsEnabled !=
        widget.settings.notificationsEnabled) {
      _controller.setNotificationsEnabled(widget.settings.notificationsEnabled);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openAddDialog() async {
    final item = await showAddScheduleDialog(
      context: context,
      days: ScheduleController.days,
      use24HourFormat: widget.settings.use24HourFormat,
    );
    if (!mounted || item == null) return;
    try {
      await _controller.addItem(item);
      if (!mounted) return;
      _showFeedback('Tarea creada con exito');
    } catch (_) {
      if (!mounted) return;
      _showFeedback('No se pudo crear la tarea', isError: true);
    }
  }

  Future<void> _signOut() async {
    await widget.authRepository.signOut();
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await _controller.deleteItem(itemId);
      if (!mounted) return;
      _showFeedback(
        'Tarea borrada con exito',
        backgroundColor: Colors.red.shade700,
      );
    } catch (_) {
      if (!mounted) return;
      _showFeedback('No se pudo borrar la tarea', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: PopupMenuButton<_ProfileMenuAction>(
                tooltip: 'Perfil',
                onSelected: (value) {
                  if (value == _ProfileMenuAction.signOut) {
                    _signOut();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<_ProfileMenuAction>(
                    enabled: false,
                    child: Text(widget.user.email ?? 'Sin correo'),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<_ProfileMenuAction>(
                    value: _ProfileMenuAction.signOut,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.logout, size: 16),
                        const SizedBox(width: 8),
                        Text('Cerrar sesion'),
                      ],
                    ),
                  ),
                ],
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: widget.user.photoURL != null
                      ? NetworkImage(widget.user.photoURL!)
                      : null,
                  child: widget.user.photoURL == null
                      ? const Icon(Icons.person, size: 18)
                      : null,
                ),
              ),
            ),
            title: const Text('Horario de Estudio'),
            actions: [
              IconButton(
                tooltip: 'Ajustes',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SettingsPage(
                        user: widget.user,
                        settings: widget.settings,
                        onSettingsChanged: widget.onSettingsChanged,
                        onSignOut: _signOut,
                        onDeleteAllSchedules: _controller.clearAllItems,
                      ),
                    ),
                  );
                },
                icon: SvgPicture.asset(
                  'assets/svg/settings-svgrepo-com.svg',
                  width: 22,
                  height: 22,
                ),
              ),
            ],
          ),
          body: _buildBody(),
          floatingActionButton: FloatingActionButton(
            onPressed: _openAddDialog,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.items.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: SvgPicture.asset(
                'assets/svg/notification-bell-1398-svgrepo-com.svg',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay horarios aun.\nAgrega uno con el boton +',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    final filteredItems = _controller.items.where((item) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      return item.subject.toLowerCase().contains(query) ||
          item.day.toLowerCase().contains(query) ||
          item.notes.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar materia...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Text(
                    'No hay resultados para esa busqueda',
                    textAlign: TextAlign.center,
                  ),
                )
              : ScheduleList(
                  items: filteredItems,
                  onDelete: (item) => _deleteItem(item.id),
                  use24HourFormat: widget.settings.use24HourFormat,
                ),
        ),
      ],
    );
  }
}
