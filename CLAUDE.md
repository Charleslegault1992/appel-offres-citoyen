# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Appel d'offres citoyen

Plateforme Web transactionnelle québécoise : les citoyens publient gratuitement leurs travaux résidentiels avec un budget maximal, et les entrepreneurs vérifiés (RBQ) paient pour déposer une soumission. L'entrepreneur paie de deux façons, par Stripe Checkout : un **crédit de soumission à 5,00 $** (paiement unique, 5,75 $ taxes comprises) ou l'abonnement **Pro à 29,99 $/mois** (10 crédits par période payée, 34,48 $ taxes comprises). Le paiement des travaux se fait hors de la plateforme.

Projet du cours 420-951-MA (équipe : Eva Bessette, Marc-André Dufour, Charles Legault).

Spécification complète (source de vérité) : @docs/cahier-des-charges.md
Diagrammes de classes et de séquence : [docs/classes.md](docs/classes.md). Maquettes : [docs/maquettes/](docs/maquettes/).

## Commandes

Le projet contient le schéma Prisma et sa migration initiale.
L'application Next.js sera développée dans les prochains laboratoires.

| Vérification                         | Commande                  |
| ------------------------------------ | ------------------------- |
| Installer les dépendances            | `npm ci`                  |
| Valider le schéma Prisma             | `npm run prisma:validate` |
| Générer le client Prisma             | `npm run prisma:generate` |
| Créer une migration en développement | `npm run db:migrate`      |
| Appliquer les migrations sur Neon    | `npm run db:deploy`       |

## Architecture et conventions

**Pile :** Next.js (App Router) + TypeScript, Clerk (authentification), Prisma + PostgreSQL (Neon), Stripe Checkout et webhooks en **mode test**, Vitest.

**Dossiers actuels :**

- `docs/` : cahier des charges, diagrammes UML (Mermaid), maquettes et journal IA ([docs/journal-ia.md](docs/journal-ia.md)).
- `.claude/settings.json` : permissions partagées de Claude Code (accès refusé aux secrets et aux commandes destructrices).
- `prisma/` : schéma de la base de données et migrations SQL.
- `package.json` : dépendances et commandes Prisma.
- `app/` : sera ajouté lors du développement de l'application Next.js.

**Données (cahier, section 7) :**

- Tous les montants (prix, taxes, budgets, offres) sont des `Int` dont le nom se termine par `Cents` (`budgetCents`, `amountCents`). Jamais de `Float` ni de `Decimal`.
- Les statuts sont des enums Prisma dont les valeurs sont en MAJUSCULES : `Project.status` = `DRAFT | OPEN | AWARDED | CLOSED | EXPIRED`, `Bid.status`, `Credit.status`, `Order.status`, `Subscription.status`, `Refund.status`, `WebhookEvent.status` (voir le tableau de la section 7.2).
- Les relations Prisma sont déclarées explicitement, avec un index sur chaque clé étrangère. `onDelete: Restrict` s'applique aux entités qui servent d'audit (utilisateurs, commandes, lignes, abonnements, crédits, offres, remboursements).
- `OrderItem` copie le code, le nom, le prix unitaire et les taxes au moment de l'achat. Un changement de `Price` ne modifie pas l'historique.
- Le serveur recalcule le prix à partir de la base de données avant de créer la commande (UC-08). Un total envoyé par le navigateur ne détermine jamais le montant facturé.
- Les rôles (`CITIZEN`, `CONTRACTOR`, `ADMIN`) sont vérifiés côté serveur. La vérification côté client ne suffit pas (ENF-06).

**Traçabilité :** réutilise les identifiants `US-xx`, `CA-xx`, `RM-xx`, `ENF-xx` et `UC-xx` du cahier dans les noms de tests et les messages de commit.

**Git :**

- Messages de commit `type: description` en français, avec l'identifiant concerné. Exemple : `docs: RM-05 préciser la confirmation des paiements`, `feat: US-07 déposer une offre`.
- Une branche par issue GitHub (par exemple `1-s1-t02-finaliser-le-cahier-des-charges`), fusionnée dans `main` par une PR.
- Chaque membre fait ses commits avec son propre compte Git.

## Règles métier

Identifiants et sens tirés du cahier, section 4.3. Les comportements attendus sont précisés par les critères `CA-xx`.

- **RM-01** : Un citoyen publie gratuitement. Seul un entrepreneur dont le profil RBQ est vérifié peut déposer une offre. Une tentative d'un profil non vérifié est refusée côté serveur, sans consommer de crédit (CA-04).
- **RM-02** : Seul un projet `OPEN` accepte des offres. Une offre sur un projet `AWARDED`, `CLOSED` ou `EXPIRED` est refusée (CA-11).
- **RM-03** : Une seule offre par entrepreneur et par projet (contrainte unique `(projectId, contractorId)`). Le crédit passe de `AVAILABLE` à `USED` **dans la même transaction** que la création de la `Bid`. Une deuxième offre au même projet est refusée sans retirer de crédit (CA-09, CA-10).
- **RM-04** : Tous les montants sont des entiers en cents. La TPS (5 %) et la TVQ (9,975 %) sont calculées chacune sur le prix avant taxes, puis arrondies séparément au cent le plus proche. Totaux attendus : crédit `500 → 25 + 50 → 575`, Pro `2999 → 150 + 299 → 3448` (CA-05).
- **RM-05** : Une commande ne passe à `PAID` qu'après un webhook Stripe dont la signature a été vérifiée. La page de succès ou une redirection du navigateur ne modifie jamais le statut d'un paiement. Une signature invalide reçoit une réponse HTTP 400 (UC-08, CA-06).
- **RM-06** : Une facture Pro payée (`invoice.paid`) donne exactement 10 crédits pour sa période. Un événement dont l'`event.id` est déjà enregistré dans `WebhookEvent` est ignoré et ne crée aucun crédit supplémentaire (CA-08, CA-12).
- **RM-07** : Un paiement échoué ou une session expirée ne donne aucun crédit. Un abonnement Pro dont le paiement échoue passe à `PAST_DUE`, et les crédits d'une période déjà payée restent valides jusqu'à la fin de cette période (CA-07).
- **RM-08** : Seul un crédit acheté à l'unité et inutilisé peut faire l'objet d'une demande de remboursement, dans les 14 jours suivant l'achat. Un administrateur la traite, et le crédit ne passe à `REFUNDED` qu'après la confirmation de Stripe (`charge.refunded`). Une demande pour un crédit déjà utilisé est refusée avec une explication (CA-14).
- **RM-09** : Seul le citoyen propriétaire d'un projet peut l'attribuer (`AWARDED`) ou le fermer (`CLOSED`).
- **RM-10** : Un entrepreneur ne peut pas soumissionner sur son propre projet ni sur un projet expiré.
- **RM-11** : Les crédits Pro non utilisés passent à `EXPIRED` à la fin de la période payée et ne sont pas reportés. Les crédits achetés à l'unité n'expirent pas (CA-13).
- **RM-12** : La liste publique des projets n'affiche ni l'adresse précise ni les coordonnées privées.
- **RM-13** : Le budget maximal est strictement positif et visible par les entrepreneurs avant qu'ils soumissionnent. Une offre dont le prix total dépasse le budget est refusée côté serveur, le budget est rappelé et aucun crédit n'est consommé. La règle est aussi imposée en SQL par un `CHECK` ou un déclencheur. Le budget ne peut plus être modifié après la première offre (CA-02, CA-15, ENF-08).

**Webhooks (cahier, section 3.4) :** pour chaque événement, vérifier la signature, enregistrer `WebhookEvent.id`, puis traiter l'opération dans une transaction Prisma. Les traitements suivants doivent être atomiques : le webhook, l'attribution des crédits, la consommation d'un crédit avec la création de l'offre, l'attribution du projet et le remboursement (ENF-07).

## Interdits

- **Demande toujours mon accord avant d'ajouter un paquet npm**, y compris en dépendance de développement.
- Ne lis pas, n'affiche pas et ne modifie pas `.env`, `.env.*` ni `secrets/**`. N'écris aucune clé ni aucun secret (Stripe, Clerk, Neon) dans le code, dans ce fichier ou dans un commit. Seul un `.env.example` sans valeurs est versionné (ENF-02).
- Ne stocke aucune donnée de carte bancaire. Le paiement passe uniquement par Stripe Checkout (ENF-01).
- N'utilise pas de clés Stripe de production. Le projet reste en mode test.
- N'utilise jamais `Float` ou `Decimal` pour un montant d'argent.
- N'accorde jamais un crédit et ne marque jamais une commande `PAID` en dehors du traitement d'un webhook vérifié.
- Ne lance pas `git push --force` ni `prisma migrate reset`.
- Ne contourne pas les hooks Git (`--no-verify`).

## Façon de travailler

1. Avant de coder, propose un plan court (fichiers touchés, règles `RM-xx` concernées, tests prévus) et **attends mon approbation**.
2. Traite une seule tâche (story ou issue) à la fois.
3. Après chaque changement, lance les tests du projet (voir **Commandes**). Si un test échoue, montre la sortie au lieu de déclarer la tâche terminée.
4. Montre le diff pour que je le relise, puis fais un petit commit dont le message contient l'identifiant de la story ou de la règle (`US-xx`, `RM-xx`).
5. Si une règle métier manque, est ambiguë ou contredit le cahier, pose une question précise au lieu de supposer. Si une règle de paiement change, mets à jour ensemble la grille tarifaire, les tests, les écrans et le schéma.

## Instructions partagées

`AGENTS.md` contient les mêmes règles pour les autres outils d'IA (Codex, Cursor, Copilot). **Toute modification de ce fichier doit être reportée dans `AGENTS.md` dans le même commit.**

@AGENTS.md
