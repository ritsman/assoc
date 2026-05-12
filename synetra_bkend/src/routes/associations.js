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
const circularUploadsDirPath = path.resolve(currentDirPath, "../../uploads/circulars");
const galleryUploadsDirPath = path.resolve(currentDirPath, "../../uploads/gallery");

function buildSafeUploadName(file, fallbackBaseName) {
  const safeBaseName = path
    .basename(file.originalname, path.extname(file.originalname))
    .replace(/[^a-zA-Z0-9-_]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 60);
  const extension = path.extname(file.originalname) || "";
  return `${Date.now()}-${safeBaseName || fallbackBaseName}${extension}`;
}

const circularStorage = multer.diskStorage({
  destination: (_req, _file, callback) => {
    fs.mkdirSync(circularUploadsDirPath, { recursive: true });
    callback(null, circularUploadsDirPath);
  },
  filename: (_req, file, callback) => {
    callback(null, buildSafeUploadName(file, "circular"));
  },
});

const galleryStorage = multer.diskStorage({
  destination: (_req, _file, callback) => {
    fs.mkdirSync(galleryUploadsDirPath, { recursive: true });
    callback(null, galleryUploadsDirPath);
  },
  filename: (_req, file, callback) => {
    callback(null, buildSafeUploadName(file, "gallery"));
  },
});

const circularUpload = multer({
  storage: circularStorage,
  limits: {
    fileSize: 20 * 1024 * 1024,
  },
});

const galleryUpload = multer({
  storage: galleryStorage,
  limits: {
    fileSize: 20 * 1024 * 1024,
  },
});

const regionalAddressSchema = z.object({
  id: z.string().optional(),
  label: z.string().optional(),
  officeAddress: z.string().optional(),
  city: z.string().optional(),
  state: z.string().optional(),
  pincode: z.string().optional(),
  registrationNumber: z.string().optional(),
  gstNumber: z.string().optional(),
  website: z.string().optional(),
  contactNumbers: z.array(z.string()).optional(),
  helpdeskNumber: z.string().optional(),
  googleMapsLink: z.string().optional(),
});

const aboutStatsSchema = z.object({
  label: z.string(),
  value: z.string(),
});

const aboutContentSchema = z.object({
  heroTitle: z.string().optional(),
  heroIntro: z.string().optional(),
  missionTitle: z.string().optional(),
  missionText: z.string().optional(),
  goalsTitle: z.string().optional(),
  goalsText: z.string().optional(),
  journeyTitle: z.string().optional(),
  journeyText: z.string().optional(),
  headOfficeImage: z.string().optional(),
  galleryImageOne: z.string().optional(),
  galleryImageTwo: z.string().optional(),
  stats: z.array(aboutStatsSchema).optional(),
});

const galleryItemSchema = z.object({
  imageUrl: z.string().optional(),
  headline: z.string().min(1),
  tagline: z.string().optional(),
  description: z.string().optional(),
});

const circularDocumentSchema = z.object({
  headline: z.string().min(1),
  tagline: z.string().optional(),
  summary: z.string().optional(),
});

const associationSchema = z.object({
  name: z.string().min(2),
  slug: z.string().min(2),
  sector: z.string().optional(),
  description: z.string().optional(),
  logoUrl: z.string().url().optional(),
  primaryColor: z.string().optional(),
  appName: z.string().optional(),
  domain: z.string().optional(),
  headOfficeAddress: z.string().optional(),
  city: z.string().optional(),
  state: z.string().optional(),
  pincode: z.string().optional(),
  registrationNumber: z.string().optional(),
  gstNumber: z.string().optional(),
  website: z.string().optional(),
  contactNumbers: z.array(z.string()).optional(),
  helpdeskNumber: z.string().optional(),
  googleMapsLink: z.string().optional(),
  regionalAddresses: z.array(regionalAddressSchema).optional(),
  isActive: z.boolean().optional(),
});

const associationUpdateSchema = associationSchema.partial();
const appAccessSchema = z.object({
  approveMembersLogin: z.boolean(),
  disableScreenshots: z.boolean(),
  approveMembership: z.boolean(),
  approveRegistrationRequest: z.boolean(),
  disableAdminFunctionsFromApp: z.boolean(),
});

function buildGalleryHeadline(fileName) {
  const baseName = path.basename(fileName, path.extname(fileName)).replace(/[-_]+/g, " ").trim();
  return baseName || "Gallery Image";
}

function deleteLocalGalleryAssetIfPresent(imageUrl) {
  if (!imageUrl || !imageUrl.includes("/uploads/gallery/")) {
    return;
  }

  try {
    const url = new URL(imageUrl);
    const relativeStoragePath = url.pathname.replace(/^\/+/, "");
    const filePath = path.resolve(currentDirPath, "../../", relativeStoragePath);

    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
    }
  } catch (_error) {
    // Ignore cleanup errors so gallery deletes still succeed.
  }
}

function serializeCircularDocument(req, circularDocument) {
  const publicUrl = buildPublicAssetUrl(req, circularDocument.storagePath);
  const fileExtension = path.extname(circularDocument.originalFileName).replace(".", "").toUpperCase() || "FILE";

  return {
    id: circularDocument.id,
    headline: circularDocument.headline,
    tagline: circularDocument.tagline,
    summary: circularDocument.summary,
    originalFileName: circularDocument.originalFileName,
    mimeType: circularDocument.mimeType,
    fileSize: circularDocument.fileSize,
    fileExtension,
    documentUrl: publicUrl,
    previewUrl: circularDocument.mimeType.startsWith("image/") ? publicUrl : null,
    createdAt: circularDocument.createdAt,
    updatedAt: circularDocument.updatedAt,
  };
}

function serializeAssociation(req, association) {
  return {
    ...association,
    circularDocuments: Array.isArray(association.circularDocuments)
      ? association.circularDocuments.map((item) => serializeCircularDocument(req, item))
      : [],
  };
}

function serializeAppAccess(appAccess) {
  return {
    approveMembersLogin: appAccess.approveMembersLogin,
    disableScreenshots: appAccess.disableScreenshots,
    approveMembership: appAccess.approveMembership,
    approveRegistrationRequest: appAccess.approveRegistrationRequest,
    disableAdminFunctionsFromApp: appAccess.disableAdminFunctionsFromApp,
    updatedAt: appAccess.updatedAt,
  };
}

async function ensureAssociationAppAccess(associationId) {
  const existingAppAccess = await prisma.associationAppAccess.findUnique({
    where: { associationId },
  });

  if (existingAppAccess) {
    return existingAppAccess;
  }

  return prisma.associationAppAccess.create({
    data: {
      associationId,
    },
  });
}

async function ensureCurrentAssociation() {
  const existingAssociation = await prisma.association.findFirst({
    orderBy: { createdAt: "asc" },
    include: {
      aboutContent: true,
      circularDocuments: {
        orderBy: [{ displayOrder: "asc" }, { createdAt: "asc" }],
      },
      appAccess: true,
      galleryItems: {
        orderBy: [{ displayOrder: "asc" }, { createdAt: "asc" }],
      },
      regionalAddresses: {
        orderBy: { createdAt: "asc" },
      },
    },
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
    include: {
      aboutContent: true,
      circularDocuments: {
        orderBy: [{ displayOrder: "asc" }, { createdAt: "asc" }],
      },
      appAccess: true,
      galleryItems: {
        orderBy: [{ displayOrder: "asc" }, { createdAt: "asc" }],
      },
      regionalAddresses: {
        orderBy: { createdAt: "asc" },
      },
    },
  });
}

router.get("/", async (req, res) => {
  const associations = await prisma.association.findMany({
    include: {
      aboutContent: true,
      circularDocuments: {
        orderBy: [{ displayOrder: "asc" }, { createdAt: "asc" }],
      },
      galleryItems: {
        orderBy: [{ displayOrder: "asc" }, { createdAt: "asc" }],
      },
      regionalAddresses: {
        orderBy: { createdAt: "asc" },
      },
      _count: {
        select: { members: true },
      },
    },
    orderBy: { createdAt: "desc" },
  });

  res.json({ associations: associations.map((association) => serializeAssociation(req, association)) });
});

router.get("/current", async (req, res) => {
  const association = await ensureCurrentAssociation();
  res.json({ association: serializeAssociation(req, association) });
});

router.get("/current/about", async (_req, res) => {
  const association = await ensureCurrentAssociation();
  const aboutContent =
    association.aboutContent ??
    (await prisma.associationAboutContent.create({
      data: {
        associationId: association.id,
      },
    }));

  res.json({ aboutContent, associationId: association.id });
});

router.get("/current/app-access", async (_req, res) => {
  const association = await ensureCurrentAssociation();
  const appAccess = await ensureAssociationAppAccess(association.id);
  res.json({ appAccess: serializeAppAccess(appAccess), associationId: association.id });
});

router.patch("/current/app-access", async (req, res) => {
  const parsed = appAccessSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid app access payload",
      details: parsed.error.flatten(),
    });
  }

  const association = await ensureCurrentAssociation();
  await ensureAssociationAppAccess(association.id);

  const appAccess = await prisma.associationAppAccess.update({
    where: { associationId: association.id },
    data: parsed.data,
  });

  res.json({ appAccess: serializeAppAccess(appAccess), associationId: association.id });
});

router.post("/", async (req, res) => {
  const parsed = associationSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid association payload",
      details: parsed.error.flatten(),
    });
  }

  const association = await prisma.association.create({
    data: {
      ...parsed.data,
      regionalAddresses: parsed.data.regionalAddresses
        ? {
            create: parsed.data.regionalAddresses.map((address) => ({
              label: address.label,
              officeAddress: address.officeAddress,
              city: address.city,
              state: address.state,
              pincode: address.pincode,
              registrationNumber: address.registrationNumber,
              gstNumber: address.gstNumber,
              website: address.website,
              contactNumbers: address.contactNumbers,
              helpdeskNumber: address.helpdeskNumber,
              googleMapsLink: address.googleMapsLink,
            })),
          }
        : undefined,
    },
    include: {
      aboutContent: true,
      circularDocuments: {
        orderBy: [{ displayOrder: "asc" }, { createdAt: "asc" }],
      },
      regionalAddresses: {
        orderBy: { createdAt: "asc" },
      },
    },
  });

  return res.status(201).json({ association });
});

router.patch("/:id", async (req, res) => {
  const parsed = associationUpdateSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid association payload",
      details: parsed.error.flatten(),
    });
  }

  const association = await prisma.association.findUnique({
    where: { id: req.params.id },
  });

  if (!association) {
    return res.status(404).json({ error: "Association not found" });
  }

  const updatedAssociation = await prisma.$transaction(async (tx) => {
    await tx.association.update({
      where: { id: req.params.id },
      data: {
        name: parsed.data.name,
        slug: parsed.data.slug,
        sector: parsed.data.sector,
        description: parsed.data.description,
        logoUrl: parsed.data.logoUrl,
        primaryColor: parsed.data.primaryColor,
        appName: parsed.data.appName,
        domain: parsed.data.domain,
        headOfficeAddress: parsed.data.headOfficeAddress,
        city: parsed.data.city,
        state: parsed.data.state,
        pincode: parsed.data.pincode,
        registrationNumber: parsed.data.registrationNumber,
        gstNumber: parsed.data.gstNumber,
        website: parsed.data.website,
        contactNumbers: parsed.data.contactNumbers,
        helpdeskNumber: parsed.data.helpdeskNumber,
        googleMapsLink: parsed.data.googleMapsLink,
        isActive: parsed.data.isActive,
      },
    });

    if (parsed.data.regionalAddresses) {
      await tx.associationRegionalAddress.deleteMany({
        where: { associationId: req.params.id },
      });

      if (parsed.data.regionalAddresses.length > 0) {
        await tx.associationRegionalAddress.createMany({
          data: parsed.data.regionalAddresses.map((address) => ({
            associationId: req.params.id,
            label: address.label,
            officeAddress: address.officeAddress,
            city: address.city,
            state: address.state,
            pincode: address.pincode,
            registrationNumber: address.registrationNumber,
            gstNumber: address.gstNumber,
            website: address.website,
            contactNumbers: address.contactNumbers,
            helpdeskNumber: address.helpdeskNumber,
            googleMapsLink: address.googleMapsLink,
          })),
        });
      }
    }

    return tx.association.findUnique({
      where: { id: req.params.id },
      include: {
        aboutContent: true,
        circularDocuments: {
          orderBy: [{ displayOrder: "asc" }, { createdAt: "asc" }],
        },
        galleryItems: {
          orderBy: [{ displayOrder: "asc" }, { createdAt: "asc" }],
        },
        regionalAddresses: {
          orderBy: { createdAt: "asc" },
        },
      },
    });
  });

  return res.json({ association: updatedAssociation });
});

router.patch("/:id/about", async (req, res) => {
  const parsed = aboutContentSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid association about payload",
      details: parsed.error.flatten(),
    });
  }

  const association = await prisma.association.findUnique({
    where: { id: req.params.id },
    include: {
      aboutContent: true,
    },
  });

  if (!association) {
    return res.status(404).json({ error: "Association not found" });
  }

  const aboutContent = association.aboutContent
    ? await prisma.associationAboutContent.update({
        where: { associationId: req.params.id },
        data: parsed.data,
      })
    : await prisma.associationAboutContent.create({
        data: {
          associationId: req.params.id,
          ...parsed.data,
        },
      });

  return res.json({ aboutContent });
});

router.get("/:id/gallery", async (req, res) => {
  const association = await prisma.association.findUnique({
    where: { id: req.params.id },
    include: {
      galleryItems: {
        orderBy: [{ displayOrder: "asc" }, { createdAt: "asc" }],
      },
    },
  });

  if (!association) {
    return res.status(404).json({ error: "Association not found" });
  }

  return res.json({ galleryItems: association.galleryItems });
});

router.post("/:id/gallery", async (req, res) => {
  const parsed = galleryItemSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid gallery payload",
      details: parsed.error.flatten(),
    });
  }

  const association = await prisma.association.findUnique({
    where: { id: req.params.id },
    include: {
      galleryItems: true,
    },
  });

  if (!association) {
    return res.status(404).json({ error: "Association not found" });
  }

  const galleryItem = await prisma.associationGalleryItem.create({
    data: {
      associationId: req.params.id,
      imageUrl: parsed.data.imageUrl,
      headline: parsed.data.headline,
      tagline: parsed.data.tagline,
      description: parsed.data.description,
      displayOrder: association.galleryItems.length,
    },
  });

  return res.status(201).json({ galleryItem });
});

router.post("/:id/gallery/uploads", galleryUpload.array("files", 30), async (req, res) => {
  const files = Array.isArray(req.files) ? req.files : [];

  if (!files.length) {
    return res.status(400).json({ error: "At least one gallery image is required" });
  }

  const association = await prisma.association.findUnique({
    where: { id: req.params.id },
    include: {
      galleryItems: true,
    },
  });

  if (!association) {
    return res.status(404).json({ error: "Association not found" });
  }

  const createdGalleryItems = await prisma.$transaction(
    files.map((file, index) =>
      prisma.associationGalleryItem.create({
        data: {
          associationId: req.params.id,
          imageUrl: buildPublicAssetUrl(req, `uploads/gallery/${file.filename}`),
          headline: buildGalleryHeadline(file.originalname),
          tagline: "",
          description: "",
          displayOrder: association.galleryItems.length + index,
        },
      }),
    ),
  );

  return res.status(201).json({ galleryItems: createdGalleryItems });
});

router.patch("/:id/gallery/:galleryItemId", async (req, res) => {
  const parsed = galleryItemSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      error: "Invalid gallery payload",
      details: parsed.error.flatten(),
    });
  }

  const galleryItem = await prisma.associationGalleryItem.findFirst({
    where: {
      id: req.params.galleryItemId,
      associationId: req.params.id,
    },
  });

  if (!galleryItem) {
    return res.status(404).json({ error: "Gallery item not found" });
  }

  const updatedGalleryItem = await prisma.associationGalleryItem.update({
    where: { id: req.params.galleryItemId },
    data: {
      imageUrl: parsed.data.imageUrl,
      headline: parsed.data.headline,
      tagline: parsed.data.tagline,
      description: parsed.data.description,
    },
  });

  return res.json({ galleryItem: updatedGalleryItem });
});

router.delete("/:id/gallery/:galleryItemId", async (req, res) => {
  const galleryItem = await prisma.associationGalleryItem.findFirst({
    where: {
      id: req.params.galleryItemId,
      associationId: req.params.id,
    },
  });

  if (!galleryItem) {
    return res.status(404).json({ error: "Gallery item not found" });
  }

  await prisma.associationGalleryItem.delete({
    where: { id: req.params.galleryItemId },
  });

  deleteLocalGalleryAssetIfPresent(galleryItem.imageUrl);

  return res.status(204).send();
});

router.get("/:id/circulars", async (req, res) => {
  const association = await prisma.association.findUnique({
    where: { id: req.params.id },
    include: {
      circularDocuments: {
        orderBy: [{ displayOrder: "asc" }, { createdAt: "asc" }],
      },
    },
  });

  if (!association) {
    return res.status(404).json({ error: "Association not found" });
  }

  return res.json({
    circularDocuments: association.circularDocuments.map((item) => serializeCircularDocument(req, item)),
  });
});

router.post("/:id/circulars", circularUpload.single("file"), async (req, res) => {
  const parsed = circularDocumentSchema.safeParse(req.body);

  if (!parsed.success) {
    if (req.file?.path) {
      fs.rmSync(req.file.path, { force: true });
    }

    return res.status(400).json({
      error: "Invalid circular payload",
      details: parsed.error.flatten(),
    });
  }

  if (!req.file) {
    return res.status(400).json({ error: "Document file is required" });
  }

  const association = await prisma.association.findUnique({
    where: { id: req.params.id },
    include: {
      circularDocuments: true,
    },
  });

  if (!association) {
    fs.rmSync(req.file.path, { force: true });
    return res.status(404).json({ error: "Association not found" });
  }

  const circularDocument = await prisma.associationCircularDocument.create({
    data: {
      associationId: req.params.id,
      headline: parsed.data.headline,
      tagline: parsed.data.tagline,
      summary: parsed.data.summary,
      originalFileName: req.file.originalname,
      storedFileName: req.file.filename,
      storagePath: `uploads/circulars/${req.file.filename}`,
      mimeType: req.file.mimetype,
      fileSize: req.file.size,
      displayOrder: association.circularDocuments.length,
    },
  });

  return res.status(201).json({ circularDocument: serializeCircularDocument(req, circularDocument) });
});

router.patch("/:id/circulars/:circularDocumentId", circularUpload.single("file"), async (req, res) => {
  const parsed = circularDocumentSchema.safeParse(req.body);

  if (!parsed.success) {
    if (req.file?.path) {
      fs.rmSync(req.file.path, { force: true });
    }

    return res.status(400).json({
      error: "Invalid circular payload",
      details: parsed.error.flatten(),
    });
  }

  const circularDocument = await prisma.associationCircularDocument.findFirst({
    where: {
      id: req.params.circularDocumentId,
      associationId: req.params.id,
    },
  });

  if (!circularDocument) {
    if (req.file?.path) {
      fs.rmSync(req.file.path, { force: true });
    }

    return res.status(404).json({ error: "Circular document not found" });
  }

  const updatedCircularDocument = await prisma.associationCircularDocument.update({
    where: { id: req.params.circularDocumentId },
    data: {
      headline: parsed.data.headline,
      tagline: parsed.data.tagline,
      summary: parsed.data.summary,
      ...(req.file
        ? {
            originalFileName: req.file.originalname,
            storedFileName: req.file.filename,
            storagePath: `uploads/circulars/${req.file.filename}`,
            mimeType: req.file.mimetype,
            fileSize: req.file.size,
          }
        : {}),
    },
  });

  if (req.file && circularDocument.storagePath) {
    const previousFilePath = path.resolve(currentDirPath, "../../", circularDocument.storagePath);
    if (fs.existsSync(previousFilePath)) {
      fs.rmSync(previousFilePath, { force: true });
    }
  }

  return res.json({ circularDocument: serializeCircularDocument(req, updatedCircularDocument) });
});

router.delete("/:id/circulars/:circularDocumentId", async (req, res) => {
  const circularDocument = await prisma.associationCircularDocument.findFirst({
    where: {
      id: req.params.circularDocumentId,
      associationId: req.params.id,
    },
  });

  if (!circularDocument) {
    return res.status(404).json({ error: "Circular document not found" });
  }

  await prisma.associationCircularDocument.delete({
    where: { id: req.params.circularDocumentId },
  });

  const filePath = path.resolve(currentDirPath, "../../", circularDocument.storagePath);
  if (fs.existsSync(filePath)) {
    fs.rmSync(filePath, { force: true });
  }

  return res.status(204).send();
});

export default router;
