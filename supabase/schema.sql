-- Caderno de Cargas: esquema do Supabase
-- Uma linha por documento do app: sessao, dia, metas, alimentos, peso, config.

create table if not exists public.registros (
  user_id    uuid        not null default auth.uid() references auth.users(id) on delete cascade,
  id         text        not null,
  tipo       text        not null check (tipo in ('sessao','dia','metas','alimentos','peso','config')),
  dia        date,
  doc        jsonb       not null,
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

create index if not exists registros_user_tipo_dia_idx
  on public.registros (user_id, tipo, dia desc);

create or replace function public.registros_touch()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end $$;

drop trigger if exists registros_touch on public.registros;
create trigger registros_touch
  before update on public.registros
  for each row execute function public.registros_touch();

alter table public.registros enable row level security;

drop policy if exists registros_dono on public.registros;
create policy registros_dono on public.registros
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

revoke all on public.registros from anon;
grant select, insert, update, delete on public.registros to authenticated;
