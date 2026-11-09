// Fonte instalada via npm (@fontsource/poppins): não depende do Google Fonts no build
import "@fontsource/poppins/400.css";
import "@fontsource/poppins/500.css";
import "./globals.css";

export const metadata = { title: "Valit" };

export default function RootLayout({ children }) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  );
}
