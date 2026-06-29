Plantilla Spec-First • Proyecto: Curso Bqto App

Estructura tu proyecto antes de escribir una línea de código o prompt
SECCIÓN 1 — Visión del producto

Una aplicación móvil minimalista para que los profesores y alumnos del curso de violonchelo consulten su cronograma de actividades diarias en tiempo real, consolidando los datos dispersos de una hoja de cálculo en una línea de tiempo limpia y organizada.

SECCIÓN 2 — Usuarios y casos de uso

    Usuario Alumno / Profesor (Es el mismo rol de consulta):

        Ve la agenda general del curso organizada cronológicamente.

        Identifica rápidamente en qué bloque horario le toca su actividad mediante resúmenes visuales.

        Revisa los detalles específicos (aula, profesor asignado) de cualquier bloque con un solo toque.

SECCIÓN 3 — Funcionalidades

    Módulo de Filtros:

        El usuario puede abrir un menú desplegable (Dropdown) para seleccionar su nombre de una lista y filtrar el cronograma.

        El sistema permite limpiar el filtro seleccionado para volver a mostrar la agenda completa de todos los participantes.

    Módulo de Cronograma (Calendario):

        El sistema descarga automáticamente los datos crudos desde Google Sheets.

        El sistema limpia la información ignorando filas fantasías o vacías.

        El sistema normaliza los formatos horarios agregando ceros a la izquierda (ej: cambia 9:00 por 09:00) para garantizar un orden cronológico perfecto.

        El sistema agrupa en una sola tarjeta las clases o actividades paralelas que ocurren el mismo día a la misma hora.

        El usuario puede visualizar las actividades separadas claramente por secciones según el día (ej: DÍA 3, DÍA 4).

    Módulo de Detalle:

        El usuario puede presionar cualquier tarjeta horaria para desplegar un panel inferior con el desglose de alumnos, profesores y aulas asignadas a ese bloque.

SECCIÓN 4 — Flujos de usuario

    Flujo 0: Filtrar la agenda por usuario

        El usuario abre la aplicación.

        El usuario selecciona su nombre del menú desplegable.

        El sistema filtra el cronograma y muestra solo las actividades del usuario seleccionado.

    Flujo 1: Consultar la agenda diaria (Happy Path)

        El usuario abre la aplicación.

        La app muestra un indicador de carga mientras descarga los datos de internet.

        Los datos se procesan, ordenan y agrupan en segundo plano.

        La pantalla muestra la lista organizada por días y horas de forma inmediata.

    Flujo 2: Ver detalles de un bloque en paralelo

        El usuario ve una tarjeta que dice: Bloque: ALU-01, ALU-05.

        Hace clic en la tarjeta.

        Se despliega un panel desde abajo mostrando de forma ordenada qué profesor y qué aula le corresponde a cada uno de esos dos alumnos en esa hora específica.

    Flujo 3: Manejo de errores (Camino alternativo)

        Error de conexión: Si el usuario no tiene internet o el servidor falla, el sistema detiene el indicador de carga y muestra un mensaje amigable en pantalla: "No se pudo cargar el cronograma. Verifica tu conexión".

        Datos vacíos: Si el Sheets no tiene clases registradas, el sistema muestra el texto: "No hay clases registradas".

SECCIÓN 5 — Arquitectura

    Frontend: Flutter (Aplicación móvil multiplataforma, probada en Android/iOS) usando arquitectura limpia y un Gestor de Estado (Store) para separar la lógica de la vista.

    Backend: Sin backend propio (Serverless). Se conecta directamente a la API Web de Google Apps Script.

    Almacenamiento de datos: Google Sheets como base de datos de lectura remota.

SECCIÓN 6 — Requisitos no funcionales

    Rendimiento: El procesamiento, ordenamiento y agrupamiento de los datos en memoria debe ser imperceptible (carga inicial en menos de 2 segundos en redes móviles convencionales).

    Idioma: Español como idioma nativo de la interfaz.

    Confiabilidad: Manejo robusto de nulos para evitar pantallas rojas en Flutter si el usuario final escribe mal o deja celdas incompletas en la hoja de cálculo.