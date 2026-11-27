-- Les prix sont envoyés à Stripe avec price_data. Le correcteur utilise son
-- propre compte Stripe, donc un produit local ne dépend pas d'un price_ externe.
ALTER TABLE "prices"
ALTER COLUMN "stripe_price_id" DROP NOT NULL;
