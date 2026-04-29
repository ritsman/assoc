import "dotenv/config";
import express from "express";
import cors from "cors";
import path from "path";
import { fileURLToPath } from "url";
import associationsRouter from "./routes/associations.js";
import eventsRouter from "./routes/events.js";
import membersRouter from "./routes/members.js";
import memberPostsRouter from "./routes/member-posts.js";
import usersRouter from "./routes/users.js";

const app = express();
const port = Number(process.env.PORT || 8083);
const currentFilePath = fileURLToPath(import.meta.url);
const currentDirPath = path.dirname(currentFilePath);
const uploadsDirPath = path.resolve(currentDirPath, "../uploads");

app.use(
  cors({
    origin: process.env.CORS_ORIGIN?.split(",") || "*",
  }),
);
app.use("/uploads", express.static(uploadsDirPath));
app.use(express.json());

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "synetra_bkend",
    timestamp: new Date().toISOString(),
  });
});

app.use("/api/associations", associationsRouter);
app.use("/api/events", eventsRouter);
app.use("/api/members", membersRouter);
app.use("/api/member-posts", memberPostsRouter);
app.use("/api/users", usersRouter);

app.listen(port, () => {
  console.log(`Synetra backend listening on port ${port}`);
});
