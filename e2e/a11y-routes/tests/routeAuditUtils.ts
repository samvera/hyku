import { expect, type Page, type Response } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";
import * as fs from "fs";
import * as path from "path";
import * as crypto from "crypto";

export type Manifest = {
  tenant_cname: string;
  admin_host: string;
  port: number;
  a11y_admin_email?: string;
  a11y_admin_password_env?: string;
  routes: { host: string; path: string }[];
  authenticated_routes?: { host: string; path: string }[];
};

export const manifestPath = path.join(__dirname, "..", "a11y-routes.manifest.json");
export const outDir = path.join(__dirname, "..", "..", "..", "tmp", "playwright-a11y");

export const PRIMARY_CONTENT_SELECTOR_CANDIDATES = [
  "#content-wrapper",
  "#content",
  'main[role="main"]',
  "main",
] as const;

export function loadManifest(): Manifest {
  const raw = fs.readFileSync(manifestPath, "utf8");
  return JSON.parse(raw) as Manifest;
}

export function routeSlug(route: { host: string; path: string }): string {
  const h = crypto.createHash("sha256").update(`${route.host}${route.path}`).digest("hex").slice(0, 12);
  return `${route.host.replace(/[^a-z0-9]+/gi, "_")}_${h}`;
}

export async function resolveAxeIncludeSelector(page: Page): Promise<string> {
  for (const sel of PRIMARY_CONTENT_SELECTOR_CANDIDATES) {
    if ((await page.locator(sel).count()) > 0) return sel;
  }
  return "body";
}

export function assertSuccessfulNavigation(response: Response | null, url: string): void {
  expect(response, `No navigation response for ${url}`).not.toBeNull();
  const status = response!.status();
  const hostHint =
    status === 403
      ? " If this is Host Authorization (Rails), allow *.localhost.direct in config.hosts for the active environment (e.g. test.rb or development.rb)."
      : "";
  const notFoundHint =
    status === 404
      ? " Multitenant tenant routes return 404 when no Account matches the Host — run hyku:demo_content:seed against the same RAILS_ENV as the server; ./bin/playwright-a11y does that before starting Rails."
      : "";
  expect(
    response!.ok(),
    `Route audit expected a successful HTML page (HTTP 2xx/3xx), got ${status} ${response!.statusText()} for ${url}. ` +
      `Update the manifest, seed data, or tenant host routing — scanning error pages mixes routing bugs with accessibility results.${hostHint}${notFoundHint}`
  ).toBe(true);
}

export async function screenshotForArtifacts(page: Page, filePath: string): Promise<void> {
  try {
    await page.screenshot({ path: filePath, fullPage: true });
  } catch {
    await page.screenshot({ path: filePath });
  }
}

export async function runBlockingAaAudit(page: Page, url: string, slug: string): Promise<void> {
  const navResponse = await page.goto(url, { waitUntil: "load", timeout: 90_000 });
  assertSuccessfulNavigation(navResponse, url);
  await page
    .locator(PRIMARY_CONTENT_SELECTOR_CANDIDATES.join(", "))
    .first()
    .waitFor({ state: "attached", timeout: 30_000 })
    .catch(() => {});

  fs.mkdirSync(outDir, { recursive: true });
  await screenshotForArtifacts(page, path.join(outDir, `${slug}.png`));

  const includeSel = await resolveAxeIncludeSelector(page);
  const aaResults = await new AxeBuilder({ page })
    .include(includeSel)
    .withTags(["wcag2a", "wcag2aa", "wcag21aa"])
    .analyze();

  fs.writeFileSync(path.join(outDir, `${slug}.violations.aa.json`), JSON.stringify(aaResults.violations, null, 2));

  expect(aaResults.violations, JSON.stringify(aaResults.violations, null, 2)).toEqual([]);
}

export async function runInformationalAaaAudit(page: Page, url: string, slug: string): Promise<void> {
  const navResponse = await page.goto(url, { waitUntil: "load", timeout: 90_000 });
  assertSuccessfulNavigation(navResponse, url);
  await page
    .locator(PRIMARY_CONTENT_SELECTOR_CANDIDATES.join(", "))
    .first()
    .waitFor({ state: "attached", timeout: 30_000 })
    .catch(() => {});

  fs.mkdirSync(outDir, { recursive: true });

  let aaaViolations: unknown[] = [];
  try {
    const includeSel = await resolveAxeIncludeSelector(page);
    const aaaResults = await new AxeBuilder({ page })
      .include(includeSel)
      .withTags(["wcag2aaa", "wcag21aaa"])
      .analyze();
    aaaViolations = aaaResults.violations;
  } catch {
    aaaViolations = [];
  }

  fs.writeFileSync(path.join(outDir, `${slug}.violations.aaa.json`), JSON.stringify(aaaViolations, null, 2));
  expect(Array.isArray(aaaViolations)).toBeTruthy();
}
