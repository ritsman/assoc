import "dotenv/config";
import express from "express";
import cors from "cors";
import associationsRouter from "./routes/associations.js";
import membersRouter from "./routes/members.js";

const app = express();
const port = Number(process.env.PORT || 8083);

app.use(
  cors({
    origin: process.env.CORS_ORIGIN?.split(",") || "*",
  }),
);
app.use(express.json());

app.get("/api/health", (_req, res) => {
  res.json({
    ok: true,
    service: "synetra_bkend",
    timestamp: new Date().toISOString(),
  });
});

app.use("/api/associations", associationsRouter);
app.use("/api/members", membersRouter);

app.listen(port, () => {
  console.log(`Synetra backend listening on port ${port}`);
});
