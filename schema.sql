-- =============================================
-- SCHEMA MULTI-TENANT — Fluzzia
-- Execute no Supabase → SQL Editor
-- =============================================

-- Tabela de salões
create table if not exists saloes (
  id           uuid default gen_random_uuid() primary key,
  slug         text not null unique,
  nome         text not null,
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
  created_at   timestamptz default now()
);

-- Tabela de serviços (substitui array hardcoded no HTML)
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

-- Adicionar salao_id à tabela de agendamentos
alter table agendamentos add column if not exists salao_id uuid references saloes(id);

-- RLS nas novas tabelas
alter table saloes   enable row level security;
alter table servicos enable row level security;
alter table combos   enable row level security;

-- Leitura pública (o site precisa ler config e serviços sem autenticação)
create policy "saloes_read"   on saloes   for select using (true);
create policy "servicos_read" on servicos for select using (true);
create policy "combos_read"   on combos   for select using (true);

-- =============================================
-- DADOS INICIAIS — Studio Beauty (Irineia)
-- =============================================
insert into saloes (slug, nome, cor_primaria, whatsapp, instagram, endereco, bairro, cidade, admin_user, admin_pass, email_from, horarios)
values (
  'irineia',
  'Studio Beauty',
  '#D4607A',
  '5531987899520',
  'moreira.irineia',
  'Rua João Gualberto Costa, 198',
  'Vila Santa Luzia',
  'Horizonte — MG',
  'irineia',
  '12345',
  'contato@fluzzia.net',
  '{"1":{"open":"09:30","close":"18:00"},"2":{"open":"09:30","close":"18:00"},"3":{"open":"09:30","close":"18:00"},"4":{"open":"09:30","close":"18:00"},"5":{"open":"09:30","close":"18:00"},"6":{"open":"07:30","close":"18:00"},"0":null}'
) on conflict (slug) do nothing;

-- Serviços da Irineia
with s as (select id from saloes where slug = 'irineia')
insert into servicos (salao_id, nome, preco, duracao, icone, categoria)
select s.id, v.nome, v.preco, v.duracao, v.icone, v.categoria
from s, (values
  ('Mechas/Luzes',                                 'A partir de R$ 150,00', 300, 'fa-solid fa-wand-magic-sparkles', 'hair'),
  ('Hidratação',                                   'A partir de R$ 90,00',   60, 'fa-solid fa-droplet',             'hair'),
  ('Hidratação com Ozônio',                        'R$ 130,00',              75, 'fa-solid fa-droplet',             'hair'),
  ('Escova',                                       'A partir de R$ 30,00',   45, 'fa-solid fa-wind',                'hair'),
  ('Queratinização ou Cauterização com Escova',    'A partir de R$ 130,00',  90, 'fa-solid fa-wind',                'hair'),
  ('Progressiva (com ou sem formol)',              'A partir de R$ 130,00', 180, 'fa-solid fa-star',                'hair'),
  ('Pé e Mão',                                     'R$ 50,00',               60, 'fa-solid fa-hand-sparkles',       'nail'),
  ('Só Pé ou Mão',                                 'R$ 30,00',               30, 'fa-solid fa-hand-sparkles',       'nail'),
  ('Esmaltação em Gel',                            'R$ 85,00',               75, 'fa-solid fa-paintbrush',          'nail'),
  ('Alongamento de Unha molde F1',                 'R$ 130,00',             150, 'fa-solid fa-paintbrush',          'nail'),
  ('Manutenção',                                   'R$ 85,00',               90, 'fa-solid fa-paintbrush',          'nail'),
  ('Design de Sobrancelhas',                       'R$ 35,00',               30, 'fa-solid fa-eye',                 'brow'),
  ('Design com Henna',                             'R$ 55,00',               60, 'fa-solid fa-eye',                 'brow'),
  ('Micropigmentação',                             'R$ 300,00',             180, 'fa-solid fa-eye',                 'brow'),
  ('Retoque de Micropigmentação',                  'A confirmar',            90, 'fa-solid fa-eye',                 'brow'),
  ('Spa dos Pés',                                  'R$ 85,00',               75, 'fa-solid fa-spa',                 'foot')
) as v(nome, preco, duracao, icone, categoria)
on conflict do nothing;

-- Combos da Irineia
with s as (select id from saloes where slug = 'irineia')
insert into combos (salao_id, nome, preco, duracao)
select s.id, v.nome, v.preco, v.duracao
from s, (values
  ('Buço + Pedicure + Manicure',                                       'R$ 65,00',   75),
  ('Design com Henna + Corte + Manicure',                              'R$ 99,90',  135),
  ('Micropigmentação + Retoque',                                        'R$ 250,00', 270),
  ('Pedicure + Buço + Design com Henna',                               'R$ 85,00',  105),
  ('Blindagem de Gel + Cutilagem',                                      'R$ 75,00',   80),
  ('Spa dos Pés + Pedicure',                                            'R$ 70,00',  105),
  ('Botox Capilar + Pedicure + Design',                                 'R$ 145,00', 180),
  ('Cristalização Térmica + Pedicure + Buço',                           'R$ 85,00',  135),
  ('Hidratação + Escova + Pedicure',                                    'R$ 85,00',  135),
  ('Progressiva sem Formol + Hidratação + Brinde Pedicure',            'R$ 200,00', 270)
) as v(nome, preco, duracao)
on conflict do nothing;

-- Vincular agendamentos existentes ao salão da Irineia
update agendamentos
set salao_id = (select id from saloes where slug = 'irineia')
where salao_id is null;
