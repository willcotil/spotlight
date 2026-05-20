# Spotlight: Documentação de APIs e Integrações

Este documento fornece uma visão geral técnica detalhada de todas as integrações de API e serviços externos utilizados no Spotlight. Ele foi criado para facilitar o entendimento arquitetural, a manutenção e a integração de novos desenvolvedores ao projeto.

## 1. Supabase & Autenticação

O **Supabase** atua como o backend central da aplicação, sendo responsável pela autenticação de usuários, banco de dados PostgreSQL e sincronização em tempo real (caso necessário no futuro).

### 1.1. Inicialização do Cliente
O cliente do Supabase é inicializado assim que a aplicação é executada. A instância do cliente fica disponível em toda a aplicação.

*   **Onde encontrar:** `lib/main.dart` e `lib/services/app_config.dart`.
*   **Lógica principal:** O método `Supabase.initialize()` é chamado no `main()`, recebendo a `url` e `anonKey` definidas na classe abstrata `AppConfig`.

### 1.2. Autenticação (Login/Cadastro)
A aplicação suporta login tradicional via E-mail/Senha e autenticação via OAuth com o Google. A lógica está isolada em um serviço dedicado que serve de wrapper para as chamadas do pacote `supabase_flutter`.

*   **Onde encontrar:** `lib/services/auth_service.dart`.
*   **E-mail/Senha:**
    *   **Cadastro:** Utiliza `supabase.auth.signUp()`, passando não só as credenciais, mas também salvando dados extras (nome, telefone, data de nascimento) na tabela auxiliar `profiles` via `data` metadata.
    *   **Login:** Utiliza `supabase.auth.signInWithPassword()`.
*   **Google OAuth:**
    *   A aplicação implementa um fluxo nativo para dispositivos móveis via `signInWithOAuth`.
    *   **Deep Linking:** Para redirecionar de volta ao aplicativo após o login com sucesso no navegador, configuramos Deep Links.
        *   **Android:** O scheme `br.com.spotlight://login-callback` está registrado via `<intent-filter>` no arquivo `android/app/src/main/AndroidManifest.xml`.
        *   **iOS:** O mesmo scheme está mapeado em `CFBundleURLSchemes` no arquivo `ios/Runner/Info.plist`.

## 2. Banco de Dados (Supabase CRUD)

Os comentários e avaliações dos filmes são salvos no banco de dados do Supabase. Essa tabela está vinculada com a tabela de perfis de usuário, permitindo listar os comentários junto com a foto de perfil e o nome do autor.

*   **Onde encontrar a camada de serviço:** `lib/services/review_service.dart`.
*   **Onde encontrar o estado (Provider):** `lib/providers/reviews_provider.dart`.

### 2.1. Estrutura de Operações CRUD
*   **Create (Adicionar avaliação):** O método `submitRating` (no service) realiza uma inserção na tabela `avaliacoes` contendo `nota` (1 a 10) e `comentario`. Ele utiliza `upsert` indiretamente ou verifica a pré-existência para evitar múltiplas avaliações do mesmo usuário no mesmo filme.
*   **Read (Ler avaliações):** O método `fetchReviews` busca todas as avaliações de um filme (`midia_id`), realizando um `select` com um "JOIN" implícito (através de foreign keys) na tabela `profiles` para puxar os dados do autor da mensagem (nome, avatar_url).
*   **Update (Editar avaliação):** O método `updateReview` chama o endpoint `update()` na tabela `avaliacoes`, localizando o registro via `id` do comentário e garantindo o Ownership com o ID do usuário autenticado.
*   **Delete (Deletar avaliação):** O método `deleteReview` exclui o comentário específico usando `delete().eq('id', reviewId)`.

## 3. The Movie Database (TMDb)

A principal fonte de dados (filmes, séries, elencos, vídeos e onde assistir) vem da API pública do TMDb. Todo o consumo da API REST é encapsulado em uma única classe estática.

*   **Onde encontrar:** `lib/services/tmdb_service.dart`.

### 3.1. Chamadas REST
O serviço utiliza a biblioteca `http` padrão do Flutter e injeta um `Bearer Token` nos cabeçalhos de autenticação (`_headers`).
*   Possui um sistema robusto de Retry e Timeout no método `_withRetry()`, impedindo que a tela fique congelada indefinidamente em caso de falhas na conexão.

### 3.2. Endpoints e Filtros Específicos
*   **Lançamentos e Tendências:** `fetchTrending`, `fetchNewsByProvider` e listagens baseadas em gêneros (`fetchAction`, `fetchFamily`, etc).
*   **Filtros de Segurança:** O método `_filterFutureContent()` foi adicionado para interceptar todas as respostas principais da API e remover filmes lançados além de `31/12/2026`. Isso resolve o problema de poluição da interface com conteúdos fictícios ou agendados para anos demasiadamente distantes.
*   **Imagens de Provedores:** O mapeamento lógico (`_providerSlugMap`) transforma IDs do TMDb em slugs (`netflix`, `hbo`, `prime`). No front-end (`lib/widgets/ui_components.dart`), os ícones das plataformas usam SVGs locais ou imagens permanentes via CDN para prevenir o erro de URLs expiradas/purgadas da Max, Star+ e Globoplay.

## 4. Google Generative AI (Gemini)

A aba de chat inteligente do Spotlight é movida pela API do Gemini. Ela permite que os usuários façam perguntas orgânicas e recebam recomendações precisas.

*   **Onde encontrar:** `lib/services/gemini_service.dart`.
*   **Onde encontrar a chave (Secrets):** `lib/services/app_secrets.dart`.

### 4.1. Lógica do Prompt
A IA possui um "System Instruction" blindado que a força a atuar sempre como um assistente gentil, no contexto de filmes e séries, e respondendo exclusivamente em Português do Brasil.

### 4.2. Fluxo da Conversa
No `chat_provider.dart`, cada mensagem digitada pelo usuário faz o seguinte caminho:
1.  Salva a mensagem do usuário localmente e atualiza a UI.
2.  Persiste a mensagem no Supabase (`loadHistory` / `sendMessage`).
3.  Usa a IA para extrair apenas "palavras-chave" (ex: "Quero filmes parecidos com Matrix" -> "Matrix") via `GeminiService.extractSearchKeywords()`.
4.  Realiza a busca dessa palavra-chave no **TMDb**.
5.  Constrói um prompt super-enriquecido que envia para a IA o pedido do usuário e, "escondida", a lista dos filmes retornados pelo TMDb.
6.  A IA responde recomendando ativamente os filmes que ela sabe que existem no catálogo da aplicação, gerando a resposta final (Markdown) com carrossel dinâmico em `lib/features/chat/chat_view.dart`.

## 5. Arquivos Ignorados (.gitignore)
Para a liberação no GitHub, garantimos que dados críticos fiquem de fora do repositório:
*   `.env`
*   `lib/services/app_secrets.dart`

Foi criado um modelo `.env.example` na raiz do projeto contendo as chaves que você precisa configurar localmente após o clone do repositório.

---
_Documento gerado automaticamente para o repositório Spotlight._