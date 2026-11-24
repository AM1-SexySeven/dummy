# Guion del video · Desafío del QR

ConectaCruz · Churrasquería El Fogón — Aplicaciones Móviles I (SIS-0180)

- **Duración:** 4 minutos 40 segundos (el tope es 5 minutos)
- **Orden:** Luis Portillo → Anderson Carvajal → Marco Kiataque
- **Láminas:** 9, en el archivo ConectaCruz — Desafío QR — Cobros con código QR


---

## LUIS PORTILLO
*Láminas 1 a 3 · 0:00 – 1:28*

### Lámina 1 · Portada  ·  0:00 – 0:22

> Buenas. Somos Luis Portillo, Anderson Carvajal y Marco Kiataque, y esta es la parte de cobros por código QR de ConectaCruz, para la Churrasquería El Fogón. El cliente arma su pedido, la aplicación le muestra un código, y el pedido se confirma recién cuando el banco avisa que recibió el pago.

### Lámina 2 · Qué pide el desafío  ·  0:22 – 0:50

> Son cuatro cosas. Que haya un cobro por pedido, y que pedir el código dos veces devuelva el mismo y no uno nuevo. Que el código tenga de verdad el formato del QR boliviano. Que el pago lo confirme el banco y no la aplicación. Y que cuando algo falla, haya una pantalla que lo diga.

### Lámina 3 · El punto de partida  ·  0:50 – 1:28

> Conviene decir de entrada con qué contábamos. Teníamos el portal SIP de MC4 y la cuenta del negocio, pero ese portal se usa a mano: uno entra, genera el código y mira si pagaron. Una aplicación no puede hablar con eso. Lo que faltaba era la documentación del banco, y el ingeniero nos confirmó que todavía estaba incompleta. Así que decidimos armar un banco de pruebas con las mismas reglas y dejar el contrato listo. Lo simulado es el banco; todo lo demás es código que va a producción.


---

## ANDERSON CARVAJAL
*Láminas 4 a 6 · 1:28 – 3:15*

### Lámina 4 · Un contrato, dos implementaciones  ·  1:28 – 2:05

> Por eso la pantalla de pago no conoce ningún banco. Conoce una interfaz con dos operaciones: generar el cobro y consultar su estado. Hoy la cumple una pasarela simulada, que son funciones en nuestra propia base llamadas por red: hay petición real, demora real y errores reales, no es un if adentro de la aplicación. Y ya está escrita la del banco, contra el mismo contrato y con sus pruebas. Le falta la dirección y las credenciales, nada más.

### Lámina 5 · Del carrito al código  ·  2:05 – 2:38

> Esta es la prueba. A la izquierda el carrito con dos platos, ciento setenta y cinco bolivianos. Al tocar «Pagar con QR» primero se crea el pedido en la base y recién después se pide el cobro, así el cobro siempre tiene de qué colgar. A la derecha el código ya en pantalla, con el monto, el número de pedido, un reloj que corre y la referencia que devolvió el banco.

### Lámina 6 · Qué lleva adentro  ·  2:38 – 3:15

> El código no es un dibujo: es un texto, y esto es lo que lee el teléfono del cliente. Cada campo son tres piezas pegadas: el número que lo identifica, cuántos caracteres mide y el contenido. Ahí están la cuenta del comercio, el rubro de restaurante, la moneda boliviano y el monto. El último campo es un dígito de control: si alguien cambia un solo carácter, la cuenta no cierra y el lector lo rechaza. Para comprobar que lo calculamos bien usamos la cadena de control del estándar, que tiene que dar 29B1, y da.


---

## MARCO KIATAQUE
*Láminas 7 a 9 · 3:15 – 4:40*

### Lámina 7 · El pago lo confirma el servidor  ·  3:15 – 3:50

> Acá está el aviso de pedido pagado, y aparece solo, sin tocar nada: llegó desde el servidor. La pantalla tiene cinco estados, cargando, con el código, error, vencido y pagado, y cada uno se ve; nadie se queda mirando una rueda que gira para siempre. El cambio llega en vivo, y por las dudas igual preguntamos cada cinco segundos. Y algo que nos importa: el carrito se vacía solo con el pago confirmado. Si la persona cierra antes, el pedido queda pendiente y no se pierde nada.

### Lámina 8 · Verificación  ·  3:50 – 4:25

> Estos son los ocho puntos, cada uno con su captura: el pedido antes del cobro, el formato del código, el dígito de control, un solo cobro por pedido, la cuenta regresiva, el pago confirmado por el servidor, el aviso cuando no hay conexión y setenta pruebas automáticas en verde. Una de esas pruebas encontró que la pasarela del banco no mostraba la pantalla de vencido; se corrigió antes de llegar acá.

### Lámina 9 · Cierre  ·  4:25 – 4:40

> En resumen: el recorrido completo anda de punta a punta contra un servidor real. Lo único que queda afuera es la dirección del banco, y cuando llegue se cambia esa línea y la aplicación no se entera. Gracias.


---

## Para el día de la grabación

- No leas la pantalla de la lámina: leé el guion. La lámina ya dice lo suyo.
- Los números se dicen con palabras: «ciento setenta y cinco bolivianos», no «Bs 175».
- El 29B1 de la lámina 6 se lee letra por letra: dos, nueve, be, uno.
- Si te pasás de tiempo, lo primero que se recorta es la lámina 2.
- El rostro va en el redondito durante todo el video, como pidió el docente.
- No muestres en cámara las credenciales del portal del banco: en las capturas solo aparece el número de cuenta del negocio, que es el que va en el código.
