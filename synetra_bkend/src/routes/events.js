import fs from "fs";
import path from "path";
import multer from "multer";
import { Router } from "express";
import { fileURLToPath } from "url";
import { z } from "zod";
import { buildPublicAssetUrl } from "../lib/public-url.js";
import { prisma } from "../lib/prisma.js";

const router = Router();
const currentFilePath = fileURLToPath(import.meta.url);
const currentDirPath = path.dirname(currentFilePath);
const eventUploadsDirPath = path.resolve(currentDirPath, "../../uploads/events");

const optionalDateField = z.preprocess(
  (value) => (value === "" || value === null ? undefined : value),
  z.coerce.date().optional(),
);

const eventTypeSchema = z.object({
  name: z.string().min(1),
  description: z.string().min(1),
});

const eventSchema = z.object({
  name: z.string().min(1),
  type: z.string().min(1),
  audience: z.string().optional(),
  entryType: z.string().optional(),
  entryCharges: z.string().optional(),
  participationCharges: z.string().optional(),
  date: z.coerce.date(),
  venue: z.string().optional(),
  startTime: z.string().optional(),
  endTime: z.string().optional(),
  summary: z.string().optional(),
});

const eventStorage = multer.diskStorage({
  destination: (_req, _file, callback) => {
    fs.mkdirSync(eventUploadsDirPath, { recursive: true });
    callback(null, eventUploadsDirPath);
  },
  filename: (_req, file, callback) => {
    const safeBaseName = path
      .basename(file.originalname, path.extname(file.originalname))
      .replace(/[^a-zA-Z0-9-_]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 60);
    callback(null, `${Date.now()}-${safeBaseName || "event"}${path.extname(file.originalname)}`);
  },
});

const eventUpload = multer({
  storage: eventStorage,
  limits: {
    fileSize: 50 * 1024 * 1024,
  },
});

async function ensureAssociation() {
  const existingAssociation = await prisma.association.findFirst({
    orderBy: { createdAt: "asc" },
  });

  if (existingAssociation) {
    return existingAssociation;
  }

  return prisma.association.create({
    data: {
      name: "Association 1",
      slug: "association-1",
      appName: "Synetra",
      isActive: true,
    },
  });
}

function serializeEventType(eventType) {
  return {
    id: eventType.id,
    title: eventType.name,
    meta: eventType.description,
    badge: "Type",
  };
}

function serializeEvent(req, event) {
  const eventDate = event.date.toISOString().slice(0, 10);
  return {
    id: event.id,
    name: event.name,
    type: event.type,
    audience: event.audience || "",
    entryType: event.entryType || "",
    entryCharges: event.entryCharges || "",
    participationCharges: event.participationCharges || "",
    date: eventDate,
    venue: event.venue || "",
    startTime: event.startTime || "",
    endTime: event.endTime || "",
    summary: event.summary || "",
    imageName: event.bannerFileName || "",
    videoName: event.promoVideoFileName || "",
    bannerUrl: event.bannerUrl ? buildPublicAssetUrl(req, event.bannerUrl) : "",
    promoVideoUrl: event.promoVideoUrl ? buildPublicAssetUrl(req, event.promoVideoUrl) : "",
    liveStatus: eventDate < new Date().toISOString().slice(0, 10) ? "Completed" : "Scheduled",
    scheduledGoLive: eventDate,
  };
}

router.get("/types", async (_req, res) => {
  const association = await ensureAssociation();
  const eventTypes = await prisma.associationEventType.findMany({
    where: { associationId: association.id },
    orderBy: [{ displayOrder: "asc" }, { createdAt: "asc" }],
  });

  return res.json({ eventTypes: eventTypes.map(serializeEventType) });
});

router.post("/types", async (req, res) => {
  const parsed = eventTypeSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "Invalid event type payload", details: parsed.error.flatten() });
  }

  const association = await ensureAssociation();
  const count = await prisma.associationEventType.count({
    where: { associationId: association.id },
  });

  const eventType = await prisma.associationEventType.create({
    data: {
      associationId: association.id,
      name: parsed.data.name,
      description: parsed.data.description,
      displayOrder: count,
    },
  });

  return res.status(201).json({ eventType: serializeEventType(eventType) });
});

router.patch("/types/:id", async (req, res) => {
  const parsed = eventTypeSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({ error: "Invalid event type payload", details: parsed.error.flatten() });
  }

  const existingType = await prisma.associationEventType.findUnique({
    where: { id: req.params.id },
  });

  if (!existingType) {
    return res.status(404).json({ error: "Event type not found" });
  }

  const eventType = await prisma.associationEventType.update({
    where: { id: req.params.id },
    data: {
      name: parsed.data.name,
      description: parsed.data.description,
    },
  });

  return res.json({ eventType: serializeEventType(eventType) });
});

router.get("/", async (req, res) => {
  const association = await ensureAssociation();
  const events = await prisma.associationEvent.findMany({
    where: { associationId: association.id },
    orderBy: [{ date: "desc" }, { createdAt: "desc" }],
  });

  return res.json({ events: events.map((event) => serializeEvent(req, event)) });
});

router.post(
  "/",
  eventUpload.fields([
    { name: "bannerFile", maxCount: 1 },
    { name: "videoFile", maxCount: 1 },
  ]),
  async (req, res) => {
    const parsed = eventSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid event payload", details: parsed.error.flatten() });
    }

    const association = await ensureAssociation();
    const bannerFile = Array.isArray(req.files?.bannerFile) ? req.files.bannerFile[0] : null;
    const videoFile = Array.isArray(req.files?.videoFile) ? req.files.videoFile[0] : null;

    const event = await prisma.associationEvent.create({
      data: {
        associationId: association.id,
        name: parsed.data.name,
        type: parsed.data.type,
        audience: parsed.data.audience,
        entryType: parsed.data.entryType,
        entryCharges: parsed.data.entryCharges,
        participationCharges: parsed.data.participationCharges,
        date: parsed.data.date,
        venue: parsed.data.venue,
        startTime: parsed.data.startTime,
        endTime: parsed.data.endTime,
        summary: parsed.data.summary,
        bannerUrl: bannerFile ? `uploads/events/${bannerFile.filename}` : undefined,
        bannerFileName: bannerFile?.originalname,
        promoVideoUrl: videoFile ? `uploads/events/${videoFile.filename}` : undefined,
        promoVideoFileName: videoFile?.originalname,
      },
    });

    return res.status(201).json({ event: serializeEvent(req, event) });
  },
);

router.patch(
  "/:id",
  eventUpload.fields([
    { name: "bannerFile", maxCount: 1 },
    { name: "videoFile", maxCount: 1 },
  ]),
  async (req, res) => {
    const parsed = eventSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: "Invalid event payload", details: parsed.error.flatten() });
    }

    const existingEvent = await prisma.associationEvent.findUnique({
      where: { id: req.params.id },
    });

    if (!existingEvent) {
      return res.status(404).json({ error: "Event not found" });
    }

    const bannerFile = Array.isArray(req.files?.bannerFile) ? req.files.bannerFile[0] : null;
    const videoFile = Array.isArray(req.files?.videoFile) ? req.files.videoFile[0] : null;

    const event = await prisma.associationEvent.update({
      where: { id: req.params.id },
      data: {
        name: parsed.data.name,
        type: parsed.data.type,
        audience: parsed.data.audience,
        entryType: parsed.data.entryType,
        entryCharges: parsed.data.entryCharges,
        participationCharges: parsed.data.participationCharges,
        date: parsed.data.date,
        venue: parsed.data.venue,
        startTime: parsed.data.startTime,
        endTime: parsed.data.endTime,
        summary: parsed.data.summary,
        bannerUrl: bannerFile ? `uploads/events/${bannerFile.filename}` : existingEvent.bannerUrl,
        bannerFileName: bannerFile?.originalname ?? existingEvent.bannerFileName,
        promoVideoUrl: videoFile ? `uploads/events/${videoFile.filename}` : existingEvent.promoVideoUrl,
        promoVideoFileName: videoFile?.originalname ?? existingEvent.promoVideoFileName,
      },
    });

    return res.json({ event: serializeEvent(req, event) });
  },
);

router.delete("/:id", async (req, res) => {
  const existingEvent = await prisma.associationEvent.findUnique({
    where: { id: req.params.id },
  });

  if (!existingEvent) {
    return res.status(404).json({ error: "Event not found" });
  }

  await prisma.associationEvent.delete({
    where: { id: req.params.id },
  });

  return res.status(204).send();
});

export default router;
