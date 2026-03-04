import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/app_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.user,
    required this.settings,
    required this.onSettingsChanged,
    required this.onSignOut,
    required this.onDeleteAllSchedules,
  });

  final User user;
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onDeleteAllSchedules;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late AppSettings _current;

  @override
  void initState() {
    super.initState();
    _current = widget.settings;
  }

  void _apply(AppSettings next) {
    setState(() {
      _current = next;
    });
    widget.onSettingsChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _current.theme == AppThemeSetting.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle(label: 'Cuenta'),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: widget.user.photoURL != null
                  ? NetworkImage(widget.user.photoURL!)
                  : null,
              child: widget.user.photoURL == null ? const Icon(Icons.person) : null,
            ),
            title: Text(widget.user.email ?? 'Sin correo'),
            subtitle: const Text('Sesion activa'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, size: 18),
            title: const Text('Cerrar sesion'),
            onTap: widget.onSignOut,
          ),
          const SizedBox(height: 12),
          const _SectionTitle(label: 'General'),
          SwitchListTile(
            title: const Text('Modo oscuro'),
            subtitle: const Text('Activa un tema oscuro para toda la app'),
            value: isDarkMode,
            onChanged: (value) {
              _apply(
                _current.copyWith(
                  theme: value ? AppThemeSetting.dark : AppThemeSetting.light,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Notificaciones'),
            subtitle: const Text('Activa o desactiva los recordatorios'),
            value: _current.notificationsEnabled,
            onChanged: (value) {
              _apply(_current.copyWith(notificationsEnabled: value));
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Formato 24 horas'),
            value: _current.use24HourFormat,
            onChanged: (value) {
              _apply(_current.copyWith(use24HourFormat: value));
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AppTextSize>(
            initialValue: _current.textSize,
            decoration: const InputDecoration(
              labelText: 'Tamano de texto',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: AppTextSize.normal,
                child: Text('Normal'),
              ),
              DropdownMenuItem(
                value: AppTextSize.large,
                child: Text('Grande'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              _apply(_current.copyWith(textSize: value));
            },
          ),
          const SizedBox(height: 16),
          const _SectionTitle(label: 'Datos'),
          FilledButton.tonalIcon(
            onPressed: () => _confirmDeleteAll(context),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Borrar todos los horarios'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar borrado'),
          content: const Text('Se eliminaran todos los horarios guardados.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
    await widget.onDeleteAllSchedules();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Horarios eliminados correctamente'),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
