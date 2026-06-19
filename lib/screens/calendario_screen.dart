import 'package:flutter/material.dart';
import '../services/actividad_services.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  final ActividadService _actividadService = ActividadService();
  String? _idAlumnoSeleccionado;
  String? _diaSeleccionado;
  late Future<Map<String, dynamic>> _fetchFuture;
  int _indiceActual = 0;

  @override
  void initState() {
    super.initState();
    _fetchFuture = _actividadService.obtenerActividades();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _indiceActual == 0 ? 'CURSO VIOLONCHELO' : 'INFORMACIÓN',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: IndexedStack(
        index: _indiceActual,
        children: [
          _buildPaginaCalendario(),
          _buildPaginaInformacion(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _indiceActual,
          onTap: (index) => setState(() => _indiceActual = index),
          backgroundColor: const Color(0xFF121212),
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey.shade600,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Calendario',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              activeIcon: Icon(Icons.info),
              label: 'Información',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginaCalendario() {
    return FutureBuilder<Map<String, dynamic>>(
        future: _fetchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sincronizando cronograma...',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? {};
          final masterAlumnos = data['Master_Alumnos'] as List<dynamic>? ?? [];
          final calendarioCurso = data['Calendario_Curso'] as List<dynamic>? ?? [];

          // Crear mapa de búsqueda para nombres de alumnos
          final Map<String, String> mapeoAlumnos = {
            for (var a in masterAlumnos)
              a['ID'].toString().trim(): (
                "${a['Nombre']?.toString().trim() ?? ''} ${a['Apellido']?.toString().trim() ?? ''}"
              ).trim()
          };

          if (snapshot.hasError || (calendarioCurso.isEmpty && masterAlumnos.isEmpty)) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade700),
                  const SizedBox(height: 16),
                  const Text('No se pudo cargar el cronograma'),
                  TextButton(
                    onPressed: () => setState(() {
                      _fetchFuture = _actividadService.obtenerActividades();
                    }),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          // Filtrar alumnos para el dropdown (excluyendo ALU-TODOS)
          final listaDropdown = masterAlumnos.where((a) {
            final id = a['ID']?.toString().trim() ?? '';
            return id.isNotEmpty && id != 'ALU-TODOS';
          }).toList();

          // Ordenar alfabéticamente por nombre completo
          listaDropdown.sort((a, b) {
            final idA = a['ID'].toString().trim();
            final idB = b['ID'].toString().trim();
            final nombreA = (mapeoAlumnos[idA] ?? idA).toLowerCase();
            final nombreB = (mapeoAlumnos[idB] ?? idB).toLowerCase();
            return nombreA.compareTo(nombreB);
          });

          // Obtener lista única de días disponibles
          final setDias = calendarioCurso.map((e) {
            final diaRaw = e['Dia'] ?? e['Día'] ?? e['dia'] ?? '3';
            return 'Día $diaRaw';
          }).toSet().toList();
          setDias.sort();

          if (_diaSeleccionado == null && setDias.isNotEmpty) {
            _diaSeleccionado = setDias.first;
          }

          // Lógica de filtrado de actividades (Primero por Alumno)
          List<dynamic> filtrado = calendarioCurso;
          if (_idAlumnoSeleccionado != null) {
            filtrado = calendarioCurso.where((clase) {
              final id = clase['ID Alumno']?.toString().trim() ?? '';
              return id == _idAlumnoSeleccionado || id == 'ALU-TODOS';
            }).toList();
          }

          // Luego filtrar por Día seleccionado
          final calendarioFiltrado = filtrado.where((clase) {
            final diaRaw = clase['Dia'] ?? clase['Día'] ?? clase['dia'] ?? '3';
            return 'Día $diaRaw' == _diaSeleccionado;
          }).toList();

          final bloquesHorarios = _agruparPorDiaYHora(calendarioFiltrado);

          return Column(
            children: [
              // Selector de Alumno (DropdownMenu con búsqueda)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: DropdownMenu<String>(
                  width: MediaQuery.of(context).size.width - 32,
                  initialSelection: _idAlumnoSeleccionado,
                  hintText: "Buscar alumno...",
                  enableSearch: true,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  leadingIcon: const Icon(Icons.search, size: 20),
                  trailingIcon: Icon(Icons.keyboard_arrow_down, color: Theme.of(context).colorScheme.primary),
                  selectedTrailingIcon: Icon(Icons.keyboard_arrow_up, color: Theme.of(context).colorScheme.primary),
                  textStyle: const TextStyle(fontSize: 16),
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStateProperty.all(const Color(0xFF1E1E1E)),
                    elevation: WidgetStateProperty.all(8),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                  ),
                  dropdownMenuEntries: [
                    const DropdownMenuEntry<String>(
                      value: 'TODOS_FILTRO',
                      label: "Ver todos los alumnos",
                      leadingIcon: Icon(Icons.groups_outlined, size: 18),
                    ),
                    ...listaDropdown.map((a) {
                      final id = a['ID'].toString().trim();
                      final nombreCompleto = mapeoAlumnos[id] ?? id;
                      return DropdownMenuEntry<String>(
                        value: id,
                        label: nombreCompleto,
                        leadingIcon: const Icon(Icons.person_outline, size: 18),
                      );
                    }),
                  ],
                  onSelected: (String? nuevoId) {
                    setState(() {
                      _idAlumnoSeleccionado = (nuevoId == 'TODOS_FILTRO') ? null : nuevoId;
                    });
                  },
                ),
              ),

              // Selector de Día (Tabs personalizados)
              if (setDias.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: setDias.map((dia) {
                      final esSeleccionado = _diaSeleccionado == dia;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _diaSeleccionado = dia),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: EdgeInsets.only(
                              right: dia == setDias.last ? 0 : 8,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: esSeleccionado 
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: esSeleccionado 
                                    ? Theme.of(context).colorScheme.primary 
                                    : Colors.white.withOpacity(0.05),
                                width: esSeleccionado ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              dia.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: esSeleccionado 
                                    ? Theme.of(context).colorScheme.primary 
                                    : Colors.grey.shade500,
                                fontWeight: esSeleccionado ? FontWeight.w900 : FontWeight.w600,
                                fontSize: 13,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              Expanded(
                child: bloquesHorarios.isEmpty 
                  ? Center(
                      child: Text(
                        'No hay actividades para este alumno',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: bloquesHorarios.length,
                      itemBuilder: (context, index) {
              final bloque = bloquesHorarios[index];

              bool mostrarEncabezadoDia = false;
              if (index == 0) {
                mostrarEncabezadoDia = true;
              } else {
                final bloqueAnterior = bloquesHorarios[index - 1];
                if (bloque['Dia'] != bloqueAnterior['Dia']) {
                  mostrarEncabezadoDia = true;
                }
              }

              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 400 + (index % 10 * 50)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mostrarEncabezadoDia)
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 24, bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              bloque['Dia'].toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _mostrarDetalles(context, bloque, mapeoAlumnos),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              // Bloque Horario
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bloque['Inicio'] ?? '--:--',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  Text(
                                    bloque['Fin'] ?? '--:--',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 24),
                              // Divisor vertical sutil
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white10,
                              ),
                              const SizedBox(width: 24),
                              // Resumen Actividad
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    final listaClases = bloque['listaClases'] as List<dynamic>;
                                    
                                    // Extraer la actividad principal del bloque
                                    final actividadPrincipal = listaClases
                                        .map((c) => c['Actividad']?.toString().trim() ?? '')
                                        .firstWhere((a) => a.isNotEmpty, orElse: () => 'Actividad');

                                    // Extraer y formatear la lista de alumnos
                                    final alumnos = listaClases
                                        .map((c) {
                                          final id = c['ID Alumno']?.toString().trim() ?? '';
                                          return mapeoAlumnos[id] ?? id;
                                        })
                                        .where((n) => n.isNotEmpty && n != 'ALU-TODOS')
                                        .toList();

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          actividadPrincipal.toUpperCase(),
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          alumnos.isEmpty ? 'General' : alumnos.join(', '),
                                          style: const TextStyle(
                                            fontSize: 17, 
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade700),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
                    ),
              ),
            ],
          );
        },
      );
  }

  Widget _buildPaginaInformacion() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Información del Curso',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta sección contendrá información relevante sobre el curso de violonchelo, '
              'reglamentos y avisos importantes para todos los participantes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalles(BuildContext context, Map<String, dynamic> bloque, Map<String, String> mapeoAlumnos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        final listaClases = bloque['listaClases'] as List<dynamic>;
        final clasesValidas = listaClases.where((c) {
          final act = c['Actividad']?.toString().trim() ?? '';
          final alu = c['ID Alumno']?.toString().trim() ?? '';
          return act.isNotEmpty || alu.isNotEmpty;
        }).toList();

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bloque['Dia'],
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '${bloque['Inicio']} — ${bloque['Fin']}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              ...clasesValidas.map((clase) {
                final esClase = clase['ID Alumno']?.toString().isNotEmpty == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          esClase ? Icons.person_outline : Icons.music_note,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              esClase 
                                ? (mapeoAlumnos[clase['ID Alumno']?.toString().trim()] ?? clase['ID Alumno'].toString()) 
                                : (clase['Actividad'] ?? 'Actividad'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                            if (esClase && clase['Actividad'] != null)
                              Text(
                                clase['Actividad'],
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                              ),
                          ],
                        ),
                      ),
                      if (clase['Profesor']?.toString().isNotEmpty == true)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('PROF.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                            Text(
                              clase['Profesor'],
                              style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // --- FUNCIÓN DE AGRUPAMIENTO CRONOLÓGICO Y NORMALIZACIÓN ---
  List<Map<String, dynamic>> _agruparPorDiaYHora(List<dynamic> clasesCrudas) {
    final Map<String, List<dynamic>> bloques = {};

    for (var clase in clasesCrudas) {
      final diaRaw = clase['Dia'] ?? clase['Día'] ?? clase['dia'] ?? '3';
      final dia = 'Día ${diaRaw.toString()}';
      
      var horaInicio = (clase['Inicio'] ?? '--:--').toString().trim();
      
      // Formateo de seguridad: cambia "9:00" por "09:00" para no romper orden alfabético
      if (horaInicio.isNotEmpty && horaInicio.contains(':') && horaInicio.length == 4) {
        horaInicio = '0$horaInicio';
      }
      
      final llaveUnica = '$dia|$horaInicio';
      
      if (!bloques.containsKey(llaveUnica)) {
        bloques[llaveUnica] = [];
      }
      bloques[llaveUnica]!.add(clase);
    }

    final listaAgrupada = bloques.entries.map((entrada) {
      final partes = entrada.key.split('|');
      final clasesDelBloque = entrada.value;
      
      var horaFin = (clasesDelBloque.first['Fin'] ?? '--:--').toString().trim();
      if (horaFin.isNotEmpty && horaFin.contains(':') && horaFin.length == 4) {
        horaFin = '0$horaFin';
      }
      
      return {
        'Dia': partes[0],
        'Inicio': partes[1],
        'Fin': horaFin,
        'listaClases': clasesDelBloque,
      };
    }).where((bloque) {
      // Filtramos bloques que no tengan ninguna actividad real
      final lista = bloque['listaClases'] as List<dynamic>;
      return lista.any((c) {
        final alu = c['ID Alumno']?.toString().trim() ?? '';
        final act = c['Actividad']?.toString().trim() ?? '';
        return alu.isNotEmpty || act.isNotEmpty;
      });
    }).toList();

    // Ordenamiento estricto por Día y luego por Hora de Inicio
    listaAgrupada.sort((a, b) {
      String diaA = a['Dia'].toString();
      String diaB = b['Dia'].toString();
      int compDia = diaA.compareTo(diaB);
      
      if (compDia != 0) return compDia;
      
      return (a['Inicio'] as String).compareTo(b['Inicio'] as String);
    });

    return listaAgrupada;
  }
}