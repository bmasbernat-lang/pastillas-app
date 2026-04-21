import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vmkqnkdnptchdgqhrkex.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZta3Fua2RucHRjaGRncWhya2V4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1NzkwMDUsImV4cCI6MjA5MjE1NTAwNX0.XNKgj7jry4WrOCTzykWmwlUXb5mRvSETHDDow_mg0U4',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pastillas App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange, useMaterial3: true),
      home: const RolSelectorPage(),
    );
  }
}

// ==================== SELECCIÓN DE ROL ====================
class RolSelectorPage extends StatefulWidget {
  const RolSelectorPage({super.key});

  @override
  State<RolSelectorPage> createState() => _RolSelectorPageState();
}

class _RolSelectorPageState extends State<RolSelectorPage> {
  String _codigoAcceso = '';
  String _mensajeError = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange, Colors.deepOrange],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.medication, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  'Pastillas App',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 40),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text('¿Eres familiar o paciente?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const FamiliarHomePage()),
                          ),
                          icon: const Icon(Icons.family_restroom),
                          label: const Text('SOY FAMILIAR (Control total)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('O', style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Código del paciente',
                            hintText: 'Introduce el código de tu familiar',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.qr_code),
                            errorText: _mensajeError.isEmpty ? null : _mensajeError,
                          ),
                          onChanged: (value) => setState(() => _codigoAcceso = value.trim()),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_codigoAcceso.isEmpty) {
                              setState(() => _mensajeError = 'Introduce el código de acceso');
                              return;
                            }
                            setState(() => _mensajeError = '');
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PacienteHomePage(codigoPaciente: _codigoAcceso),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person),
                          label: const Text('SOY PACIENTE (Solo avisos)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Los pacientes necesitan un código que les dará su familiar',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== FAMILIAR (CONTROL TOTAL) ====================
class FamiliarHomePage extends StatefulWidget {
  const FamiliarHomePage({super.key});

  @override
  State<FamiliarHomePage> createState() => _FamiliarHomePageState();
}

class _FamiliarHomePageState extends State<FamiliarHomePage> {
  final _nombreController = TextEditingController();
  final _dosisController = TextEditingController();
  final _laboratorioController = TextEditingController();
  final _precioController = TextEditingController();
  final _codigoPacienteController = TextEditingController();

  DateTime? _fechaCaducidad;
  int _cantidad = 0;
  bool _tieneRecordatorio = false;
  TimeOfDay? _horaRecordatorio;
  bool _guardando = false;
  bool _buscando = false;
  
  // Para resultados de búsqueda
  List<Map<String, dynamic>> _resultadosBusqueda = [];

  @override
  void dispose() {
    _nombreController.dispose();
    _dosisController.dispose();
    _laboratorioController.dispose();
    _precioController.dispose();
    _codigoPacienteController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaCaducidad() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _fechaCaducidad = picked);
  }

  Future<void> _seleccionarHoraRecordatorio() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      setState(() {
        _horaRecordatorio = picked;
        _tieneRecordatorio = true;
      });
    }
  }

  // Buscar en CIMA por NOMBRE con resultados múltiples
  Future<void> _buscarPorNombre(String nombre) async {
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un nombre para buscar')),
      );
      return;
    }
    setState(() => _buscando = true);
    try {
      final url = 'https://cima.aemps.es/cima/rest/medicamentos?nombre=${Uri.encodeComponent(nombre)}';
      final response = await http.get(Uri.parse(url), headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        List<dynamic> resultados = [];
        if (data is Map && data['resultados'] != null) {
          resultados = data['resultados'] as List<dynamic>;
        } else if (data is List) {
          resultados = data;
        }

        if (resultados.isNotEmpty) {
          setState(() {
            _resultadosBusqueda = resultados.map((e) => Map<String, dynamic>.from(e)).toList();
            _buscando = false;
          });
        } else {
          setState(() => _buscando = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('⚠️ No se encontraron resultados'), backgroundColor: Colors.orange),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _buscando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Rellena los campos con los datos seleccionados
  void _seleccionarMedicamento(Map<String, dynamic> med) {
    String principioActivo = '';
    if (med['pactivos'] != null && (med['pactivos'] as List).isNotEmpty) {
      principioActivo = (med['pactivos'] as List).first['nombre']?.toString() ?? '';
    }
    setState(() {
      _nombreController.text = med['nombre']?.toString() ?? '';
      _dosisController.text = principioActivo;
      _laboratorioController.text = med['labt']?.toString() ?? med['laboratorio']?.toString() ?? '';
      _resultadosBusqueda = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Seleccionado: ${med['nombre']}'), backgroundColor: Colors.green),
    );
  }

  // Compartir código del paciente
  void _compartirCodigo() {
    final codigo = _codigoPacienteController.text.trim();
    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero escribe un código de paciente'), backgroundColor: Colors.red),
      );
      return;
    }
    Share.share(
      '💊 Tu código para ver tus medicamentos en Pastillas App es:\n\n*$codigo*\n\nIntrodúcelo en la app cuando te pida el código de paciente.',
      subject: 'Tu código de Pastillas App',
    );
  }

  Future<void> _guardar() async {
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe o selecciona un medicamento')),
      );
      return;
    }
    if (_codigoPacienteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce el código del paciente'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final data = {
        'nombre': _nombreController.text.trim(),
        'dosis': _dosisController.text.trim().isEmpty ? 'Sin especificar' : _dosisController.text.trim(),
        'laboratorio': _laboratorioController.text.trim(),
        'precio': double.tryParse(_precioController.text.trim()) ?? 0,
        'fecha_caducidad': _fechaCaducidad?.toIso8601String(),
        'cantidad': _cantidad,
        'horario': _tieneRecordatorio && _horaRecordatorio != null
            ? '${_horaRecordatorio!.hour.toString().padLeft(2, '0')}:${_horaRecordatorio!.minute.toString().padLeft(2, '0')}'
            : null,
        'codigo_paciente': _codigoPacienteController.text.trim(),
        'ultima_toma': null,
        'created_at': DateTime.now().toIso8601String(),
      };
      await Supabase.instance.client.from('pastillas').insert(data);

      _nombreController.clear();
      _dosisController.clear();
      _laboratorioController.clear();
      _precioController.clear();
      setState(() {
        _fechaCaducidad = null;
        _cantidad = 0;
        _tieneRecordatorio = false;
        _horaRecordatorio = null;
        _resultadosBusqueda = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Medicamento guardado correctamente'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAMILIAR - Control'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ListaFamiliarPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RolSelectorPage()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Código del paciente
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('CÓDIGO DEL PACIENTE', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _codigoPacienteController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                      decoration: InputDecoration(
                        hintText: 'Ej: MAMA2024',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _compartirCodigo,
                      icon: const Icon(Icons.share),
                      label: const Text('Compartir código por WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Usa siempre el mismo código para el mismo paciente',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Campo nombre
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: '💊 Nombre del medicamento *',
                hintText: 'Ej: Paracetamol, Tadalafilo...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            // Botón buscar
            ElevatedButton.icon(
              onPressed: _buscando ? null : () => _buscarPorNombre(_nombreController.text),
              icon: _buscando
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search),
              label: Text(_buscando ? 'Buscando...' : '🔍 Buscar en BOT PLUS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),

            // Resultados de búsqueda (desplegable)
            if (_resultadosBusqueda.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(top: 8),
                child: Column(
                  children: _resultadosBusqueda.map((med) {
                    return ListTile(
                      leading: const Icon(Icons.medication, color: Colors.orange),
                      title: Text(med['nombre'] ?? 'Sin nombre'),
                      subtitle: Text(
                        '${med['principioActivo'] ?? ''} | ${med['laboratorio'] ?? ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _seleccionarMedicamento(med),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 12),

            // Dosis
            TextField(
              controller: _dosisController,
              decoration: const InputDecoration(
                labelText: '⏰ Principio activo / Dosis',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Laboratorio
            TextField(
              controller: _laboratorioController,
              decoration: const InputDecoration(
                labelText: '🏭 Laboratorio',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Precio
            TextField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: '💰 Precio (€)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),

            // Fecha caducidad
            ListTile(
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.calendar_today, color: Colors.orange),
              title: Text(_fechaCaducidad == null
                  ? '📅 Fecha de caducidad'
                  : 'Caduca: ${_fechaCaducidad!.day}/${_fechaCaducidad!.month}/${_fechaCaducidad!.year}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _seleccionarFechaCaducidad,
            ),
            const SizedBox(height: 12),

            // Cantidad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('📦 Cantidad: $_cantidad'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () => setState(() => _cantidad = _cantidad > 0 ? _cantidad - 1 : 0),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => _cantidad++),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Recordatorio
            ListTile(
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.notifications, color: Colors.orange),
              title: Text(_tieneRecordatorio && _horaRecordatorio != null
                  ? '⏰ Recordatorio: ${_horaRecordatorio!.format(context)}'
                  : '🔔 Configurar recordatorio'),
              trailing: Switch(
                value: _tieneRecordatorio,
                onChanged: (value) {
                  if (value && _horaRecordatorio == null) {
                    _seleccionarHoraRecordatorio();
                  } else {
                    setState(() => _tieneRecordatorio = value);
                  }
                },
                activeColor: Colors.orange,
              ),
              onTap: _seleccionarHoraRecordatorio,
            ),
            const SizedBox(height: 20),

            // Botón guardar
            _guardando
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    child: const Text(
                      '💾 GUARDAR MEDICAMENTO',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ==================== LISTA PARA FAMILIAR ====================
class ListaFamiliarPage extends StatefulWidget {
  const ListaFamiliarPage({super.key});

  @override
  State<ListaFamiliarPage> createState() => _ListaFamiliarPageState();
}

class _ListaFamiliarPageState extends State<ListaFamiliarPage> {
  List<Map<String, dynamic>> _medicamentos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final response = await Supabase.instance.client
          .from('pastillas')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _medicamentos = List<Map<String, dynamic>>.from(response);
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _eliminar(String id, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar'),
        content: Text('¿Eliminar "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await Supabase.instance.client.from('pastillas').delete().eq('id', id);
    await _cargar();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ "$nombre" eliminado'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TODOS LOS MEDICAMENTOS'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar)],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _medicamentos.isEmpty
              ? const Center(child: Text('No hay medicamentos guardados'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _medicamentos.length,
                  itemBuilder: (context, index) {
                    final med = _medicamentos[index];
                    return Dismissible(
                      key: Key(med['id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) => _eliminar(med['id'].toString(), med['nombre']),
                      child: Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.medication)),
                          title: Text(med['nombre']),
                          subtitle: Text(
                            '${med['dosis'] ?? ''} | ${med['cantidad'] ?? 0} uds | ${med['horario'] ?? 'Sin horario'}\n🔑 Código: ${med['codigo_paciente'] ?? ''}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _mostrarDetalles(med),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.arrow_back),
      ),
    );
  }

  void _mostrarDetalles(Map<String, dynamic> med) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(med['nombre']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('💊 Dosis: ${med['dosis'] ?? "Sin especificar"}'),
            const SizedBox(height: 8),
            Text('🏭 Laboratorio: ${med['laboratorio'] ?? "No especificado"}'),
            const SizedBox(height: 8),
            Text('💰 Precio: ${med['precio'] != null ? "${med['precio']} €" : "No especificado"}'),
            const SizedBox(height: 8),
            Text('📦 Cantidad: ${med['cantidad'] ?? 0} unidades'),
            const SizedBox(height: 8),
            Text('📅 Caducidad: ${med['fecha_caducidad'] != null ? med['fecha_caducidad'].toString().substring(0, 10) : "No especificada"}'),
            const SizedBox(height: 8),
            Text('🔔 Recordatorio: ${med['horario'] ?? "No configurado"}'),
            const SizedBox(height: 8),
            Text('🔑 Código paciente: ${med['codigo_paciente'] ?? ""}'),
          ],
        ),
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

// ==================== PACIENTE (SOLO VER Y CONFIRMAR) ====================
class PacienteHomePage extends StatefulWidget {
  final String codigoPaciente;
  const PacienteHomePage({super.key, required this.codigoPaciente});

  @override
  State<PacienteHomePage> createState() => _PacienteHomePageState();
}

class _PacienteHomePageState extends State<PacienteHomePage> {
  List<Map<String, dynamic>> _medicamentos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final response = await Supabase.instance.client
          .from('pastillas')
          .select()
          .eq('codigo_paciente', widget.codigoPaciente);

      setState(() {
        _medicamentos = List<Map<String, dynamic>>.from(response);
        _cargando = false;
      });

      if (_medicamentos.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ No se encontraron medicamentos para el código "${widget.codigoPaciente}"'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _confirmarToma(Map<String, dynamic> med) async {
    try {
      await Supabase.instance.client
          .from('pastillas')
          .update({'ultima_toma': DateTime.now().toIso8601String()})
          .eq('id', med['id']);

      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Toma confirmada: ${med['nombre']}'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MIS MEDICAMENTOS'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RolSelectorPage()),
            ),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _medicamentos.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No tienes medicamentos asignados', style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text('Código usado: "${widget.codigoPaciente}"\n\nVerifica que el código es correcto con tu familiar.', style: const TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton(onPressed: _cargar, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _medicamentos.length,
                  itemBuilder: (context, index) {
                    final med = _medicamentos[index];
                    final necesitaToma = med['horario'] != null &&
                        (med['ultima_toma'] == null || DateTime.parse(med['ultima_toma']).day != DateTime.now().day);
                    final estaCaducado = med['fecha_caducidad'] != null &&
                        DateTime.parse(med['fecha_caducidad']).isBefore(DateTime.now());

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: estaCaducado
                              ? Colors.red.shade100
                              : (necesitaToma ? Colors.orange.shade100 : Colors.green.shade100),
                          child: Icon(
                            estaCaducado
                                ? Icons.warning
                                : (necesitaToma ? Icons.notifications_active : Icons.check_circle),
                            color: estaCaducado
                                ? Colors.red
                                : (necesitaToma ? Colors.orange : Colors.green),
                          ),
                        ),
                        title: Text(
                          med['nombre'],
                          style: TextStyle(decoration: estaCaducado ? TextDecoration.lineThrough : null),
                        ),
                        subtitle: Text(
                          '${med['dosis'] ?? ''} | ${med['cantidad'] ?? 0} uds${med['horario'] != null ? ' | ⏰ ${med['horario']}' : ''}',
                        ),
                        trailing: necesitaToma && !estaCaducado
                            ? ElevatedButton(
                                onPressed: () => _confirmarToma(med),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Tomado'),
                              )
                            : null,
                        onTap: () => _mostrarDetalles(med),
                      ),
                    );
                  },
                ),
    );
  }

  void _mostrarDetalles(Map<String, dynamic> med) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(med['nombre']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('💊 Dosis: ${med['dosis'] ?? "Sin especificar"}'),
            const SizedBox(height: 8),
            Text('🏭 Laboratorio: ${med['laboratorio'] ?? "No especificado"}'),
            const SizedBox(height: 8),
            Text('💰 Precio: ${med['precio'] != null ? "${med['precio']} €" : "No especificado"}'),
            const SizedBox(height: 8),
            Text('📦 Cantidad: ${med['cantidad'] ?? 0} unidades'),
            const SizedBox(height: 8),
            Text('📅 Caducidad: ${med['fecha_caducidad'] != null ? med['fecha_caducidad'].toString().substring(0, 10) : "No especificada"}'),
            const SizedBox(height: 8),
            Text('🔔 Recordatorio: ${med['horario'] ?? "No configurado"}'),
            const SizedBox(height: 8),
            Text('✅ Última toma: ${med['ultima_toma'] != null ? med['ultima_toma'].toString().substring(0, 16) : "Nunca"}'),
          ],
        ),
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