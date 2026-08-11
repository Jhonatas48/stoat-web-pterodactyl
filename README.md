# Stoat Web Development para Pterodactyl

Egg de desenvolvimento do cliente oficial [`stoatchat/for-web`](https://github.com/stoatchat/for-web),
preparado para conectar ao egg do backend Stoat.

## Recursos

- Node.js 26 e pnpm 11.3 pré-instalados na imagem;
- compatível com `linux/amd64` e `linux/arm64`;
- clonagem do fork e dos submódulos públicos;
- fallback automático para os assets públicos quando os assets internos da
  marca não estiverem disponíveis;
- modo `development` com Vite e hot reload;
- modo `preview` para validar o build final;
- caches persistentes dentro de `/home/container`;
- configuração separada para API, WebSocket, Autumn, January e Gifbox.

## Topologia esperada

| Serviço | Porta |
|---|---:|
| Frontend | 14701 |
| Delta/API | 14702 |
| Bonfire/WebSocket | 14703 |
| Autumn/arquivos | 14704 |
| January/proxy | 14705 |
| Gifbox | 14706 |

Para o primeiro teste, todas essas portas podem apontar para o mesmo IP público
do nó. O frontend fica em um servidor Pterodactyl separado do backend.

## 1. Publicar a imagem

Crie um repositório GitHub para este pacote, envie os arquivos para a raiz e
execute o workflow `Build and publish frontend image`. Ele publicará:

```text
ghcr.io/SEU_USUARIO/stoat-web-pterodactyl:latest
```

Deixe o package público. No arquivo `egg-stoat-web-development.json`, substitua
todas as ocorrências de `ghcr.io/seu_usuario/stoat-web-pterodactyl:latest` pela
imagem real, sempre em letras minúsculas.

## 2. Importar o egg

1. Entre na administração do Pterodactyl.
2. Abra um Nest e use `Import Egg`.
3. Selecione `egg-stoat-web-development.json`.
4. Crie um servidor com a allocation principal `14701`.
5. Reserve inicialmente 4 GB de RAM, 2 vCPUs e 10 GB de disco.

## 3. Configurar as variáveis

Exemplo usando o IP `203.0.113.10`:

```text
GIT_REPOSITORY=https://github.com/SEU_USUARIO/for-web.git
GIT_BRANCH=main
APP_MODE=development
INSTANCE_HOST=203.0.113.10:14701
API_URL=http://203.0.113.10:14702
WS_URL=ws://203.0.113.10:14703
MEDIA_URL=http://203.0.113.10:14704
PROXY_URL=http://203.0.113.10:14705
GIFBOX_URL=http://203.0.113.10:14706
INSTALL_ON_START=0
PULL_ON_START=0
```

Se ainda não criou um fork do frontend, use temporariamente:

```text
GIT_REPOSITORY=https://github.com/stoatchat/for-web.git
```

Para editar e enviar alterações, crie seu próprio fork.

## 4. Configurar o backend

No servidor do backend, `PUBLIC_HOST` deve usar o mesmo IP ou domínio. A
configuração gerada pelo egg anterior já define o app em `:14701`.

Reinicie o backend depois de alterar domínio, protocolo ou IP para que o arquivo
`Revolt.overrides.toml` seja recriado.

## 5. Abrir o cliente

Depois de aparecer:

```text
[stoat-web] Vite pronto na porta 14701
```

acesse:

```text
http://IP_DO_SERVIDOR:14701
```

No modo `development`, alterações salvas pelo VS Code são atualizadas pelo Vite
sem recompilar o contêiner inteiro.

## HTTPS

Ao usar um domínio com HTTPS, altere para:

```text
INSTANCE_HOST=chat.seudominio.com
API_URL=https://api.seudominio.com
WS_URL=wss://events.seudominio.com
MEDIA_URL=https://media.seudominio.com
PROXY_URL=https://proxy.seudominio.com
GIFBOX_URL=https://gifbox.seudominio.com
```

O reverse proxy deve suportar WebSocket para o frontend do Vite e para o
Bonfire. Não misture página HTTPS com URLs `http://` ou `ws://`, pois o navegador
bloqueará conteúdo misto.

## Modo preview

Para testar o build final:

```text
APP_MODE=preview
BUILD_ON_START=1
```

Nesse modo o script executa o build Vite e depois inicia `vite preview`.

## Atualizações

Mantenha `PULL_ON_START=0` enquanto houver alterações locais pelo VS Code. Para
buscar o remoto conscientemente:

```bash
cd /home/container/source
git status
git pull --ff-only
git submodule update --init --recursive packages/stoat.js packages/solid-livekit-components
```

## Diagnóstico

Dentro do contêiner:

```bash
node --version
pnpm --version
nc -zv 127.0.0.1 14701
curl -I http://127.0.0.1:14701
```

Da sua máquina Windows:

```powershell
Test-NetConnection IP_DO_SERVIDOR -Port 14701
```

