import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Chat with Gemini",
  description: "A simple chat application powered by Google Gemini AI",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ja">
      <body className="antialiased">
        {children}
      </body>
    </html>
  );
}
