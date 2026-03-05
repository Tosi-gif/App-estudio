import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/app_settings.dart';
import '../../auth/data/auth_repository.dart';
import '../../settings/presentation/settings_page.dart';
import '../data/schedule_repository.dart';
import '../domain/schedule_item.dart';
import 'schedule_controller.dart';
import 'widgets/add_schedule_dialog.dart';
import 'widgets/schedule_list.dart';

enum _ProfileMenuAction { signOut }
enum _HomeViewMode { lista, calendario }
enum _ListTab { pendientes, completadas }

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
  _HomeViewMode _viewMode = _HomeViewMode.lista;
  _ListTab _listTab = _ListTab.pendientes;
  DateTime _selectedCalendarDate = DateTime.now();

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
    _controller = ScheduleController(widget.scheduleRepository);
    _controller.load();
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

  Future<void> _editItem(ScheduleItem item) async {
    final updated = await showAddScheduleDialog(
      context: context,
      use24HourFormat: widget.settings.use24HourFormat,
      initialItem: item,
    );
    if (!mounted || updated == null) return;
    try {
      await _controller.updateItem(updated);
      if (!mounted) return;
      _showFeedback('Tarea actualizada con exito');
    } catch (_) {
      if (!mounted) return;
      _showFeedback('No se pudo actualizar la tarea', isError: true);
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

  Future<void> _toggleCompleted(ScheduleItem item, bool completed) async {
    try {
      await _controller.setCompleted(item.id, completed);
      if (!mounted) return;
      _showFeedback(
        completed
            ? 'Tarea marcada como completada'
            : 'Tarea movida a pendientes',
      );
    } catch (_) {
      if (!mounted) return;
      _showFeedback('No se pudo actualizar la tarea', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [Color(0xFF0A1418), Color(0xFF0F1D22)]
                    : const [Color(0xFFF2FAF8), Color(0xFFE7F2EE)],
              ),
            ),
            child: _buildBody(),
          ),
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
      if (_listTab == _ListTab.pendientes && item.isCompleted) return false;
      if (_listTab == _ListTab.completadas && !item.isCompleted) return false;
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      return item.subject.toLowerCase().contains(query) ||
          item.day.toLowerCase().contains(query) ||
          item.notes.toLowerCase().contains(query);
    }).toList();
    filteredItems.sort(_compareItems);

    final tasksForSelectedDate = _controller.items.where((item) {
      if (_listTab == _ListTab.pendientes && item.isCompleted) return false;
      if (_listTab == _ListTab.completadas && !item.isCompleted) return false;
      return _matchesDate(item, _selectedCalendarDate);
    }).toList();
    tasksForSelectedDate.sort(_compareItems);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              Text(
                'Tus horarios',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _viewMode == _HomeViewMode.lista
                    ? '${filteredItems.length} materias'
                    : '${tasksForSelectedDate.length} materias',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<_HomeViewMode>(
            segments: const [
              ButtonSegment<_HomeViewMode>(
                value: _HomeViewMode.lista,
                icon: Icon(Icons.view_list),
                label: Text('Lista'),
              ),
              ButtonSegment<_HomeViewMode>(
                value: _HomeViewMode.calendario,
                icon: Icon(Icons.calendar_month),
                label: Text('Calendario'),
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (value) {
              setState(() {
                _viewMode = value.first;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<_ListTab>(
            segments: const [
              ButtonSegment<_ListTab>(
                value: _ListTab.pendientes,
                icon: Icon(Icons.pending_actions),
                label: Text('Pendientes'),
              ),
              ButtonSegment<_ListTab>(
                value: _ListTab.completadas,
                icon: Icon(Icons.task_alt),
                label: Text('Completadas'),
              ),
            ],
            selected: {_listTab},
            onSelectionChanged: (value) {
              setState(() {
                _listTab = value.first;
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchController,
            enabled: _viewMode == _HomeViewMode.lista,
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
          child: _viewMode == _HomeViewMode.lista
              ? filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          'No hay resultados para esa busqueda',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ScheduleList(
                        items: filteredItems,
                        onDelete: (item) => _deleteItem(item.id),
                        onToggleCompleted: _toggleCompleted,
                        onEdit: _editItem,
                        use24HourFormat: widget.settings.use24HourFormat,
                      )
              : _buildCalendarView(tasksForSelectedDate),
        ),
      ],
    );
  }

  Widget _buildCalendarView(List<ScheduleItem> tasksForSelectedDate) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CalendarDatePicker(
                initialDate: _selectedCalendarDate,
                firstDate: DateTime(DateTime.now().year - 2),
                lastDate: DateTime(DateTime.now().year + 3),
                currentDate: DateTime.now(),
                onDateChanged: (date) {
                  setState(() {
                    _selectedCalendarDate = date;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Tareas del ${_selectedCalendarDate.day.toString().padLeft(2, '0')}/${_selectedCalendarDate.month.toString().padLeft(2, '0')}/${_selectedCalendarDate.year}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: tasksForSelectedDate.isEmpty
              ? const Center(
                  child: Text('No hay tareas para este dia'),
                )
              : ScheduleList(
                  items: tasksForSelectedDate,
                  onDelete: (item) => _deleteItem(item.id),
                  onToggleCompleted: _toggleCompleted,
                  onEdit: _editItem,
                  use24HourFormat: widget.settings.use24HourFormat,
                ),
        ),
      ],
    );
  }

  bool _matchesDate(ScheduleItem item, DateTime selectedDate) {
    final parsed = ScheduleItem.tryParseIsoDate(item.day);
    if (parsed != null) {
      return parsed.year == selectedDate.year &&
          parsed.month == selectedDate.month &&
          parsed.day == selectedDate.day;
    }
    return _matchesLegacyWeekday(item.day, selectedDate.weekday);
  }

  bool _matchesLegacyWeekday(String day, int weekday) {
    switch (day.toLowerCase()) {
      case 'lunes':
        return weekday == DateTime.monday;
      case 'martes':
        return weekday == DateTime.tuesday;
      case 'miercoles':
      case 'miércoles':
        return weekday == DateTime.wednesday;
      case 'jueves':
        return weekday == DateTime.thursday;
      case 'viernes':
        return weekday == DateTime.friday;
      case 'sabado':
      case 'sábado':
        return weekday == DateTime.saturday;
      case 'domingo':
        return weekday == DateTime.sunday;
      default:
        return false;
    }
  }

  int _compareItems(ScheduleItem a, ScheduleItem b) {
    switch (widget.settings.sortCriterion) {
      case AppSortCriterion.date:
        return _compareByDateThenTime(a, b);
      case AppSortCriterion.priority:
        final byPriority = _priorityWeight(a.priority).compareTo(
          _priorityWeight(b.priority),
        );
        if (byPriority != 0) return byPriority;
        return _compareByDateThenTime(a, b);
      case AppSortCriterion.subject:
        final bySubject = a.subject.toLowerCase().compareTo(
          b.subject.toLowerCase(),
        );
        if (bySubject != 0) return bySubject;
        return _compareByDateThenTime(a, b);
    }
  }

  int _compareByDateThenTime(ScheduleItem a, ScheduleItem b) {
    final dateA = _dateForSorting(a);
    final dateB = _dateForSorting(b);
    final byDate = dateA.compareTo(dateB);
    if (byDate != 0) return byDate;

    final byStartHour = a.startHour.compareTo(b.startHour);
    if (byStartHour != 0) return byStartHour;

    final byStartMinute = a.startMinute.compareTo(b.startMinute);
    if (byStartMinute != 0) return byStartMinute;

    final byPriority = _priorityWeight(a.priority).compareTo(
      _priorityWeight(b.priority),
    );
    if (byPriority != 0) return byPriority;

    return a.subject.toLowerCase().compareTo(b.subject.toLowerCase());
  }

  DateTime _dateForSorting(ScheduleItem item) {
    final parsed = ScheduleItem.tryParseIsoDate(item.day);
    if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);

    final now = DateTime.now();
    final weekday = _weekdayFromLegacyDay(item.day);
    if (weekday == null) return DateTime(now.year, now.month, now.day);
    final offset = (weekday - now.weekday) % 7;
    final next = now.add(Duration(days: offset));
    return DateTime(next.year, next.month, next.day);
  }

  int _priorityWeight(String priority) {
    switch (priority.toLowerCase()) {
      case 'alta':
        return 0;
      case 'media':
        return 1;
      case 'baja':
        return 2;
      default:
        return 1;
    }
  }

  int? _weekdayFromLegacyDay(String day) {
    switch (day.toLowerCase()) {
      case 'lunes':
        return DateTime.monday;
      case 'martes':
        return DateTime.tuesday;
      case 'miercoles':
      case 'miércoles':
        return DateTime.wednesday;
      case 'jueves':
        return DateTime.thursday;
      case 'viernes':
        return DateTime.friday;
      case 'sabado':
      case 'sábado':
        return DateTime.saturday;
      case 'domingo':
        return DateTime.sunday;
      default:
        return null;
    }
  }
}
