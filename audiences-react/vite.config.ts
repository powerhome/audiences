import path from "path"
import { defineConfig } from "vite"
import react from "@vitejs/plugin-react"
import dts from "vite-plugin-dts"

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
      entry: path.resolve(__dirname, "src/audiencesUMD.tsx"),
      name: "AudiencesReact",
      formats: ["umd"],
      fileName: () => "audiences-ujs.js",
    },
    outDir: path.resolve(__dirname, "dist"),
    emptyOutDir: true,
    rollupOptions: {
      external: [],
      output: {
        format: "umd",
        name: "AudiencesRails",
      },
    },
  },
  css: {
    postcss: {
      plugins: [],
    },
  },
  define: {
    "process.env.NODE_ENV": JSON.stringify("production"),
  },
})
