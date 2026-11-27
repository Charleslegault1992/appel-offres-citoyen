import Link from "next/link";

export default function HomePage() {
  return (
    <main>
      <h1>Appel d’offres citoyen</h1>
      <p>Publiez un projet résidentiel ou consultez les produits offerts aux entrepreneurs.</p>
      <Link href="/catalogue">Voir le catalogue</Link>
    </main>
  );
}
