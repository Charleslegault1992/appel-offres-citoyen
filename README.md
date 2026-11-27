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
npm run db:seed
```

`db:deploy` applique les migrations existantes sans en générer une nouvelle. Ne jamais versionner `.env` ni afficher son contenu dans un terminal partagé.

`db:seed` ajoute ou remet à jour des données fictives de démonstration. Il écrit dans la base configurée par `DATABASE_URL_UNPOOLED`; vérifiez toujours la cible avant de le lancer.

## Comptes de test du seed

| Courriel | Rôle | Usage |
| --- | --- | --- |
| `admin@exemple.ca` | `ADMIN` | Administration |
| `citoyen@exemple.ca` | `CITIZEN` | Publication d'un projet |
| `entrepreneur@exemple.ca` | `CONTRACTOR` | Achat et soumission |

Le seed est idempotent et contient aussi deux produits, leurs prix en cents, un projet ouvert, une commande payée, sa ligne avec snapshot, un crédit disponible et l'événement webhook fictif correspondant. Les identifiants Stripe de prix restent vides : le parcours du Laboratoire 3 utilisera `price_data` avec les montants relus dans la base.

## Développement

```powershell
npm install
npm run prisma:generate
npm run dev
```

L'application répond sur `http://localhost:3000`. Avant une PR :

```powershell
npm run typecheck
npm run lint
npm run build
```

## Architecture

```text
Navigateur
   |
   v
app/                         Pages et points d'entrée HTTP
   |
   v
lib/services/                Logique métier réutilisable
   |
   v
lib/prisma.ts                Accès unique à PostgreSQL avec Prisma
```

Les pages et Route Handlers restent minces : ils reçoivent la requête, délèguent au service, puis construisent la réponse. Les composants client n'accèdent jamais à Prisma. Les modules serveur qui utilisent la base ou des secrets importent `server-only`.
