import 'package:flutter/material.dart';

import '../services/settings_service.dart';

class SettingsSupportScreen extends StatefulWidget {
  const SettingsSupportScreen({super.key});

  @override
  State<SettingsSupportScreen> createState() => _SettingsSupportScreenState();
}

class _SettingsSupportScreenState extends State<SettingsSupportScreen> {
  int _selectedSection = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajustes y soporte',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: IndexedStack(
        index: _selectedSection,
        children: [
          _buildSettings(),
          _buildSupport(),
          _buildPermissions(),
          _buildInformation(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedSection,
        onDestinationSelected: (index) {
          setState(() => _selectedSection = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Ajustes',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build_rounded),
            label: 'Soporte',
          ),
          NavigationDestination(
            icon: Icon(Icons.lock_outline_rounded),
            selectedIcon: Icon(Icons.lock_rounded),
            label: 'Permisos',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline_rounded),
            selectedIcon: Icon(Icons.info_rounded),
            label: 'Información',
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('AJUSTES'),
        _option(
          icon: Icons.settings_rounded,
          title: 'Ajustes generales',
          subtitle: 'Preferencias generales de ARTattoo',
          onTap: _showGeneralSettings,
        ),
        _option(
          icon: Icons.motion_photos_auto_rounded,
          title: 'Animaciones',
          subtitle: 'Transiciones y efectos visuales de ARTattoo',
          onTap: _showAnimationSettings,
        ),
        _option(
          icon: Icons.palette_outlined,
          title: 'Apariencia',
          subtitle: 'Tema claro, oscuro o automático',
          onTap: _showAppearanceSettings,
        ),
        _option(
          icon: Icons.image_rounded,
          title: 'Calidad y exportación',
          subtitle: 'Preparado para la configuración de calidad',
          onTap: _showQualitySettings,
        ),
        _option(
          icon: Icons.auto_awesome_rounded,
          title: 'IA y servicios online',
          subtitle: 'APIs y proveedores online',
          onTap: _showOnlineSettings,
        ),
        _option(
          icon: Icons.cleaning_services_rounded,
          title: 'Caché y almacenamiento',
          subtitle: 'Gestión de archivos temporales',
          onTap: _showStorageSettings,
        ),
        _option(
          icon: Icons.restart_alt_rounded,
          title: 'Restablecer configuración',
          subtitle: 'Volver a los valores predeterminados',
          onTap: _resetSettings,
        ),
      ],
    );
  }

  Future<void> _showAppearanceSettings() async {
    final currentMode = SettingsService.themeModeNotifier.value;

    final selectedMode = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Apariencia',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                subtitle: Text('Selecciona cómo quieres ver ARTattoo'),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                groupValue: currentMode,
                title: const Text('Sistema'),
                subtitle: const Text('Usar la configuración del dispositivo'),
                secondary: const Icon(Icons.settings_suggest_rounded),
                onChanged: (value) => Navigator.pop(sheetContext, value),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                groupValue: currentMode,
                title: const Text('Claro'),
                subtitle: const Text('Usar siempre el tema claro'),
                secondary: const Icon(Icons.light_mode_rounded),
                onChanged: (value) => Navigator.pop(sheetContext, value),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: currentMode,
                title: const Text('Oscuro'),
                subtitle: const Text('Usar siempre el tema oscuro'),
                secondary: const Icon(Icons.dark_mode_rounded),
                onChanged: (value) => Navigator.pop(sheetContext, value),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selectedMode == null) return;

    await SettingsService.setThemeMode(selectedMode);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apariencia guardada.')),
    );
  }

  Future<void> _showAnimationSettings() async {
    final enabled = SettingsService.animationsNotifier.value;
    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Animaciones', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              subtitle: Text('Controla las transiciones y efectos visuales.'),
            ),
            SwitchListTile(
              value: enabled,
              title: const Text('Animaciones activas'),
              subtitle: const Text('Recomendado para una experiencia más dinámica.'),
              onChanged: (value) => Navigator.pop(sheetContext, value),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (result == null) return;
    await SettingsService.setAnimationsEnabled(result);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result ? 'Animaciones activadas.' : 'Animaciones desactivadas.')),
    );
  }

  void _showGeneralSettings() {
    _showInfoSheet(
      'Ajustes generales',
      'La base de preferencias está preparada. El idioma, las notificaciones y otras opciones se añadirán sin alterar la configuración actual.',
    );
  }

  void _showQualitySettings() {
    _showInfoSheet(
      'Calidad y exportación',
      'La sección está preparada para incorporar resolución, formato y calidad de exportación cuando se integre el módulo correspondiente.',
    );
  }

  void _showOnlineSettings() {
    _showInfoSheet(
      'IA y servicios online',
      'La sección está preparada para configurar proveedores y APIs online. No se simulan conexiones ni estados de servicio que todavía no estén integrados.',
    );
  }

  void _showStorageSettings() {
    _showInfoSheet(
      'Caché y almacenamiento',
      'La sección está preparada para gestionar caché y archivos temporales. No se eliminará ningún contenido del usuario desde aquí en esta versión.',
    );
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Restablecer configuración'),
          content: const Text(
            'Se restablecerán las preferencias guardadas de ARTattoo. Tus contenidos y conversaciones locales de la aplicación no se modificarán.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Restablecer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await SettingsService.reset();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración restablecida.')),
    );
  }

  Widget _buildSupport() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('SOPORTE TÉCNICO'),
        _option(
          icon: Icons.health_and_safety_rounded,
          title: 'Estado del sistema',
          subtitle: 'Comprobaciones disponibles',
          onTap: () => _showInfoDialog(
            'Estado del sistema',
            'La aplicación está iniciada correctamente. Las comprobaciones avanzadas se activarán al integrar los servicios correspondientes.',
          ),
        ),
        _option(
          icon: Icons.bug_report_rounded,
          title: 'Diagnóstico',
          subtitle: 'Revisión de configuración y contenido',
          onTap: () => _showInfoDialog(
            'Diagnóstico',
            'El diagnóstico avanzado queda preparado para comprobar almacenamiento, red, APIs y recursos cuando esos módulos estén integrados.',
          ),
        ),
        _option(
          icon: Icons.network_check_rounded,
          title: 'Servicios y APIs',
          subtitle: 'Estado de los servicios online',
          onTap: () => _showInfoDialog(
            'Servicios y APIs',
            'Todavía no hay proveedores online conectados en esta versión; por eso no se muestran estados ficticios.',
          ),
        ),
        _option(
          icon: Icons.description_outlined,
          title: 'Registro de errores',
          subtitle: 'Eventos y errores recientes',
          onTap: () => _showInfoDialog(
            'Registro de errores',
            'El sistema de registro avanzado queda reservado para la siguiente integración de diagnóstico.',
          ),
        ),
        _option(
          icon: Icons.build_circle_outlined,
          title: 'Herramientas de reparación',
          subtitle: 'Utilidades de recuperación',
          onTap: () => _showInfoDialog(
            'Herramientas de reparación',
            'No hay acciones destructivas automáticas en esta versión.',
          ),
        ),
      ],
    );
  }

  Widget _buildPermissions() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('PERMISOS Y ACCESOS'),
        _permissionOption(
          Icons.photo_library_outlined,
          'Galería',
          'Acceso a imágenes de referencia',
        ),
        _permissionOption(
          Icons.folder_outlined,
          'Archivos',
          'Acceso al gestor de archivos',
        ),
        _permissionOption(
          Icons.storage_rounded,
          'Almacenamiento',
          'Acceso a almacenamiento de la aplicación',
        ),
        _permissionOption(
          Icons.language_rounded,
          'Internet',
          'Conectividad para servicios online e IA',
        ),
        _permissionOption(
          Icons.security_rounded,
          'Permisos de la aplicación',
          'Revisión de permisos concedidos',
        ),
      ],
    );
  }

  Widget _permissionOption(IconData icon, String title, String subtitle) {
    return _option(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () => _showInfoDialog(
        title,
        'La gestión específica de este permiso se conectará con las APIs nativas de Android cuando se incorpore el módulo de acceso correspondiente.',
      ),
    );
  }

  Widget _buildInformation() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle('INFORMACIÓN'),
        _option(
          icon: Icons.info_outline_rounded,
          title: 'Acerca de ARTattoo',
          subtitle: 'Aplicación educativa para tatuadores',
          onTap: () => _showInfoDialog(
            'Acerca de ARTattoo',
            'ARTattoo Academy PRO\n\nAplicación educativa y técnica para tatuadores.',
          ),
        ),
        _option(
          icon: Icons.verified_outlined,
          title: 'Versión',
          subtitle: 'ARTattoo Academy PRO · 1.1.1',
          onTap: () => _showInfoDialog(
            'Versión',
            'ARTattoo Academy PRO\nVersión 1.1.1',
          ),
        ),
        _option(
          icon: Icons.article_outlined,
          title: 'Licencias',
          subtitle: 'Licencias de las dependencias utilizadas',
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: 'ARTattoo Academy',
              applicationVersion: '1.1.1',
            );
          },
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _option({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  void _showInfoSheet(String title, String message) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
