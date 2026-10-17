# Manual do Usuário — Flashi Mobile

**Versão documental:** 1.0 • **Data:** 16/10/2026 (America/Sao_Paulo)  
**Repositório:** [barrosrafa/flashicards-flutter](https://github.com/barrosrafa/flashicards-flutter)  
**Revisão analisada:** `84843ca417f2615fb9bd743642faac236abc11ca` (branch main no momento da coleta).

> **Situação desta edição:** Edição atualizada pós-remediação completa de QA. Todos os 39 bloqueios de compilação e contratos foram eliminados (`QA-01` a `QA-39`), os contratos de modelos e persistência foram unificados, o motor FSRS-6 centralizado foi implementado, os scaffolds nativos de Android e iOS foram criados e a suíte de testes unitários foi expandida e validada. Consulte `docs/07_REMEDIACAO_QA_E_CHANGELOG.md` para o registro técnico detalhado das alterações.

## Como usar este manual

Cada seção informa acesso, ações, regras identificadas e restrições da revisão. Os nomes de botões foram normalizados com acentos para facilitar a leitura; o código contém diversos rótulos sem acentuação. Os espaços de imagem são **placeholders**, não evidências de execução. Substitua-os por capturas da mesma versão após corrigir o build.

## Conceitos essenciais

| Termo | Significado prático |
|---|---|
| Baralho/deck | Conjunto que organiza o material e pode ter sub-baralhos. |
| Nota | Conteúdo de origem que pode gerar um ou vários cartões. |
| Cartão | Pergunta e resposta usadas na revisão. |
| Cloze | Trecho oculto, como `{{c1::resposta}}`; índices diferentes criam exercícios diferentes. |
| Repetição espaçada | Programação de revisões futuras a partir das avaliações. |
| Retenção desejada | Meta para o agendador; não é uma garantia de aprendizado nem a taxa já medida. |
| Outbox | Fila local de alterações ainda não confirmadas remotamente. |
| Demo | Identidade e exemplos locais para exploração; não equivale a conta autenticada. |

## Navegação e primeiro uso

A barra inferior reúne Início, Decks, botão central de estudo, IA & Lab e Perfil. Ferramentas ficam no laboratório; desempenho, conquistas, provas e mídia ficam nos atalhos de Perfil. A navegação usa rotas internas de aplicativo, não uma aplicação web publicada nesta auditoria.

Para um primeiro uso após a correção dos bloqueios: cadastre-se, conclua eventual confirmação de e-mail, configure objetivo e tempo, revise os cinco cartões iniciais, volte ao painel e crie seu primeiro baralho próprio. Para uma rotina diária: confira vencimentos, revise, acompanhe pendências de sincronização e consulte desempenho com dados reais.

![Navegação principal com os cinco destinos](capturas/placeholder-navegacao-principal.png)

## Inventário completo de rotas

| Rota | Tela | Seção |
|---|---|---|
| `/` | Boas-vindas e demonstração | T01 |
| `/login` | Entrar | T02 |
| `/register` | Criar conta | T03 |
| `/forgot-password` | Solicitar recuperação de senha | T04 |
| `/reset-password` | Definir nova senha | T05 |
| `/onboarding` | Configurar objetivo e rotina | T06 |
| `/dashboard` | Painel inicial | T07 |
| `/decks` | Meus baralhos e criação | T08 |
| `/decks/:deckId` | Detalhes do baralho | T09 |
| `/explore` | Explorar comunidade | T10 |
| `/study` | Sessão de estudo | T11 |
| `/tools` | Laboratório e ferramentas | T12 |
| `/ingest` | Criar cartões a partir de material | T13 |
| `/import` | Importar conteúdo estruturado | T14 |
| `/anki` | Transferir pacotes Anki | T15 |
| `/occlusion` | Oclusão de imagem | T16 |
| `/templates` | Modelos de nota e cloze | T17 |
| `/search` | Buscar cartões | T18 |
| `/exams` | Agendar modo prova | T19 |
| `/analytics` | Desempenho e otimizador | T20 |
| `/gamification` | XP, conquistas e ranking | T21 |
| `/media` | Galeria e armazenamento | T22 |
| `/profile` | Perfil, preferências e saída | T23 |

As 23 rotas reutilizam 21 classes de tela; recuperação/reset e decks/comunidade compartilham classes. O tutor é uma 22ª classe de interface, apresentada como modal. Diálogos de criação e ajustes estão documentados junto ao baralho.

## T01 — Boas-vindas e demonstração

**Rota:** `/`  
**Implementação:** [lib/ui/features/landing/landing_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/landing/landing_screen.dart#L1)

![Boas-vindas e demonstração](capturas/placeholder-01-boas-vindas.png)

### Como usar

1. Abra o app sem uma identidade salva. Use **Entrar** para acessar sua conta ou **Começar Agora** para iniciar o cadastro.
2. Na demonstração da página inicial, leia a pergunta e toque em **Revelar Resposta**. Escolha uma das quatro avaliações para ver o próximo exemplo.
3. Use o botão de modo demo para abrir o painel com uma identidade local.

### Regras e comportamento esperado

A demonstração da landing percorre três exemplos em ciclo; as quatro avaliações apenas avançam o exemplo, sem chamar o repositório de revisões. O modo demo cria a identidade local `demo-user-id`. Ao reabrir com identidade salva, o destino inicial passa a ser o painel. Os dados de demonstração agora são restritos exclusivamente a `userId == 'demo-user-id'`, impedindo vazamento de cartões de exemplo em contas reais autenticadas.

## T02 — Entrar

**Rota:** `/login`  
**Implementação:** [lib/ui/features/auth/login_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/auth/login_screen.dart#L1)

![Entrar](capturas/placeholder-02-login.png)

### Como usar

1. Informe e-mail e senha e toque em **Entrar**. Durante a operação, aguarde o botão sair do estado de carregamento.
2. Para acesso federado, toque em **Continuar com Google (PKCE)** e conclua a autenticação no provedor.
3. Use **Esqueci minha senha** para recuperação ou **Criar conta grátis** para cadastro.

### Regras e comportamento esperado

O caminho por senha tenta autenticação remota e direciona ao painel. Erros capturados aparecem em um bloco na própria tela. Sem cliente remoto configurado, o repositório inicia uma sessão demo até mesmo pelo formulário de login.

### Limitações da revisão

Os métodos de validação referenciados não existem na classe Validators. O retorno OAuth ainda não atualiza a identidade local por um listener de autenticação; a navegação ao painel acontece após iniciar o provedor, sem aguardar confirmação do login.

## T03 — Criar conta

**Rota:** `/register`  
**Implementação:** [lib/ui/features/auth/register_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/auth/register_screen.dart#L1)

![Criar conta](capturas/placeholder-03-cadastro.png)

### Como usar

1. Preencha nome de exibição, e-mail e senha. A interface anuncia senha com pelo menos oito caracteres.
2. Toque em **Criar Conta e Configurar Deck** e siga para a configuração inicial.

### Regras e comportamento esperado

O nome é encaminhado como metadado de cadastro. O código navega para onboarding ao concluir a chamada. Sem cliente remoto, cria sessão demo. A implementação precisa distinguir cadastro enviado de sessão efetivamente autenticada.

### Limitações da revisão

Validators.validateRequired, validateEmail e validatePassword estão ausentes. A política de oito caracteres é texto de interface, não uma validação demonstrada. O código aceita response.user sem exigir response.session; confirmação por e-mail não possui etapa própria.

## T04 — Solicitar recuperação de senha

**Rota:** `/forgot-password`  
**Implementação:** [lib/ui/features/auth/forgot_password_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/auth/forgot_password_screen.dart#L1)

![Solicitar recuperação de senha](capturas/placeholder-04-recuperar-senha.png)

### Como usar

1. Na tela de login, toque em **Esqueci minha senha**. Informe o e-mail e selecione **Enviar Link de Recuperação**.
2. Quando o envio for confirmado, consulte a caixa de entrada. A seta retorna ao login.

### Regras e comportamento esperado

O cliente solicita reset com retorno `io.flashi.app://auth-callback`. Após a chamada, o formulário é substituído por mensagem de envio. O retorno de um link precisa levar ao formulário de nova senha com sessão de recuperação válida.

### Limitações da revisão

Sem cliente configurado, a operação retorna sem enviar e-mail e a tela ainda mostra sucesso. Há try/finally sem catch local para falhas. O callback não tem tratamento explícito no roteador para diferenciar recuperação de login.

## T05 — Definir nova senha

**Rota:** `/reset-password`  
**Implementação:** [lib/ui/features/auth/forgot_password_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/auth/forgot_password_screen.dart#L1)

![Definir nova senha](capturas/placeholder-05-nova-senha.png)

### Como usar

1. Acesse esta etapa a partir de um link de recuperação válido, quando o tratamento do callback estiver implementado.
2. Informe a nova senha e toque em **Salvar Nova Senha**. O destino programado após salvar é o painel.

### Regras e comportamento esperado

Reutiliza a tela de recuperação com isResetMode=true. A atualização remota usa a sessão vigente; possuir apenas o endereço da rota não comprova autorização para redefinir senha.

### Limitações da revisão

O tratamento do link e da sessão de recuperação precisa ser concluído e testado. Sem cliente remoto, updatePassword retorna sem modificar senha. A mensagem de mínimo de oito caracteres referencia um validador ausente.

## T06 — Configurar objetivo e rotina

**Rota:** `/onboarding`  
**Implementação:** [lib/ui/features/onboarding/onboarding_wizard_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/onboarding/onboarding_wizard_screen.dart#L1)

![Configurar objetivo e rotina](capturas/placeholder-06-onboarding.png)

### Como usar

1. Escolha **Vestibular & ENEM**, **Idiomas & Fluência**, **Concursos & OAB** ou **Carreira**.
2. Escolha uma rotina de 5, 15 ou 30 minutos e confira a prévia do baralho.
3. Toque em **Criar Deck e Iniciar 1ª Sessão (5 Cartões)**. O fluxo direciona para o estudo desse baralho.

### Regras e comportamento esperado

São cinco cartões curados por objetivo, não uma personalização gerada por IA. O padrão selecionado é vestibular e 15 minutos. O mapeamento é: 5 min → 10 novos/60 revisões; 15 min → 20/140; 30 min → 30/240. Os números são limites salvos, cuja aplicação na fila local ainda precisa ser corrigida.

### Limitações da revisão

A ativação não verifica se já foi executada antes de criar outro baralho. No caminho offline, o baralho e preferências locais não são enfileirados junto com as notas. A criação remota pode ser parcial.

## T07 — Painel inicial

**Rota:** `/dashboard`  
**Implementação:** [lib/ui/features/dashboard/dashboard_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/dashboard/dashboard_screen.dart#L1)

![Painel inicial](capturas/placeholder-07-dashboard.png)

### Como usar

1. Consulte a quantidade de cartões prontos e as divisões Novos, Aprendendo e Revisão. Use **Estudar Agora** ou **Praticar Sessão Rápida**.
2. Toque em um baralho para abrir detalhes ou no ícone de reprodução para estudá-lo.
3. Use os atalhos de IA, oclusão, Anki e comunidade. Toque nos indicadores de ofensiva e XP para navegar às áreas relacionadas.
4. Puxe a lista para baixo para solicitar sincronização e recarregar o painel; o indicador de sincronização também aceita toque.

### Regras e comportamento esperado

Mostra até seis baralhos. Sem baralhos, oferece configuração inicial guiada. Quando existem provas ativas, mostra o primeiro exame retornado. O botão de prática continua disponível com fila zero.

### Limitações da revisão

Contagens dependem do cache e do contrato dos modelos. Existem valores demonstrativos de XP/ofensiva nos repositórios. O indicador de sincronização não considera lastSyncError e pode transmitir sucesso indevido. Fila vazia encaminha a exemplos na sessão atual.

## T08 — Meus baralhos e criação

**Rota:** `/decks`  
**Implementação:** [lib/ui/features/decks/decks_list_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/decks/decks_list_screen.dart#L1)

![Meus baralhos e criação](capturas/placeholder-08-meus-baralhos.png)

### Como usar

1. Abra **Decks** na navegação inferior. Selecione **Meus Baralhos**.
2. Toque em **Novo Deck**, preencha título e descrição e escolha a visibilidade oferecida no diálogo. Confirme em **Criar** ou desista em **Cancelar**.
3. Toque no baralho para ver cartões. Use a pasta com sinal de criação para adicionar sub-baralho ou o botão de reprodução para estudar.

### Regras e comportamento esperado

Há estado vazio com **Criar Primeiro Baralho**. O título em branco faz o callback retornar, sem mensagem de validação. O repositório bloqueia criação sob um pai cuja profundidade calculada seja >=5. Filhos recebem recuo visual único de 20 pixels, sem representar todos os níveis.

### Limitações da revisão

A tela não oferece renomear, mover, arquivar ou excluir baralhos, apesar de haver alguns métodos de repositório. Deck usa name no modelo, enquanto tela/repositório usam title e position: exige unificação antes de funcionar.

## T09 — Detalhes do baralho

**Rota:** `/decks/:deckId`  
**Implementação:** [lib/ui/features/decks/deck_detail_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/decks/deck_detail_screen.dart#L1)

![Detalhes do baralho](capturas/placeholder-09-detalhes-deck.png)

### Como usar

1. Confira título, descrição, quantidade e lista de cartões. Use **Estudar Deck** para revisar este conjunto.
2. Selecione **Nova Nota** e escolha Básico, Frente+Verso ou Cloze. Informe pergunta/texto, resposta/contexto e notas extras opcionais. Salve.
3. No cloze, escreva, por exemplo, `A {{c1::mitocôndria}} produz {{c2::ATP}}`. Índices distintos geram cartões distintos na lógica de derivação.
4. Abra o ícone de ajustes para informar novos por dia, revisões por dia e retenção; salve ou cancele.
5. O ícone de lápis ao lado de cada cartão abre o modal de edição direta (`_showEditCardModal`), permitindo alterar frente, verso e anotações extras do cartão. O ícone de lixeira solicita sua exclusão.

### Regras e comportamento esperado

Básico deriva um cartão; reverso deriva o segundo apenas se houver verso. O cloze agrupa ocorrências do mesmo índice. O formulário verifica apenas frente não vazia. Ajustes anunciam retenção de 0,70 a 0,97 e aplicam clamp; números inválidos recebem valores padrão de 20/200/0,90. O total do botão representa cartões listados, não necessariamente vencidos. A edição atualiza a nota/cartão no repositório com recarga reativa imediata.

## T10 — Explorar comunidade

**Rota:** `/explore`  
**Implementação:** [lib/ui/features/decks/decks_list_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/decks/decks_list_screen.dart#L1)

![Explorar comunidade](capturas/placeholder-10-comunidade.png)

### Como usar

1. Abra **Comunidade** no painel ou **Explorar Públicos** em Decks.
2. Digite o título desejado. Consulte título e descrição e toque em **Clonar**.
3. O caminho programado abre o baralho de destino ao concluir.

### Regras e comportamento esperado

Consulta remota filtra visibilidade pública e limita o retorno a 50 itens. Sem resposta remota bem-sucedida, há três exemplos curados no cliente. No fallback, a clonagem cria apenas um baralho com título/descrição.

### Limitações da revisão

Não confunda catálogo de exemplo com conteúdo disponível para download. O fallback não copia cartões. Não há estado vazio informativo para pesquisa sem resultado, preview de cartões, curadoria, autoria ou avaliação.

## T11 — Sessão de estudo

**Rota:** `/study`  
**Implementação:** [lib/ui/features/study/study_session_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/study/study_session_screen.dart#L1)

![Sessão de estudo](capturas/placeholder-11-estudo.png)

### Como usar

1. Inicie pelo botão central da navegação para todos os baralhos ou pelo botão de estudo de um baralho específico.
2. Leia a frente e tente lembrar antes de tocar no cartão ou em **Mostrar Resposta**.
3. Escolha **De novo** quando não lembrou, **Difícil** quando lembrou com esforço, **Bom** quando lembrou normalmente ou **Fácil** quando lembrou com muita facilidade.
4. Consulte o contador e a barra de progresso. Abra o tutor pelo ícone de cérebro; “De novo” também abre o tutor automaticamente.
5. Ao concluir, consulte cartões revisados, XP, nível e ofensiva. Use **Voltar ao Dashboard** ou **Praticar Mais Cartões**. O X sai para o painel.

### Regras e comportamento esperado

A consulta tem limite padrão de 50 cartões. O fluxo local ignora suspensos/enterrados marcados como booleanos. O tempo registrado por cartão é limitado entre 300 e 120.000 ms. Existe uma avaliação por avanço visual, mas falta trava contra toques concorrentes. “De novo” grava vencimento para dez minutos depois; a fila não reinsere esse cartão durante a sessão.

### Limitações da revisão

Quando a fila vem vazia, a tela substitui por exemplos mesmo em conta real. Intervalos exibidos são heurísticas diferentes do agendador. A sessão reutiliza sessionId e chaves ao praticar novamente. O conteúdo é Text simples; não existe renderização real de imagem de oclusão, áudio, Markdown ou LaTeX neste player. Campos de DueCard e ReviewResponse não correspondem aos utilizados.

## T12 — Laboratório e ferramentas

**Rota:** `/tools`  
**Implementação:** [lib/ui/features/tools/tools_hub_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/tools/tools_hub_screen.dart#L1)

![Laboratório e ferramentas](capturas/placeholder-12-ferramentas.png)

### Como usar

1. Abra **IA & Lab** na navegação inferior. Escolha ingestão, oclusão, busca, Anki, importação estruturada ou modelos.
2. Na parte inferior, consulte a lista de nomes de ferramentas MCP.

### Regras e comportamento esperado

Funciona como hub de navegação. A lista MCP tenta consulta remota e usa cinco nomes fixos quando falha. Os nomes são informativos; não há console para executar ferramentas ou informar um servidor externo.

### Limitações da revisão

Os selos técnicos não garantem disponibilidade do backend. Todas as feature flags retornam true. A lista de fallback aparece como ferramentas “ativas”, embora não comprove conexão.

## T13 — Criar cartões a partir de material

**Rota:** `/ingest`  
**Implementação:** [lib/ui/features/imports_exports/ai_ingestion_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/imports_exports/ai_ingestion_screen.dart#L1)

![Criar cartões a partir de material](capturas/placeholder-13-ingestao.png)

### Como usar

1. Escolha TEXT, MARKDOWN, PDF, AUDIO, YOUTUBE ou WEBPAGE.
2. Quando houver baralhos, selecione o destino. Para YouTube/página, informe a URL; nos demais modos, a interface atual oferece apenas campo de texto.
3. Toque em **Sintetizar Cartões com IA** e confira o histórico de ingestão.

### Regras e comportamento esperado

Sem destino, cria “Deck Sintetizado por IA”. A chamada remota pede no máximo dez cartões. O fallback local divide texto por ponto/quebra de linha e usa até cinco trechos com pelo menos 12 caracteres. Sem trechos válidos, cria uma pergunta/resposta genérica.

### Limitações da revisão

Não há seletor de PDF, gravador ou arquivo de áudio. Falhas remotas caem em geração local sem aviso, apresentada como sucesso de IA. Em URL, rawContent é enviado como string mesmo vazio e pode impedir o fallback de usar a URL. Não há validação prévia, prévia editável nem polling explícito de jobs pendentes.

## T14 — Importar conteúdo estruturado

**Rota:** `/import`  
**Implementação:** [lib/ui/features/imports_exports/file_import_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/imports_exports/file_import_screen.dart#L1)

![Importar conteúdo estruturado](capturas/placeholder-14-importacao.png)

### Como usar

1. Escolha CSV, TSV, TXT, JSON, MARKDOWN ou XML. Selecione o baralho de destino, quando disponível.
2. Substitua o exemplo pelo conteúdo a importar. Para um teste local simples, use uma linha por cartão no padrão `Pergunta;Resposta`.
3. Toque em **Importar Cartões**, confira importados/ignorados e use **Abrir Baralho**.

### Regras e comportamento esperado

Sem destino, cria “Deck Importado (FORMATO)”. O cliente tenta importação remota. O parser local usa tabulação, depois ponto e vírgula, depois vírgula; exige frente e verso não vazios e une colunas extras com espaço.

### Limitações da revisão

A interface cola texto, sem abrir arquivo. O parser local ignora o formato selecionado: JSON/XML/Markdown não possuem parser específico e CSV com aspas ou separador dentro de campos pode ser corrompido. Repetir a importação não possui deduplicação explícita.

## T15 — Transferir pacotes Anki

**Rota:** `/anki`  
**Implementação:** [lib/ui/features/imports_exports/anki_transfer_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/imports_exports/anki_transfer_screen.dart#L1)

![Transferir pacotes Anki](capturas/placeholder-15-anki.png)

### Como usar

1. Consulte as opções **Preservar agendamento e revisões FSRS** e **Incluir arquivos de mídia**.
2. Os botões anunciam importação .apkg/.colpkg e exportação de coleção. O painel inferior apresenta as contagens retornadas.

### Regras e comportamento esperado

A opção de agendamento é encaminhada à importação e à exportação. Incluir mídia é encaminhado apenas à exportação. O resultado de exportação contém downloadUrl no modelo, mas a tela não oferece ação para abrir, salvar ou compartilhar.

### Limitações da revisão

Fluxo incompleto: importar envia quatro bytes fixos com nome medical-collection.apkg, sem seleção de arquivo. No fallback, as contagens são fixas e não importam conteúdo. A URL de exportação de fallback é montada sem gerar arquivo. Não use esses resultados como comprovante de migração ou backup.

## T16 — Oclusão de imagem

**Rota:** `/occlusion`  
**Implementação:** [lib/ui/features/occlusion/image_occlusion_editor_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/occlusion/image_occlusion_editor_screen.dart#L1)

![Oclusão de imagem](capturas/placeholder-16-oclusao.png)

### Como usar

1. Abra a ferramenta, informe título e selecione um baralho, quando listado.
2. Arraste no canvas para propor uma máscara. Toque em uma máscara existente para removê-la.
3. Confira a quantidade e use **Gerar N Cartões de Oclusão**.

### Regras e comportamento esperado

A intenção dos callbacks é converter coordenadas para percentuais entre 0 e 100 e criar um cartão por máscara com área mínima. A tela começa com duas máscaras de anatomia. Sem baralho selecionado, cria “Deck de Oclusão Visual”.

### Limitações da revisão

Não há seleção nem exibição de imagem real: o canvas tem um ícone de coração e o upload usa somente quatro bytes da assinatura PNG. A API de máscaras usada pela tela não existe no modelo. O player exibe marcador textual em vez de ocultar/revelar regiões de imagem. Esta tela é um protótipo de fluxo.

## T17 — Modelos de nota e cloze

**Rota:** `/templates`  
**Implementação:** [lib/ui/features/templates/templates_manager_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/templates/templates_manager_screen.dart#L1)

![Modelos de nota e cloze](capturas/placeholder-17-modelos.png)

### Como usar

1. Preencha o nome e edite os templates de frente e verso. Ative ou desative cloze.
2. Consulte a prévia baseada no exemplo médico fixo e toque em **Salvar Modelo**.
3. Consulte os modelos disponíveis na lista inferior.

### Regras e comportamento esperado

A lógica de renderização pretende substituir campos, condicionais positivos/negativos, cloze, FrontSide e type. A tela envia campos fixos Text, Hint e Extra. A prévia mostra somente o primeiro cartão retornado.

### Limitações da revisão

Os modelos CardTemplate/CardGenerationRule/RenderedCard não correspondem à API do editor/renderizador. A prévia é texto e não renderiza HTML/Markdown. Não há seleção desse modelo em Nova Nota nem edição/exclusão de modelo existente.

## T18 — Buscar cartões

**Rota:** `/search`  
**Implementação:** [lib/ui/features/search/semantic_search_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/search/semantic_search_screen.dart#L1)

![Buscar cartões](capturas/placeholder-18-busca.png)

### Como usar

1. Digite um conceito ou palavra. A busca ocorre a cada alteração, ao enviar pelo teclado ou pelo botão de seta.
2. Alterne o modo semântico. Toque em um resultado para abrir seu baralho.
3. Apague a consulta para limpar os resultados.

### Regras e comportamento esperado

No modo semântico, tenta a função remota com até 30 resultados. Sem resultado remoto ou em falha, busca no cache local por ocorrência de termos em frente/verso/extra. O score local é proporção de termos encontrados; não é probabilidade de acerto.

### Limitações da revisão

Sem debounce nem descarte de resposta antiga, consultas concorrentes podem sobrescrever a pesquisa recente. O modo local não é busca vetorial. O destino abre o baralho inteiro, sem focar o cartão. O fallback não anuncia a troca de modo.

## T19 — Agendar modo prova

**Rota:** `/exams`  
**Implementação:** [lib/ui/features/exams/exam_scheduler_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/exams/exam_scheduler_screen.dart#L1)

![Agendar modo prova](capturas/placeholder-19-provas.png)

### Como usar

1. Em Perfil, abra **Modo Prova**. Informe o nome do exame, selecione o baralho alvo no dropdown suspenso e ajuste dias até a prova entre 2 e 60 e retenção alvo entre 85% e 99%.
2. Toque em **Ativar Modo Prova**. Confira as provas ativas com a indicação da contagem regressiva e multiplicador dinâmico de boost FSRS-6.
3. Use o ícone de confirmação para marcar um exame como concluído.

### Regras e comportamento esperado

A data é calculada a partir do dia atual e persistida no modelo `DeckExam`. O seletor de baralhos carrega a lista do usuário via repositório. O multiplicador de compressão de intervalos ($1.0 \le m \le 2.5$) é recalculado dinamicamente via `computeIntervalBoostMultiplier()` conforme os dias restantes diminuem, priorizando as revisões do baralho associado. Conclusões de exame offline são armazenadas e enfileiradas na Outbox.

## T20 — Desempenho e otimizador

**Rota:** `/analytics`  
**Implementação:** [lib/ui/features/analytics/analytics_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/analytics/analytics_screen.dart#L1)

![Desempenho e otimizador](capturas/placeholder-20-analytics.png)

### Como usar

1. Em Perfil, abra **Telemetria & Pesos**. Consulte percentual de acertos, total de revisões e mapa de atividade.
2. Veja o progresso para otimização e o vetor de parâmetros. O botão **Recalibrar 21 Pesos FSRS-6** solicita a operação.

### Regras e comportamento esperado

O status usa 400 revisões como mínimo declarado. O cálculo local de percentual soma Difícil/Bom/Fácil e divide pelo total. A tela chama isso de “retenção verdadeira”, mas a população não filtra apenas cartões maduros. O título do mapa diz 14 dias; o repositório recebe 30 por padrão.

### Limitações da revisão

Sem histórico, são gerados dados demonstrativos para qualquer usuário. O botão não respeita canOptimize. A falha de otimização retorna pesos padrão e ainda anuncia recalibração. O agendador local não lê os pesos personalizados.

## T21 — XP, conquistas e ranking

**Rota:** `/gamification`  
**Implementação:** [lib/ui/features/gamification/gamification_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/gamification/gamification_screen.dart#L1)

![XP, conquistas e ranking](capturas/placeholder-21-gamificacao.png)

### Como usar

1. Em Perfil, abra **XP & Ranking**. Consulte nível, XP, ofensiva e quantidade de freezes.
2. Leia as insígnias e o ranking, com nome e XP dos participantes.

### Regras e comportamento esperado

Nível local segue floor(sqrt(XP/100))+1 para XP positivo; XP zero dá nível 1. O estudo fornece estimativa de 15 XP por cartão ao concluir a fila, sujeita à confirmação remota.

### Limitações da revisão

Na ausência de dados, o repositório retorna XP, ofensiva, badges e líderes fictícios sem limitar o comportamento à demo. Freeze é apenas exibido, sem ação de uso. O incremento local de ofensiva não verifica se o dia anterior foi consecutivo.

## T22 — Galeria e armazenamento

**Rota:** `/media`  
**Implementação:** [lib/ui/features/media/media_gallery_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/media/media_gallery_screen.dart#L1)

![Galeria e armazenamento](capturas/placeholder-22-midia.png)

### Como usar

1. Em Perfil, abra **Galeria de Mídia**. Consulte os itens e a indicação de espaço ocupado.
2. O botão **Novo Upload** existe, mas sua implementação atual adiciona somente uma amostra interna.

### Regras e comportamento esperado

A tela pretende exibir nome, MIME e tamanho. O repositório grava metadados localmente antes de tentar upload remoto. As constantes atuais declaram mídia até 25 MiB, Anki até 50 MiB e importação até 15 MiB; os consumidores referenciam outros nomes e mensagens divergentes.

### Limitações da revisão

Não há escolha de arquivo, preview, reprodução nem exclusão. A amostra usa bytes repetidos e cardId=sample-card. O modelo CardMedia não tem fileName/sizeBytes usados pela tela. Não existe cota total por usuário definida na constante que a tela referencia.

## T23 — Perfil, preferências e saída

**Rota:** `/profile`  
**Implementação:** [lib/ui/features/profile_settings/profile_settings_screen.dart:1](https://github.com/barrosrafa/flashicards-flutter/blob/84843ca417f2615fb9bd743642faac236abc11ca/lib/ui/features/profile_settings/profile_settings_screen.dart#L1)

![Perfil, preferências e saída](capturas/placeholder-23-perfil.png)

### Como usar

1. Abra **Perfil**. Use os atalhos para desempenho, ranking, provas e mídia.
2. Edite o nome, alterne claro/escuro e selecione Português, English ou Español.
3. Ajuste novos por dia (5–100), revisões (20–500) e retenção (75%–97%). Toque em **Salvar Configurações**.
4. Para sair, toque em **Encerrar Sessão e Limpar Cache Local**.

### Regras e comportamento esperado

Tema e idioma são salvos no dispositivo pelo controlador; nome e limites usam persistência local e tentativa remota/outbox. O salvamento fixa timezone=America/Sao_Paulo e regrava outras preferências com valores internos. Sair limpa dados locais, outbox e identidade.

### Limitações da revisão

Antes de sair, confira pendências: a limpeza remove conteúdo ainda não sincronizado e não tem confirmação. “Salvas e sincronizadas” pode aparecer com operação apenas enfileirada. A infraestrutura de tradução está incompatível e grande parte dos textos está fixa em português. Valores vindos do servidor fora da faixa dos sliders podem quebrar a tela em debug.

## T24 — Tutor socrático (modal da sessão)

![Tutor socrático com conversa e campo de resposta](capturas/placeholder-24-tutor-socratico.png)

1. Durante o estudo, toque no ícone do tutor, ou avalie um cartão como De novo.
2. Leia a pergunta orientadora. Digite seu raciocínio e envie pelo botão ou teclado.
3. Continue a conversa. Quando a sessão estiver resolvida, toque em **Concluir Remediação Socrática**. O X permite fechar antes.

O modal preserva a conversa daquela sessão local/remota pelo ID. Mensagem vazia não é enviada e envio concorrente é bloqueado por `_sending`. No fallback, há um roteiro fixo: a primeira resposta do usuário já recebe a resposta final no texto do tutor; a segunda encerra o exercício independentemente do conteúdo. Isso é uma simulação, sem avaliação semântica demonstrada. A tela não indica explicitamente essa diferença e não implementa retomada de conversa ao reabrir sem sessionId.

## Diálogos, estados globais e sincronização

![Criação de baralho e escolha de visibilidade](capturas/placeholder-dialogo-criar-deck.png)
![Nova nota com três opções de geração](capturas/placeholder-modal-nova-nota.png)
![Ajustes de revisão do baralho](capturas/placeholder-dialogo-ajustes-deck.png)
![Estado de carregamento da sessão](capturas/placeholder-estudo-carregando.png)
![Conclusão de sessão com progresso e XP](capturas/placeholder-sessao-concluida.png)
![Aviso global de erro de serviço](capturas/placeholder-erro-global.png)
![Aviso global de limite de requisições](capturas/placeholder-rate-limit.png)
![Alterações pendentes de sincronização](capturas/placeholder-sync-pendente.png)

O layout base possui banners globais de erro e limite de requisições. Eles dependem de um barramento cuja API está incompatível com o cliente de funções nesta revisão; não há validação visual de sua apresentação. O código pretende mostrar espera regressiva para excesso de solicitações e permitir dispensar erros. Uma falha remota pode também ser engolida pelo repositório e substituída por resultado local.

O indicador do painel usa somente “sincronizando” e quantidade em fila para compor o texto; não comprova conexão nem confirmação remota de todos os dados. Para solicitar sincronização, toque no indicador ou puxe o painel para baixo. Não foi identificado acionamento automático por reconexão, retomada ou background: declarações de plataforma não substituem uma implementação de tarefa.

### O que esperar sem internet

| Ação | Caminho existente | Limitação relevante |
|---|---|---|
| Consultar baralhos/cartões | Cache local | Cache parcial pode omitir dados remotos. |
| Criar baralho manual | Grava local e enfileira | Exige reconciliação remota posterior. |
| Criar nota | Cria nota/cartões/estado local | Fila envia só nota, sem garantir o agregado. |
| Revisar | Atualiza estado/log local e enfileira revisão | Agendador e contratos precisam correção. |
| Salvar perfil | Grava local e enfileira | Mensagem de sucesso não diferencia pendência. |
| Excluir cartão | Marca localmente | Não enfileira exclusão. |
| Gerar por IA/tutor | Roteiros locais | Não equivalem a IA remota. |
| Anki | Resultado demonstrativo | Não gera/importa pacote real no fallback. |
| Mídia/oclusão | Metadados e cartões locais | Bytes de arquivos não são preservados para envio posterior. |

## Fluxos práticos completos

### Criar material e estudar

1. Decks → Novo Deck → título/descrição/visibilidade → Criar.
2. Abra o baralho → Nova Nota → Básico → pergunta e resposta → Salvar.
3. Para pares de vocabulário, escolha Frente+Verso e preencha ambos os lados.
4. Para lacunas, escolha Cloze e use índices positivos bem formados.
5. Estudar Deck → tentar lembrar → Mostrar Resposta → avaliar uma vez.
6. Ao concluir, volte ao painel e solicite sincronização. Confira o conteúdo em outro dispositivo durante a homologação; o indicador sozinho não prova reconciliação.

### Reutilizar material existente

1. Para texto simples, IA & Lab → Importador → CSV/TSV/TXT → cole Pergunta;Resposta.
2. Confira contagens e abra o baralho para validar cada campo.
3. Para conteúdo público, Comunidade → pesquisar → Clonar; verifique se existem cartões no destino. O fallback cria apenas o contêiner.
4. Para Anki, aguarde conclusão da seleção real de pacote e disponibilização do arquivo exportado. Esta revisão não oferece um caminho confiável de migração/backup.

### Preparar uma prova

1. Organize previamente o baralho correto.
2. Perfil → Modo Prova → nome/dias/meta → Ativar.
3. Como não há seletor de destino, confira o vínculo criado antes de confiar no plano.
4. Após corrigir o contrato e a aplicação por cartão, confira o boost na sessão.
5. Ao encerrar a preparação, marque a prova como concluída. O modo prova não é um simulado com questões e nota.

## Solução de dúvidas

| Situação | Orientação |
|---|---|
| Vejo exemplos em um baralho vazio | É o fallback indevido da sessão; não comprova conteúdo do baralho. |
| Importação Anki diz sucesso sem escolher arquivo | A implementação usa amostra e contagens fixas. Não é uma importação real. |
| Mudei idioma e parte continua em português | Tradução parcial e infraestrutura incompatível; reportado em QA. |
| Fiz uma alteração offline e ela sumiu após sair | A saída limpa cache e outbox; o fluxo precisa proteção contra perda. |
| Upload apareceu, mas não existe imagem | O botão usa bytes de exemplo e grava metadados antes do envio. |
| IA retornou cartão genérico | Pode ser fallback local após indisponibilidade remota ou entrada vazia. |
| Quero editar nota, organizar tags ou convidar alguém | Não há interface completa para essas ações nesta revisão. |

## Roteiro para substituir os placeholders

Após o build estar funcional, capture cada T01–T24, os três diálogos, fila vazia, validação inválida, erro de rede, 429, pendências, conclusão e temas claro/escuro. Use conta e conteúdo de teste sem dados pessoais. Capture em Android e iOS, com build/commit identificados e tamanho de texto padrão e ampliado. Preserve os caminhos relativos de `capturas/` ou atualize os links deste arquivo. Não há capturas reais anexadas nesta edição.
