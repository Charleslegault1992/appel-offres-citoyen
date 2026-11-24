-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('CITIZEN', 'CONTRACTOR', 'ADMIN');

-- CreateEnum
CREATE TYPE "ProfileStatus" AS ENUM ('PENDING', 'VERIFIED', 'REJECTED');

-- CreateEnum
CREATE TYPE "ProjectStatus" AS ENUM ('DRAFT', 'OPEN', 'AWARDED', 'CLOSED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "BidStatus" AS ENUM ('SUBMITTED', 'ACCEPTED', 'REJECTED', 'WITHDRAWN');

-- CreateEnum
CREATE TYPE "CreditSource" AS ENUM ('UNIT_PURCHASE', 'SUBSCRIPTION');

-- CreateEnum
CREATE TYPE "CreditStatus" AS ENUM ('AVAILABLE', 'USED', 'EXPIRED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "ProductType" AS ENUM ('CREDIT_UNIT', 'SUBSCRIPTION');

-- CreateEnum
CREATE TYPE "BillingInterval" AS ENUM ('ONE_TIME', 'MONTH');

-- CreateEnum
CREATE TYPE "OrderStatus" AS ENUM ('PENDING', 'PAID', 'CANCELED', 'REFUNDED');

-- CreateEnum
CREATE TYPE "SubscriptionStatus" AS ENUM ('INCOMPLETE', 'ACTIVE', 'PAST_DUE', 'CANCELED');

-- CreateEnum
CREATE TYPE "RefundStatus" AS ENUM ('REQUESTED', 'APPROVED', 'REJECTED', 'SUCCEEDED', 'FAILED');

-- CreateEnum
CREATE TYPE "WebhookStatus" AS ENUM ('RECEIVED', 'PROCESSED', 'FAILED', 'IGNORED');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "clerk_id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" "UserRole" NOT NULL,
    "region" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "contractor_profiles" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "rbq_number" TEXT NOT NULL,
    "specialty" TEXT NOT NULL,
    "status" "ProfileStatus" NOT NULL DEFAULT 'PENDING',
    "verified_at" TIMESTAMP(3),

    CONSTRAINT "contractor_profiles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "projects" (
    "id" TEXT NOT NULL,
    "citizen_id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "region" TEXT NOT NULL,
    "budget_cents" INTEGER NOT NULL,
    "status" "ProjectStatus" NOT NULL DEFAULT 'DRAFT',
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "projects_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "project_images" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "position" INTEGER NOT NULL,

    CONSTRAINT "project_images_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "bids" (
    "id" TEXT NOT NULL,
    "project_id" TEXT NOT NULL,
    "contractor_id" TEXT NOT NULL,
    "credit_id" TEXT NOT NULL,
    "amount_cents" INTEGER NOT NULL,
    "availability" TEXT NOT NULL,
    "conditions" TEXT,
    "status" "BidStatus" NOT NULL DEFAULT 'SUBMITTED',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "bids_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "credits" (
    "id" TEXT NOT NULL,
    "contractor_id" TEXT NOT NULL,
    "order_item_id" TEXT,
    "subscription_id" TEXT,
    "source" "CreditSource" NOT NULL,
    "status" "CreditStatus" NOT NULL DEFAULT 'AVAILABLE',
    "expires_at" TIMESTAMP(3),
    "used_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "credits_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "products" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" "ProductType" NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "products_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "prices" (
    "id" TEXT NOT NULL,
    "product_id" TEXT NOT NULL,
    "stripe_price_id" TEXT NOT NULL,
    "amount_cents" INTEGER NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'cad',
    "interval" "BillingInterval" NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "prices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "orders" (
    "id" TEXT NOT NULL,
    "contractor_id" TEXT NOT NULL,
    "status" "OrderStatus" NOT NULL DEFAULT 'PENDING',
    "stripe_checkout_session_id" TEXT,
    "subtotal_cents" INTEGER NOT NULL,
    "gst_cents" INTEGER NOT NULL,
    "qst_cents" INTEGER NOT NULL,
    "total_cents" INTEGER NOT NULL,
    "paid_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "order_items" (
    "id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "product_code_snapshot" TEXT NOT NULL,
    "product_name_snapshot" TEXT NOT NULL,
    "unit_price_cents" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,
    "subtotal_cents" INTEGER NOT NULL,
    "gst_cents" INTEGER NOT NULL,
    "qst_cents" INTEGER NOT NULL,
    "total_cents" INTEGER NOT NULL,

    CONSTRAINT "order_items_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subscriptions" (
    "id" TEXT NOT NULL,
    "contractor_id" TEXT NOT NULL,
    "price_id" TEXT NOT NULL,
    "stripe_subscription_id" TEXT NOT NULL,
    "stripe_customer_id" TEXT NOT NULL,
    "status" "SubscriptionStatus" NOT NULL DEFAULT 'INCOMPLETE',
    "period_start_at" TIMESTAMP(3) NOT NULL,
    "period_end_at" TIMESTAMP(3) NOT NULL,
    "cancel_at_period_end" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refunds" (
    "id" TEXT NOT NULL,
    "order_id" TEXT NOT NULL,
    "credit_id" TEXT NOT NULL,
    "stripe_refund_id" TEXT,
    "amount_cents" INTEGER NOT NULL,
    "status" "RefundStatus" NOT NULL DEFAULT 'REQUESTED',
    "reason" TEXT NOT NULL,
    "requested_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processed_at" TIMESTAMP(3),

    CONSTRAINT "refunds_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "webhook_events" (
    "id" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "status" "WebhookStatus" NOT NULL DEFAULT 'RECEIVED',
    "received_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processed_at" TIMESTAMP(3),

    CONSTRAINT "webhook_events_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_clerk_id_key" ON "users"("clerk_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "contractor_profiles_user_id_key" ON "contractor_profiles"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "contractor_profiles_rbq_number_key" ON "contractor_profiles"("rbq_number");

-- CreateIndex
CREATE INDEX "projects_citizen_id_idx" ON "projects"("citizen_id");

-- CreateIndex
CREATE INDEX "projects_status_region_idx" ON "projects"("status", "region");

-- CreateIndex
CREATE INDEX "projects_status_expires_at_idx" ON "projects"("status", "expires_at");

-- CreateIndex
CREATE INDEX "project_images_project_id_idx" ON "project_images"("project_id");

-- CreateIndex
CREATE UNIQUE INDEX "project_images_project_id_position_key" ON "project_images"("project_id", "position");

-- CreateIndex
CREATE UNIQUE INDEX "bids_credit_id_key" ON "bids"("credit_id");

-- CreateIndex
CREATE INDEX "bids_contractor_id_idx" ON "bids"("contractor_id");

-- CreateIndex
CREATE INDEX "bids_project_id_status_idx" ON "bids"("project_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "bids_project_id_contractor_id_key" ON "bids"("project_id", "contractor_id");

-- CreateIndex
CREATE INDEX "credits_order_item_id_idx" ON "credits"("order_item_id");

-- CreateIndex
CREATE INDEX "credits_subscription_id_idx" ON "credits"("subscription_id");

-- CreateIndex
CREATE INDEX "credits_contractor_id_status_expires_at_idx" ON "credits"("contractor_id", "status", "expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "products_code_key" ON "products"("code");

-- CreateIndex
CREATE UNIQUE INDEX "prices_stripe_price_id_key" ON "prices"("stripe_price_id");

-- CreateIndex
CREATE INDEX "prices_product_id_idx" ON "prices"("product_id");

-- CreateIndex
CREATE UNIQUE INDEX "orders_stripe_checkout_session_id_key" ON "orders"("stripe_checkout_session_id");

-- CreateIndex
CREATE INDEX "orders_contractor_id_created_at_idx" ON "orders"("contractor_id", "created_at");

-- CreateIndex
CREATE INDEX "order_items_order_id_idx" ON "order_items"("order_id");

-- CreateIndex
CREATE UNIQUE INDEX "subscriptions_stripe_subscription_id_key" ON "subscriptions"("stripe_subscription_id");

-- CreateIndex
CREATE INDEX "subscriptions_price_id_idx" ON "subscriptions"("price_id");

-- CreateIndex
CREATE INDEX "subscriptions_stripe_customer_id_idx" ON "subscriptions"("stripe_customer_id");

-- CreateIndex
CREATE INDEX "subscriptions_contractor_id_status_idx" ON "subscriptions"("contractor_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "refunds_credit_id_key" ON "refunds"("credit_id");

-- CreateIndex
CREATE UNIQUE INDEX "refunds_stripe_refund_id_key" ON "refunds"("stripe_refund_id");

-- CreateIndex
CREATE INDEX "refunds_order_id_idx" ON "refunds"("order_id");

-- AddForeignKey
ALTER TABLE "contractor_profiles" ADD CONSTRAINT "contractor_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "projects" ADD CONSTRAINT "projects_citizen_id_fkey" FOREIGN KEY ("citizen_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "project_images" ADD CONSTRAINT "project_images_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "projects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bids" ADD CONSTRAINT "bids_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "projects"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bids" ADD CONSTRAINT "bids_contractor_id_fkey" FOREIGN KEY ("contractor_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "bids" ADD CONSTRAINT "bids_credit_id_fkey" FOREIGN KEY ("credit_id") REFERENCES "credits"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "credits" ADD CONSTRAINT "credits_contractor_id_fkey" FOREIGN KEY ("contractor_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "credits" ADD CONSTRAINT "credits_order_item_id_fkey" FOREIGN KEY ("order_item_id") REFERENCES "order_items"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "credits" ADD CONSTRAINT "credits_subscription_id_fkey" FOREIGN KEY ("subscription_id") REFERENCES "subscriptions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "prices" ADD CONSTRAINT "prices_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "products"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_contractor_id_fkey" FOREIGN KEY ("contractor_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "order_items" ADD CONSTRAINT "order_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_contractor_id_fkey" FOREIGN KEY ("contractor_id") REFERENCES "users"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_price_id_fkey" FOREIGN KEY ("price_id") REFERENCES "prices"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refunds" ADD CONSTRAINT "refunds_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refunds" ADD CONSTRAINT "refunds_credit_id_fkey" FOREIGN KEY ("credit_id") REFERENCES "credits"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Contraintes métier que le schéma Prisma ne peut pas exprimer.
ALTER TABLE "projects"
ADD CONSTRAINT "projects_budget_cents_positive" CHECK ("budget_cents" > 0);

ALTER TABLE "project_images"
ADD CONSTRAINT "project_images_position_nonnegative" CHECK ("position" >= 0);

ALTER TABLE "bids"
ADD CONSTRAINT "bids_amount_cents_positive" CHECK ("amount_cents" > 0);

ALTER TABLE "prices"
ADD CONSTRAINT "prices_amount_cents_positive" CHECK ("amount_cents" > 0);

ALTER TABLE "orders"
ADD CONSTRAINT "orders_amounts_valid" CHECK (
    "subtotal_cents" >= 0
    AND "gst_cents" >= 0
    AND "qst_cents" >= 0
    AND "total_cents" = "subtotal_cents" + "gst_cents" + "qst_cents"
);

ALTER TABLE "order_items"
ADD CONSTRAINT "order_items_amounts_valid" CHECK (
    "unit_price_cents" > 0
    AND "quantity" > 0
    AND "subtotal_cents" = "unit_price_cents" * "quantity"
    AND "gst_cents" >= 0
    AND "qst_cents" >= 0
    AND "total_cents" = "subtotal_cents" + "gst_cents" + "qst_cents"
);

ALTER TABLE "refunds"
ADD CONSTRAINT "refunds_amount_cents_positive" CHECK ("amount_cents" > 0);

ALTER TABLE "credits"
ADD CONSTRAINT "credits_source_has_one_origin" CHECK (
    ("source" = 'UNIT_PURCHASE' AND "order_item_id" IS NOT NULL AND "subscription_id" IS NULL)
    OR
    ("source" = 'SUBSCRIPTION' AND "order_item_id" IS NULL AND "subscription_id" IS NOT NULL AND "expires_at" IS NOT NULL)
);

-- RM-13 : une offre doit rester dans le budget annoncé du projet.
CREATE FUNCTION "validate_bid_against_project"()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    project_budget INTEGER;
    project_state "ProjectStatus";
    project_expiry TIMESTAMP(3);
    project_owner TEXT;
BEGIN
    SELECT "budget_cents", "status", "expires_at", "citizen_id"
    INTO project_budget, project_state, project_expiry, project_owner
    FROM "projects"
    WHERE "id" = NEW."project_id"
    FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Projet introuvable: %', NEW."project_id"
            USING ERRCODE = '23503';
    END IF;

    IF project_state <> 'OPEN' OR project_expiry <= CURRENT_TIMESTAMP THEN
        RAISE EXCEPTION 'Le projet % n''accepte pas de soumission', NEW."project_id"
            USING ERRCODE = '23514';
    END IF;

    IF project_owner = NEW."contractor_id" THEN
        RAISE EXCEPTION 'Un propriétaire ne peut pas soumissionner sur son projet'
            USING ERRCODE = '23514';
    END IF;

    IF NEW."amount_cents" > project_budget THEN
        RAISE EXCEPTION 'Le montant de la soumission dépasse le budget du projet'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER "bids_validate_project"
BEFORE INSERT OR UPDATE OF "project_id", "contractor_id", "amount_cents" ON "bids"
FOR EACH ROW
EXECUTE FUNCTION "validate_bid_against_project"();

-- RM-13 : le budget est figé dès la première soumission.
CREATE FUNCTION "prevent_budget_change_after_bid"()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW."budget_cents" <> OLD."budget_cents"
       AND EXISTS (SELECT 1 FROM "bids" WHERE "project_id" = OLD."id") THEN
        RAISE EXCEPTION 'Le budget ne peut plus changer après la première soumission'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER "projects_freeze_budget_after_bid"
BEFORE UPDATE OF "budget_cents" ON "projects"
FOR EACH ROW
EXECUTE FUNCTION "prevent_budget_change_after_bid"();
