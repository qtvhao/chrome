const express = require("express");
const http = require("http");
const { spawn, execSync } = require("child_process");

const PORT = process.env.PORT || 80;
const CDP_HOST = process.env.CDP_HOST || "127.0.0.1";
const CDP_PORT = parseInt(process.env.CDP_PORT || "9222");
const SOCAT_PORT = parseInt(process.env.SOCAT_PORT || "9223");
const RESPAWN_DELAY_MS = 3000;
const HEALTH_INTERVAL_MS = 10000;

const CHROME_ARGS = [
  "--no-sandbox",
  "--no-first-run",
  "--disable-gpu",
  "--disable-features=VizDisplayCompositor,PrivacySandboxSettings4",
  "--disable-dev-shm-usage",
  "--disable-software-rasterizer",
  "--disable-proxy-certificate-handler",
  "--memory-pressure-off",
  "--user-data-dir=/tmp/chrome-profile",
  `--remote-debugging-port=${CDP_PORT}`,
  "--remote-allow-origins=*",
  "--user-agent=Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Safari/605.1.15",
];

let chromeProc = null;
let respawnTimer = null;

function spawnChrome() {
  if (respawnTimer) {
    clearTimeout(respawnTimer);
    respawnTimer = null;
  }

  console.log("Spawning Chrome...");
  chromeProc = spawn("google-chrome", CHROME_ARGS, {
    stdio: "inherit",
    detached: false,
  });

  chromeProc.on("exit", (code, signal) => {
    console.log(`Chrome exited (code=${code} signal=${signal}), respawning in ${RESPAWN_DELAY_MS}ms`);
    chromeProc = null;
    respawnTimer = setTimeout(spawnChrome, RESPAWN_DELAY_MS);
  });

  chromeProc.on("error", (err) => {
    console.error("Chrome spawn error:", err.message);
    chromeProc = null;
    respawnTimer = setTimeout(spawnChrome, RESPAWN_DELAY_MS);
  });
}

function checkSocatAndRespawn() {
  const req = http.get(
    `http://${CDP_HOST}:${SOCAT_PORT}/json/version`,
    (res) => {
      res.resume(); // drain
    }
  );
  req.on("error", (err) => {
    console.warn(`Port ${SOCAT_PORT} unreachable (${err.message}), killing Chrome to force respawn`);
    if (chromeProc) {
      chromeProc.kill();
    } else {
      spawnChrome();
    }
  });
  req.setTimeout(3000, () => {
    req.destroy();
    console.warn(`Port ${SOCAT_PORT} timed out, killing Chrome to force respawn`);
    if (chromeProc) {
      chromeProc.kill();
    } else {
      spawnChrome();
    }
  });
}

// Wait for X server, then start Chrome
function waitForXAndStart() {
  try {
    execSync("xdpyinfo", { env: process.env, stdio: "ignore" });
    console.log("X server ready");
    spawnChrome();
    setInterval(checkSocatAndRespawn, HEALTH_INTERVAL_MS);
  } catch {
    setTimeout(waitForXAndStart, 1000);
  }
}

const app = express();

app.get("/healthcheck", (_req, res) => {
  const req = http.get(
    `http://${CDP_HOST}:${CDP_PORT}/json/version`,
    (cdpRes) => {
      let body = "";
      cdpRes.on("data", (chunk) => (body += chunk));
      cdpRes.on("end", () => {
        try {
          const info = JSON.parse(body);
          res.json({ status: "ok", cdp: { host: CDP_HOST, port: CDP_PORT, browser: info.Browser, protocol: info["Protocol-Version"], webSocketUrl: info.webSocketDebuggerUrl } });
        } catch {
          res.status(502).json({ status: "error", reason: "invalid CDP response", body });
        }
      });
    }
  );
  req.on("error", (err) => {
    res.status(502).json({ status: "error", reason: "CDP unreachable", detail: err.message });
  });
  req.setTimeout(3000, () => {
    req.destroy();
    res.status(504).json({ status: "error", reason: "CDP timeout" });
  });
});

app.listen(PORT, () => {
  console.log(`Chrome service listening on port ${PORT}`);
  waitForXAndStart();
});
