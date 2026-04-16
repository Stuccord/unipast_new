import type { Config } from "tailwindcss";

const config: Config = {
    content: [
        "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
        "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
        "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
        "./pages/**/*.{js,ts,jsx,tsx,mdx}",
        "./components/**/*.{js,ts,jsx,tsx,mdx}",
        "./app/**/*.{js,ts,jsx,tsx,mdx}",
    ],
    theme: {
        extend: {
            colors: {
                primary: "#00FFCC", // Neon Teal/Cyan
                secondary: "#B026FF", // Neon Purple
                accent: "#FFB800", // Gold
                bg: "#05080F", // Very dark navy/black
                surface: "#0D1526",
                card: "#111D35",
                danger: "#FF2A5F",
            },
            fontFamily: {
                orbitron: ['var(--font-orbitron)', 'sans-serif'],
                inter: ['var(--font-inter)', 'sans-serif'],
                firaCode: ['var(--font-fira-code)', 'monospace'],
            },
            backgroundImage: {
                "gradient-radial": "radial-gradient(var(--tw-gradient-stops))",
                "gradient-conic":
                    "conic-gradient(from 180deg at 50% 50%, var(--tw-gradient-stops))",
            },
        },
    },
    plugins: [],
};
export default config;
