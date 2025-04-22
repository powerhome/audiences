import path from "path"
import { defineConfig } from "vite"
import react from "@vitejs/plugin-react"
import dts from "vite-plugin-dts"

export default defineConfig(({ mode }) => {
  const isUJS = mode === "ujs"

  return {
    plugins: [
      react(),
      dts({
        insertTypesEntry: true,
      }),
    ],
     resolve: {
      dedupe: ["trix", "trix-toolbar"],
    },
    build: {
      target: ["es2018"],
      lib: {
        entry: path.resolve(__dirname, isUJS ? "src/ujs.js" : "src/index.tsx"),
        name: isUJS ? "AudiencesReact" : "audiences",
        formats: isUJS ? ["umd"] : ["es", "cjs"],
        fileName: (format) =>
          isUJS ? "audiences-ujs.js" : `audiences.${format}.js`,
      },
      outDir: path.resolve(__dirname, "dist"),
      emptyOutDir: true,
      rollupOptions: {
        external: isUJS
          ? []
          : [
              "react",
              "react-dom",
              "playbook-ui",
              "react-trix",
              "react/jsx-runtime",
            ],
        output: {
          format: isUJS ? "umd" : undefined,
          name: isUJS ? "AudiencesRails" : undefined,
        },
      },
    },
    define: {
      "process.env.NODE_ENV": JSON.stringify("production"),
    },
  }
})
