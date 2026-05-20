-- Migração: criação da tabela chat_history
-- Execute este script no SQL Editor do painel Supabase.
--
-- Tabela: chat_history
--   Armazena o histórico de mensagens trocadas entre o usuário e o Spot AI.
--   Cada linha representa uma única mensagem (do usuário ou do assistente).

create table if not exists public.chat_history (
  id          uuid        primary key default gen_random_uuid(),
  user_id     uuid        not null references auth.users(id) on delete cascade,
  -- 'user' ou 'assistant'
  role        text        not null check (role in ('user', 'assistant')),
  content     text        not null,
  created_at  timestamptz not null default now()
);

-- Índice para buscar o histórico de um usuário ordenado por data
create index if not exists chat_history_user_id_created_at_idx
  on public.chat_history (user_id, created_at asc);

-- Habilita Row Level Security
alter table public.chat_history enable row level security;

-- Política: cada usuário só pode ver suas próprias mensagens
create policy "Usuário lê apenas o próprio histórico"
  on public.chat_history for select
  using (auth.uid() = user_id);

-- Política: cada usuário só pode inserir mensagens para si mesmo
create policy "Usuário insere apenas no próprio histórico"
  on public.chat_history for insert
  with check (auth.uid() = user_id);

-- Política: cada usuário só pode deletar suas próprias mensagens
create policy "Usuário deleta apenas o próprio histórico"
  on public.chat_history for delete
  using (auth.uid() = user_id);
