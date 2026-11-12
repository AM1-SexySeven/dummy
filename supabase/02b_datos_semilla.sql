-- =====================================================================
--  02b · Datos de ejemplo (menú real de la Churrasquería)
--  Ejecutar DESPUÉS de 02_rls_lectura.sql
-- =====================================================================

insert into public.productos (nombre, descripcion, precio) values
  ('Parrillada para dos', 'Carne, chorizo, yuca y ensalada', 120.00),
  ('Majadito batido',     'Arroz con charque, huevo y plátano', 35.00),
  ('Pique macho',         'Carne, papas fritas, huevo y llajua', 55.00),
  ('Sonso asado',         'Plátano con queso, mantequilla y dulce de leche', 20.00)
on conflict do nothing;
