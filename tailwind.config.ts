import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        panel: "#12181f",
        surface: "#1a2129",
        surfaceAlt: "#212a33",
        border: "#2c3742",
        steel: {
          50: "#f2f6f8",
          100: "#dce6ec",
          200: "#b9ccd8",
          300: "#8fabbd",
          400: "#5f829a",
          500: "#456578",
          600: "#374f5f",
          700: "#2b3d49",
          800: "#202d36",
          900: "#161e24",
        },
        signal: {
          critical: "#e5484d",
          warning: "#f5a623",
          info: "#3b9dd6",
          ok: "#3fb27f",
        },
        accent: "#e07a2c",
      },
      fontFamily: {
        sans: ["Inter", "Segoe UI", "system-ui", "sans-serif"],
        mono: ["JetBrains Mono", "ui-monospace", "SFMono-Regular", "monospace"],
      },
      boxShadow: {
        card: "0 1px 2px rgba(0,0,0,0.4), 0 0 0 1px rgba(255,255,255,0.03)",
      },
    },
  },
  plugins: [],
};

export default config;
