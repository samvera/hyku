import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";
import * as fs from "fs";
import * as path from "path";
import * as crypto from "crypto";

const crawlEnabled = process.env.PLAYWRIGHT_CRAWL === "1";
const maxPages = Number(process.env.PLAYWRIGHT_CRAWL_MAX || "15");
const manifestPath = path.join(__dirname, "..", "a11y-routes.manifest.json");
const outDir = path.join(__dirname, "..", "..", "..", "tmp", "playwright-a11y");

test.describe("Optional BFS crawl (PLAYWRIGHT_CRAWL=1)", () => {
  test.skip(!crawlEnabled, "Set PLAYWRIGHT_CRAWL=1 to enable");

  test("crawl tenant collection page for internal links", async ({ page, browserName }) => {
    const raw = fs.readFileSync(manifestPath, "utf8");
    const manifest = JSON.parse(raw) as { tenant_cname: string; port: number; routes: { host: string; path: string }[] };
    const port = process.env.PLAYWRIGHT_SERVER_PORT || String(manifest.port || 3000);
    const collectionRoute = manifest.routes.find((r) => r.path.includes("/collections/"));
    if (!collectionRoute) {
      test.skip();
      return;
    }

    const start = `http://${collectionRoute.host}:${port}${collectionRoute.path}`;
    const seen = new Set<string>([start]);
    const queue: string[] = [start];
    const hostPat = new RegExp(`^http://${collectionRoute.host}:${port}`);

    fs.mkdirSync(outDir, { recursive: true });

    while (queue.length > 0 && seen.size <= maxPages) {
      const url = queue.shift()!;
      await page.goto(url, { waitUntil: "domcontentloaded", timeout: 60_000 });

      const aa = await new AxeBuilder({ page }).withTags(["wcag2a", "wcag2aa", "wcag21aa"]).analyze();
      const slug = crypto.createHash("sha256").update(url).digest("hex").slice(0, 12);
      fs.writeFileSync(path.join(outDir, `crawl-${browserName}-${slug}.aa.json`), JSON.stringify(aa.violations, null, 2));
      expect(aa.violations, JSON.stringify(aa.violations, null, 2)).toEqual([]);

      if (seen.size >= maxPages) break;

      const hrefs = await page.$$eval("a[href]", (as) => as.map((a) => (a as HTMLAnchorElement).href));
      for (const href of hrefs) {
        if (!hostPat.test(href)) continue;
        if (seen.has(href)) continue;
        if (seen.size >= maxPages) break;
        seen.add(href);
        queue.push(href);
      }
    }
  });
});
