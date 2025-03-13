import path from "path";
import { defineConfig } from "vite";
import FullReload from "vite-plugin-full-reload";
import rubyPlugin from "vite-plugin-ruby";

export default defineConfig({
  plugins: [
    rubyPlugin(),
    FullReload(["config/routes.rb", "app/views/**/*"], { delay: 300 }),
  ],
  server: {
    host: "localhost",
    port: 3036,
    strictPort: true,
    hmr: {
      host: "localhost",
    },
    allowedHosts: ["localhost", "dummy-vite"],
  },
  build: {
    outDir: path.resolve(__dirname, "../../public/assets/builds"),
  },
  css: {
    postcss: {
      plugins: [],
    },
  },
});
