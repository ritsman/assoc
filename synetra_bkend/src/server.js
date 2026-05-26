import "dotenv/config";
import express from "express";
import compression from "compression";
import cors from "cors";
import path from "path";
import { fileURLToPath } from "url";
import associationsRouter from "./routes/associations.js";
import eventsRouter from "./routes/events.js";
import membersRouter from "./routes/members.js";
import memberPostsRouter from "./routes/member-posts.js";
import timelinePostsRouter from "./routes/timeline-posts.js";
import appBannersRouter from "./routes/app-banners.js";
import authRouter from "./routes/auth.js";
import usersRouter from "./routes/users.js";
import vendorsRouter from "./routes/vendors.js";
import { ensureBootstrapAdmin } from "./lib/bootstrap-admin.js";
import { attachSessionContext } from "./lib/session-auth.js";

const app = express();
const port = Number(process.env.PORT || 8083);
const currentFilePath = fileURLToPath(import.meta.url);
const currentDirPath = path.dirname(currentFilePath);
const uploadsDirPath = path.resolve(currentDirPath, "../uploads");
const configuredOrigins = process.env.CORS_ORIGIN?.split(",")
  .map((origin) => origin.trim())
  .filter(Boolean) || ["*"];

app.set("trust proxy", true);

function isAllowedOrigin(origin) {
  if (!origin) {
    return true;
  }

  if (configuredOrigins.includes("*") || configuredOrigins.includes(origin)) {
    return true;
  }

  return /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
}

app.use(
  cors({
    origin(origin, callback) {
      if (isAllowedOrigin(origin)) {
        callback(null, true);
        return;
      }

      callback(new Error(`Origin not allowed by CORS: ${origin}`));
    },
  }),
);
app.use(
  compression({
    threshold: 1024,
  }),
);
app.use("/uploads", express.static(uploadsDirPath));
app.use(express.json({ limit: "25mb" }));
app.use(express.urlencoded({ extended: true, limit: "25mb" }));
app.use("/api", attachSessionContext);

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "synetra_bkend",
    timestamp: new Date().toISOString(),
  });
});

app.use("/api/associations", associationsRouter);
app.use("/api/auth", authRouter);
app.use("/api/events", eventsRouter);
app.use("/api/members", membersRouter);
app.use("/api/member-posts", memberPostsRouter);
app.use("/api/timeline-posts", timelinePostsRouter);
app.use("/api/app-banners", appBannersRouter);
app.use("/api/users", usersRouter);
app.use("/api/vendors", vendorsRouter);

async function startServer() {
  await ensureBootstrapAdmin();

  app.listen(port, () => {
    console.log(`Synetra backend listening on port ${port}`);
  });
}

startServer().catch((error) => {
  console.error("Failed to start Synetra backend", error);
  process.exit(1);
});
