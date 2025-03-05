import path from "path";
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import dts from "vite-plugin-dts";

export default defineConfig({
  plugins: [
    react(),
    dts({
      insertTypesEntry: true,
    }),
  ],
  build: {
    target: ["es2018"],
    lib: {
      entry: path.resolve(__dirname, "src/index.tsx"),
      name: "audiences",
      fileName: (format) => `audiences.${format}.js`,
    },
    rollupOptions: {
      external: ["react", "react-dom", "playbook-ui", "react/jsx-runtime"],
    },
  },
});
