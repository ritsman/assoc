# VPS Rebuild Playbook

Use this flow on the VPS for the deployed app in `/var/web/assoc`.

## Repo root

```bash
cd /var/web/assoc
```

## Update code

Check current branch if needed:

```bash
git branch --show-current
git status
```

Fetch latest refs:

```bash
git fetch origin
```

Pull the current branch:

```bash
git pull
```

Or pull a specific branch:

```bash
git pull origin <branch-name>
```

## Rebuild containers

For full web + backend rebuild on the VPS, use both compose files so the services join the `shared_backend` external network:

```bash
docker compose -f docker-compose.yml -f docker-compose.vps.yml up -d --build synetra_bkend synetra_web
```

If you need a clean restart first:

```bash
docker compose down
docker compose -f docker-compose.yml -f docker-compose.vps.yml up -d --build synetra_bkend synetra_web
```

## Rebuild one service only

Backend only:

```bash
docker compose --env-file .env.compose -f docker-compose.yml -f docker-compose.vps.yml up -d --build synetra_bkend
```

Web only:

```bash
docker compose --env-file .env.compose -f docker-compose.yml -f docker-compose.vps.yml up -d --build synetra_web
```

## Verify

Check running containers:

```bash
docker compose -f docker-compose.yml -f docker-compose.vps.yml ps
```

Check logs:

```bash
docker compose -f docker-compose.yml -f docker-compose.vps.yml logs --tail=100 synetra_bkend
docker compose -f docker-compose.yml -f docker-compose.vps.yml logs --tail=100 synetra_web
```

Health checks:

```bash
curl -s http://127.0.0.1:8083/api/health
curl -I http://127.0.0.1:5001
```

## Notes

- `docker-compose.vps.yml` is required on the VPS because it attaches the app containers to the external `shared_backend` network.
- `.env.compose.example` in this repo maps env files for compose-based startup.
- If backend code changes include Prisma migrations, run the migration separately after the containers are up.
