# VS Code com o frontend Stoat

Use o mesmo usuário SSH e o mesmo método de ACL criado para o backend, mas
libere somente o volume do servidor frontend.

## Localizar o volume

No painel administrativo, copie o UUID do servidor frontend. Na VPS:

```bash
sudo ls -la /var/lib/pterodactyl/volumes/UUID_FRONTEND
```

## Conceder acesso ao usuário `stoatdev`

```bash
sudo setfacl -R -m u:stoatdev:rwx /var/lib/pterodactyl/volumes/UUID_FRONTEND
sudo setfacl -R -d -m u:stoatdev:rwx /var/lib/pterodactyl/volumes/UUID_FRONTEND
sudo ln -s /var/lib/pterodactyl/volumes/UUID_FRONTEND /home/stoatdev/stoat-web
sudo chown -h stoatdev:stoatdev /home/stoatdev/stoat-web
```

## Abrir no VS Code

1. `Ctrl+Shift+P`.
2. `Remote-SSH: Connect to Host`.
3. Selecione sua VPS.
4. Abra `/home/stoatdev/stoat-web/source`.

Extensões recomendadas na janela remota:

- ESLint;
- Prettier;
- SolidJS;
- Even Better TOML.

O Node e o pnpm ficam dentro do contêiner. O VS Code conectado ao host será
usado para edição e Git; o Vite executará pelo Pterodactyl.

No modo `development`, salve um arquivo em `packages/client` e acompanhe no
console:

```text
hmr update
```

Se o Git reclamar da propriedade do diretório:

```bash
git config --global --add safe.directory /home/stoatdev/stoat-web/source
```

Não conceda acesso ao socket Docker e não use `chmod -R 777`.

