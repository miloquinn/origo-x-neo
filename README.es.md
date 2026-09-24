<div align="center">
  <img src="assets/images/app_icon.png" width="112" alt="Icono de Origo X">
  <h1>Origo X</h1>
  <p>Un lector de libros electrónicos local, multiplataforma y compatible con fuentes abiertas</p>
  <p><a href="README.en.md">English</a> · <a href="README.md">简体中文</a> · <a href="README.zh-TW.md">繁體中文</a> · <a href="README.ja.md">日本語</a> · <a href="README.ko.md">한국어</a> · <strong>Español</strong></p>
</div>

Origo X es un lector de libros electrónicos de código abierto creado con
Flutter. Los libros, el progreso, los marcadores y las notas permanecen de
forma predeterminada en el dispositivo del usuario.

## Un motor nativo de Flutter, no una envoltura WebView

La pantalla principal de lectura utiliza un motor propio y nativo de Flutter.
El análisis de capítulos, la medición real con `TextPainter`, la paginación por
búsqueda binaria, las imágenes, la caché y los anclajes de posición se procesan
dentro del sistema de renderizado de Flutter. La ruta principal de lectura no
depende de WebView.

## Funciones principales

- Importación de EPUB, PDF, TXT y ZIP y biblioteca local
- Maquetación nativa de Flutter, paginación precisa, caché y restauración de posición
- Tipografía, espaciado, márgenes, temas y caché de paginación
- Marcadores, resaltados, notas, historial y estadísticas
- Texto a voz del sistema y servicios de IA configurables
- Proyectos para Android, iOS, Windows, macOS, Linux y Web

## Fuentes de libros abiertas

Las fuentes en línea utilizan **Origo Source Protocol (ORSP)**, una API
HTTP común para descubrimiento, búsqueda, datos del libro, capítulos y texto.

**[Ver la especificación, OpenAPI y el servidor de referencia](https://github.com/miloquinn/origo-source-protocol)**

ORSP está destinado a contenido original, de dominio público o debidamente
licenciado.

## Desarrollo

```bash
git clone https://github.com/miloquinn/origo-x-neo.git
cd origo-x
flutter pub get
flutter run
```

Licencia [GNU AGPL-3.0](LICENSE). Las versiones modificadas distribuidas o utilizadas para prestar servicios de red deben ofrecer el código fuente correspondiente. Las versiones hasta `v1.0.0` conservan su [licencia MIT](LICENSE-MIT-LEGACY); consulte [LICENSING.md](LICENSING.md). Se aceptan Issues, Pull Requests y traducciones.
