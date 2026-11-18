import { Controller, Get } from "@nestjs/common";
import { resolveIntegrationModes } from "./config/integration-mode";

@Controller({ path: "health", version: "1" })
export class HealthController {
  @Get()
  get() {
    const modes = resolveIntegrationModes(process.env);
    return {
      status: "ok",
      service: "quickcred-api",
      integrationMode: modes.integrationMode,
      providers: modes.providers,
      notice: modes.liveAllowed ? undefined : "MOCK MODE: no real KYC, bureau, or money movement.",
    };
  }
}
