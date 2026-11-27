import type { Metadata } from "next";
import type { ReactNode } from "react";
import "./globals.css";

export const metadata: Metadata = {
  title: "Appel d'offres citoyen",
  description: "Projets résidentiels et soumissions d'entrepreneurs vérifiés.",
};

export default function RootLayout({ children }: Readonly<{ children: ReactNode }>) {
  return <html lang="fr-CA"><body>{children}</body></html>;
}
