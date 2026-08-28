import fs from "fs";
import path from "path";
import crypto from "crypto";
import multer from "multer";
import { Router } from "express";
import { fileURLToPath } from "url";
import prismaPkg from "@prisma/client";
import { z } from "zod";
import {
  buildPublicAssetUrl,
  buildPublicThumbnailUrl,
  resolvePublicAssetUrl,
} from "../lib/public-url.js";
import { requireAuthenticatedSession } from "../lib/session-auth.js";
import { prisma } from "../lib/prisma.js";
import { getUploadSubdirPath } from "../lib/uploads-dir.js";

const router = Router();
const { EventAttendeeType } = prismaPkg;
const currentFilePath = fileURLToPath(import.meta.url);
const eventUploadsDirPath = getUploadSubdirPath("events");

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
const eventAttendanceSchema = z.object({
  participantCount: z.coerce.number().int().min(1).max(25),
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
  const myAttendance = event.myAttendance
    ? serializeEventAttendanceSummary(event.myAttendance)
    : null;
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
    bannerUrl: resolvePublicAssetUrl(req, event.bannerUrl),
    thumbnailUrl: buildPublicThumbnailUrl(req, event.bannerUrl),
    promoVideoUrl: resolvePublicAssetUrl(req, event.promoVideoUrl),
    liveStatus: eventDate < new Date().toISOString().slice(0, 10) ? "Completed" : "Scheduled",
    scheduledGoLive: eventDate,
    myAttendance,
  };
}

function serializeEventAttendanceSummary(attendance) {
  return {
    id: attendance.id,
    attendeeType: attendance.attendeeType,
    attendeeName: attendance.attendeeName,
    attendeeEmail: attendance.attendeeEmail,
    companyName: attendance.companyName || "",
    participantCount: attendance.participantCount,
    passCount:
      typeof attendance._count?.passes === "number"
        ? attendance._count.passes
        : Array.isArray(attendance.passes)
          ? attendance.passes.length
          : 0,
    updatedAt: attendance.updatedAt,
  };
}

function serializeEventPass(req, pass, event) {
  return {
    id: pass.id,
    passCode: pass.passCode,
    attendeeType: pass.attendeeType,
    attendeeName: pass.attendeeName,
    attendeeEmail: pass.attendeeEmail,
    companyName: pass.companyName || "",
    slotNumber: pass.slotNumber,
    participantCount: pass.participantCount,
    status: pass.status,
    createdAt: pass.createdAt,
    event: {
      id: event.id,
      name: event.name,
      type: event.type,
      date: event.date.toISOString().slice(0, 10),
      venue: event.venue || "",
      startTime: event.startTime || "",
      endTime: event.endTime || "",
      audience: event.audience || "",
      entryType: event.entryType || "",
      entryCharges: event.entryCharges || "",
      summary: event.summary || "",
    },
  };
}

function resolveAuthenticatedAttendanceContext(req) {
  const user = req.auth?.user;
  if (!user || (!user.isMember && !user.isVendor)) {
    return null;
  }

  if (user.isVendor) {
    if (!user.vendorId) {
      return null;
    }
    return {
      attendeeType: EventAttendeeType.VENDOR,
      userId: user.id,
      memberId: null,
      vendorId: String(user.vendorId),
    };
  }

  if (!user.memberId) {
    return null;
  }

  return {
    attendeeType: EventAttendeeType.MEMBER,
    userId: user.id,
    memberId: String(user.memberId),
    vendorId: null,
  };
}

async function buildAttendanceProfile(tx, context) {
  if (context.attendeeType === EventAttendeeType.VENDOR) {
    const vendor = await tx.vendor.findUnique({
      where: { id: context.vendorId },
      select: {
        id: true,
        companyName: true,
        email: true,
        name: true,
        contactPerson: true,
      },
    });
    if (!vendor) {
      throw new Error("Vendor not found");
    }
    return {
      attendeeName:
        vendor.contactPerson?.trim() || vendor.name.trim() || vendor.companyName.trim(),
      attendeeEmail: vendor.email,
      companyName: vendor.companyName,
    };
  }

  const member = await tx.member.findUnique({
    where: { id: context.memberId },
    select: {
      id: true,
      firstName: true,
      lastName: true,
      email: true,
      companyName: true,
    },
  });
  if (!member) {
    throw new Error("Member not found");
  }
  return {
    attendeeName: `${member.firstName || ""} ${member.lastName || ""}`
      .replace(/\s+/g, " ")
      .trim(),
    attendeeEmail: member.email,
    companyName: member.companyName || "",
  };
}

function buildPassCode(eventId, slotNumber) {
  const suffix = crypto.randomBytes(3).toString("hex").toUpperCase();
  return `EVT-${eventId.slice(-6).toUpperCase()}-${slotNumber}-${suffix}`;
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
  const attendanceContext = resolveAuthenticatedAttendanceContext(req);
  const attendanceMap = new Map();
  if (attendanceContext) {
    const attendances = await prisma.eventAttendance.findMany({
      where: {
        associationId: association.id,
        userId: attendanceContext.userId,
      },
      include: {
        _count: {
          select: {
            passes: true,
          },
        },
      },
    });
    for (const attendance of attendances) {
      attendanceMap.set(attendance.eventId, attendance);
    }
  }
  const events = await prisma.associationEvent.findMany({
    where: { associationId: association.id },
    orderBy: [{ date: "desc" }, { createdAt: "desc" }],
  });

  return res.json({
    events: events.map((event) =>
      serializeEvent(req, {
        ...event,
        myAttendance: attendanceMap.get(event.id) ?? null,
      }),
    ),
  });
});

router.get("/:id/passes/me", requireAuthenticatedSession, async (req, res) => {
  const association = await ensureAssociation();
  const attendanceContext = resolveAuthenticatedAttendanceContext(req);
  if (!attendanceContext) {
    return res.status(403).json({
      error: "Member or vendor access is required for this action.",
    });
  }

  const event = await prisma.associationEvent.findFirst({
    where: {
      id: req.params.id,
      associationId: association.id,
    },
  });
  if (!event) {
    return res.status(404).json({ error: "Event not found" });
  }

  const attendance = await prisma.eventAttendance.findUnique({
    where: {
      eventId_userId: {
        eventId: event.id,
        userId: attendanceContext.userId,
      },
    },
    include: {
      passes: {
        orderBy: { slotNumber: "asc" },
      },
    },
  });

  return res.json({
    attendance: attendance ? serializeEventAttendanceSummary(attendance) : null,
    passes:
      attendance?.passes.map((pass) => serializeEventPass(req, pass, event)) ??
      [],
  });
});

router.post("/:id/attend", requireAuthenticatedSession, async (req, res) => {
  const parsed = eventAttendanceSchema.safeParse(req.body);
  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid attendance payload",
      details: parsed.error.flatten(),
    });
  }

  const association = await ensureAssociation();
  const attendanceContext = resolveAuthenticatedAttendanceContext(req);
  if (!attendanceContext) {
    return res.status(403).json({
      error: "Member or vendor access is required for this action.",
    });
  }

  const event = await prisma.associationEvent.findFirst({
    where: {
      id: req.params.id,
      associationId: association.id,
    },
  });
  if (!event) {
    return res.status(404).json({ error: "Event not found" });
  }

  const participantCount = parsed.data.participantCount;

  const result = await prisma.$transaction(async (tx) => {
    const profile = await buildAttendanceProfile(tx, attendanceContext);
    const attendance = await tx.eventAttendance.upsert({
      where: {
        eventId_userId: {
          eventId: event.id,
          userId: attendanceContext.userId,
        },
      },
      create: {
        associationId: association.id,
        eventId: event.id,
        userId: attendanceContext.userId,
        memberId: attendanceContext.memberId,
        vendorId: attendanceContext.vendorId,
        attendeeType: attendanceContext.attendeeType,
        attendeeName: profile.attendeeName,
        attendeeEmail: profile.attendeeEmail,
        companyName: profile.companyName,
        participantCount,
      },
      update: {
        attendeeName: profile.attendeeName,
        attendeeEmail: profile.attendeeEmail,
        companyName: profile.companyName,
        participantCount,
      },
    });

    await tx.eventPass.deleteMany({
      where: {
        attendanceId: attendance.id,
      },
    });

    for (let index = 0; index < participantCount; index += 1) {
      await tx.eventPass.create({
        data: {
          associationId: association.id,
          eventId: event.id,
          attendanceId: attendance.id,
          userId: attendanceContext.userId,
          memberId: attendanceContext.memberId,
          vendorId: attendanceContext.vendorId,
          attendeeType: attendanceContext.attendeeType,
          passCode: buildPassCode(event.id, index + 1),
          attendeeName: profile.attendeeName,
          attendeeEmail: profile.attendeeEmail,
          companyName: profile.companyName,
          slotNumber: index + 1,
          participantCount,
        },
      });
    }

    const attendanceWithPasses = await tx.eventAttendance.findUnique({
      where: { id: attendance.id },
      include: {
        passes: {
          orderBy: { slotNumber: "asc" },
        },
        _count: {
          select: {
            passes: true,
          },
        },
      },
    });

    return attendanceWithPasses;
  });

  return res.json({
    attendance: serializeEventAttendanceSummary(result),
    passes: result.passes.map((pass) => serializeEventPass(req, pass, event)),
  });
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
