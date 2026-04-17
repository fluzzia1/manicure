-- =============================================
-- SCHEMA MULTI-TENANT — Fluzzia
-- Execute no Supabase → SQL Editor
-- =============================================

-- Tabela de salões
create table if not exists saloes (
  id           uuid default gen_random_uuid() primary key,
  slug         text not null unique,
  nome         text not null,
  tipo         text not null default 'salao',   -- 'salao' | 'barbearia' | ...
  cor_primaria text not null default '#D4607A',
  whatsapp     text,
  instagram    text,
  endereco     text,
  bairro       text,
  cidade       text,
  horarios     jsonb default '{"1":{"open":"09:00","close":"18:00"},"2":{"open":"09:00","close":"18:00"},"3":{"open":"09:00","close":"18:00"},"4":{"open":"09:00","close":"18:00"},"5":{"open":"09:00","close":"18:00"},"6":{"open":"09:00","close":"18:00"},"0":null}',
  admin_user   text not null,
  admin_pass   text not null,
  email_from   text default 'contato@fluzzia.net',
  hero_titulo  text,
  hero_desc    text,
  created_at   timestamptz default now()
);

-- Garante colunas novas em DBs já existentes
alter table saloes add column if not exists tipo        text not null default 'salao';
alter table saloes add column if not exists hero_titulo text;
alter table saloes add column if not exists hero_desc   text;

-- Tabela de serviços
create table if not exists servicos (
  id        serial primary key,
  salao_id  uuid not null references saloes(id) on delete cascade,
  nome      text not null,
  preco     text not null,
  duracao   integer not null,
  icone     text not null default 'fa-solid fa-star',
  categoria text not null default 'hair',
  ativo     boolean default true
);

-- Tabela de combos
create table if not exists combos (
  id        serial primary key,
  salao_id  uuid not null references saloes(id) on delete cascade,
  nome      text not null,
  preco     text not null,
  duracao   integer not null,
  ativo     boolean default true
);

-- Tabela de agendamentos (cria se não existir; adiciona coluna salao_id se faltar)
create table if not exists agendamentos (
  id        uuid default gen_random_uuid() primary key,
  salao_id  uuid references saloes(id),
  user_id   uuid,
  name      text,
  phone     text,
  email     text,
  service   text,
  date      date,
  time      text,
  duration  integer,
  price     text,
  done      boolean default false,
  cancelled boolean default false,
  created_at timestamptz default now()
);
alter table agendamentos add column if not exists salao_id uuid references saloes(id);

-- Tabela de perfis de usuário
create table if not exists profiles (
  id    uuid primary key references auth.users(id) on delete cascade,
  name  text,
  email text,
  phone text
);

-- =============================================
-- RLS
-- =============================================
alter table saloes      enable row level security;
alter table servicos    enable row level security;
alter table combos      enable row level security;
alter table agendamentos enable row level security;
alter table profiles    enable row level security;

-- Leitura pública de saloes / serviços / combos
create policy if not exists "saloes_read"   on saloes   for select using (true);
create policy if not exists "servicos_read" on servicos for select using (true);
create policy if not exists "combos_read"   on combos   for select using (true);

-- Agendamentos: leitura pública (necessária para verificar disponibilidade de horários)
create policy if not exists "agendamentos_select" on agendamentos for select using (true);
-- Agendamentos: qualquer um pode inserir (cliente agendando)
create policy if not exists "agendamentos_insert" on agendamentos for insert with check (true);
-- Agendamentos: usuário só atualiza os próprios (cancel/reschedule no frontend)
create policy if not exists "agendamentos_update" on agendamentos for update using (auth.uid() = user_id);

-- Profiles: usuário gerencia apenas o próprio
create policy if not exists "profiles_select" on profiles for select using (auth.uid() = id);
create policy if not exists "profiles_insert" on profiles for insert with check (auth.uid() = id);
create policy if not exists "profiles_update" on profiles for update using (auth.uid() = id);

-- =============================================
-- DADOS — Studio Beauty
-- =============================================
insert into saloes (slug, nome, tipo, cor_primaria, whatsapp, instagram, endereco, bairro, cidade, admin_user, admin_pass, email_from, hero_titulo, hero_desc, horarios)
values (
  'studiobeauty',
  'Studio Beauty',
  'salao',
  '#D4607A',
  '5531987899520',
  'moreira.irineia',
  'Rua João Gualberto Costa, 198',
  'Vila Santa Luzia',
  'Horizonte — MG',
  'irineia',
  '12345',
  'contato@fluzzia.net',
  'Beleza que <em>transforma</em> o seu dia',
  'Cabelo, unhas, sobrancelhas e muito mais. Agende online e venha se cuidar!',
  '{"1":{"open":"09:30","close":"18:00"},"2":{"open":"09:30","close":"18:00"},"3":{"open":"09:30","close":"18:00"},"4":{"open":"09:30","close":"18:00"},"5":{"open":"09:30","close":"18:00"},"6":{"open":"07:30","close":"18:00"},"0":null}'
) on conflict (slug) do update set
  tipo        = excluded.tipo,
  hero_titulo = excluded.hero_titulo,
  hero_desc   = excluded.hero_desc;

-- Serviços Studio Beauty
with s as (select id from saloes where slug = 'studiobeauty')
insert into servicos (salao_id, nome, preco, duracao, icone, categoria)
select s.id, v.nome, v.preco, v.duracao, v.icone, v.categoria
from s, (values
  ('Mechas/Luzes',                              'A partir de R$ 150,00', 300, 'fa-solid fa-wand-magic-sparkles', 'hair'),
  ('Hidratação',                                'A partir de R$ 90,00',   60, 'fa-solid fa-droplet',             'hair'),
  ('Hidratação com Ozônio',                     'R$ 130,00',              75, 'fa-solid fa-droplet',             'hair'),
  ('Escova',                                    'A partir de R$ 30,00',   45, 'fa-solid fa-wind',                'hair'),
  ('Queratinização ou Cauterização com Escova', 'A partir de R$ 130,00',  90, 'fa-solid fa-wind',                'hair'),
  ('Progressiva (com ou sem formol)',           'A partir de R$ 130,00', 180, 'fa-solid fa-star',                'hair'),
  ('Pé e Mão',                                  'R$ 50,00',               60, 'fa-solid fa-hand-sparkles',       'nail'),
  ('Só Pé ou Mão',                              'R$ 30,00',               30, 'fa-solid fa-hand-sparkles',       'nail'),
  ('Esmaltação em Gel',                         'R$ 85,00',               75, 'fa-solid fa-paintbrush',          'nail'),
  ('Alongamento de Unha molde F1',              'R$ 130,00',             150, 'fa-solid fa-paintbrush',          'nail'),
  ('Manutenção',                                'R$ 85,00',               90, 'fa-solid fa-paintbrush',          'nail'),
  ('Design de Sobrancelhas',                    'R$ 35,00',               30, 'fa-solid fa-eye',                 'brow'),
  ('Design com Henna',                          'R$ 55,00',               60, 'fa-solid fa-eye',                 'brow'),
  ('Micropigmentação',                          'R$ 300,00',             180, 'fa-solid fa-eye',                 'brow'),
  ('Retoque de Micropigmentação',               'A confirmar',            90, 'fa-solid fa-eye',                 'brow'),
  ('Spa dos Pés',                               'R$ 85,00',               75, 'fa-solid fa-spa',                 'foot')
) as v(nome, preco, duracao, icone, categoria)
on conflict do nothing;

-- Combos Studio Beauty
with s as (select id from saloes where slug = 'studiobeauty')
insert into combos (salao_id, nome, preco, duracao)
select s.id, v.nome, v.preco, v.duracao
from s, (values
  ('Buço + Pedicure + Manicure',                              'R$ 65,00',   75),
  ('Design com Henna + Corte + Manicure',                     'R$ 99,90',  135),
  ('Micropigmentação + Retoque',                              'R$ 250,00', 270),
  ('Pedicure + Buço + Design com Henna',                     'R$ 85,00',  105),
  ('Blindagem de Gel + Cutilagem',                            'R$ 75,00',   80),
  ('Spa dos Pés + Pedicure',                                  'R$ 70,00',  105),
  ('Botox Capilar + Pedicure + Design',                       'R$ 145,00', 180),
  ('Cristalização Térmica + Pedicure + Buço',                 'R$ 85,00',  135),
  ('Hidratação + Escova + Pedicure',                          'R$ 85,00',  135),
  ('Progressiva sem Formol + Hidratação + Brinde Pedicure',  'R$ 200,00', 270)
) as v(nome, preco, duracao)
on conflict do nothing;

-- =============================================
-- DADOS — Barbearia BH
-- =============================================
insert into saloes (slug, nome, tipo, cor_primaria, whatsapp, instagram, endereco, bairro, cidade, admin_user, admin_pass, email_from, hero_desc, horarios)
values (
  'barbeariabh',
  'Barbearia BH',
  'barbearia',
  '#C4A25A',
  '5531900000000',
  '',
  'Av. Exemplo, 100',
  'Centro',
  'Belo Horizonte — MG',
  'barbearia',
  '12345',
  'contato@fluzzia.net',
  'Estilo com Precisão',
  '{"1":{"open":"09:00","close":"19:00"},"2":{"open":"09:00","close":"19:00"},"3":{"open":"09:00","close":"19:00"},"4":{"open":"09:00","close":"19:00"},"5":{"open":"09:00","close":"19:00"},"6":{"open":"08:00","close":"17:00"},"0":null}'
) on conflict (slug) do update set
  tipo       = excluded.tipo,
  admin_user = excluded.admin_user,
  admin_pass = excluded.admin_pass;

-- Serviços Barbearia BH
with s as (select id from saloes where slug = 'barbeariabh')
insert into servicos (salao_id, nome, preco, duracao, icone, categoria)
select s.id, v.nome, v.preco, v.duracao, v.icone, v.categoria
from s, (values
  ('Corte',            'R$ 35,00', 30, 'fa-solid fa-scissors', 'hair'),
  ('Corte + Barba',    'R$ 55,00', 50, 'fa-solid fa-scissors', 'hair'),
  ('Barba',            'R$ 25,00', 30, 'fa-solid fa-star',     'hair'),
  ('Pigmentação',      'R$ 80,00', 60, 'fa-solid fa-star',     'hair'),
  ('Sobrancelha',      'R$ 15,00', 20, 'fa-solid fa-eye',      'brow'),
  ('Relaxamento',      'R$ 70,00', 60, 'fa-solid fa-droplet',  'hair')
) as v(nome, preco, duracao, icone, categoria)
on conflict do nothing;

-- Vincular agendamentos sem salao_id ao Studio Beauty
update agendamentos
set salao_id = (select id from saloes where slug = 'studiobeauty')
where salao_id is null;

-- =============================================
-- PARA ADICIONAR NOVO SALÃO NO FUTURO:
-- 1. Insira um registro em `saloes` com slug único e tipo correto
-- 2. Insira serviços em `servicos` vinculados ao salao_id
-- 3. Se tipo novo (ex: 'spa'), adicione o arquivo HTML e registre
--    no mapa TIPO_HTML em server.js
-- 4. Aponte o domínio no Heroku e no Supabase Redirect URLs
-- =============================================
