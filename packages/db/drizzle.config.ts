import { defineConfig } from "drizzle-kit";

export default defineConfig({
  dialect: "postgresql",
  schema: "./src/schema/index.ts",
  out: "./migrations",
  dbCredentials: { url: process.env.DATABASE_URL ?? "postgres://quickcred:quickcred_local_only@localhost:5432/quickcred" },
  strict: true,
  verbose: true,
});
