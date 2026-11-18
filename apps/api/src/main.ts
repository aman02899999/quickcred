import "reflect-metadata";
import { NestFactory } from "@nestjs/core";
import { VersioningType } from "@nestjs/common";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";
import { AppModule } from "./app.module";
import { resolveIntegrationModes } from "./config/integration-mode";

async function bootstrap() {
  // Fail fast before binding a port if live mode is misconfigured.
  const modes = resolveIntegrationModes(process.env);

  const app = await NestFactory.create(AppModule);
  app.enableVersioning({ type: VersioningType.URI });
  app.enableCors({ origin: (process.env.CORS_ORIGINS ?? "").split(",").filter(Boolean), credentials: true });

  const doc = new DocumentBuilder().setTitle("QuickCred API").setVersion("0.0.0").addBearerAuth().build();
  SwaggerModule.setup("docs", app, SwaggerModule.createDocument(app, doc));

  const port = Number(process.env.API_PORT ?? 4000);
  await app.listen(port);
  // eslint-disable-next-line no-console
  console.log(`quickcred-api on :${port} (integration mode: ${modes.integrationMode})`);
}
bootstrap();
