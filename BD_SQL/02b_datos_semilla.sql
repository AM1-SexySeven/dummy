-- =====================================================================
--  02b · Datos de ejemplo (menú real de la Churrasquería El Fogón)
--  Ejecutar DESPUÉS de 02_rls_lectura.sql
-- =====================================================================

insert into public.productos (nombre, descripcion, precio, imagen_url) values
  ('Parrillada para dos',             'Carne de res, chorizo criollo, yuca y ensalada fresca',          120.00, 'https://ywscetqmxkmjppiomrbv.supabase.co/storage/v1/object/public/negocios/platos/parrillada.jpg'),
  ('Bife de Chorizo a las Brasas',   'Corte jugoso de res a la parrilla servido con papas fritas',      75.00, ''),
  ('Pique Macho Cruceño',             'Carne salteada, papas fritas, salchichas, huevo frito y llajua',  55.00, 'https://ywscetqmxkmjppiomrbv.supabase.co/storage/v1/object/public/negocios/platos/piquemacho.jpg'),
  ('Majadito Batido con Huevo',       'Arroz tostado con charque de res, huevo frito y plátano frito',   35.00, 'https://ywscetqmxkmjppiomrbv.supabase.co/storage/v1/object/public/negocios/platos/majadito.jpg'),
  ('Keperí al Horno',                 'Tierno keperí horneado servido con arroz con queso y yuca',       50.00, ''),
  ('Pacumuto de Res',                 'Brochetas de carne de res con pimentón y cebolla a las brasas',   40.00, ''),
  ('Pacú a la Parrilla',              'Pescado de río pacú a la parrilla servido con ensalada criolla',  65.00, ''),
  ('Sonso Asado a la Brasa',          'Masa de yuca con queso a las brasas y mantequilla',              20.00, 'https://ywscetqmxkmjppiomrbv.supabase.co/storage/v1/object/public/negocios/platos/sonso.jpg'),
  ('Sopa de Maní Tradicional',        'Sopa cruceña con carne, papas fritas en hilo y arvejas',          25.00, ''),
  ('Chicha Cruceña Helada',           'Bebida artesanal de maíz bien helada',                            12.00, ''),
  ('Cuadril Especial a la Parrilla', 'Corte jugoso a la parrilla con yuca frita y arroz con queso',     85.00, ''),
  ('Costillitas de Cerdo a la BBQ',  'Costillas ahumadas a las brasas bañadas en salsa BBQ criolla',     60.00, ''),
  ('Tira de Asado a la Cruz',         'Tira de asado tierna a las brasas con ensalada de la casa',       70.00, ''),
  ('Arroz con Queso Extra',           'Porción generosa de arroz con queso fundido tradicional',         18.00, ''),
  ('Limonada de la Casa Helada',      'Limonada natural helada con hojas de menta',                      10.00, '')
on conflict do nothing;
