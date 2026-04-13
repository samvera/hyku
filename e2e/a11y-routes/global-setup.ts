import { chromium, firefox, type FullConfig } from "@playwright/test";

/** Must match playwright.config.ts / bin/playwright-a11y (Firefox default only on arm64 Docker). */
function a11yBrowser() {
  return process.env.PLAYWRIGHT_A11Y_BROWSER === "firefox" ? firefox : chromium;
}

const firefoxLaunchOptions = {
  firefoxUserPrefs: { "security.sandbox.content.level": 0 },
} as const;
import * as fs from "fs";
import * as path from "path";
import { loadManifest, manifestPath } from "./tests/routeAuditUtils";

/**
 * Signs in on the tenant host as the a11y-admin user (see hyku:demo_content:seed) and writes
 * .auth/a11y-admin.json for dashboard route audits. Uses the same HTTP basic defaults as playwright.config.ts.
 */
export default async function globalSetup(_config: FullConfig): Promise<void> {
  if (!fs.existsSync(manifestPath)) {
    console.warn(`[a11y global-setup] Skip auth: manifest missing at ${manifestPath}`);
    return;
  }

  const manifest = loadManifest();
  const authRoutes = manifest.authenticated_routes ?? [];
  if (authRoutes.length === 0) {
    console.warn("[a11y global-setup] Skip auth: manifest has no authenticated_routes.");
    return;
  }
  const port = process.env.PLAYWRIGHT_SERVER_PORT || String(manifest.port || 3000);
  const email =
    process.env.HYKU_DEMO_A11Y_ADMIN_EMAIL || manifest.a11y_admin_email || "hyku-a11y-admin@example.com";
  const password =
    process.env.HYKU_DEMO_A11Y_ADMIN_PASSWORD ||
    process.env.HYKU_USER_DEFAULT_PASSWORD ||
    "password";

  const httpCredentials =
    process.env.PLAYWRIGHT_HTTP_BASIC_OFF === "1"
      ? undefined
      : {
          username: process.env.PLAYWRIGHT_HTTP_BASIC_USER ?? "samvera",
          password: process.env.PLAYWRIGHT_HTTP_BASIC_PASSWORD ?? "hyku",
        };

  const host = manifest.tenant_cname;
  const baseURL = `http://${host}:${port}`;

  const browserType = a11yBrowser();
  // Match playwright.config.ts: headed Chromium on Xvfb in Docker (avoids headless-shell GLib issues).
  const chromiumHeadless = process.env.PLAYWRIGHT_DOCKER_XVFB !== "1";
  const browser = await browserType.launch({
    headless: browserType === firefox ? true : chromiumHeadless,
    ...(browserType === chromium
      ? {
          args: [
            "--disable-gpu",
            "--disable-software-rasterizer",
            "--in-process-gpu",
          ],
        }
      : firefoxLaunchOptions),
  });
  const context = await browser.newContext({
    ...(httpCredentials ? { httpCredentials } : {}),
    ignoreHTTPSErrors: true,
  });
  const page = await context.newPage();

  await page.goto(`${baseURL}/users/sign_in?locale=en`, { waitUntil: "load", timeout: 90_000 });
  await page.fill("#user_email", email);
  await page.fill("#user_password", password);
  await page.getByRole("button", { name: /log in|sign in/i }).click();
  await page.waitForURL((u) => !u.pathname.includes("/users/sign_in"), { timeout: 60_000 });

  const authDir = path.join(__dirname, ".auth");
  fs.mkdirSync(authDir, { recursive: true });
  const out = path.join(authDir, "a11y-admin.json");
  await context.storageState({ path: out });
  await browser.close();
}
