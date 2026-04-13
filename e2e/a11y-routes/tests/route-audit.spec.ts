import { test } from "@playwright/test";
import {
  loadManifest,
  routeSlug,
  runBlockingAaAudit,
  runInformationalAaaAudit,
} from "./routeAuditUtils";

const manifest = loadManifest();
const port = process.env.PLAYWRIGHT_SERVER_PORT || String(manifest.port || 3000);

for (const route of manifest.routes) {
  const label = `${route.host}${route.path}`;
  const slug = routeSlug(route);

  test.describe(label, () => {
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
