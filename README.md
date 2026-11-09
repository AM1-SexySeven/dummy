ConectaCruz · Churrasquería El Fogón

Aplicación móvil para conectar a Churrasquería El Fogón con sus clientes en Santa Cruz de la Sierra, Bolivia.

ConectaCruz es una propuesta de aplicación móvil que centraliza la carta de platos con sus respectivos precios, las consultas de los clientes y la gestión de reservas en una sola plataforma.

!Bienvenida de ConectaCruz

Información del proyecto
Dato	Descripción
Proyecto	ConectaCruz · Churrasquería El Fogón
Actividad	Actividad 01
Asignatura	Aplicaciones Móviles I
Código	SIS-0180
Universidad	Universidad Privada Domingo Savio (UPDS)
Ubicación	Santa Cruz de la Sierra, Bolivia
Gestión	2026
Integrantes
Luis Gerardo Portillo Gonzales
Marco Antonio Kiataque Uchima
Anderson Carvajal Romero
1. Descripción del problema

Actualmente, muchos negocios gastronómicos locales gestionan sus cartas, consultas y reservas mediante diferentes canales de comunicación.

En el caso de Churrasquería El Fogón, esta situación representa dificultades para mantener actualizada la información de los precios, responder oportunamente a las consultas y organizar las reservas de los clientes.

Entre los principales problemas identificados se encuentran:

Información dispersa: la carta y los precios se comparten mediante fotografías y mensajes de WhatsApp.
Consultas desorganizadas: las preguntas de los clientes se gestionan mediante conversaciones independientes, dificultando su seguimiento.
Reservas manuales: las solicitudes se registran en un cuaderno físico, lo que puede ocasionar errores o reservas duplicadas.
Demoras en la atención: la falta de un canal centralizado puede provocar que los clientes no reciban respuestas oportunas.
Solución propuesta

ConectaCruz plantea desarrollar una aplicación móvil que reúna estos servicios en un solo lugar, permitiendo a los clientes consultar los platos y sus precios, realizar consultas y registrar solicitudes de reserva.

Además, la información se almacena en una base de datos centralizada, facilitando su organización y administración.

2. Objetivo del proyecto

Desarrollar una aplicación móvil multiplataforma para Churrasquería El Fogón, utilizando un framework que permita ofrecer una experiencia de usuario fluida, reducir los costos de desarrollo y facilitar la disponibilidad del servicio en Android e iOS.

Objetivos específicos
Comparar Flutter, React Native y el desarrollo nativo.
Identificar el framework más conveniente según las necesidades del negocio.
Implementar una interfaz móvil intuitiva y funcional.
Integrar una base de datos para almacenar la información del negocio, las consultas y las reservas.
Establecer una arquitectura que permita ampliar las funcionalidades en futuras versiones.
3. Evaluación de frameworks móviles

Para seleccionar la tecnología se analizaron tres alternativas de desarrollo:

Alternativa	Tecnología	Características
Flutter	Dart	Una única base de código para Android e iOS.
React Native	JavaScript y React	Desarrollo multiplataforma mediante React Native.
Desarrollo nativo	Kotlin + Swift	Aplicaciones independientes para Android e iOS.

También se consideraron alternativas basadas en WebView, como Ionic. Sin embargo, se descartaron debido a que el proyecto prioriza una experiencia de navegación fluida, especialmente al visualizar una carta extensa con fotografías.

3.1 Criterios de evaluación

Se establecieron cinco criterios ponderados, considerando las características del negocio y las capacidades del equipo de desarrollo.

Criterio	Peso	Justificación
Costo de desarrollo	25%	El negocio cuenta con un presupuesto limitado y no puede asumir dos equipos de desarrollo independientes.
Curva de aprendizaje	25%	El equipo está conformado por tres estudiantes sin experiencia móvil previa.
Rendimiento	20%	La aplicación debe funcionar adecuadamente en dispositivos de gama baja y manejar fotografías de los platos.
Comunidad y documentación	15%	Se necesita documentación gratuita y soporte de la comunidad para resolver dificultades técnicas.
Compatibilidad Android e iOS	15%	El negocio busca llegar a usuarios de ambas plataformas.
Total	100%	

Se asignó el mismo peso al costo y a la curva de aprendizaje, incluso cuando este último criterio podía favorecer a React Native debido a que el equipo ya tenía conocimientos de JavaScript. Esta decisión busca mantener una evaluación equilibrada y evitar modificar los criterios para favorecer una alternativa determinada.

3.2 Resultados de la evaluación

Después de aplicar los criterios de ponderación, se obtuvieron los siguientes resultados:

Framework	Puntaje ponderado (sobre 500)	Calificación (sobre 5)
Flutter	435	4,35
React Native	430	4,30
Desarrollo nativo	280	2,80

<details>
<summary><strong>Interpretación de los resultados</strong></summary>

Flutter obtuvo el puntaje más alto, con 435 puntos sobre 500, seguido de React Native con 430 puntos.

La diferencia es de cinco puntos, equivalente al 1% del puntaje máximo. Por tanto, el resultado representa una ventaja reducida y no demuestra una superioridad técnica general de Flutter sobre React Native.

La elección debe entenderse dentro del contexto específico de ConectaCruz y de los criterios definidos para el proyecto.

</details>

3.3 Framework seleccionado: Flutter

Se seleccionó Flutter como tecnología principal para desarrollar ConectaCruz.

Las razones principales son:

Desarrollo multiplataforma: permite mantener una única base de código para Android e iOS.
Rendimiento: utiliza su propio motor de renderizado para dibujar la interfaz, proporcionando un mayor control sobre la presentación visual.
Compilación nativa: en las compilaciones de producción, Dart utiliza AOT (Ahead-of-Time) para generar código máquina nativo.
Productividad: dispone de herramientas como hot reload, que permiten visualizar cambios durante el desarrollo sin reiniciar completamente la aplicación.
Documentación: cuenta con documentación oficial gratuita y una comunidad de desarrolladores que facilita el aprendizaje.

Además, la revisión de Joët y Taneski (2025) encontró diferencias en la satisfacción a largo plazo entre ambos frameworks, con una mediana de 68,1 para Flutter y 57,2 para React Native (p = 0,004).

3.4 Limitaciones de la elección

Aunque Flutter obtuvo el mejor resultado, también presenta aspectos que deben considerarse:

Diferencia reducida: su ventaja frente a React Native es de apenas un 1%, por lo que no puede afirmarse que sea superior en todos los escenarios.
Aprendizaje de Dart: el equipo necesita aprender un nuevo lenguaje de programación, mientras que React Native permite aprovechar los conocimientos previos de JavaScript.
Pruebas en dispositivos reales: todavía no se realizaron mediciones propias de consumo de memoria, CPU y tiempos de carga en celulares de gama baja.
Mercado laboral: React Native presenta una presencia importante en las ofertas laborales, aspecto que también debe considerarse al evaluar las oportunidades profesionales.
Resultados de estudios externos: las conclusiones de Joët y Taneski (2025) no deben generalizarse. Su investigación tampoco encontró diferencias estadísticamente significativas en popularidad (p = 0,59) ni en interés (p = 0,818).
4. Tecnologías utilizadas

Para el desarrollo de ConectaCruz se utilizaron las siguientes tecnologías:

Tecnología	Función dentro del proyecto
Flutter	Framework para el desarrollo de la aplicación móvil.
Dart	Lenguaje de programación utilizado por Flutter.
Supabase	Plataforma backend para gestionar los servicios de datos.
PostgreSQL	Sistema de gestión de base de datos relacional.
Row Level Security (RLS)	Políticas de seguridad para controlar el acceso a los registros.
Android Studio	Entorno de desarrollo y administración de emuladores.
Android SDK	Herramientas necesarias para compilar y ejecutar la aplicación en Android.
Arquitectura general

La aplicación utiliza Flutter como interfaz móvil y Supabase como backend.

El flujo general de funcionamiento es el siguiente:

El cliente interactúa con la aplicación móvil.
La aplicación realiza las operaciones necesarias mediante la integración con Supabase.
Supabase procesa las solicitudes y se comunica con PostgreSQL.
Los datos se almacenan y se recuperan de acuerdo con las políticas de seguridad configuradas.
5. Estado actual del desarrollo

El proyecto cuenta con un entorno de desarrollo configurado, una interfaz funcional y conexión con una base de datos real.

!Catálogo de Churrasquería El Fogón

5.1 Funcionalidades implementadas
Funcionalidad	Estado
Pantalla de bienvenida con identidad visual del negocio.	Implementada
Navegación mediante el botón «Ver negocio».	Implementada
Visualización del catálogo de platos.	Implementada
Obtención de información desde Supabase.	Implementada
Registro de consultas en la base de datos.	Implementado
Registro de reservas en la base de datos.	Implementado
Políticas de seguridad RLS.	Configuradas
5.2 Entorno de desarrollo verificado

Se verificó el funcionamiento del entorno con la siguiente configuración:

Sistema operativo: Windows 11.
Framework: Flutter 3.47.9.
Android SDK: 36.0.0.
Dispositivo de prueba: emulador Pixel_6.
IDE: Android Studio.

También se realizaron las siguientes verificaciones:

flutter doctor: entorno revisado correctamente.
flutter analyze: sin problemas reportados.
Pruebas automatizadas: 2 de 2 aprobadas.
5.3 Compatibilidad con iOS

El proyecto cuenta con la configuración necesaria para desarrollar la versión de iOS.

Sin embargo, todavía no se ha realizado la compilación ni las pruebas en dispositivos Apple, debido a que estas tareas requieren un equipo con macOS y Xcode.

Por tanto, la compatibilidad está contemplada en la estructura del proyecto, pero su funcionamiento en dispositivos iOS queda pendiente de verificación.

6. Próximas etapas

Para continuar con el desarrollo de ConectaCruz se establecieron las siguientes actividades:

Pruebas en dispositivos físicos: ejecutar la aplicación en celulares Android de gama baja para medir el consumo de memoria, CPU y los tiempos de carga.
Ampliación del catálogo: reemplazar y complementar los datos de ejemplo con información real y actualizada del negocio.
Validación de consultas y reservas: comprobar el correcto registro, recuperación y administración de la información.
Versión para iOS: realizar la compilación y las pruebas correspondientes mediante un equipo con macOS y Xcode, o un servicio de compilación en la nube.
Mejoras de rendimiento: optimizar la carga y visualización de imágenes para ofrecer una experiencia fluida en diferentes dispositivos.
7. Instalación y ejecución

Para ejecutar el proyecto en un entorno local es necesario contar con Flutter, Android Studio y el Android SDK configurados.

Requisitos previos
Flutter SDK.
Dart SDK (incluido con Flutter).
Android Studio.
Android SDK.
Un emulador Android o dispositivo físico.
Pasos de instalación

1. Obtener el proyecto

Clonar el repositorio desde GitHub:

bash
git clone URL_DEL_REPOSITORIO


Ingresar al directorio del proyecto:

bash
cd NOMBRE_DEL_PROYECTO


2. Instalar las dependencias

bash
flutter pub get


3. Verificar el entorno de desarrollo

bash
flutter doctor


4. Analizar el código

bash
flutter analyze


5. Ejecutar las pruebas

bash
flutter test


6. Iniciar la aplicación

bash
flutter run


También es posible ejecutar la aplicación desde Android Studio utilizando el botón Run ▶.

Dispositivo recomendado

Para las pruebas iniciales se recomienda utilizar el emulador Pixel_6 desde Android Studio:

Tools → Device Manager

Para ejecutar la versión de iOS se necesita un equipo con macOS y Xcode.

8. Conclusión

A partir del análisis comparativo realizado, se seleccionó Flutter como framework para el desarrollo de ConectaCruz, al obtener 435 puntos sobre 500, frente a los 430 puntos de React Native.

Sin embargo, la diferencia de cinco puntos representa un margen reducido, por lo que no permite establecer una superioridad general de Flutter sobre React Native.

La decisión responde a las necesidades específicas de Churrasquería El Fogón, considerando principalmente el costo de desarrollo, el rendimiento esperado y la posibilidad de mantener una única base de código para Android e iOS.

El proyecto demuestra la aplicación práctica de los conceptos de desarrollo móvil mediante una interfaz funcional, integración con un backend real y almacenamiento de información en una base de datos.

Se reconoce que todavía existen aspectos pendientes, especialmente las pruebas de rendimiento en dispositivos físicos y la validación de la versión para iOS.

Por tanto, Flutter representa la alternativa más conveniente según los criterios y ponderaciones definidos para este proyecto, sin descartar que React Native pueda ser igualmente adecuado en otros contextos.

9. Documentación y referencias bibliográficas

Este README presenta un resumen del proyecto y de la decisión tecnológica adoptada.

El análisis metodológico completo, la matriz de evaluación, la discusión de limitaciones y las referencias en formato APA 7 se encuentran en el informe académico:

Informe IMRyD – Frameworks ConectaCruz

La presentación del proyecto se encuentra en:

ConectaCruz · Churrasquería El Fogón.pptx

Referencias
Crespo Parrales, W. A. (2026). Comparación de Flutter y React Native en el desarrollo de aplicaciones móviles multiplataforma para las Pymes [Tesis de posgrado]. Universidad Politécnica Salesiana.
Flutter. (s. f.). Flutter architectural overview. https://docs.flutter.dev/resources/architectural-overview
Joët, G., & Taneski, V. (2025). State-of-the-art cross-platform mobile application development frameworks. Informatics, 12(2), 45. https://doi.org/10.3390/informatics12020045
Meta Platforms. (s. f.). About the New Architecture. React Native. https://reactnative.dev/architecture/landing-page

Actividad 01 · Criterio de verificación N.º 4

Aplicaciones Móviles I (SIS-0180)

Universidad Privada Domingo Savio (UPDS)
Santa Cruz de la Sierra, Bolivia · 2026
