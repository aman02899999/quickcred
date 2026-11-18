import { describe, expect, it } from "vitest";
import { resolveIntegrationModes } from "../src/config/integration-mode";

describe("integration mode guard", () => {
  it("defaults everything to mock", () => {
    const r = resolveIntegrationModes({});
    expect(r.integrationMode).toBe("mock");
    expect(Object.values(r.providers).every((m) => m === "mock")).toBe(true);
    expect(r.liveAllowed).toBe(false);
  });

  it("refuses a live payout provider without lender authorization", () => {
    expect(() => resolveIntegrationModes({ PAYOUT_MODE: "live" })).toThrow(/PAYOUT_MODE=live refused/);
  });

  it("refuses global live mode outside production even with a lender ref", () => {
    expect(() =>
      resolveIntegrationModes({ INTEGRATION_MODE: "live", LENDER_AUTHORIZATION_REF: "LSP-001", APP_ENV: "staging" }),
    ).toThrow(/refused/);
  });

  it("refuses live mode in production without a lender ref", () => {
    expect(() => resolveIntegrationModes({ INTEGRATION_MODE: "live", APP_ENV: "production" })).toThrow(/refused/);
  });

  it("rejects unknown mode strings", () => {
    expect(() => resolveIntegrationModes({ KYC_MODE: "real" })).toThrow(/mock\|sandbox\|live/);
  });
});
