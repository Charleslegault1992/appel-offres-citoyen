import {
  BillingInterval,
  CreditSource,
  CreditStatus,
  OrderStatus,
  PrismaClient,
  ProductType,
  ProfileStatus,
  ProjectStatus,
  UserRole,
  WebhookStatus,
} from "@prisma/client";

const prisma = new PrismaClient();

const ids = {
  admin: "seed-user-admin",
  citizen: "seed-user-citizen",
  contractor: "seed-user-contractor",
  contractorProfile: "seed-contractor-profile",
  project: "seed-project-kitchen",
  creditProduct: "seed-product-credit",
  proProduct: "seed-product-pro",
  creditPrice: "seed-price-credit",
  proPrice: "seed-price-pro",
  order: "seed-order-paid",
  orderItem: "seed-order-item-credit",
  credit: "seed-credit-available",
  webhookEvent: "evt_seed_order_paid",
} as const;

async function seedUsers() {
  await prisma.user.upsert({
    where: { email: "admin@exemple.ca" },
    update: { name: "Administratrice Démo", role: UserRole.ADMIN, region: "Montréal" },
    create: {
      id: ids.admin,
      clerkId: "clerk_seed_admin",
      email: "admin@exemple.ca",
      name: "Administratrice Démo",
      role: UserRole.ADMIN,
      region: "Montréal",
    },
  });

  await prisma.user.upsert({
    where: { email: "citoyen@exemple.ca" },
    update: { name: "Camille Citoyenne", role: UserRole.CITIZEN, region: "Laval" },
    create: {
      id: ids.citizen,
      clerkId: "clerk_seed_citizen",
      email: "citoyen@exemple.ca",
      name: "Camille Citoyenne",
      role: UserRole.CITIZEN,
      region: "Laval",
    },
  });

  await prisma.user.upsert({
    where: { email: "entrepreneur@exemple.ca" },
    update: { name: "Émile Entrepreneur", role: UserRole.CONTRACTOR, region: "Montréal" },
    create: {
      id: ids.contractor,
      clerkId: "clerk_seed_contractor",
      email: "entrepreneur@exemple.ca",
      name: "Émile Entrepreneur",
      role: UserRole.CONTRACTOR,
      region: "Montréal",
    },
  });

  await prisma.contractorProfile.upsert({
    where: { userId: ids.contractor },
    update: {
      rbqNumber: "1234-5678-01",
      specialty: "Rénovation résidentielle",
      status: ProfileStatus.VERIFIED,
      verifiedAt: new Date("2026-11-01T14:00:00.000Z"),
    },
    create: {
      id: ids.contractorProfile,
      userId: ids.contractor,
      rbqNumber: "1234-5678-01",
      specialty: "Rénovation résidentielle",
      status: ProfileStatus.VERIFIED,
      verifiedAt: new Date("2026-11-01T14:00:00.000Z"),
    },
  });
}

async function seedCatalogue() {
  await prisma.product.upsert({
    where: { code: "BID_CREDIT" },
    update: { name: "Crédit de soumission", type: ProductType.CREDIT_UNIT, active: true },
    create: {
      id: ids.creditProduct,
      code: "BID_CREDIT",
      name: "Crédit de soumission",
      type: ProductType.CREDIT_UNIT,
    },
  });

  await prisma.product.upsert({
    where: { code: "PRO_MONTHLY" },
    update: { name: "Abonnement Pro", type: ProductType.SUBSCRIPTION, active: true },
    create: {
      id: ids.proProduct,
      code: "PRO_MONTHLY",
      name: "Abonnement Pro",
      type: ProductType.SUBSCRIPTION,
    },
  });

  await prisma.price.upsert({
    where: { id: ids.creditPrice },
    update: { amountCents: 500, currency: "cad", interval: BillingInterval.ONE_TIME, active: true },
    create: {
      id: ids.creditPrice,
      productId: ids.creditProduct,
      amountCents: 500,
      currency: "cad",
      interval: BillingInterval.ONE_TIME,
    },
  });

  await prisma.price.upsert({
    where: { id: ids.proPrice },
    update: { amountCents: 2999, currency: "cad", interval: BillingInterval.MONTH, active: true },
    create: {
      id: ids.proPrice,
      productId: ids.proProduct,
      amountCents: 2999,
      currency: "cad",
      interval: BillingInterval.MONTH,
    },
  });
}

async function seedProjectAndOrder() {
  await prisma.project.upsert({
    where: { id: ids.project },
    update: {
      title: "Rénover une cuisine",
      description: "Remplacement des armoires et du comptoir dans une cuisine résidentielle.",
      region: "Laval",
      budgetCents: 2500000,
      status: ProjectStatus.OPEN,
      expiresAt: new Date("2027-01-31T04:59:59.000Z"),
    },
    create: {
      id: ids.project,
      citizenId: ids.citizen,
      title: "Rénover une cuisine",
      description: "Remplacement des armoires et du comptoir dans une cuisine résidentielle.",
      region: "Laval",
      budgetCents: 2500000,
      status: ProjectStatus.OPEN,
      expiresAt: new Date("2027-01-31T04:59:59.000Z"),
    },
  });

  await prisma.order.upsert({
    where: { id: ids.order },
    update: {
      status: OrderStatus.PAID,
      subtotalCents: 500,
      gstCents: 25,
      qstCents: 50,
      totalCents: 575,
      paidAt: new Date("2026-11-20T15:00:00.000Z"),
    },
    create: {
      id: ids.order,
      contractorId: ids.contractor,
      status: OrderStatus.PAID,
      subtotalCents: 500,
      gstCents: 25,
      qstCents: 50,
      totalCents: 575,
      paidAt: new Date("2026-11-20T15:00:00.000Z"),
    },
  });

  await prisma.orderItem.upsert({
    where: { id: ids.orderItem },
    update: {
      productCodeSnapshot: "BID_CREDIT",
      productNameSnapshot: "Crédit de soumission",
      unitPriceCents: 500,
      quantity: 1,
      subtotalCents: 500,
      gstCents: 25,
      qstCents: 50,
      totalCents: 575,
    },
    create: {
      id: ids.orderItem,
      orderId: ids.order,
      productCodeSnapshot: "BID_CREDIT",
      productNameSnapshot: "Crédit de soumission",
      unitPriceCents: 500,
      quantity: 1,
      subtotalCents: 500,
      gstCents: 25,
      qstCents: 50,
      totalCents: 575,
    },
  });

  await prisma.credit.upsert({
    where: { id: ids.credit },
    update: { status: CreditStatus.AVAILABLE },
    create: {
      id: ids.credit,
      contractorId: ids.contractor,
      orderItemId: ids.orderItem,
      source: CreditSource.UNIT_PURCHASE,
      status: CreditStatus.AVAILABLE,
    },
  });

  await prisma.webhookEvent.upsert({
    where: { id: ids.webhookEvent },
    update: { status: WebhookStatus.PROCESSED, processedAt: new Date("2026-11-20T15:00:05.000Z") },
    create: {
      id: ids.webhookEvent,
      type: "checkout.session.completed",
      status: WebhookStatus.PROCESSED,
      processedAt: new Date("2026-11-20T15:00:05.000Z"),
    },
  });
}

async function main() {
  await seedUsers();
  await seedCatalogue();
  await seedProjectAndOrder();
  console.log("Seed terminé: 3 utilisateurs, 2 produits, 2 prix, 1 projet et 1 commande.");
}

main()
  .catch((error: unknown) => {
    console.error("Échec du seed Prisma.", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
