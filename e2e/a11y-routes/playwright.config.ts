import { defineConfig, devices } from "@playwright/test";

const port = process.env.PLAYWRIGHT_SERVER_PORT || "3000";
/** Set by bin/playwright-a11y on linux/arm64 where Chromium's GPU helper often fails in Docker. */
const useFirefox = process.env.PLAYWRIGHT_A11Y_BROWSER === "firefox";

/**
 * Local/staging: ApplicationController may require HTTP basic when the tenant is not public
 * (`hidden?`); Rails skips this in test. Defaults match ApplicationController (samvera / hyku).
 * Set PLAYWRIGHT_HTTP_BASIC_OFF=1 to omit credentials. Override user/password via env if needed.
 */
const httpCredentials =
  process.env.PLAYWRIGHT_HTTP_BASIC_OFF === "1"
    ? undefined
    : {
        username: process.env.PLAYWRIGHT_HTTP_BASIC_USER ?? "samvera",
        password: process.env.PLAYWRIGHT_HTTP_BASIC_PASSWORD ?? "hyku",
      };

export default defineConfig({
  globalSetup: require.resolve("./global-setup.ts"),
  testDir: "./tests",
  timeout: 120_000,
  expect: { timeout: 30_000 },
  fullyParallel: false,
  workers: 1,
  reporter: [["list"], ["html", { open: "never", outputFolder: "../../tmp/playwright-a11y/html-report" }]],
  use: {
    ...(useFirefox ? devices["Desktop Firefox"] : devices["Desktop Chrome"]),
    ...(httpCredentials ? { httpCredentials } : {}),
    ignoreHTTPSErrors: true,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: "off",
    baseURL: process.env.PLAYWRIGHT_BASE_URL || `http://admin-hyku.localhost.direct:${port}`,
    headless: useFirefox ? true : process.env.PLAYWRIGHT_DOCKER_XVFB !== "1",
    launchOptions: useFirefox
      ? {}
      : {
          args: [
            "--disable-gpu",
            "--disable-software-rasterizer",
            "--in-process-gpu",
          ],
        },
  },
});
