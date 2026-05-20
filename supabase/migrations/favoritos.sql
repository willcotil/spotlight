-- Migração: criação da tabela favoritos
-- Cada linha representa um favorito de um usuário para uma mídia do TMDb.

create table if not exists favoritos (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  tmdb_id     integer not null,
  media_type  text not null check (media_type in ('movie', 'tv')),
  title       text not null,
  poster_path text,
  added_at    timestamptz not null default now(),

  -- Garante que o mesmo usuário não favorite a mesma mídia duas vezes.
  unique (user_id, tmdb_id)
);

-- Índice para buscas por usuário (carregamento da lista de favoritos).
create index if not exists favoritos_user_id_idx on favoritos (user_id);

-- ─── Row Level Security ────────────────────────────────────────────────────────

alter table favoritos enable row level security;

-- Usuários só lêem os próprios favoritos.
create policy "favoritos: leitura própria"
  on favoritos for select
  using (auth.uid() = user_id);

-- Usuários só inserem favoritos em seu próprio nome.
create policy "favoritos: inserção própria"
  on favoritos for insert
  with check (auth.uid() = user_id);

-- Usuários só excluem os próprios favoritos.
create policy "favoritos: exclusão própria"
  on favoritos for delete
  using (auth.uid() = user_id);
