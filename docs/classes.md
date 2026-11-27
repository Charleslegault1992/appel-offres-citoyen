# Diagrammes de classes et de séquence

[Retour au cahier des charges](cahier-des-charges.md#5-diagrammes-de-classes-et-de-séquence)

Les deux diagrammes suivants couvrent le cœur métier et le paiement. Tous les montants sont des entiers en cents (RM-04). Les relations avec une commande sont conservées afin de garder un historique comptable; elles ne doivent pas être supprimées en cascade.

## 1. Diagramme de classes

```mermaid
classDiagram
  direction LR

  class User {
    +String id
    +String clerkId
    +String email
    +String name
    +UserRole role
    +String region
    +DateTime createdAt
  }

  class ContractorProfile {
    +String id
    +String userId
    +String rbqNumber
    +String specialty
    +ProfileStatus status
    +DateTime verifiedAt
  }

  class Project {
    +String id
    +String citizenId
    +String title
    +String description
    +String region
    +Int budgetCents
    +ProjectStatus status
    +DateTime expiresAt
    +DateTime createdAt
  }

  class ProjectImage {
    +String id
    +String projectId
    +String url
    +Int position
  }

  class Bid {
    +String id
    +String projectId
    +String contractorId
    +String creditId
    +Int amountCents
    +String availability
    +String conditions
    +BidStatus status
    +DateTime createdAt
  }

  class Credit {
    +String id
    +String contractorId
    +String orderItemId
    +String subscriptionId
    +CreditSource source
    +CreditStatus status
    +DateTime expiresAt
    +DateTime usedAt
  }

  class Product {
    +String id
    +String code
    +String name
    +ProductType type
    +Boolean active
  }

  class Price {
    +String id
    +String productId
    +String? stripePriceId
    +Int amountCents
    +String currency
    +BillingInterval interval
    +Boolean active
  }

  class Order {
    +String id
    +String contractorId
    +OrderStatus status
    +String stripeCheckoutSessionId
    +Int subtotalCents
    +Int gstCents
    +Int qstCents
    +Int totalCents
    +DateTime paidAt
    +DateTime createdAt
  }

  class OrderItem {
    +String id
    +String orderId
    +String productCodeSnapshot
    +String productNameSnapshot
    +Int unitPriceCents
    +Int quantity
    +Int subtotalCents
    +Int gstCents
    +Int qstCents
    +Int totalCents
  }

  class Subscription {
    +String id
    +String contractorId
    +String priceId
    +String stripeSubscriptionId
    +String stripeCustomerId
    +SubscriptionStatus status
    +DateTime periodStartAt
    +DateTime periodEndAt
    +Boolean cancelAtPeriodEnd
  }

  class Refund {
    +String id
    +String orderId
    +String creditId
    +String stripeRefundId
    +Int amountCents
    +RefundStatus status
    +String reason
    +DateTime requestedAt
    +DateTime processedAt
  }

  class WebhookEvent {
    +String id
    +String type
    +WebhookStatus status
    +DateTime receivedAt
    +DateTime processedAt
  }

  User "1" -- "0..1" ContractorProfile : possède
  User "1" -- "0..*" Project : publie
  Project "1" *-- "0..*" ProjectImage : contient
  Project "1" -- "0..*" Bid : reçoit
  User "1" -- "0..*" Bid : dépose
  Credit "1" -- "0..1" Bid : paie le dépôt
  User "1" -- "0..*" Credit : détient
  Product "1" -- "1..*" Price : possède
  User "1" -- "0..*" Order : passe
  Order "1" *-- "1..*" OrderItem : fige
  OrderItem "1" -- "0..*" Credit : génère
  User "1" -- "0..*" Subscription : souscrit
  Price "1" -- "0..*" Subscription : facture
  Subscription "0..1" -- "0..*" Credit : génère
  Order "1" -- "0..*" Refund : remboursements
  Credit "0..1" -- "0..1" Refund : crédit visé
```

**Contraintes structurantes :** une seule soumission par couple `(projectId, contractorId)` (RM-03); une seule utilisation par `creditId`; `stripePriceId` est optionnel et unique lorsqu'il existe, puisque Checkout utilisera `price_data`; `stripeCheckoutSessionId`, `stripeSubscriptionId` et `stripeRefundId` sont uniques; `WebhookEvent.id` est l'identifiant Stripe sans valeur générée; une offre doit respecter `amountCents <= Project.budgetCents` (RM-13).

## 2. Diagramme de séquence — achat d'un crédit

```mermaid
sequenceDiagram
  autonumber
  actor U as Navigateur entrepreneur
  participant S as Serveur Next.js
  participant DB as PostgreSQL
  participant ST as Stripe Checkout

  U->>S: POST /api/checkout (produit = CREDIT_UNIT)
  S->>DB: Lire le prix actif et recalculer les taxes
  DB-->>S: Prix = 500 cents
  S->>DB: Créer Order PENDING + OrderItem figé
  S->>ST: Créer Checkout Session (575 cents)
  ST-->>S: sessionId + URL
  S->>DB: Enregistrer stripeCheckoutSessionId
  S-->>U: Redirection vers Stripe
  U->>ST: Saisir et confirmer le paiement
  ST-->>U: Redirection /confirmation?orderId=...
  Note over U,S: La redirection ne confirme jamais le paiement
  U->>S: GET /api/orders/:id
  S->>DB: Lire le statut
  DB-->>S: PENDING tant que le webhook valide manque
  S-->>U: Afficher « Confirmation en cours »

  ST->>S: POST /api/stripe/webhook + signature
  S->>S: Vérifier la signature Stripe
  alt Signature invalide
    S-->>ST: HTTP 400
    Note over S,DB: Aucun changement et aucun crédit
  else Signature valide
    S->>DB: Transaction: insérer WebhookEvent.id
    alt Événement déjà traité
      DB-->>S: Conflit d'unicité / déjà traité
      S-->>ST: HTTP 200 sans doublon
    else checkout.session.completed et payé
      S->>DB: Order = PAID + créer 1 Credit AVAILABLE
      DB-->>S: Transaction validée
      S-->>ST: HTTP 200
    else Paiement non confirmé
      S->>DB: Journaliser sans accorder de crédit
      S-->>ST: HTTP 200
    end
  end

  U->>S: GET /api/orders/:id
  S->>DB: Lire Order et Credit
  DB-->>S: PAID + crédit disponible
  S-->>U: Afficher la confirmation et le reçu
```

Le même principe s'applique à Pro : seul un `invoice.paid` signé crée les 10 crédits de la période. L'unicité de `WebhookEvent.id` et de la facture Stripe empêche toute double attribution (RM-06, ENF-07).
