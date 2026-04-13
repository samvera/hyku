import * as fs from "fs";
import * as path from "path";
import { test } from "@playwright/test";
import {
  loadManifest,
  routeSlug,
  runBlockingAaAudit,
  runInformationalAaaAudit,
} from "./routeAuditUtils";

const authFile = path.join(__dirname, "..", ".auth", "a11y-admin.json");
const hasAuth = fs.existsSync(authFile);
const manifest = loadManifest();
const authRoutes = manifest.authenticated_routes ?? [];
const port = process.env.PLAYWRIGHT_SERVER_PORT || String(manifest.port || 3000);

const shouldRun = hasAuth && authRoutes.length > 0;
const skipReason = !hasAuth
  ? `Missing ${authFile} (globalSetup login).`
  : "No authenticated_routes in manifest.";

test.describe("Manifest authenticated routes (dashboard)", () => {
  if (!shouldRun) {
    test("dashboard WCAG audits (skipped)", () => {
      test.skip(true, skipReason);
    });
    return;
  }

  test.use({ storageState: authFile });

  for (const route of authRoutes) {
    const label = `${route.host}${route.path}`;
    const slug = `auth_${routeSlug(route)}`;

    test.describe(`[auth] ${label}`, () => {
      test("WCAG 2.1 A/AA (blocking)", async ({ page }) => {
        const url = `http://${route.host}:${port}${route.path}`;
        await runBlockingAaAudit(page, url, slug);
      });

      test("WCAG AAA (informational only)", async ({ page }) => {
        const url = `http://${route.host}:${port}${route.path}`;
        await runInformationalAaaAudit(page, url, slug);
      });
    });
  }
});
