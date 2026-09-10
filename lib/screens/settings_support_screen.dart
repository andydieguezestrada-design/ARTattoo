import 'package:flutter/material.dart';

import '../services/ai_service.dart';
import '../services/image_quota_service.dart';
import '../services/chat_quota_service.dart';
import '../services/settings_service.dart';

class SettingsSupportScreen extends StatefulWidget {
  const SettingsSupportScreen({super.key});
  @override
  State<SettingsSupportScreen> createState() => _SettingsSupportScreenState();
}

class _SettingsSupportScreenState extends State<SettingsSupportScreen> {
  int _section = 0;
  final _key = TextEditingController();
  final _service = AiService();
  String _model = SettingsService.defaultGeminiModel;
  int _used = 0;
  int _chatUsed = 0;
  bool _obscure = true;

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async { _key.text = await SettingsService.getGeminiApiKey(); _model = await SettingsService.getGeminiModel(); _used = await ImageQuotaService.usedToday(); _chatUsed = await ChatQuotaService.usedToday(); if (mounted) setState(() {}); }
  @override
  void dispose() { _key.dispose(); _service.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ajustes y soporte', style: TextStyle(fontWeight: FontWeight.w900))),
    body: IndexedStack(index: _section, children: [_settings(), _support(), _info()]),
    bottomNavigationBar: NavigationBar(selectedIndex: _section, onDestinationSelected: (v)=>setState(()=>_section=v), destinations: const [NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label:'Ajustes'), NavigationDestination(icon: Icon(Icons.health_and_safety_outlined), selectedIcon: Icon(Icons.health_and_safety), label:'Soporte'), NavigationDestination(icon: Icon(Icons.info_outline), selectedIcon: Icon(Icons.info), label:'Información')]),
  );

  Widget _settings() => ListView(padding: const EdgeInsets.all(18), children: [
    _title('IA Y SERVICIOS ONLINE'),
    Card(child: ListTile(leading: const Icon(Icons.auto_awesome), title: const Text('Gemini API', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(_key.text.isEmpty ? 'No configurada' : 'API key configurada · $_model'), trailing: const Icon(Icons.chevron_right), onTap: _geminiSettings)),
    Card(child: ListTile(leading: const Icon(Icons.image_search_rounded), title: const Text('Análisis de imágenes', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: Text('$_used/${ImageQuotaService.dailyLimit} usados hoy · límite local diario'), trailing: const Icon(Icons.bar_chart_rounded))),
    const SizedBox(height: 16),
    _title('APARIENCIA'),
    Card(child: SwitchListTile(title: const Text('Animaciones'), subtitle: const Text('Transiciones y efectos visuales'), value: SettingsService.animationsNotifier.value, onChanged: SettingsService.setAnimationsEnabled)),
    Card(child: ListTile(title: const Text('Tema'), subtitle: Text(_themeName(SettingsService.themeModeNotifier.value)), trailing: const Icon(Icons.chevron_right), onTap: _theme)),
    const SizedBox(height: 16),
    _title('SISTEMA'),
    Card(child: ListTile(leading: const Icon(Icons.restart_alt), title: const Text('Restablecer configuración'), subtitle: const Text('Borra preferencias y API key guardada'), onTap: _reset)),
  ]);

  Future<void> _geminiSettings() async {
    final controller = TextEditingController(text: _key.text);
    var model = _model;
    await showDialog<void>(context: context, builder: (ctx) => StatefulBuilder(builder: (_, setLocal) => AlertDialog(
      title: const Text('Gemini API'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Pega aquí tu API key de Google AI Studio. Se guarda solo en este dispositivo. No la publiques en GitHub.', style: TextStyle(height: 1.35)),
        const SizedBox(height: 14),
        TextField(controller: controller, obscureText: _obscure, decoration: InputDecoration(labelText:'API key', border: const OutlineInputBorder(), suffixIcon: IconButton(onPressed:()=>setLocal(()=>_obscure=!_obscure), icon: Icon(_obscure?Icons.visibility:Icons.visibility_off)))),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: model, decoration: const InputDecoration(labelText:'Modelo', border: OutlineInputBorder()), items: const [DropdownMenuItem(value:'gemini-2.5-flash', child:Text('Gemini 2.5 Flash')), DropdownMenuItem(value:'gemini-2.5-flash-lite', child:Text('Gemini 2.5 Flash-Lite'))], onChanged:(v){if(v!=null)setLocal(()=>model=v);}),
        const SizedBox(height: 10),
        const Text('El nivel gratuito de Gemini tiene cuotas/rate limits. ARTattoo no promete uso ilimitado.', style: TextStyle(fontSize:12)),
      ])),
      actions: [TextButton(onPressed:()=>Navigator.pop(ctx), child:const Text('Cancelar')), FilledButton(onPressed:() async { await SettingsService.setGeminiApiKey(controller.text); await SettingsService.setGeminiModel(model); _key.text=controller.text; _model=model; if(mounted)setState((){}); if(ctx.mounted)Navigator.pop(ctx); }, child:const Text('Guardar'))],
    )));
    controller.dispose();
  }

  Future<void> _theme() async { final mode=await showModalBottomSheet<ThemeMode>(context:context,showDragHandle:true,builder:(_)=>Column(mainAxisSize:MainAxisSize.min,children:[_themeTile(ThemeMode.system,'Automático'),_themeTile(ThemeMode.light,'Claro'),_themeTile(ThemeMode.dark,'Oscuro'),const SizedBox(height:10)])); if(mode!=null)await SettingsService.setThemeMode(mode); }
  ListTile _themeTile(ThemeMode m,String label)=>ListTile(title:Text(label), trailing:SettingsService.themeModeNotifier.value==m?const Icon(Icons.check):null,onTap:()=>Navigator.pop(context,m));
  String _themeName(ThemeMode m)=>m==ThemeMode.dark?'Oscuro':m==ThemeMode.light?'Claro':'Automático';

  Widget _support()=>ListView(padding:const EdgeInsets.all(18),children:[_title('DIAGNÓSTICO'),Card(child:ListTile(leading:const Icon(Icons.network_check),title:const Text('Probar Gemini'),subtitle:const Text('Comprueba la API key y el modelo configurado'),onTap:_testGemini)),Card(child:ListTile(leading:const Icon(Icons.image_search),title:const Text('Cuota de imágenes'),subtitle:Text('Imágenes: $_used/${ImageQuotaService.dailyLimit} · Chat: $_chatUsed/${ChatQuotaService.dailyLimit} mensajes'))),const SizedBox(height:14),_title('SEGURIDAD'),const Card(child:Padding(padding:EdgeInsets.all(16),child:Text('La API key guardada en una APK puede ser extraída. Para una aplicación pública, la arquitectura recomendada es ARTattoo → servidor propio → Gemini, con la clave protegida en el servidor.',style:TextStyle(height:1.4))))]);
  Future<void> _testGemini() async { try { final key=await SettingsService.getGeminiApiKey(); final model=await SettingsService.getGeminiModel(); await _service.testConnection(apiKey:key,model:model); if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Gemini conectado correctamente.'))); } catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString().replaceFirst('AiServiceException: ',''))));} }
  Widget _info()=>ListView(padding:const EdgeInsets.all(18),children:[_title('ARTATTOO ACADEMY PRO'),const Card(child:Padding(padding:EdgeInsets.all(18),child:Text('Biblioteca técnica de tatuaje, estilos y mentor de IA especializado en tatuaje, dibujo y diseño. Se eliminaron los módulos de ejercicios y clases para concentrar la aplicación en referencia, técnica y asistencia creativa.',style:TextStyle(height:1.45)))),const SizedBox(height:12),const Card(child:ListTile(title:Text('Versión'),subtitle:Text('1.2.0 · Gemini AI · análisis de imágenes'))),Card(child:ListTile(title:const Text('Licencias'),onTap:()=>showLicensePage(context:context,applicationName:'ARTattoo Academy',applicationVersion:'1.2.0')))]);
  Widget _title(String t)=>Padding(padding:const EdgeInsets.fromLTRB(4,4,4,10),child:Text(t,style:TextStyle(color:Theme.of(context).colorScheme.primary,fontSize:12,fontWeight:FontWeight.w900,letterSpacing:1.3)));
  Future<void> _reset() async { final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Restablecer'),content:const Text('Se borrarán las preferencias, incluido el API key guardado localmente.'),actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Restablecer'))])); if(ok==true){await SettingsService.reset();await _load();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Configuración restablecida.')));}}
}
