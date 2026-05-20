-- Adiciona a coluna metadata (jsonb) para salvar metadados extras das mensagens,
-- como a lista de filmes sugeridos pelo assistente.
ALTER TABLE public.chat_history ADD COLUMN metadata jsonb;
