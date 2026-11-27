import { listerProduitsActifs } from "@/lib/services/catalogue";

export async function GET() {
  const produits = await listerProduitsActifs();
  return Response.json({ data: produits });
}
