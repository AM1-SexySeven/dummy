# Guion del video · Actividad 04

ConectaCruz · Churrasquería El Fogón — Aplicaciones Móviles I (SIS-0180)

- **Duración:** 4 minutos 40 segundos (el tope es 5 minutos)
- **Orden:** Luis Portillo → Anderson Carvajal → Marco Kiataque
- **Láminas:** 9, en el archivo ConectaCruz — Actividad 4 — Fotos y Voz


---

## LUIS PORTILLO
*Láminas 1 a 3 · 0:00 – 1:30*

### Lámina 1 · Portada  ·  0:00 – 0:25

> Buenas. Somos Luis Portillo, Anderson Carvajal y Marco Kiataque, y esta es la Actividad 4 de ConectaCruz, sobre la Churrasquería El Fogón. Le agregamos dos cosas a la aplicación: que el dueño pueda subir la foto de un plato desde su teléfono y que el cliente pueda buscar en el catálogo hablando, en vez de escribir.

### Lámina 2 · Cómo se evalúa  ·  0:25 – 0:55

> Vamos a mostrar cuatro cosas. Que la foto se guarda en la nube y no en el teléfono. Que los permisos de cámara, galería y micrófono se piden en el momento, y que si la persona dice que no, la app sigue andando. Que la búsqueda por voz funciona. Y que todo esto tiene su captura: no lo contamos, lo mostramos.

### Lámina 3 · Fotos, paso 1  ·  0:55 – 1:30

> Acá está el detalle de un plato. La cuenta del dueño ve el botón «Cambiar foto» arriba de la imagen; la cuenta de un cliente abre la misma pantalla y el botón no está. Al tocarlo se abre esta hoja con dos opciones: elegir de la galería o sacar una foto. El permiso recién se pide ahí, cuando se elige una. Y algo importante: esconder el botón no alcanza. El servidor también rechaza a quien no es dueño, porque cualquiera podría llamarlo por su cuenta.


---

## ANDERSON CARVAJAL
*Láminas 4 a 6 · 1:30 – 3:15*

### Lámina 4 · Fotos, paso 2  ·  1:30 – 2:05

> Esta es la prueba de punta a punta. A la izquierda, el Pique macho sin foto: muestra el logo del negocio. Al medio, la misma pantalla después de subir la foto desde la galería. Y a la derecha, la lista del catálogo, donde la foto ya aparece en miniatura. O sea, la foto no se quedó en la pantalla: subió al depósito y el plato guardó su dirección en la base.

### Lámina 5 · Seguridad del depósito  ·  2:05 – 2:40

> El depósito tiene sus propias reglas, aparte de la aplicación. Leer puede cualquiera, incluso sin iniciar sesión, porque las fotos del menú son el escaparate del negocio. Subir y reemplazar, solo el dueño y solo dentro de la carpeta de platos. Y borrar, nadie: preferimos que una foto quede sin usar antes que un error borre la de un plato publicado. Hay una regla más, del lado de la base: al guardar la dirección pedimos la fila tocada, porque si no vuelve ninguna la app estaba dando por hecho que había guardado.

### Lámina 6 · Voz, paso 1  ·  2:40 – 3:15

> Para la voz lo primero es el micrófono. Android lo pide recién cuando se toca el botón del buscador, no al abrir la app. En Android, además del permiso hay que declarar el servicio de reconocimiento en el manifiesto; sin esa línea el teléfono no encuentra el motor de dictado y el botón no hace nada. En iOS van dos textos en el Info.plist explicando para qué se usa. Y si la persona dice que no, la app no se cae ni insiste: el buscador sigue ahí y se escribe a mano.


---

## MARCO KIATAQUE
*Láminas 7 a 9 · 3:15 – 4:40*

### Lámina 7 · Voz, paso 2  ·  3:15 – 3:50

> Acá está el detalle que nos costó. Quien dicta nunca pone tildes, y quien escribe apurado tampoco. Probamos con «platano», sin acento. A la izquierda, comparando el texto tal cual: ningún plato coincide, aunque el Sonso asado dice plátano en la descripción. A la derecha, comparando sin tildes y sin distinguir mayúsculas: la misma palabra trae el Sonso asado y el Majadito batido. El filtro busca en el nombre y en el rubro, así que decir «artesanía» trae los negocios de ese rubro aunque ninguno se llame así.

### Lámina 8 · Verificación  ·  3:50 – 4:25

> Estos son los ocho puntos, cada uno con su captura. Y queremos marcar algo: probar de verdad encontró cuatro fallas. La foto se veía pero no se guardaba, los platos se duplicaron en el catálogo, el botón no aparecía y la búsqueda no encontraba. Las cuatro están corregidas y vueltas a probar. Cerramos con setenta pruebas automáticas en verde, trece de ellas nuevas.

### Lámina 9 · Cierre  ·  4:25 – 4:40

> En resumen: el dueño publica la foto de un plato desde su teléfono y el cliente lo busca hablando, las dos cosas contra un servidor real y con sus permisos puestos. Gracias.


---

## Para el día de la grabación

- No leas la pantalla de la lámina: leé el guion. La lámina ya dice lo suyo, y repetirla en voz alta suena a lectura.
- Si te pasás de tiempo, lo primero que se recorta es la lámina 2, que es la única sin captura.
- El rostro va en el redondito durante todo el video, como pidió el docente.
- Antes de grabar, dejá la app abierta en la pantalla del negocio: así los cambios de lámina coinciden con lo que se está contando.
