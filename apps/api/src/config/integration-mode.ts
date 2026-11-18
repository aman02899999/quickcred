/**
 * Boot-time guard: the API refuses to start with any live provider unless the
 * environment proves a lender authorization exists. This is a code-level control
 * for execution rules 15, 22 and 23 in the product spec.
 */
export const PROVIDER_MODE_KEYS = [
  "SMS_MODE",
  "PAN_MODE",
  "KYC_MODE",
  "AA_MODE",
  "BUREAU_MODE",
  "ESIGN_MODE",
  "PAYOUT_MODE",
  "COLLECTIONS_MODE",
] as const;

export type Mode = "mock" | "sandbox" | "live";

export interface IntegrationModeReport {
  integrationMode: Mode;
  providers: Record<string, Mode>;
  liveAllowed: boolean;
}

function parseMode(value: string | undefined, key: string): Mode {
  const v = (value ?? "mock").trim().toLowerCase();
  if (v === "mock" || v === "sandbox" || v === "live") return v;
  throw new Error(`${key} must be one of mock|sandbox|live, got "${value}"`);
}

export function resolveIntegrationModes(env: NodeJS.ProcessEnv): IntegrationModeReport {
  const integrationMode = parseMode(env.INTEGRATION_MODE, "INTEGRATION_MODE");
  const providers: Record<string, Mode> = {};
  for (const key of PROVIDER_MODE_KEYS) providers[key] = parseMode(env[key], key);

  const lenderRef = (env.LENDER_AUTHORIZATION_REF ?? "").trim();
  const liveAllowed = integrationMode === "live" && lenderRef.length > 0 && env.APP_ENV === "production";

  for (const [key, mode] of Object.entries(providers)) {
    if (mode === "live" && !liveAllowed) {
      throw new Error(
        `${key}=live refused: live providers need INTEGRATION_MODE=live, APP_ENV=production and a LENDER_AUTHORIZATION_REF.`,
      );
    }
  }
  if (integrationMode === "live" && !liveAllowed) {
    throw new Error("INTEGRATION_MODE=live refused without APP_ENV=production and LENDER_AUTHORIZATION_REF.");
  }
  return { integrationMode, providers, liveAllowed };
}
