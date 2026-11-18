import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "QuickCred",
  description: "Short-term personal loans from RBI-regulated lending partners. Demo build: no real loans.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en-IN">
      <body className="min-h-screen antialiased">
        {process.env.NEXT_PUBLIC_DEMO_BANNER !== "false" && (
          <div role="status" className="bg-warning px-4 py-2 text-center text-sm font-medium text-white">
            Demo environment. No real loans, KYC checks or payments happen here.
          </div>
        )}
        {children}
      </body>
    </html>
  );
}
