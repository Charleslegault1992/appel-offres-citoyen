import "server-only";
import { prisma } from "@/lib/prisma";

export async function listerProduitsActifs() {
  return prisma.product.findMany({
    where: { active: true },
    orderBy: { name: "asc" },
    select: {
      id: true,
      code: true,
      name: true,
      type: true,
      prices: {
        where: { active: true },
        orderBy: { amountCents: "asc" },
        select: { id: true, amountCents: true, currency: true, interval: true },
      },
    },
  });
}
