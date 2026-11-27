import { listerProduitsActifs } from "@/lib/services/catalogue";

export const dynamic = "force-dynamic";

const dollarsCanadiens = new Intl.NumberFormat("fr-CA", { style: "currency", currency: "CAD" });

export default async function CataloguePage() {
  const produits = await listerProduitsActifs();

  return (
    <main>
      <h1>Catalogue</h1>
      {produits.length === 0 ? <p>Aucun produit n’est offert pour le moment.</p> : (
        <ul className="cards">
          {produits.map((produit) => (
            <li className="card" key={produit.id}>
              <h2>{produit.name}</h2>
              {produit.prices.map((prix) => (
                <p key={prix.id}>{dollarsCanadiens.format(prix.amountCents / 100)}{prix.interval === "MONTH" ? " par mois" : ""}</p>
              ))}
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}
