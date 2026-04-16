import type { Metadata } from "next";
import { Inter, Orbitron, Fira_Code } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter" });
const orbitron = Orbitron({ subsets: ["latin"], variable: "--font-orbitron" });
const firaCode = Fira_Code({ subsets: ["latin"], variable: "--font-fira-code" });

export const metadata: Metadata = {
    title: "UniPast Admin Dashboard",
    description: "God Mind Premium Administrative Interface for UniPast",
};

export default function RootLayout({
    children,
}: Readonly<{
    children: React.ReactNode;
}>) {
    return (
        <html lang="en">
            <body className={`${inter.variable} ${orbitron.variable} ${firaCode.variable} font-inter bg-bg text-white min-h-screen antialiased`}>
                {children}
            </body>
        </html>
    );
}
