import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth/data/auth_repository.dart';
import '../data/schedule_repository.dart';
import 'schedule_controller.dart';
import 'widgets/add_schedule_dialog.dart';
import 'widgets/profile_card.dart';
import 'widgets/schedule_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.user,
    required this.authRepository,
    required this.scheduleRepository,
  });

  final User user;
  final AuthRepository authRepository;
  final ScheduleRepository scheduleRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ScheduleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScheduleController(widget.scheduleRepository);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openAddDialog() async {
    final item = await showAddScheduleDialog(
      context: context,
      days: ScheduleController.days,
    );
    if (!mounted || item == null) return;
    await _controller.addItem(item);
  }

  Future<void> _signOut() async {
    await widget.authRepository.signOut();
  }

  Future<void> _deleteItem(String itemId) async {
    await _controller.deleteItem(itemId);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Horario de Estudio'),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesion',
                icon: const Icon(Icons.logout),
                onPressed: _signOut,
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
      return Column(
        children: [
          ProfileCard(user: widget.user),
          const Expanded(
            child: Center(
              child: Text(
                'No hay horarios aun.\nAgrega uno con el boton +',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        ProfileCard(user: widget.user),
        Expanded(
          child: ScheduleList(
            items: _controller.items,
            onDelete: (item) => _deleteItem(item.id),
          ),
        ),
      ],
    );
  }
}
