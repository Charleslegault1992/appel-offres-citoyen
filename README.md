# Appel d'offres citoyen

Plateforme Web transactionnelle québécoise où les citoyens publient gratuitement leurs travaux résidentiels et où les entrepreneurs paient pour déposer une soumission.

## Équipe

- Eva Bessette
- Marc-André Dufour
- Charles Legault

## Documentation

- [Cahier des charges](docs/cahier-des-charges.md)
- [Diagrammes de classes et de séquence](docs/classes.md)
- [Maquettes](docs/maquettes/)

## Base de données

Le schéma Prisma cible PostgreSQL sur Neon. Les montants sont stockés en cents et la migration initiale ajoute les contraintes financières décrites dans le cahier des charges.

```powershell
npm install
Copy-Item .env.example .env
# Remplir DATABASE_URL_UNPOOLED avec l'URL directe fournie par Neon.
npm run prisma:validate
npm run prisma:generate
npm run db:deploy
```

`db:deploy` applique les migrations existantes sans en générer une nouvelle. Ne jamais versionner `.env` ni afficher son contenu dans un terminal partagé.
