import { resolve } from "path"
import { defineConfig } from "vite";
import RubyPlugin from "vite-plugin-ruby";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [RubyPlugin(), react()],
  resolve: {
    alias: {
      "audiences": resolve(__dirname, "../../../audiences-react/src")
    }
  }
});
