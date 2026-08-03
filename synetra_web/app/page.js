"use client";

import Link from "next/link";
import { useEffect, useRef, useState } from "react";

const apiBaseUrl =
  process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:8083/api";
const webAdminSessionStorageKey = "synetra_web.adminSession";
const committeePostMasterStorageKey = "synetra_web.committeePostMaster";
const membershipTypeMasterStorageKey = "synetra_web.membershipTypeMaster";
const bootstrapSuperAdminEmail = "ritsman@gmail.com";
const defaultCommitteePostOptions = [
  "Chairman",
  "Secretary",
  "Treasurer",
  "Vice Chairman",
  "Member",
];
const defaultMembershipTypeOptions = [
  "Primary",
  "Associate",
  "Temporary Visit",
];
const topLevelSections = {
  dashboard: "Dashboard",
  admin: "Admin",
  association: "Association",
  members: "Members",
  vendors: "Vendors",
  events: "Events",
  timeline: "Timeline",
  profile: "Profile",
};

function normalizeAuthSession(payload, fallbackSession = null) {
  if (!payload?.auth?.token || !payload?.user) {
    return null;
  }

  return {
    authToken: payload.auth.token,
    refreshToken:
      payload.auth.refreshToken || fallbackSession?.refreshToken || "",
    sessionId: payload.auth.sessionId || fallbackSession?.sessionId || "",
    userId: payload.user.id || fallbackSession?.userId || "",
    email: payload.user.email || fallbackSession?.email || "",
    viewerRole:
      payload.user.viewerRole || fallbackSession?.viewerRole || "viewOnly",
    isSuperAdmin:
      payload.user.isSuperAdmin === true ||
      payload.user.viewerRole === "superAdmin",
    displayName:
      payload.user.displayName ||
      [payload.user.firstName, payload.user.lastName]
        .filter(Boolean)
        .join(" ")
        .trim() ||
      payload.user.email ||
      "",
  };
}

function normalizeAppAccessSettings(settings) {
  return {
    approveMembersLogin: settings?.approveMembersLogin === true,
    disableScreenshots: settings?.disableScreenshots === true,
    approveMembership: settings?.approveMembership !== false,
    approveRegistrationRequest: settings?.approveRegistrationRequest !== false,
    disableAdminFunctionsFromApp:
      settings?.disableAdminFunctionsFromApp === true,
  };
}

function readStoredAdminSession() {
  if (typeof window === "undefined") {
    return null;
  }

  try {
    const rawValue = window.localStorage.getItem(webAdminSessionStorageKey);
    if (!rawValue) {
      return null;
    }

    const parsed = JSON.parse(rawValue);
    return normalizeAuthSession({
      auth: {
        token: parsed.authToken,
        refreshToken: parsed.refreshToken,
        sessionId: parsed.sessionId,
      },
      user: {
        id: parsed.userId,
        email: parsed.email,
        viewerRole: parsed.viewerRole,
        isSuperAdmin: parsed.isSuperAdmin,
        displayName: parsed.displayName,
      },
    });
  } catch {
    return null;
  }
}

function persistAdminSession(session) {
  if (typeof window === "undefined") {
    return;
  }

  if (!session) {
    window.localStorage.removeItem(webAdminSessionStorageKey);
    return;
  }

  window.localStorage.setItem(
    webAdminSessionStorageKey,
    JSON.stringify(session),
  );
}

function isElevatedViewerRole(viewerRole) {
  return viewerRole === "admin" || viewerRole === "superAdmin";
}

function getMemberAdminLabel(member) {
  if (member.isSuperAdmin) {
    return "Super Admin";
  }

  if (member.isAdmin) {
    return "Admin";
  }

  return "Member";
}

function normalizeCommitteePostLabel(value) {
  return value.replace(/\s+/g, " ").trim();
}

function isReusableCommitteePost(value) {
  return normalizeCommitteePostLabel(value).toLowerCase() === "member";
}

function normalizeMembershipTypeLabel(value) {
  return value.replace(/\s+/g, " ").trim();
}

function getMembershipTypeDisplayLabel(value) {
  const normalizedValue = normalizeMembershipTypeLabel(value);
  return normalizedValue === "Temporary Visit" ? "Guest" : normalizedValue;
}

function readStoredCommitteePostOptions() {
  if (typeof window === "undefined") {
    return [];
  }

  try {
    const rawValue = window.localStorage.getItem(committeePostMasterStorageKey);
    if (!rawValue) {
      return [];
    }

    const parsed = JSON.parse(rawValue);
    if (!Array.isArray(parsed)) {
      return [];
    }

    return parsed
      .map((item) =>
        typeof item === "string" ? normalizeCommitteePostLabel(item) : "",
      )
      .filter(Boolean);
  } catch {
    return [];
  }
}

function persistCommitteePostOptions(posts) {
  if (typeof window === "undefined") {
    return;
  }

  window.localStorage.setItem(
    committeePostMasterStorageKey,
    JSON.stringify(posts),
  );
}

const navSections = [
  {
    label: topLevelSections.dashboard,
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
      >
        <rect x="3.5" y="3.5" width="7" height="7" rx="1.8" />
        <rect x="13.5" y="3.5" width="7" height="4.5" rx="1.8" />
        <rect x="13.5" y="11.5" width="7" height="9" rx="1.8" />
        <rect x="3.5" y="13.5" width="7" height="7" rx="1.8" />
      </svg>
    ),
  },
  {
    label: topLevelSections.admin,
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
      >
        <circle cx="12" cy="8" r="3.2" />
        <path d="M5 19c1.2-3 3.5-4.5 7-4.5S17.8 16 19 19" />
        <path d="M18.5 6.5h2" />
        <path d="M19.5 5.5v2" />
      </svg>
    ),
  },
  {
    label: topLevelSections.association,
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
      >
        <path d="M4 19.5h16" />
        <path d="M6 19.5V10.5h12v9" />
        <path d="M3.5 10.5 12 4l8.5 6.5" />
        <path d="M9 14h6" />
      </svg>
    ),
  },
  {
    label: topLevelSections.members,
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
      >
        <circle cx="9" cy="8" r="3" />
        <path d="M4.5 18c.9-2.8 3-4.2 6-4.2s5.1 1.4 6 4.2" />
        <path d="M16.5 9.5c.7-.8 1.6-1.2 2.8-1.2 1.7 0 3.1 1 3.7 2.7" />
      </svg>
    ),
  },
  {
    label: topLevelSections.vendors,
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
      >
        <path d="M4 7.5 12 4l8 3.5-8 3.5L4 7.5Z" />
        <path d="M4 12l8 3.5 8-3.5" />
        <path d="M4 16.5 12 20l8-3.5" />
      </svg>
    ),
  },
  {
    label: topLevelSections.events,
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
      >
        <rect x="4" y="5" width="16" height="15" rx="2.4" />
        <path d="M8 3.5v4" />
        <path d="M16 3.5v4" />
        <path d="M4 10h16" />
        <path d="M9 14h2" />
        <path d="M13 14h2" />
      </svg>
    ),
  },
  {
    label: topLevelSections.timeline,
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
      >
        <path d="M7 5.5h13" />
        <path d="M7 12h13" />
        <path d="M7 18.5h13" />
        <circle cx="4.5" cy="5.5" r="1.2" />
        <circle cx="4.5" cy="12" r="1.2" />
        <circle cx="4.5" cy="18.5" r="1.2" />
      </svg>
    ),
  },
  {
    label: topLevelSections.profile,
    icon: (
      <svg
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
      >
        <circle cx="12" cy="8" r="3.2" />
        <path d="M5 19c1.1-3 3.5-4.5 7-4.5s5.9 1.5 7 4.5" />
      </svg>
    ),
    href: "/profile",
  },
];

const adminAccessSections = [
  "App Access",
  "Registration Requests",
  "Member Access",
  "Banner Access",
  "Timeline Access",
  "Event Access",
];
const associationMenuSections = [
  "Profile",
  "About Us",
  "Finance",
  "Committee",
  "Circulars",
  "Gallery",
  "Master",
];
const memberMenuSections = [
  "Primary Members",
  "Associate Members",
  "Guest",
  "Master",
];
const vendorSubSections = [
  "Vendor",
  "Category",
  "Sub-category",
  "Vendor Registration",
  "Vendor Status",
  "App Banner",
];
const flutterAppPermissions = [
  {
    key: "approveMembersLogin",
    label: "Approve members to login",
  },
  {
    key: "disableScreenshots",
    label: "Disable screen shots",
  },
  {
    key: "approveMembership",
    label: "Approve membership",
  },
  {
    key: "approveRegistrationRequest",
    label: "Accept and approve registration request",
  },
  {
    key: "disableAdminFunctionsFromApp",
    label: "Disable admin functions from app",
  },
];

const adminMemberAccessFilters = [
  { key: "All", label: "All" },
  { key: "Primary", label: "Primary" },
  { key: "Associate", label: "Associate" },
  { key: "Guest", label: "Guest" },
  { key: "Committee", label: "Committee Members" },
];
const dashboardMemberApprovalTabs = [
  { key: "Primary", label: "Primary" },
  { key: "Associate", label: "Associate" },
  { key: "Guest", label: "Guest" },
  { key: "Committee", label: "Committee" },
];
const adminMemberAccessViews = [
  { key: "app", label: "Member App Access" },
  { key: "content", label: "Member Content Access" },
];
const adminVendorAccessViews = [
  { key: "app", label: "Vendor App Access" },
  { key: "content", label: "Vendor Content Access" },
];
const galleryItems = [
  {
    id: "gallery-1",
    title: "Plant Visit 2026",
    meta: "Manufacturing Excellence Tour",
    badge: "Featured",
  },
  {
    id: "gallery-2",
    title: "Annual Meet",
    meta: "Association 1 Community Event",
    badge: "Community",
  },
  {
    id: "gallery-3",
    title: "Vendor Showcase",
    meta: "Preferred Partner Highlights",
    badge: "Partner",
  },
];

const circularItems = [
  {
    id: "circular-1",
    title: "Membership Renewal Notice",
    meta: "Deadline: 30 April 2026",
    badge: "Priority",
  },
  {
    id: "circular-2",
    title: "Quarterly Safety Circular",
    meta: "Issued by Association Admin Board",
    badge: "Policy",
  },
  {
    id: "circular-3",
    title: "Training Schedule Release",
    meta: "Manufacturing Skills Program",
    badge: "Program",
  },
];

const advertisementItems = [
  {
    id: "ad-1",
    title: "Precision Tools Partner",
    meta: "Sponsored visibility slot",
    badge: "Ad Slot",
  },
  {
    id: "ad-2",
    title: "Industrial ERP Suite",
    meta: "Digital systems for associations",
    badge: "Software",
  },
  {
    id: "ad-3",
    title: "Fabrication Expo",
    meta: "Upcoming industry showcase",
    badge: "Event",
  },
];

const associationTabs = [
  "Profile",
  "About Us",
  "Finance",
  "Committee",
  "Circulars",
  "Gallery",
  "Master",
];
const financeTabs = ["Income", "Expense", "Journal", "Statement"];

const managementCommittee = [
  {
    id: "committee-1",
    name: "Aarav Mehta",
    role: "President",
    note: "Leads association strategy and annual program planning.",
  },
  {
    id: "committee-2",
    name: "Nisha Rao",
    role: "Secretary",
    note: "Coordinates circulars, records, and meeting agendas.",
  },
  {
    id: "committee-3",
    name: "Kunal Sethi",
    role: "Treasurer",
    note: "Oversees finance reviews, dues, and member billing cycles.",
  },
];

const masterRecords = [
  {
    id: "master-1",
    label: "Membership Types",
    value: "Corporate, Associate, Student",
  },
  {
    id: "master-2",
    label: "Zones",
    value: "North, West, Central, South",
  },
  {
    id: "master-3",
    label: "Document Library",
    value: "Policies, bylaws, renewal forms",
  },
];
const financeRecords = {
  Income: [
    {
      id: "income-1",
      title: "Membership Renewal Collection",
      meta: "Rs. 4,80,000 received from annual membership renewals in April 2026.",
      badge: "Income",
    },
    {
      id: "income-2",
      title: "Vendor Listing Revenue",
      meta: "Rs. 1,10,000 billed for preferred vendor visibility and ad placements.",
      badge: "Income",
    },
    {
      id: "income-3",
      title: "Workshop Registration Fees",
      meta: "Rs. 72,000 collected from technical workshop registrations.",
      badge: "Income",
    },
  ],
  Expense: [
    {
      id: "expense-1",
      title: "Annual Event Venue Advance",
      meta: "Rs. 1,65,000 paid as venue advance for the annual association meet.",
      badge: "Expense",
    },
    {
      id: "expense-2",
      title: "Communication and Printing",
      meta: "Rs. 38,000 spent on circular printing, signage, and dispatch support.",
      badge: "Expense",
    },
    {
      id: "expense-3",
      title: "Admin Operations",
      meta: "Rs. 56,000 cleared toward office operations and vendor coordination.",
      badge: "Expense",
    },
  ],
  Journal: [
    {
      id: "journal-1",
      title: "Accrued Membership Revenue",
      meta: "Journal entry posted for pending membership renewals due in the current quarter.",
      badge: "Journal",
    },
    {
      id: "journal-2",
      title: "Expense Allocation Adjustment",
      meta: "Shared event costs reclassified between administration and outreach heads.",
      badge: "Journal",
    },
    {
      id: "journal-3",
      title: "Vendor Campaign Revenue Recognition",
      meta: "Ad visibility revenue recognized for approved vendor promotions.",
      badge: "Journal",
    },
  ],
  Statement: [],
};
const financeStatementEntries = [
  {
    id: "statement-1",
    date: "2026-04-03",
    particulars: "Primary membership renewal received",
    reference: "MEM-APR-104",
    entryType: "Membership Payment",
    direction: "Credit",
    amount: "Rs. 1,20,000",
  },
  {
    id: "statement-2",
    date: "2026-04-06",
    particulars: "Vendor visibility invoice collected",
    reference: "VEN-AD-221",
    entryType: "Credit",
    direction: "Credit",
    amount: "Rs. 55,000",
  },
  {
    id: "statement-3",
    date: "2026-04-09",
    particulars: "Circular print and dispatch payment",
    reference: "OPS-PRINT-18",
    entryType: "Debit",
    direction: "Debit",
    amount: "Rs. 18,500",
  },
  {
    id: "statement-4",
    date: "2026-04-12",
    particulars: "Quarter-end adjustment entry",
    reference: "JRN-Q4-12",
    entryType: "Journal",
    direction: "Journal",
    amount: "Rs. 42,000",
  },
  {
    id: "statement-5",
    date: "2026-04-18",
    particulars: "Associate membership renewal received",
    reference: "MEM-APR-188",
    entryType: "Membership Payment",
    direction: "Credit",
    amount: "Rs. 78,000",
  },
  {
    id: "statement-6",
    date: "2026-04-21",
    particulars: "Event venue advance released",
    reference: "EXP-EVT-019",
    entryType: "Debit",
    direction: "Debit",
    amount: "Rs. 1,65,000",
  },
];
const eventTimelineGroups = [];
const eventMasterRecords = [
  {
    id: "event-master-1",
    title: "Venues",
    meta: "Association Hall, Expo Grounds, City Convention Center",
    badge: "Master",
  },
  {
    id: "event-master-2",
    title: "Hosts",
    meta: "Association Office, Committee Board, Vendor Relations Desk",
    badge: "Master",
  },
  {
    id: "event-master-3",
    title: "Audience Buckets",
    meta: "Members, Vendors, Committee, Guests, Students",
    badge: "Master",
  },
];
const initialEventTypeRecords = [];

const cityMemberships = [
  { city: "Delhi", count: 23 },
  { city: "Ahmedabad", count: 41 },
  { city: "Mumbai", count: 37 },
  { city: "Pune", count: 19 },
  { city: "Surat", count: 14 },
  { city: "Jaipur", count: 11 },
];

const associationOverviewStats = [
  { value: "18", label: "Cities" },
  { value: "1,284", label: "Total Members" },
  { value: "42", label: "Circulars" },
  { value: "148", label: "Gallery Photos" },
];

const committeeHighlights = [
  { name: "Aarav Mehta", role: "Chairman", initials: "AM" },
  { name: "Nisha Rao", role: "Secretary", initials: "NR" },
  { name: "Kunal Sethi", role: "Treasurer", initials: "KS" },
  { name: "Rhea Patel", role: "Vice Chair", initials: "RP" },
];

const memberArenaTabs = [
  "Primary Members",
  "Associate Members",
  "Guest",
  "Master",
];
const vendorArenaTabs = ["Registration", "Membership & Payment", "Master"];
const eventsArenaTabs = [
  "Master",
  "Create New Event",
  "Type of Event",
  "Event",
];
const initialCreatedEvents = [];
const defaultEventForm = {
  name: "",
  type: "",
  audience: "",
  entryType: "",
  entryCharges: "",
  participationCharges: "",
  date: "",
  venue: "",
  startTime: "",
  endTime: "",
  summary: "",
};

const defaultEventMedia = {
  imageName: "",
  videoName: "",
  imageFile: null,
  videoFile: null,
  bannerUrl: "",
  promoVideoUrl: "",
};

const defaultMemberMediaPostForm = {
  memberId: "",
  title: "",
  summary: "",
  body: "",
  imageFile: null,
  imagePreviewUrl: "",
  imageName: "",
};

const memberRecords = [
  {
    id: "member-1",
    name: "Aarav Mehta",
    company: "Mehta Industrial Systems",
    address: "14 Ashram Road, Ahmedabad",
    gst: "24AABCM1201A1Z3",
    membershipDetails: "Chairman account with full committee access.",
    phone: "+91 98765 10001",
    whatsapp: "919876510001",
    email: "aarav@mehtaindustrial.com",
    membershipType: "Committee",
    membershipPeriod: "Apr 2023 - Mar 2027",
    membershipStartDate: "2023-04-01",
    membershipEndDate: "2027-03-31",
    paymentAmount: "Rs. 0",
    paymentStatus: "Paid",
    badge: "Chairman",
    initials: "AM",
    group: "Committee Members",
    expiryStatus: "active",
    appAccessStatus: "Approved",
  },
  {
    id: "member-2",
    name: "Nisha Rao",
    company: "Rao Process Engineers",
    address: "22 C G Road, Ahmedabad",
    gst: "24AADCR3321J1ZU",
    membershipDetails:
      "Secretary account managing member circular coordination.",
    phone: "+91 98765 10002",
    whatsapp: "919876510002",
    email: "nisha@raoengineers.com",
    membershipType: "Committee",
    membershipPeriod: "Apr 2024 - Mar 2027",
    membershipStartDate: "2024-04-01",
    membershipEndDate: "2027-03-31",
    paymentAmount: "Rs. 0",
    paymentStatus: "Paid",
    badge: "Secretary",
    initials: "NR",
    group: "Committee Members",
    expiryStatus: "active",
    appAccessStatus: "Approved",
  },
  {
    id: "member-3",
    name: "Kunal Sethi",
    company: "Sethi Fabrication Works",
    address: "7 Industrial Layout, Delhi",
    gst: "07ABGCS4510M1ZX",
    membershipDetails: "Primary member record for fabrication services.",
    phone: "+91 98765 10003",
    whatsapp: "919876510003",
    email: "kunal@sethifab.com",
    membershipType: "Primary",
    membershipPeriod: "Jan 2022 - Dec 2026",
    membershipStartDate: "2022-01-01",
    membershipEndDate: "2026-12-31",
    paymentAmount: "Rs. 48,000",
    paymentStatus: "Paid",
    badge: "Primary",
    initials: "KS",
    group: "Primary Members",
    expiryStatus: "active",
    appAccessStatus: "Approved",
  },
  {
    id: "member-4",
    name: "Rhea Patel",
    company: "Patel Precision Cast",
    address: "85 Ring Road, Surat",
    gst: "24AAICP6722K1ZT",
    membershipDetails:
      "Primary member with casting and traceability specialization.",
    phone: "+91 98765 10004",
    whatsapp: "919876510004",
    email: "rhea@patelprecision.com",
    membershipType: "Primary",
    membershipPeriod: "Jul 2021 - Jun 2026",
    membershipStartDate: "2021-07-01",
    membershipEndDate: "2026-06-30",
    paymentAmount: "Rs. 48,000",
    paymentStatus: "Pending",
    badge: "Primary",
    initials: "RP",
    group: "Primary Members",
    expiryStatus: "expiring-soon",
    appAccessStatus: "Restricted",
  },
  {
    id: "member-5",
    name: "Dev Khanna",
    company: "Khanna Automation",
    address: "31 MIDC Estate, Pune",
    gst: "27AAECK9043E1ZF",
    membershipDetails: "Associate member for automation and controls.",
    phone: "+91 98765 10005",
    whatsapp: "919876510005",
    email: "dev@khannaauto.in",
    membershipType: "Associate",
    membershipPeriod: "Apr 2025 - Mar 2026",
    membershipStartDate: "2025-04-01",
    membershipEndDate: "2026-03-31",
    paymentAmount: "Rs. 24,000",
    paymentStatus: "Paid",
    badge: "Associate",
    initials: "DK",
    group: "Associate Members",
    expiryStatus: "expiring-soon",
    appAccessStatus: "Approved",
  },
  {
    id: "member-6",
    name: "Ira Joshi",
    company: "Joshi Toolcraft",
    address: "11 Sector 18, Mumbai",
    gst: "27AAFCJ2019R1ZC",
    membershipDetails: "Associate member for toolcraft and machining.",
    phone: "+91 98765 10006",
    whatsapp: "919876510006",
    email: "ira@joshitoolcraft.com",
    membershipType: "Associate",
    membershipPeriod: "Apr 2024 - Mar 2026",
    membershipStartDate: "2024-04-01",
    membershipEndDate: "2026-03-31",
    paymentAmount: "Rs. 24,000",
    paymentStatus: "Overdue",
    badge: "Associate",
    initials: "IJ",
    group: "Associate Members",
    expiryStatus: "expiring-soon",
    appAccessStatus: "Suspended",
  },
  {
    id: "member-7",
    name: "Vikram Shah",
    company: "Visitor - Expo Delegate",
    address: "Temporary desk, Association Office",
    gst: "",
    membershipDetails: "Temporary visitor pass for expo access.",
    phone: "+91 98765 10007",
    whatsapp: "919876510007",
    email: "vikram.visitor@example.com",
    membershipType: "Temporary Visit",
    membershipPeriod: "Valid until 30 Apr 2026",
    membershipStartDate: "2026-04-01",
    membershipEndDate: "2026-04-30",
    paymentAmount: "Rs. 5,000",
    paymentStatus: "Pending",
    badge: "Visitor",
    initials: "VS",
    group: "Temporary Visitors",
    expiryStatus: "expiring-soon",
    appAccessStatus: "Guest",
  },
  {
    id: "member-8",
    name: "Maya Fernandes",
    company: "Visitor - Training Cohort",
    address: "Guest desk, Training Center",
    gst: "",
    membershipDetails: "Temporary visitor for the training cohort.",
    phone: "+91 98765 10008",
    whatsapp: "919876510008",
    email: "maya.visitor@example.com",
    membershipType: "Temporary Visit",
    membershipPeriod: "Valid until 12 May 2026",
    membershipStartDate: "2026-04-12",
    membershipEndDate: "2026-05-12",
    paymentAmount: "Rs. 5,000",
    paymentStatus: "Paid",
    badge: "Visitor",
    initials: "MF",
    group: "Temporary Visitors",
    expiryStatus: "active",
    appAccessStatus: "Guest",
  },
];

const memberSummaryStats = [
  { value: "1,284", label: "Total Members" },
  { value: "864", label: "Primary" },
  { value: "312", label: "Associate" },
  { value: "108", label: "Visitors" },
];
const initialMembershipFormFields = [
  {
    id: "field-name",
    key: "name",
    label: "Name",
    type: "text",
    required: true,
    isDefault: true,
  },
  {
    id: "field-company-address",
    key: "companyAddress",
    label: "Company Address",
    type: "textarea",
    required: true,
    isDefault: true,
  },
  {
    id: "field-gst",
    key: "gst",
    label: "GST",
    type: "text",
    required: true,
    isDefault: true,
  },
  {
    id: "field-membership-details",
    key: "membershipDetails",
    label: "Membership Details",
    type: "textarea",
    required: true,
    isDefault: true,
  },
];
const defaultMemberAdminForm = {
  name: "",
  company: "",
  companyAddress: "",
  gst: "",
  photoUrl: "",
  membershipDetails: "",
  email: "",
  phone: "",
  membershipType: "Primary",
  membershipStartDate: "",
  membershipEndDate: "",
  paymentAmount: "",
  paymentStatus: "Pending",
  badge: "Draft",
  appAccessStatus: "Pending Approval",
  customFieldValues: {},
};

const defaultCommitteeMemberForm = {
  memberId: "",
  committeePost: "",
  committeeTenureStart: "",
  committeeTenureEnd: "",
  memberBio: "",
  photoUrl: "",
};

function formatMembershipPeriod(startDate, endDate) {
  if (!startDate || !endDate) {
    return "Membership period pending";
  }

  return `${startDate} to ${endDate}`;
}

function getMemberAccessStatus(user, membershipStatus) {
  if (user?.approvalStatus === "REJECTED") {
    return "Cancelled";
  }

  if (user?.approvalStatus === "APPROVED" && user?.isActive === false) {
    return "Suspended";
  }

  if (user?.approvalStatus === "APPROVED") {
    return "Approved";
  }

  if (membershipStatus === "INACTIVE") {
    return "Suspended";
  }

  return "Pending Approval";
}

function formatCommitteeTenure(startDate, endDate) {
  if (!startDate && !endDate) {
    return "Tenure not added yet";
  }

  if (startDate && endDate) {
    return `${startDate} to ${endDate}`;
  }

  if (startDate) {
    return `${startDate} onwards`;
  }

  return `Until ${endDate}`;
}

function getCommitteeRank(post) {
  switch ((post || "").toLowerCase()) {
    case "chairman":
      return 1;
    case "secretary":
      return 2;
    case "treasurer":
      return 3;
    case "vice chairman":
      return 4;
    case "member":
      return 5;
    default:
      return 6;
  }
}

function readStoredMembershipTypeOptions() {
  if (typeof window === "undefined") {
    return [];
  }

  try {
    const rawValue = window.localStorage.getItem(membershipTypeMasterStorageKey);
    if (!rawValue) {
      return [];
    }

    const parsed = JSON.parse(rawValue);
    if (!Array.isArray(parsed)) {
      return [];
    }

    return parsed
      .map((item) =>
        typeof item === "string" ? normalizeMembershipTypeLabel(item) : "",
      )
      .filter(Boolean);
  } catch {
    return [];
  }
}

function persistMembershipTypeOptions(types) {
  if (typeof window === "undefined") {
    return;
  }

  try {
    window.localStorage.setItem(
      membershipTypeMasterStorageKey,
      JSON.stringify(types),
    );
  } catch {}
}

function getCommitteeMembers(allMembers) {
  return [...allMembers]
    .filter((member) => member.isCommitteeMember)
    .sort((left, right) => {
      const rankDiff =
        getCommitteeRank(left.committeePost) -
        getCommitteeRank(right.committeePost);
      if (rankDiff !== 0) {
        return rankDiff;
      }

      return left.name.localeCompare(right.name);
    });
}

function buildCommitteePostOptions(committeeMembers, storedPosts = []) {
  const occupiedPosts = committeeMembers
    .map((member) => normalizeCommitteePostLabel(member.committeePost || ""))
    .filter(Boolean);

  return [
    ...new Set([
      ...defaultCommitteePostOptions,
      ...storedPosts,
      ...occupiedPosts,
    ]),
  ].sort((left, right) => getCommitteeRank(left) - getCommitteeRank(right));
}

function buildMembershipTypeOptions(allMembers, storedTypes = []) {
  const occupiedTypes = allMembers
    .map((member) => normalizeMembershipTypeLabel(member.membershipType || ""))
    .filter(Boolean);

  return [...new Set([...defaultMembershipTypeOptions, ...storedTypes, ...occupiedTypes])].sort(
    (left, right) => left.localeCompare(right),
  );
}

function areStringListsEqual(left, right) {
  if (left === right) {
    return true;
  }

  if (!Array.isArray(left) || !Array.isArray(right) || left.length !== right.length) {
    return false;
  }

  return left.every((value, index) => value === right[index]);
}

function mapApiMemberToUi(member, linkedUser = member.user ?? null) {
  const firstName = member.firstName ?? "";
  const lastName = member.lastName ?? "";
  const name = `${firstName} ${lastName}`.trim();
  const membershipType = member.roleTitle || "Primary";
  const membershipStatus = member.membershipStatus ?? "PENDING";
  const isPendingMember = membershipStatus === "PENDING";
  const isInactiveMember = membershipStatus === "INACTIVE";
  const appAccessStatus = getMemberAccessStatus(linkedUser, membershipStatus);
  const committeePost = member.committeePost || "";
  const committeeTenureStart =
    member.committeeTenureStart?.slice?.(0, 10) || "";
  const committeeTenureEnd = member.committeeTenureEnd?.slice?.(0, 10) || "";

  return {
    id: member.id,
    name,
    company: member.companyName || "",
    address: member.address || "",
    gst: member.gst || "",
    membershipDetails: member.membershipDetails || "",
    phone: member.phone || "",
    whatsapp: (member.phone || "").replace(/\D/g, ""),
    email: member.email,
    photoUrl: member.photoUrl || "",
    membershipType,
    membershipPeriod: formatMembershipPeriod(
      member.membershipStartDate?.slice?.(0, 10) || "",
      member.membershipEndDate?.slice?.(0, 10) || "",
    ),
    membershipStartDate: member.membershipStartDate?.slice?.(0, 10) || "",
    membershipEndDate: member.membershipEndDate?.slice?.(0, 10) || "",
    paymentAmount: member.paymentAmount || "",
    paymentStatus:
      member.paymentStatus === "PAID"
        ? "Paid"
        : member.paymentStatus === "OVERDUE"
          ? "Overdue"
          : member.paymentStatus === "WAIVED"
            ? "Waived"
            : "Pending",
    badge: member.roleTitle || membershipType,
    committeePost,
    committeeTenureStart,
    committeeTenureEnd,
    committeeTenure: formatCommitteeTenure(
      committeeTenureStart,
      committeeTenureEnd,
    ),
    memberBio: member.memberBio || "",
    isCommitteeMember: Boolean(committeePost),
    initials: name
      .split(" ")
      .filter(Boolean)
      .slice(0, 2)
      .map((part) => part[0]?.toUpperCase() ?? "")
      .join(""),
    group:
      membershipType === "Committee"
        ? "Committee Members"
        : membershipType === "Associate"
          ? "Associate Members"
          : membershipType === "Temporary Visit"
            ? "Temporary Visitors"
            : "Primary Members",
    expiryStatus: isPendingMember
      ? "expiring-soon"
      : isInactiveMember
        ? "expiring-soon"
        : "active",
    appAccessStatus,
    accessUserId: linkedUser?.id ?? "",
    isAdmin: Boolean(linkedUser?.isAdmin),
    isSuperAdmin: Boolean(linkedUser?.isSuperAdmin),
    approvalStatus: linkedUser?.approvalStatus ?? "",
    membershipStatus,
    customFieldValues: member.customFieldValues || {},
  };
}

function mapApiMemberPostToUi(post) {
  const status =
    post.reviewStatus === "APPROVED"
      ? "Approved"
      : post.reviewStatus === "ON_HOLD"
        ? "Hold"
        : post.reviewStatus === "REJECTED"
          ? "Rejected"
          : "Pending Review";
  const displayPeriod =
    post.displayStart && post.displayEnd
      ? `${post.displayStart} to ${post.displayEnd}`
      : status === "Rejected"
        ? "Rejected"
        : "Pending approval";

  return {
    id: post.id,
    memberId: post.memberId,
    title: post.title,
    summary: post.summary,
    body: post.body || "",
    status,
    postedBy: post.member?.name ?? "Member",
    postedOn: post.postedOn,
    displayStart: post.displayStart,
    displayEnd: post.displayEnd,
    displayPeriod,
    badge: post.postType || "Post",
    mediaUrl: post.mediaUrl || "",
    mediaType: post.mediaType || "",
    memberPhotoUrl: post.member?.photoUrl || "",
    memberCompany: post.member?.company || "",
  };
}

function mapApiTimelinePostToUi(post) {
  const status =
    post.reviewStatus === "APPROVED"
      ? "Approved"
      : post.reviewStatus === "ON_HOLD"
        ? "Hold"
        : post.reviewStatus === "REJECTED"
          ? "Rejected"
          : "Pending Review";

  return {
    id: post.id,
    sourceType: post.sourceType || "VENDOR",
    sourceId: post.sourceId || "",
    sourceName: post.sourceName || "Timeline Source",
    postedBy: post.postedBy || "",
    caption: post.caption || "",
    contactNumber: post.contactNumber || "",
    imageUrl: post.imageUrl || "",
    landingPageUrl: post.landingPageUrl || "",
    youtubeUrl: post.youtubeUrl || "",
    facebookUrl: post.facebookUrl || "",
    brochureUrl: post.brochureUrl || "",
    brochureMimeType: post.brochureMimeType || "",
    postedOn: post.postedOn || "",
    displayStart: post.displayStart || "",
    displayEnd: post.displayEnd || "",
    status,
  };
}

function getTimelineSourceTheme(sourceType) {
  switch (String(sourceType || "").toUpperCase()) {
    case "MEMBER":
      return { start: "#15803d", end: "#16a34a" };
    case "VENDOR":
      return { start: "#ea580c", end: "#f59e0b" };
    default:
      return { start: "#2563eb", end: "#1d4ed8" };
  }
}

function getInitialsLabel(value) {
  return String(value || "")
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? "")
    .join("");
}

function mapApiAppBannerToUi(banner) {
  const status =
    banner.reviewStatus === "APPROVED"
      ? "Approved"
      : banner.reviewStatus === "ON_HOLD"
        ? "Hold"
        : banner.reviewStatus === "REJECTED"
          ? "Rejected"
          : "Pending Review";

  return {
    id: banner.id,
    vendorId: banner.vendorId || "",
    vendorName: banner.vendorName || "Vendor",
    shortText: banner.shortText || "",
    contactNumber: banner.contactNumber || "",
    socialMediaUrl: banner.socialMediaUrl || "",
    mediaUrl: banner.mediaUrl || "",
    mediaType: banner.mediaType || "",
    brochureUrl: banner.brochureUrl || "",
    brochureMimeType: banner.brochureMimeType || "",
    paymentReceived: Boolean(banner.paymentReceived),
    paymentMode: banner.paymentMode || "",
    paymentRemarks: banner.paymentRemarks || "",
    displayStart: banner.displayStart || "",
    displayEnd: banner.displayEnd || "",
    displayIndex:
      typeof banner.displayIndex === "number" ? banner.displayIndex : "",
    postedOn: banner.postedOn || "",
    createdAt: banner.createdAt || "",
    status,
  };
}

function isAppBannerVisibleOnDashboard(banner) {
  if (banner.status !== "Approved") {
    return false;
  }

  const today = new Date().toISOString().slice(0, 10);
  const startsOnOrBeforeToday =
    !banner.displayStart || banner.displayStart <= today;
  const endsOnOrAfterToday = !banner.displayEnd || banner.displayEnd >= today;

  return (
    startsOnOrBeforeToday &&
    endsOnOrAfterToday &&
    Number.isInteger(Number(banner.displayIndex))
  );
}

function formatVendorRange(startDate, endDate) {
  if (startDate && endDate) {
    return `${startDate} - ${endDate}`;
  }

  if (startDate) {
    return `${startDate} onwards`;
  }

  if (endDate) {
    return `Until ${endDate}`;
  }

  return "Not scheduled";
}

function isTimelinePostVisibleOnDashboard(post) {
  if (post.status !== "Approved") {
    return false;
  }

  const today = new Date().toISOString().slice(0, 10);
  const startsOnOrBeforeToday =
    !post.displayStart || post.displayStart <= today;
  const endsOnOrAfterToday = !post.displayEnd || post.displayEnd >= today;

  return startsOnOrBeforeToday && endsOnOrAfterToday;
}

function DashboardTimelineFeed({ posts }) {
  return (
    <section className="dashboard-timeline-layout">
      <div className="dashboard-timeline-column">
        <div className="panel-topline dashboard-timeline-topline">
          <div>
            <span className="mini-label">Timeline Feed</span>
            <h2>Community Spotlight</h2>
          </div>
          <span className="mini-label">Social Style Stream</span>
        </div>

        <div className="dashboard-timeline-feed">
          {posts.map((post) => (
            <article key={post.id} className="dashboard-timeline-card">
              <div className="dashboard-timeline-head">
                <div className="dashboard-timeline-avatar">
                  {(post.sourceName || "TL")
                    .split(" ")
                    .filter(Boolean)
                    .slice(0, 2)
                    .map((part) => part[0]?.toUpperCase() ?? "")
                    .join("")}
                </div>
                <div className="dashboard-timeline-heading">
                  <strong>{post.sourceName}</strong>
                  <span>
                    Posted by {post.postedBy || post.sourceName} on{" "}
                    {post.postedOn}
                  </span>
                </div>
              </div>

              <p className="dashboard-timeline-copy">{post.caption}</p>

              {post.imageUrl ? (
                <div className="dashboard-timeline-visual">
                  <img
                    src={post.imageUrl}
                    alt={post.caption.slice(0, 80) || "Timeline post"}
                  />
                </div>
              ) : null}

              <div className="dashboard-timeline-actions">
                {post.landingPageUrl ? (
                  <a
                    className="dashboard-timeline-icon"
                    href={post.landingPageUrl}
                    target="_blank"
                    rel="noreferrer"
                    aria-label="Open landing page"
                    title="Landing page"
                  >
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="1.8"
                    >
                      <path d="M10 14 21 3" />
                      <path d="M15 3h6v6" />
                      <path d="M21 14v4a3 3 0 0 1-3 3H6a3 3 0 0 1-3-3V6a3 3 0 0 1 3-3h4" />
                    </svg>
                  </a>
                ) : null}
                {post.youtubeUrl ? (
                  <a
                    className="dashboard-timeline-icon"
                    href={post.youtubeUrl}
                    target="_blank"
                    rel="noreferrer"
                    aria-label="Open YouTube"
                    title="YouTube"
                  >
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="1.8"
                    >
                      <rect x="3" y="6" width="18" height="12" rx="3" />
                      <path
                        d="m10 9 5 3-5 3V9Z"
                        fill="currentColor"
                        stroke="none"
                      />
                    </svg>
                  </a>
                ) : null}
                {post.facebookUrl ? (
                  <a
                    className="dashboard-timeline-icon"
                    href={post.facebookUrl}
                    target="_blank"
                    rel="noreferrer"
                    aria-label="Open Facebook"
                    title="Facebook"
                  >
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="1.8"
                    >
                      <path d="M14 8h3V4h-3c-2.2 0-4 1.8-4 4v3H7v4h3v5h4v-5h3l1-4h-4v-3c0-.6.4-1 1-1Z" />
                    </svg>
                  </a>
                ) : null}
                {post.brochureUrl ? (
                  <a
                    className="dashboard-timeline-icon"
                    href={post.brochureUrl}
                    target="_blank"
                    rel="noreferrer"
                    aria-label="Open brochure"
                    title="Brochure"
                  >
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="1.8"
                    >
                      <path d="M7 3h7l5 5v13H7z" />
                      <path d="M14 3v5h5" />
                      <path d="M10 13h4" />
                      <path d="M10 17h4" />
                    </svg>
                  </a>
                ) : null}
                {post.contactNumber ? (
                  <a
                    className="dashboard-timeline-icon"
                    href={`tel:${post.contactNumber.replace(/\s+/g, "")}`}
                    aria-label="Call contact number"
                    title={post.contactNumber}
                  >
                    <svg
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="1.8"
                    >
                      <path d="M5 4h4l2 5-2.5 1.5a16 16 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A15 15 0 0 1 3 6a2 2 0 0 1 2-2Z" />
                    </svg>
                  </a>
                ) : null}
              </div>
            </article>
          ))}

          {posts.length === 0 ? (
            <article className="association-empty-state">
              <span className="mini-label">Timeline Feed</span>
              <h2>No approved timeline posts are currently live.</h2>
              <p>
                Approve a timeline post in Admin arena, then Timeline Access, to
                feature it here.
              </p>
            </article>
          ) : null}
        </div>
      </div>

      <aside className="dashboard-timeline-sidecard">
        <span className="mini-label">Feed Notes</span>
        <h3>Stream Rules</h3>
        <p>
          This feed is styled like a Facebook page stream, but without likes,
          comments, or reaction counts.
        </p>
        <ul className="dashboard-timeline-rules">
          <li>Only approved posts appear here.</li>
          <li>Posts respect their saved visibility dates.</li>
          <li>
            Icons route users directly to links, brochures, or contact actions.
          </li>
        </ul>
      </aside>
    </section>
  );
}

function DashboardAppBannerCarousel({ items }) {
  const [activeIndex, setActiveIndex] = useState(0);
  const [isAutoPlaying, setIsAutoPlaying] = useState(true);

  useEffect(() => {
    if (items.length <= 1 || !isAutoPlaying) {
      return undefined;
    }

    const timerId = window.setInterval(() => {
      setActiveIndex((current) => (current + 1) % items.length);
    }, 8000);

    return () => window.clearInterval(timerId);
  }, [items.length, isAutoPlaying]);

  useEffect(() => {
    setActiveIndex((current) =>
      items.length === 0 ? 0 : Math.min(current, items.length - 1),
    );
  }, [items.length]);

  if (items.length === 0) {
    return (
      <section className="welcome-panel welcome-panel-compact">
        <div className="panel-topline">
          <div>
            <span className="mini-label">App Banner Carousel</span>
            <h2>Paid Promotions</h2>
          </div>
          <span className="mini-label">Sequence Ready</span>
        </div>
        <article className="association-empty-state">
          <span className="mini-label">No Active Banners</span>
          <h2>No approved app banners are active right now.</h2>
          <p>
            Approved banners with sequence numbers from 1 to 50 will appear here
            in order.
          </p>
        </article>
      </section>
    );
  }

  const activeItem = items[activeIndex] ?? items[0];
  const showControls = items.length > 1;

  const goToPrevious = () => {
    setActiveIndex((current) => (current - 1 + items.length) % items.length);
  };

  const goToNext = () => {
    setActiveIndex((current) => (current + 1) % items.length);
  };

  return (
    <section className="welcome-panel welcome-panel-compact dashboard-banner-panel">
      <div className="panel-topline">
        <div>
          <span className="mini-label">App Banner Carousel</span>
          <h2>Paid Promotions</h2>
        </div>
        <div className="dashboard-banner-toolbar">
          <span className="mini-label">Starts From Sequence 1</span>
          {showControls ? (
            <div className="dashboard-banner-controls">
              <button
                type="button"
                className="dashboard-banner-control"
                onClick={goToPrevious}
                aria-label="Show previous banner"
              >
                ‹
              </button>
              <button
                type="button"
                className="dashboard-banner-control"
                onClick={() => setIsAutoPlaying((current) => !current)}
                aria-label={isAutoPlaying ? "Pause banner carousel" : "Play banner carousel"}
              >
                {isAutoPlaying ? "Pause" : "Play"}
              </button>
              <button
                type="button"
                className="dashboard-banner-control"
                onClick={goToNext}
                aria-label="Show next banner"
              >
                ›
              </button>
            </div>
          ) : null}
        </div>
      </div>

      <div className="carousel-viewport dashboard-banner-viewport">
        <article className="carousel-card tone-advertisement dashboard-banner-card">
          <div className="carousel-visual dashboard-banner-visual">
            {activeItem.mediaUrl ? (
              <img
                src={activeItem.mediaUrl}
                alt={activeItem.shortText.slice(0, 60) || "App banner"}
              />
            ) : (
              <span>Ad</span>
            )}
          </div>
          <div className="carousel-copy dashboard-banner-copy">
            <em className="carousel-badge">Slot {activeItem.displayIndex}</em>
            <strong>{activeItem.vendorName}</strong>
            <p>{activeItem.shortText}</p>
          </div>
        </article>
      </div>
      {showControls ? (
        <div className="dashboard-banner-dots" aria-hidden="true">
          {items.map((item, index) => (
            <button
              key={item.id}
              type="button"
              className={`dashboard-banner-dot ${index === activeIndex ? "is-active" : ""}`}
              onClick={() => setActiveIndex(index)}
              aria-label={`Show banner ${index + 1}`}
            />
          ))}
        </div>
      ) : null}
    </section>
  );
}

function getVendorAccessStatus(linkedUser, vendorStatus) {
  if (linkedUser?.approvalStatus === "REJECTED") {
    return "Removed";
  }

  if (
    linkedUser?.approvalStatus === "APPROVED" &&
    linkedUser?.isActive === false
  ) {
    return "Suspended";
  }

  if (linkedUser?.approvalStatus === "APPROVED") {
    return "Approved";
  }

  if (vendorStatus === "ACTIVE") {
    return "Approved";
  }

  if (vendorStatus === "SUSPENDED") {
    return "Suspended";
  }

  if (vendorStatus === "LAPSED") {
    return "Removed";
  }

  return "Pending Approval";
}

function splitPhoneNumber(value) {
  const normalizedValue = String(value || "").trim();
  const match = normalizedValue.match(/^(\+\d+)\s*(.*)$/);

  if (!match) {
    return {
      code: "+91",
      number: normalizedValue,
    };
  }

  return {
    code: match[1] || "+91",
    number: (match[2] || "").trim(),
  };
}

function DashboardHeroStats({
  primaryMembersCount,
  associateMembersCount,
  guestMembersCount,
  totalVendorsCount,
  approvedVendorsCount,
  pendingVendorsCount,
  suspendedVendorsCount,
  activeUsersCount,
  activeUsersThisMonthCount,
  activeUsersLastSixMonthsCount,
  totalMembersCount,
}) {
  return (
    <section className="dashboard-hero-stats">
      <article className="dashboard-hero-card">
        <div className="dashboard-hero-card-head">
          <span className="mini-label">Members</span>
          <h2>Membership Snapshot</h2>
        </div>
        <div className="dashboard-hero-metrics">
          <div className="dashboard-hero-metric">
            <strong>{primaryMembersCount}</strong>
            <span>Primary Members</span>
          </div>
          <div className="dashboard-hero-metric">
            <strong>{associateMembersCount}</strong>
            <span>Associate Members</span>
          </div>
          <div className="dashboard-hero-metric">
            <strong>{guestMembersCount}</strong>
            <span>Guest Members</span>
          </div>
        </div>
      </article>

      <article className="dashboard-hero-card">
        <div className="dashboard-hero-card-head">
          <span className="mini-label">Vendors</span>
          <h2>Vendor Access Status</h2>
        </div>
        <div className="dashboard-hero-metrics">
          <div className="dashboard-hero-metric">
            <strong>{totalVendorsCount}</strong>
            <span>Total Vendors</span>
          </div>
          <div className="dashboard-hero-metric">
            <strong>{approvedVendorsCount}</strong>
            <span>Approved</span>
          </div>
          <div className="dashboard-hero-metric">
            <strong>{pendingVendorsCount}</strong>
            <span>Pending</span>
          </div>
          <div className="dashboard-hero-metric">
            <strong>{suspendedVendorsCount}</strong>
            <span>Suspended</span>
          </div>
        </div>
      </article>

      <article className="dashboard-hero-card">
        <div className="dashboard-hero-card-head">
          <span className="mini-label">Logins</span>
          <h2>Login Activity</h2>
        </div>
        <div className="dashboard-hero-metrics">
          <div className="dashboard-hero-metric">
            <strong>{activeUsersThisMonthCount}</strong>
            <span>This Month</span>
          </div>
          <div className="dashboard-hero-metric">
            <strong>{activeUsersCount}</strong>
            <span>Active Now</span>
          </div>
          <div className="dashboard-hero-metric">
            <strong>{activeUsersLastSixMonthsCount}</strong>
            <span>Last 6 Months</span>
          </div>
        </div>
        <p className="dashboard-hero-note">
          Counts are based on authenticated session activity in this association.
        </p>
      </article>

      <article className="dashboard-hero-card">
        <div className="dashboard-hero-card-head">
          <span className="mini-label">Association</span>
          <h2>Overall Totals</h2>
        </div>
        <div className="dashboard-hero-metrics">
          <div className="dashboard-hero-metric">
            <strong>{totalMembersCount}</strong>
            <span>Total Members</span>
          </div>
        </div>
      </article>
    </section>
  );
}

function DashboardPendingApprovalsPanel({
  activeTab,
  allItems,
  items,
  onTabChange,
  onOpenRequests,
}) {
  return (
    <article className="dashboard-section-block dashboard-approvals-panel">
      <div className="dashboard-section-head">
        <div>
          <h2>Pending Member Approvals</h2>
          <p>
            Review member login requests by membership type. This panel stays
            focused on pending approvals only.
          </p>
        </div>
        <button
          type="button"
          className="dashboard-link-button"
          onClick={onOpenRequests}
        >
          Open Full Requests
        </button>
      </div>

      <div className="dashboard-approval-tabs" role="tablist" aria-label="Pending member approval types">
        {dashboardMemberApprovalTabs.map((tab) => (
          <button
            key={tab.key}
            type="button"
            role="tab"
            aria-selected={activeTab === tab.key}
            className={`dashboard-approval-tab ${activeTab === tab.key ? "active" : ""}`}
            onClick={() => onTabChange(tab.key)}
          >
            {tab.label}
            <span className="dashboard-approval-tab-count">
              {
                allItems.filter((member) => {
                  if (tab.key === "Guest") {
                    return member.membershipType === "Temporary Visit";
                  }

                  return member.membershipType === tab.key;
                }).length
              }
            </span>
          </button>
        ))}
      </div>

      <div className="dashboard-approvals-scroll">
        <table className="member-table dashboard-approvals-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Company</th>
              <th>Member Type</th>
              <th>Membership Period</th>
              <th>Contact</th>
            </tr>
          </thead>
          <tbody>
            {items.map((member) => (
              <tr key={member.id}>
                <td>{member.name}</td>
                <td>{member.company}</td>
                <td>
                  {member.membershipType === "Temporary Visit"
                    ? "Guest"
                    : member.membershipType}
                </td>
                <td>{member.membershipPeriod}</td>
                <td>
                  <div className="member-table-contact">
                    <a href={`mailto:${member.email}`}>{member.email}</a>
                    <span>{member.phone}</span>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {items.length === 0 ? (
          <article className="association-empty-state dashboard-approvals-empty">
            <span className="mini-label">No Pending Requests</span>
            <h2>No {activeTab.toLowerCase()} approvals waiting right now.</h2>
            <p>New requests for this membership type will appear here automatically.</p>
          </article>
        ) : null}
      </div>
    </article>
  );
}

function DashboardPendingVendorApprovalsPanel({
  items,
  onOpenRequests,
}) {
  return (
    <article className="dashboard-section-block dashboard-approvals-panel">
      <div className="dashboard-section-head">
        <div>
          <h2>Pending Vendor Approvals</h2>
          <p>
            Review pending vendor registrations from the dashboard before moving
            into the full approval workspace.
          </p>
        </div>
        <button
          type="button"
          className="dashboard-link-button"
          onClick={onOpenRequests}
        >
          Open Full Requests
        </button>
      </div>

      <div className="dashboard-approvals-scroll">
        <table className="member-table dashboard-approvals-table">
          <thead>
            <tr>
              <th>Vendor</th>
              <th>Company</th>
              <th>Category</th>
              <th>Sub Category</th>
              <th>Contact</th>
            </tr>
          </thead>
          <tbody>
            {items.map((vendor) => (
              <tr key={vendor.id}>
                <td>{vendor.name}</td>
                <td>{vendor.company}</td>
                <td>{vendor.category || "--"}</td>
                <td>{vendor.vendorType || "--"}</td>
                <td>
                  <div className="member-table-contact">
                    <a href={`mailto:${vendor.email}`}>{vendor.email}</a>
                    <span>{vendor.phone}</span>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {items.length === 0 ? (
          <article className="association-empty-state dashboard-approvals-empty">
            <span className="mini-label">No Pending Requests</span>
            <h2>No vendor approvals are waiting right now.</h2>
            <p>New vendor registration requests will appear here automatically.</p>
          </article>
        ) : null}
      </div>
    </article>
  );
}

function DashboardVendorStrip({ vendors, onOpenVendors }) {
  if (vendors.length === 0) {
    return null;
  }

  return (
    <section className="dashboard-section-block">
      <div className="dashboard-section-head">
        <h2>Vendors</h2>
        <button type="button" className="dashboard-link-button" onClick={onOpenVendors}>
          See all
        </button>
      </div>

      <div className="dashboard-vendor-strip">
        {vendors.map((vendor) => (
          <button
            key={vendor.id}
            type="button"
            className="dashboard-vendor-chip"
            onClick={onOpenVendors}
          >
            <span className="dashboard-vendor-avatar">
              {(vendor.displayName || vendor.company || "V")
                .split(" ")
                .filter(Boolean)
                .slice(0, 2)
                .map((part) => part[0]?.toUpperCase() ?? "")
                .join("")}
            </span>
            <span className="dashboard-vendor-name">
              {vendor.displayName || vendor.company}
            </span>
          </button>
        ))}
      </div>
    </section>
  );
}

function DashboardCommitteeSection({ members }) {
  if (members.length === 0) {
    return (
      <section className="dashboard-section-block">
        <div className="dashboard-section-head">
          <h2>Management Committee</h2>
        </div>
        <article className="association-empty-state">
          <span className="mini-label">Committee</span>
          <h2>No committee members found.</h2>
          <p>Committee members will appear here once published from member records.</p>
        </article>
      </section>
    );
  }

  return (
    <section className="dashboard-section-block">
      <div className="dashboard-section-head">
        <div>
          <span className="mini-label">Management Committee</span>
          <h2>Current Leadership</h2>
        </div>
      </div>

      <div className="dashboard-committee-grid">
        {members.map((member) => (
          <article key={member.id} className="dashboard-committee-card">
            <div className="dashboard-committee-hero">
              {member.photoUrl ? (
                <img src={member.photoUrl} alt={member.name} />
              ) : (
                <span>
                  {member.name
                    .split(" ")
                    .filter(Boolean)
                    .slice(0, 2)
                    .map((part) => part[0]?.toUpperCase() ?? "")
                    .join("")}
                </span>
              )}
            </div>
            <div className="dashboard-committee-copy">
              <span className="mini-label">
                {member.committeePost || "Committee"}
              </span>
              <h3>{member.name}</h3>
              <p>{member.company || "Company not added yet"}</p>
              <small>
                {member.memberBio ||
                  member.membershipDetails ||
                  "Leadership profile will appear here."}
              </small>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}

function DashboardArenaShortcuts({ items }) {
  return (
    <section className="dashboard-shortcuts-card">
      <div className="dashboard-section-head">
        <div>
          <h2>Explore Arenas</h2>
          <p>Jump straight into the areas you use most.</p>
        </div>
      </div>

      <div className="dashboard-shortcuts-grid">
        {items.map((item) => (
          <button
            key={item.label}
            type="button"
            className="dashboard-shortcut-tile"
            style={{
              background: `linear-gradient(135deg, ${item.colors[0]}, ${item.colors[1]})`,
            }}
            onClick={item.onClick}
          >
            <span className="dashboard-shortcut-icon">{item.icon}</span>
            <strong>{item.label}</strong>
          </button>
        ))}
      </div>
    </section>
  );
}

function mapApiVendorToUi(vendor) {
  const vendorStatus = vendor.status ?? "PENDING";
  const linkedUsers = Array.isArray(vendor.users)
    ? [...vendor.users].sort(
        (left, right) =>
          new Date(left.createdAt).getTime() -
          new Date(right.createdAt).getTime(),
      )
    : vendor.user
      ? [vendor.user]
      : [];
  const linkedUser = linkedUsers[0] ?? null;
  const name = vendor.name || vendor.companyName || "Vendor";

  return {
    id: vendor.id,
    name,
    company: vendor.companyName || name,
    address: vendor.address || "",
    city: vendor.city || "",
    phone: vendor.phone || "",
    whatsapp: (vendor.whatsapp || vendor.phone || "").replace(/\D/g, ""),
    email: vendor.email || "",
    vendorType: vendor.vendorType || "",
    category: vendor.category || "General",
    website: readVendorNoteValue(vendor.notes, "Website"),
    facebookUrl: vendor.facebookUrl || "",
    instagramUrl: vendor.instagramUrl || "",
    youtubeUrl: vendor.youtubeUrl || "",
    linkedinUrl: vendor.linkedinUrl || "",
    xUrl: vendor.xUrl || "",
    onboardingPeriod: formatVendorRange(
      vendor.onboardingStartAt,
      vendor.onboardingEndAt,
    ),
    onboardingStartDate: vendor.onboardingStartAt || "",
    onboardingEndDate: vendor.onboardingEndAt || "",
    registrationStatus:
      vendorStatus === "ACTIVE"
        ? "Active"
        : vendorStatus === "SUSPENDED"
          ? "Suspended"
          : vendorStatus === "LAPSED"
            ? "Lapsed"
            : "Pending",
    membershipPlan: vendor.membershipPlan || "Standard Listing",
    paymentStatus:
      vendor.paymentStatus === "PAID"
        ? "Paid"
        : vendor.paymentStatus === "OVERDUE"
          ? "Overdue"
          : vendor.paymentStatus === "WAIVED"
            ? "Waived"
            : "Pending",
    paymentAmount: vendor.paymentAmount || "--",
    paymentDue: vendor.paymentDueDate || "--",
    badge: vendor.badge || vendor.category || "Vendor",
    initials: name
      .split(" ")
      .filter(Boolean)
      .slice(0, 2)
      .map((part) => part[0]?.toUpperCase() ?? "")
      .join(""),
    appAccessStatus: getVendorAccessStatus(linkedUser, vendorStatus),
    contactPerson: vendor.contactPerson || "",
    notes: vendor.notes || "",
    approvalStatus: linkedUser?.approvalStatus ?? "",
    accessUserId: linkedUser?.id ?? "",
    linkedUsers,
    loginEmails:
      vendor.loginEmails ||
      linkedUsers.map((user) => user.email).filter(Boolean),
    primaryLoginEmail:
      vendor.primaryLoginEmail || linkedUsers[0]?.email || vendor.email || "",
    secondaryLoginEmail:
      vendor.secondaryLoginEmail || linkedUsers[1]?.email || "",
  };
}

function readVendorNoteValue(notes, label) {
  if (!notes) {
    return "";
  }

  const match = notes.match(new RegExp(`${label}:\\s*(.*)`));
  return match?.[1]?.trim() ?? "";
}

function buildVendorApprovalForm(vendor) {
  return {
    planName: readVendorNoteValue(vendor?.notes, "Plan Name"),
    openingTime: readVendorNoteValue(vendor?.notes, "Opening Time"),
    closingTime: readVendorNoteValue(vendor?.notes, "Closing Time"),
    membershipPlan:
      vendor?.membershipPlan && vendor.membershipPlan !== "Standard Listing"
        ? vendor.membershipPlan
        : "",
    paymentAmount:
      vendor?.paymentAmount && vendor.paymentAmount !== "--"
        ? vendor.paymentAmount
        : "",
    onboardingStartAt: vendor?.onboardingStartDate || "",
    onboardingEndAt: vendor?.onboardingEndDate || "",
    idProof: null,
    locationProof: null,
    gstNumber: readVendorNoteValue(vendor?.notes, "GST Number"),
    companyBrochure: null,
    profilePhoto: null,
    visitingCard: null,
    isRestaurant: readVendorNoteValue(vendor?.notes, "Is Restaurant") === "Yes",
    paymentMode:
      readVendorNoteValue(vendor?.notes, "Payment Mode") || "Online/NEFT/IMPS",
    bankName: readVendorNoteValue(vendor?.notes, "Bank Name"),
    transactionId: readVendorNoteValue(vendor?.notes, "Transaction ID"),
    paymentDescription: readVendorNoteValue(
      vendor?.notes,
      "Payment Description",
    ),
    googleLocation: readVendorNoteValue(vendor?.notes, "Google Location"),
    paymentDueDate:
      vendor?.paymentDue && vendor.paymentDue !== "--" ? vendor.paymentDue : "",
  };
}

function buildVendorRegistrationForm(vendor) {
  const phoneParts = splitPhoneNumber(vendor?.phone);
  const whatsappParts = splitPhoneNumber(vendor?.whatsapp);

  return {
    id: vendor?.id || "",
    company: vendor?.company || "",
    category: vendor?.category || "",
    subCategory: vendor?.vendorType || "",
    contactPerson: vendor?.contactPerson || "",
    phoneCode: phoneParts.code || "+91",
    whatsappCode: whatsappParts.code || "+91",
    whatsapp: whatsappParts.number || "",
    country: readVendorNoteValue(vendor?.notes, "Country") || "India",
    state: readVendorNoteValue(vendor?.notes, "State") || "",
    membershipPlan: vendor?.membershipPlan || "",
    paymentAmount:
      vendor?.paymentAmount && vendor.paymentAmount !== "--"
        ? vendor.paymentAmount
        : "",
    address: vendor?.address || "",
    city: vendor?.city || "",
    phone: phoneParts.number || "",
    email: vendor?.email || "",
    primaryLoginEmail: vendor?.primaryLoginEmail || vendor?.email || "",
    secondaryLoginEmail: vendor?.secondaryLoginEmail || "",
    website: readVendorNoteValue(vendor?.notes, "Website") || "",
    facebookUrl: vendor?.facebookUrl || "",
    instagramUrl: vendor?.instagramUrl || "",
    youtubeUrl: vendor?.youtubeUrl || "",
    linkedinUrl: vendor?.linkedinUrl || "",
    xUrl: vendor?.xUrl || "",
    workDescription:
      readVendorNoteValue(vendor?.notes, "Work Description") || "",
    zipcode: readVendorNoteValue(vendor?.notes, "Zipcode") || "",
    planName: readVendorNoteValue(vendor?.notes, "Plan Name") || "",
    openingTime: readVendorNoteValue(vendor?.notes, "Opening Time") || "",
    closingTime: readVendorNoteValue(vendor?.notes, "Closing Time") || "",
    gstNumber: readVendorNoteValue(vendor?.notes, "GST Number") || "",
    isRestaurant: readVendorNoteValue(vendor?.notes, "Is Restaurant") === "Yes",
    paymentMode:
      readVendorNoteValue(vendor?.notes, "Payment Mode") || "Online/NEFT/IMPS",
    bankName: readVendorNoteValue(vendor?.notes, "Bank Name") || "",
    transactionId: readVendorNoteValue(vendor?.notes, "Transaction ID") || "",
    paymentDescription:
      readVendorNoteValue(vendor?.notes, "Payment Description") || "",
    googleLocation: readVendorNoteValue(vendor?.notes, "Google Location") || "",
    companyLogo: null,
    idProof: null,
    locationProof: null,
    companyBrochure: null,
    profilePhoto: null,
    visitingCard: null,
    onboardingStartAt: vendor?.onboardingStartDate || "",
    onboardingEndAt: vendor?.onboardingEndDate || "",
    paymentDueDate:
      vendor?.paymentDue && vendor.paymentDue !== "--" ? vendor.paymentDue : "",
  };
}

function isLikelyEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value.trim());
}

function isLikelyUrl(value) {
  if (!value.trim()) {
    return true;
  }

  try {
    const parsed = new URL(value.trim());
    return parsed.protocol === "http:" || parsed.protocol === "https:";
  } catch {
    return false;
  }
}

function getVendorRegistrationValidationError(formData, subCategories) {
  if (!formData.company.trim()) {
    return "Company name is required before saving a vendor record.";
  }
  if (!formData.contactPerson.trim()) {
    return "Contact person name is required before saving a vendor record.";
  }
  if (!formData.phone.trim()) {
    return "Mobile number is required before saving a vendor record.";
  }
  if (!/^\d{10,15}$/.test(formData.phone.trim())) {
    return "Use a 10 to 15 digit mobile number for the vendor contact.";
  }
  if (!formData.email.trim()) {
    return "Contact email is required before saving a vendor record.";
  }
  if (!isLikelyEmail(formData.email)) {
    return "Enter a valid contact email address for the vendor.";
  }
  if (!formData.primaryLoginEmail.trim()) {
    return "Primary login ID is required for vendor app access.";
  }
  if (!isLikelyEmail(formData.primaryLoginEmail)) {
    return "Enter a valid primary login email address.";
  }
  if (
    formData.secondaryLoginEmail.trim() &&
    !isLikelyEmail(formData.secondaryLoginEmail)
  ) {
    return "Enter a valid secondary login email address or leave it blank.";
  }
  if (
    formData.secondaryLoginEmail.trim() &&
    formData.secondaryLoginEmail.trim().toLowerCase() ===
      formData.primaryLoginEmail.trim().toLowerCase()
  ) {
    return "Primary and secondary login IDs must be different.";
  }
  if (!formData.category.trim()) {
    return "Select a vendor category before saving.";
  }
  if (!formData.subCategory.trim()) {
    return "Select a vendor sub category before saving.";
  }
  if (
    Array.isArray(subCategories) &&
    subCategories.length > 0 &&
    !subCategories.includes(formData.subCategory)
  ) {
    return "Choose a sub category from the selected vendor category list.";
  }
  if (!formData.address.trim()) {
    return "Address is required before saving a vendor record.";
  }
  if (formData.country === "India" && !formData.state.trim()) {
    return "Select a state for vendors registered in India.";
  }
  if (formData.country === "India" && !formData.city.trim()) {
    return "Select a city for vendors registered in India.";
  }
  if (formData.zipcode.trim() && !/^\d{5,6}$/.test(formData.zipcode.trim())) {
    return "Use a valid 5 or 6 digit zipcode/pincode.";
  }
  if (
    formData.whatsapp.trim() &&
    !/^\d{10,15}$/.test(formData.whatsapp.trim())
  ) {
    return "Use a 10 to 15 digit WhatsApp number or leave it blank.";
  }

  const urlFields = [
    ["website", formData.website],
    ["Facebook page", formData.facebookUrl],
    ["Instagram page", formData.instagramUrl],
    ["YouTube channel", formData.youtubeUrl],
    ["LinkedIn page", formData.linkedinUrl],
    ["X / Twitter page", formData.xUrl],
  ];

  for (const [label, value] of urlFields) {
    if (!isLikelyUrl(value)) {
      return `${label} must begin with http:// or https://`;
    }
  }

  return "";
}

function getVendorApprovalValidationError(reviewForm) {
  if (!reviewForm.planName.trim()) {
    return "Plan name is required before approving a vendor registration.";
  }

  if (!reviewForm.membershipPlan.trim()) {
    return "Membership plan is required before approving a vendor registration.";
  }

  if (!reviewForm.paymentAmount.trim()) {
    return "Payment amount is required before approving a vendor registration.";
  }

  if (!reviewForm.onboardingStartAt) {
    return "Start date is required before approving a vendor registration.";
  }

  if (!reviewForm.onboardingEndAt) {
    return "End date is required before approving a vendor registration.";
  }

  if (!reviewForm.paymentMode.trim()) {
    return "Payment mode is required before approving a vendor registration.";
  }

  if (!reviewForm.bankName.trim()) {
    return "Bank name is required before approving a vendor registration.";
  }

  if (!reviewForm.transactionId.trim()) {
    return "Transaction ID is required before approving a vendor registration.";
  }

  return "";
}

function MemberMediaPanel({
  isAdmin,
  members,
  posts,
  form,
  isSaving,
  feedbackMessage,
  onFieldChange,
  onImageChange,
  onSubmit,
  onClearImage,
  onStatusChange,
}) {
  return (
    <section className="association-tab-section member-media-layout">
      <article className="member-media-composer">
        <div className="panel-topline">
          <h2>Member Media</h2>
          <span className="mini-label">Image posts only</span>
        </div>

        <div className="profile-form-grid">
          <label className="profile-field">
            <span>Post as Member</span>
            <select
              value={form.memberId}
              onChange={(event) =>
                onFieldChange("memberId", event.target.value)
              }
            >
              <option value="">Select member</option>
              {members.map((member) => (
                <option key={member.id} value={member.id}>
                  {member.name} {member.company ? `- ${member.company}` : ""}
                </option>
              ))}
            </select>
          </label>

          <label className="profile-field">
            <span>Headline</span>
            <input
              type="text"
              value={form.title}
              placeholder="Give the post a short headline"
              onChange={(event) => onFieldChange("title", event.target.value)}
            />
          </label>

          <label className="profile-field profile-field-wide">
            <span>Summary</span>
            <textarea
              rows="3"
              value={form.summary}
              placeholder="Short intro shown in the feed"
              onChange={(event) => onFieldChange("summary", event.target.value)}
            />
          </label>

          <label className="profile-field profile-field-wide">
            <span>Description</span>
            <textarea
              rows="5"
              value={form.body}
              placeholder="Optional details for the member post"
              onChange={(event) => onFieldChange("body", event.target.value)}
            />
          </label>

          <div className="profile-field profile-field-wide">
            <span>Picture</span>
            <label className="member-media-upload">
              <input
                type="file"
                accept="image/*"
                onChange={(event) =>
                  onImageChange(event.target.files?.[0] ?? null)
                }
              />
              <span>{form.imageName || "Choose picture"}</span>
            </label>
            <p className="member-media-hint">
              Only image uploads are allowed here. Videos are not supported.
            </p>
          </div>
        </div>

        {form.imagePreviewUrl ? (
          <div className="member-media-preview-card">
            <img src={form.imagePreviewUrl} alt="Member post preview" />
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={onClearImage}
            >
              Remove picture
            </button>
          </div>
        ) : null}

        <div className="profile-action-row">
          {feedbackMessage ? (
            <p className="admin-access-feedback">{feedbackMessage}</p>
          ) : null}
          <button
            className="primary-link admin-action-button"
            type="button"
            onClick={onSubmit}
            disabled={isSaving}
          >
            {isSaving ? "Posting..." : "Publish Member Post"}
          </button>
        </div>
      </article>

      <section className="member-media-feed">
        <div className="panel-topline">
          <h2>Member Feed</h2>
          <span className="mini-label">Newest first</span>
        </div>

        {posts.length > 0 ? (
          <div className="member-media-feed-list">
            {posts.map((post) => (
              <article key={post.id} className="member-feed-card">
                <div className="member-feed-card-head">
                  <div className="member-feed-avatar">
                    {post.memberPhotoUrl ? (
                      <img src={post.memberPhotoUrl} alt={post.postedBy} />
                    ) : (
                      <span>
                        {post.postedBy
                          .split(" ")
                          .filter(Boolean)
                          .slice(0, 2)
                          .map((part) => part[0]?.toUpperCase() ?? "")
                          .join("") || "MB"}
                      </span>
                    )}
                  </div>
                  <div className="member-feed-heading">
                    <strong>{post.postedBy}</strong>
                    <p>{post.memberCompany || "Member update"}</p>
                    <span>{post.postedOn}</span>
                  </div>
                  <span
                    className={`member-feed-status status-${(post.status || "pending").toLowerCase().replace(/\s+/g, "-")}`}
                  >
                    {post.status}
                  </span>
                </div>

                <div className="member-feed-card-copy">
                  <h3>{post.title}</h3>
                  <p>{post.summary}</p>
                  {post.body ? (
                    <div className="member-feed-body">{post.body}</div>
                  ) : null}
                </div>

                {post.mediaUrl ? (
                  <div className="member-feed-image-wrap">
                    <img src={post.mediaUrl} alt={post.title} />
                  </div>
                ) : null}

                {isAdmin ? (
                  <div className="member-feed-admin-row">
                    <label className="content-control-field">
                      <span>Post Status</span>
                      <select
                        value={post.status}
                        onChange={(event) =>
                          onStatusChange(post.id, event.target.value)
                        }
                      >
                        <option value="Approved">Approved</option>
                        <option value="Rejected">Rejected</option>
                        <option value="Pending Review">Pending Review</option>
                      </select>
                    </label>
                  </div>
                ) : null}
              </article>
            ))}
          </div>
        ) : (
          <article className="association-empty-state">
            <span className="mini-label">No Posts</span>
            <h2>No member media posts yet.</h2>
            <p>
              The first approved or pending image post will appear here as soon
              as it is submitted.
            </p>
          </article>
        )}
      </section>
    </section>
  );
}

function buildEventTimelineGroups(events) {
  const today = new Date().toISOString().slice(0, 10);
  const groupedEvents = [
    {
      title: "Past Events",
      tone: "tone-gallery",
      badge: "Past",
      items: events.filter((event) => event.date < today),
    },
    {
      title: "Current Events",
      tone: "tone-circular",
      badge: "Current",
      items: events.filter((event) => event.date === today),
    },
    {
      title: "Coming Events",
      tone: "tone-advertisement",
      badge: "Coming",
      items: events.filter((event) => event.date > today),
    },
  ];

  return groupedEvents.map((group) => ({
    ...group,
    items: group.items.map((event) => ({
      id: event.id,
      title: event.name,
      meta: `${event.summary || "Event details saved in the event desk."}${event.venue ? ` Venue: ${event.venue}.` : ""}`,
      badge: group.badge,
      bannerUrl: event.bannerUrl || "",
      eventDate: event.date,
    })),
  }));
}
const initialVendorRecords = [
  {
    id: "vendor-1",
    name: "Precision Tools Partner",
    company: "Precision Tools Partner",
    address: "Plot 12, Industrial Estate, Ahmedabad",
    city: "Ahmedabad",
    phone: "+91 98980 20001",
    whatsapp: "919898020001",
    email: "hello@precisiontools.in",
    vendorType: "Machinery",
    category: "Industrial Machinery",
    onboardingPeriod: "Apr 2025 - Mar 2027",
    registrationStatus: "Active",
    membershipPlan: "Gold Listing",
    paymentStatus: "Paid",
    paymentAmount: "Rs. 48,000",
    paymentDue: "31 Mar 2027",
    badge: "Preferred",
    initials: "PT",
    appAccessStatus: "Approved",
  },
  {
    id: "vendor-2",
    name: "Industrial ERP Suite",
    company: "Industrial ERP Suite",
    address: "Tower 4, BKC, Mumbai",
    city: "Mumbai",
    phone: "+91 98980 20002",
    whatsapp: "919898020002",
    email: "sales@industrialerp.com",
    vendorType: "Software",
    category: "Digital Solutions",
    onboardingPeriod: "Jan 2026 - Dec 2026",
    registrationStatus: "Suspended",
    membershipPlan: "Featured Listing",
    paymentStatus: "Pending",
    paymentAmount: "Rs. 36,000",
    paymentDue: "15 May 2026",
    badge: "Software",
    initials: "IE",
    appAccessStatus: "Restricted",
  },
  {
    id: "vendor-3",
    name: "Fabrication Expo",
    company: "Fabrication Expo",
    address: "Expo Grounds, Pune",
    city: "Pune",
    phone: "+91 98980 20003",
    whatsapp: "919898020003",
    email: "team@fabexpo.in",
    vendorType: "Events",
    category: "Events & Promotion",
    onboardingPeriod: "Jun 2025 - Jun 2026",
    registrationStatus: "Lapsed",
    membershipPlan: "Campaign Listing",
    paymentStatus: "Overdue",
    paymentAmount: "Rs. 24,000",
    paymentDue: "30 Apr 2026",
    badge: "Events",
    initials: "FE",
    appAccessStatus: "Approved",
  },
];
const initialVendorCategories = [
  "Industrial Machinery",
  "Digital Solutions",
  "Events & Promotion",
];
const vendorSubCategoryMap = {
  "Industrial Machinery": [
    "CNC Machines",
    "Tooling",
    "Automation",
    "Packaging",
  ],
  "Digital Solutions": ["ERP", "CRM", "IoT", "Cybersecurity"],
  "Events & Promotion": [
    "Exhibitions",
    "Media",
    "Conference Support",
    "Brand Activation",
  ],
};
const initialVendorCategoryIdMap = {};
const initialVendorSubCategoryIdMap = {};

function hydrateVendorTaxonomy(categories) {
  const nextCategories = [];
  const nextSubCategoryMap = {};
  const nextCategoryIdMap = {};
  const nextSubCategoryIdMap = {};

  for (const category of Array.isArray(categories) ? categories : []) {
    if (!category?.name) {
      continue;
    }

    nextCategories.push(category.name);
    nextCategoryIdMap[category.name] = category.id;
    nextSubCategoryMap[category.name] = [];
    nextSubCategoryIdMap[category.name] = {};

    for (const subCategory of Array.isArray(category.subCategories)
      ? category.subCategories
      : []) {
      if (!subCategory?.name) {
        continue;
      }

      nextSubCategoryMap[category.name].push(subCategory.name);
      nextSubCategoryIdMap[category.name][subCategory.name] = subCategory.id;
    }
  }

  return {
    categories: nextCategories,
    subCategoryMap: nextSubCategoryMap,
    categoryIdMap: nextCategoryIdMap,
    subCategoryIdMap: nextSubCategoryIdMap,
  };
}
const vendorCountryOptions = ["India", "United Arab Emirates", "Singapore"];
const vendorStateOptionsByCountry = {
  India: ["Gujarat", "Maharashtra", "Karnataka", "Delhi"],
  "United Arab Emirates": ["Dubai", "Abu Dhabi", "Sharjah"],
  Singapore: ["Central Region"],
};
const vendorCityOptionsByState = {
  Gujarat: ["Ahmedabad", "Surat", "Vadodara", "Rajkot"],
  Maharashtra: ["Mumbai", "Pune", "Nagpur"],
  Karnataka: ["Bengaluru", "Mysuru"],
  Delhi: ["New Delhi"],
  Dubai: ["Dubai"],
  "Abu Dhabi": ["Abu Dhabi"],
  Sharjah: ["Sharjah"],
  "Central Region": ["Singapore"],
};
const vendorPhoneCodeOptions = ["+91", "+971", "+65"];
const vendorPlanOptions = [
  "Basic Plan",
  "Silver Plan",
  "Gold Plan",
  "Premium Plan",
];
const vendorPaymentModeOptions = ["Online/NEFT/IMPS", "Cheque", "Cash", "UPI"];
const vendorContentPosts = [
  {
    id: "vendor-post-1",
    vendorId: "vendor-1",
    title: "High Precision CNC Package",
    summary:
      "Short-form ad banner promoting a new CNC bundle for association members.",
    status: "Approved",
    postedBy: "Precision Tools Partner",
    postedOn: "20 Apr 2026",
    displayPeriod: "20 Apr 2026 - 20 May 2026",
    displayStart: "2026-04-20",
    displayEnd: "2026-05-20",
    badge: "Ad Banner",
  },
  {
    id: "vendor-post-2",
    vendorId: "vendor-2",
    title: "ERP Migration Campaign",
    summary:
      "Short article-style ad for digital transformation onboarding and implementation support.",
    status: "Pending Review",
    postedBy: "Industrial ERP Suite",
    postedOn: "19 Apr 2026",
    displayPeriod: "Pending approval",
    displayStart: "2026-04-19",
    displayEnd: "2026-05-05",
    badge: "Ad Article",
  },
  {
    id: "vendor-post-3",
    vendorId: "vendor-3",
    title: "Expo Floor Visitor Pass",
    summary:
      "Guest-facing ad campaign offering early registration for the next fabrication expo.",
    status: "Rejected",
    postedBy: "Fabrication Expo",
    postedOn: "18 Apr 2026",
    displayPeriod: "Rejected",
    displayStart: "2026-04-18",
    displayEnd: "2026-04-30",
    badge: "Ad Banner",
  },
];

function buildMemberTabData(allMembers) {
  return {
    "All Members": allMembers,
    "Primary Members": allMembers.filter(
      (member) => member.group === "Primary Members",
    ),
    "Associate Members": allMembers.filter(
      (member) => member.group === "Associate Members",
    ),
    Guest: allMembers.filter(
      (member) => member.group === "Temporary Visitors",
    ),
  };
}

const initialAssociationTabData = {
  Profile: [
    {
      id: "profile-1",
      title: "Association Profile",
      meta: "Manufacturing and engineering community for one active tenant.",
      badge: "Overview",
    },
    {
      id: "profile-2",
      title: "Contact Snapshot",
      meta: "Industrial Estate Road, Ahmedabad | admin@association1.org",
      badge: "Contact",
    },
    {
      id: "profile-3",
      title: "Coverage",
      meta: "18 cities, 1,284 members, 26 partner vendors.",
      badge: "Reach",
    },
  ],
  "About Us": [
    {
      id: "about-1",
      title: "Mission",
      meta: "Support industrial collaboration, member growth, and knowledge exchange.",
      badge: "Purpose",
    },
    {
      id: "about-2",
      title: "Association Story",
      meta: "Built to connect manufacturing businesses, professionals, and partners.",
      badge: "Story",
    },
    {
      id: "about-3",
      title: "Public Summary",
      meta: "A tenant-aware public-facing section that can expand over time.",
      badge: "Public",
    },
  ],
  Finance: financeRecords.Income,
  Committee: managementCommittee.map((member) => ({
    id: member.id,
    title: member.name,
    meta: member.note,
    badge: member.role,
  })),
  Circulars: circularItems,
  Gallery: galleryItems,
  Master: masterRecords.map((item) => ({
    id: item.id,
    title: item.label,
    meta: item.value,
    badge: "Master",
  })),
};

const defaultRegionalAddress = {
  id: "",
  label: "",
  officeAddress: "",
  city: "",
  state: "",
  pincode: "",
  registrationNumber: "",
  gstNumber: "",
  website: "",
  contactNumbers: "",
  helpdeskNumber: "",
  googleMapsLink: "",
};

const defaultAssociationProfile = {
  id: "",
  name: "Association 1",
  slug: "association-1",
  headOfficeAddress: "",
  city: "",
  state: "",
  pincode: "",
  registrationNumber: "",
  gstNumber: "",
  website: "",
  contactNumbers: "",
  helpdeskNumber: "",
  googleMapsLink: "",
  regionalAddresses: [],
};

const defaultAssociationAbout = {
  heroTitle: "Forging a stronger industrial community together.",
  heroIntro:
    "Association 1 brings manufacturers, exporters, service partners, and industry leaders onto one shared platform to grow capability, trust, and regional influence.",
  missionTitle: "Our Mission",
  missionText:
    "We exist to help member businesses collaborate more easily, represent shared interests more confidently, and build long-term industrial strength through knowledge exchange and collective action.",
  goalsTitle: "What We Focus On",
  goalsText:
    "From business networking and policy representation to technical training, exhibitions, vendor discovery, and regional expansion, our work is designed to make every member more connected and more competitive.",
  journeyTitle: "Journey So Far",
  journeyText:
    "What started as a focused local trade body has grown into a vibrant association with members across multiple cities, active committees, regular events, and an expanding support network for both established firms and emerging businesses.",
  stats: [
    { label: "Years of collective legacy", value: "18+" },
    { label: "Member companies connected", value: "1,200+" },
    { label: "Industry events hosted", value: "85+" },
  ],
  headOfficeImage:
    "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?auto=format&fit=crop&w=1200&q=80",
  galleryImageOne:
    "https://images.unsplash.com/photo-1517048676732-d65bc937f952?auto=format&fit=crop&w=900&q=80",
  galleryImageTwo:
    "https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?auto=format&fit=crop&w=900&q=80",
};

const defaultGalleryItemForm = {
  id: "",
  imageUrl: "",
  headline: "",
  tagline: "",
  description: "",
};

const defaultGalleryFolderForm = {
  id: "",
  name: "",
  files: [],
};

const defaultCircularDocumentForm = {
  id: "",
  headline: "",
  tagline: "",
  summary: "",
  file: null,
  fileName: "",
  documentUrl: "",
  previewUrl: "",
  mimeType: "",
  fileExtension: "",
};

const defaultTimelinePostForm = {
  sourceType: "ASSOCIATION",
  memberId: "",
  vendorId: "",
  postedBy: "",
  caption: "",
  contactNumber: "",
  landingPageUrl: "",
  youtubeUrl: "",
  facebookUrl: "",
  imageFile: null,
  brochureFile: null,
};

const defaultAppBannerForm = {
  vendorId: "",
  shortText: "",
  contactNumber: "",
  socialMediaUrl: "",
  mediaFile: null,
  brochureFile: null,
};

const appBannerMediaRecommendation =
  "Recommended banner: 1080 x 360 px, JPG/PNG/WebP, max 1 MB.";
const appBannerPdfRecommendation =
  "Optional brochure PDF: keep under 2 MB for smoother Flutter downloads.";

function getGoogleMapsEmbedUrl(value) {
  const trimmedValue = value?.trim();
  if (!trimmedValue) {
    return "";
  }

  try {
    const parsedUrl = new URL(trimmedValue);

    if (
      parsedUrl.hostname.includes("google.") &&
      parsedUrl.pathname.includes("/maps/embed")
    ) {
      return parsedUrl.toString();
    }

    const mapQuery =
      parsedUrl.searchParams.get("q") ||
      parsedUrl.searchParams.get("query") ||
      parsedUrl.searchParams.get("destination") ||
      parsedUrl.searchParams.get("daddr") ||
      parsedUrl.searchParams.get("ll");

    if (mapQuery) {
      return `https://www.google.com/maps?q=${encodeURIComponent(mapQuery)}&output=embed`;
    }
  } catch {
    return `https://www.google.com/maps?q=${encodeURIComponent(trimmedValue)}&output=embed`;
  }

  return `https://www.google.com/maps?q=${encodeURIComponent(trimmedValue)}&output=embed`;
}

function AssociationMapPreview({ label, value }) {
  const trimmedValue = value?.trim();

  if (!trimmedValue) {
    return (
      <div className="association-profile-wide">
        <span className="mini-label">{label}</span>
        <p>Not added yet</p>
      </div>
    );
  }

  const embedUrl = getGoogleMapsEmbedUrl(trimmedValue);

  return (
    <div className="association-profile-wide">
      <span className="mini-label">{label}</span>
      <div className="association-map-card">
        <iframe
          className="association-map-frame"
          src={embedUrl}
          title={label}
          loading="lazy"
          referrerPolicy="no-referrer-when-downgrade"
          allowFullScreen
        />
        <a
          className="association-map-link"
          href={trimmedValue}
          target="_blank"
          rel="noreferrer"
        >
          Open in Google Maps
        </a>
      </div>
    </div>
  );
}

function mapAssociationAboutToForm(aboutContent) {
  return {
    heroTitle: aboutContent?.heroTitle ?? defaultAssociationAbout.heroTitle,
    heroIntro: aboutContent?.heroIntro ?? defaultAssociationAbout.heroIntro,
    missionTitle:
      aboutContent?.missionTitle ?? defaultAssociationAbout.missionTitle,
    missionText:
      aboutContent?.missionText ?? defaultAssociationAbout.missionText,
    goalsTitle: aboutContent?.goalsTitle ?? defaultAssociationAbout.goalsTitle,
    goalsText: aboutContent?.goalsText ?? defaultAssociationAbout.goalsText,
    journeyTitle:
      aboutContent?.journeyTitle ?? defaultAssociationAbout.journeyTitle,
    journeyText:
      aboutContent?.journeyText ?? defaultAssociationAbout.journeyText,
    headOfficeImage:
      aboutContent?.headOfficeImage ?? defaultAssociationAbout.headOfficeImage,
    galleryImageOne:
      aboutContent?.galleryImageOne ?? defaultAssociationAbout.galleryImageOne,
    galleryImageTwo:
      aboutContent?.galleryImageTwo ?? defaultAssociationAbout.galleryImageTwo,
    stats:
      Array.isArray(aboutContent?.stats) && aboutContent.stats.length > 0
        ? aboutContent.stats
        : defaultAssociationAbout.stats,
  };
}

function mapAssociationGalleryItems(items) {
  if (!Array.isArray(items)) {
    return [];
  }

  return items.map((item) => ({
    id: item.id ?? "",
    imageUrl: item.imageUrl ?? "",
    headline: item.headline ?? "",
    tagline: item.tagline ?? "",
    description: item.description ?? "",
  }));
}

function mapAssociationGalleryPhotos(items) {
  if (!Array.isArray(items)) {
    return [];
  }

  return items.map((item) => ({
    id: item.id ?? "",
    imageUrl: item.imageUrl ?? "",
    thumbnailUrl: item.thumbnailUrl ?? item.imageUrl ?? "",
    createdAt: item.createdAt ?? "",
  }));
}

function mapAssociationGalleryFolders(items) {
  if (!Array.isArray(items)) {
    return [];
  }

  return items.map((item) => ({
    id: item.id ?? "",
    name: item.name ?? "",
    createdAt: item.createdAt ?? "",
    updatedAt: item.updatedAt ?? "",
    photoCount:
      item.photoCount ??
      (Array.isArray(item.photos) ? item.photos.length : 0),
    previewPhotos: mapAssociationGalleryPhotos(
      item.previewPhotos ?? item.photos,
    ),
    photos: mapAssociationGalleryPhotos(item.photos),
  }));
}

function mapAssociationCircularDocuments(items) {
  if (!Array.isArray(items)) {
    return [];
  }

  return [...items]
    .map((item) => ({
      id: item.id ?? "",
      headline: item.headline ?? "",
      tagline: item.tagline ?? "",
      summary: item.summary ?? "",
      fileName: item.originalFileName ?? "",
      mimeType: item.mimeType ?? "",
      fileExtension: item.fileExtension ?? "",
      documentUrl: item.documentUrl ?? "",
      previewUrl: item.previewUrl ?? "",
      createdAt: item.createdAt ?? "",
    }))
    .sort((left, right) =>
      String(right.createdAt || "").localeCompare(String(left.createdAt || "")),
    );
}

const INDIA_STATE_CITY_OPTIONS = {
  "Andhra Pradesh": [
    "Visakhapatnam",
    "Vijayawada",
    "Guntur",
    "Nellore",
    "Kurnool",
  ],
  "Arunachal Pradesh": ["Itanagar", "Naharlagun", "Tawang", "Pasighat", "Ziro"],
  Assam: ["Guwahati", "Dibrugarh", "Silchar", "Jorhat", "Tezpur"],
  Bihar: ["Patna", "Gaya", "Muzaffarpur", "Bhagalpur", "Purnia"],
  Chhattisgarh: ["Raipur", "Bhilai", "Bilaspur", "Korba", "Durg"],
  Goa: ["Panaji", "Margao", "Vasco da Gama", "Mapusa", "Ponda"],
  Gujarat: ["Ahmedabad", "Surat", "Vadodara", "Rajkot", "Gandhinagar"],
  Haryana: ["Gurugram", "Faridabad", "Panipat", "Ambala", "Hisar"],
  "Himachal Pradesh": ["Shimla", "Dharamshala", "Solan", "Mandi", "Kullu"],
  Jharkhand: ["Ranchi", "Jamshedpur", "Dhanbad", "Bokaro", "Deoghar"],
  Karnataka: ["Bengaluru", "Mysuru", "Mangaluru", "Hubballi", "Belagavi"],
  Kerala: ["Thiruvananthapuram", "Kochi", "Kozhikode", "Thrissur", "Kollam"],
  "Madhya Pradesh": ["Bhopal", "Indore", "Jabalpur", "Gwalior", "Ujjain"],
  Maharashtra: [
    "Mumbai",
    "Pune",
    "Nagpur",
    "Nashik",
    "Chhatrapati Sambhajinagar",
    "Thane",
    "Navi Mumbai",
    "Kalyan-Dombivli",
    "Mira-Bhayandar",
    "Vasai-Virar",
    "Palghar",
    "Bhiwandi",
    "Ulhasnagar",
    "Panvel",
    "Amravati",
    "Akola",
    "Yavatmal",
    "Chandrapur",
    "Wardha",
    "Gondia",
    "Bhandara",
    "Jalgaon",
    "Dhule",
    "Nandurbar",
    "Ahmednagar",
    "Solapur",
    "Kolhapur",
    "Sangli",
    "Satara",
    "Ratnagiri",
    "Sindhudurg",
    "Raigad",
    "Latur",
    "Osmanabad",
    "Nanded",
    "Parbhani",
    "Beed",
    "Jalna",
    "Hingoli",
  ],
  Manipur: ["Imphal", "Thoubal", "Bishnupur", "Churachandpur", "Ukhrul"],
  Meghalaya: ["Shillong", "Tura", "Jowai", "Nongpoh", "Baghmara"],
  Mizoram: ["Aizawl", "Lunglei", "Champhai", "Serchhip", "Kolasib"],
  Nagaland: ["Kohima", "Dimapur", "Mokokchung", "Wokha", "Tuensang"],
  Odisha: ["Bhubaneswar", "Cuttack", "Rourkela", "Sambalpur", "Berhampur"],
  Punjab: ["Ludhiana", "Amritsar", "Jalandhar", "Patiala", "Mohali"],
  Rajasthan: ["Jaipur", "Jodhpur", "Udaipur", "Kota", "Ajmer"],
  Sikkim: ["Gangtok", "Namchi", "Geyzing", "Mangan", "Singtam"],
  "Tamil Nadu": [
    "Chennai",
    "Coimbatore",
    "Madurai",
    "Salem",
    "Tiruchirappalli",
  ],
  Telangana: ["Hyderabad", "Warangal", "Nizamabad", "Karimnagar", "Khammam"],
  Tripura: ["Agartala", "Udaipur", "Dharmanagar", "Kailashahar", "Belonia"],
  "Uttar Pradesh": ["Lucknow", "Kanpur", "Noida", "Varanasi", "Agra"],
  Uttarakhand: ["Dehradun", "Haridwar", "Roorkee", "Haldwani", "Rishikesh"],
  "West Bengal": ["Kolkata", "Howrah", "Siliguri", "Durgapur", "Asansol"],
  "Andaman and Nicobar Islands": ["Port Blair"],
  Chandigarh: ["Chandigarh"],
  "Dadra and Nagar Haveli and Daman and Diu": ["Daman", "Diu", "Silvassa"],
  Delhi: ["New Delhi", "Central Delhi", "Dwarka", "Rohini", "Saket"],
  "Jammu and Kashmir": [
    "Srinagar",
    "Jammu",
    "Anantnag",
    "Baramulla",
    "Pulwama",
  ],
  Ladakh: ["Leh", "Kargil"],
  Lakshadweep: ["Kavaratti"],
  Puducherry: ["Puducherry", "Karaikal", "Mahe", "Yanam"],
};

const INDIA_STATES = Object.keys(INDIA_STATE_CITY_OPTIONS);

function mapAssociationProfileToForm(association) {
  return {
    id: association?.id ?? "",
    name: association?.name ?? "Association 1",
    slug: association?.slug ?? "association-1",
    headOfficeAddress: association?.headOfficeAddress ?? "",
    city: association?.city ?? "",
    state: association?.state ?? "",
    pincode: association?.pincode ?? "",
    registrationNumber: association?.registrationNumber ?? "",
    gstNumber: association?.gstNumber ?? "",
    website: association?.website ?? "",
    contactNumbers: Array.isArray(association?.contactNumbers)
      ? association.contactNumbers.join(", ")
      : "",
    helpdeskNumber: association?.helpdeskNumber ?? "",
    googleMapsLink: association?.googleMapsLink ?? "",
    regionalAddresses: Array.isArray(association?.regionalAddresses)
      ? association.regionalAddresses.map((address) => ({
          id: address.id ?? "",
          label: address.label ?? "",
          officeAddress: address.officeAddress ?? "",
          city: address.city ?? "",
          state: address.state ?? "",
          pincode: address.pincode ?? "",
          registrationNumber: address.registrationNumber ?? "",
          gstNumber: address.gstNumber ?? "",
          website: address.website ?? "",
          contactNumbers: Array.isArray(address.contactNumbers)
            ? address.contactNumbers.join(", ")
            : "",
          helpdeskNumber: address.helpdeskNumber ?? "",
          googleMapsLink: address.googleMapsLink ?? "",
        }))
      : [],
  };
}

function splitContactNumbers(value) {
  return value
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function getIndianCities(state) {
  return INDIA_STATE_CITY_OPTIONS[state] ?? [];
}

function readFileAsDataUrl(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result ?? ""));
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(file);
  });
}

function mergeMemberUsers(members, users) {
  const userByMemberId = new Map(
    users.filter((user) => user.memberId).map((user) => [user.memberId, user]),
  );
  const userByEmail = new Map(users.map((user) => [user.email, user]));

  return members.map((member) => {
    const linkedUser =
      userByMemberId.get(member.id) ??
      userByEmail.get(member.email) ??
      member.user ??
      null;
    return mapApiMemberToUi(member, linkedUser);
  });
}

const initialMemberTabData = buildMemberTabData(memberRecords);

function CarouselSection({
  title,
  items,
  tone,
  compact = false,
  motionClass = "",
  compactLimit = null,
}) {
  const visibleItems =
    compact && Number.isInteger(compactLimit) && compactLimit > 0
      ? items.slice(0, compactLimit)
      : items;
  const carouselItems = compact ? [...visibleItems, ...visibleItems] : visibleItems;

  return (
    <section
      className={`welcome-panel ${compact ? "welcome-panel-compact" : ""}`}
    >
      <div className="panel-topline">
        <h2>{title}</h2>
        <Link className="text-link" href="#">
          Show all
        </Link>
      </div>

      <div className={compact ? "carousel-viewport" : ""}>
        <div
          className={`carousel-row ${compact ? "carousel-row-moving" : ""} ${motionClass}`.trim()}
        >
          {carouselItems.map((item, index) => (
            <article
              key={`${item.id ?? item.title}-${compact ? index : "static"}`}
              className={`carousel-card ${tone}`}
            >
              <div className="carousel-visual">
                {item.imageUrl || item.previewUrl ? (
                  <img
                    src={item.imageUrl || item.previewUrl}
                    alt={item.headline || item.title || title}
                  />
                ) : tone === "tone-circular" ? (
                  <div className="carousel-doc-fallback">
                    <strong>{item.fileExtension || "DOC"}</strong>
                    <span>{item.headline || item.title || "Circular"}</span>
                    <small>{item.tagline || item.fileName || "Document update"}</small>
                  </div>
                ) : (
                  <span>
                    {String((index % visibleItems.length) + 1).padStart(2, "0")}
                  </span>
                )}
              </div>
              <div className="carousel-copy">
                <em className="carousel-badge">
                  {item.badge || item.tagline || item.fileExtension || "Item"}
                </em>
                <strong>{item.title || item.headline || "Untitled"}</strong>
                <p>
                  {item.meta ||
                    item.description ||
                    item.summary ||
                    item.tagline ||
                    "No details added yet."}
                </p>
              </div>
            </article>
          ))}
        </div>
      </div>

      {compact ? (
        <div className="carousel-dots" aria-hidden="true">
          {visibleItems.map((item, index) => (
            <span
              key={`${item.id ?? item.title}-dot`}
              className={`carousel-dot ${index === 0 ? "is-active" : ""}`}
            />
          ))}
        </div>
      ) : null}
    </section>
  );
}

function MemberCarouselSection({ title, items, tone }) {
  const carouselItems = [...items, ...items];

  return (
    <section className="welcome-panel welcome-panel-compact member-carousel-panel">
      <div className="panel-topline">
        <h2>{title}</h2>
        <Link className="text-link" href="#">
          Show all
        </Link>
      </div>

      <div className="carousel-viewport">
        <div className="carousel-row carousel-row-moving">
          {carouselItems.map((member, index) => (
            <article
              key={`${member.id}-${index}`}
              className={`carousel-card member-carousel-card ${tone}`}
            >
              <div className="member-carousel-photo">
                {member.photoUrl ? (
                  <img
                    className="member-record-photo-image"
                    src={member.photoUrl}
                    alt={member.name}
                  />
                ) : (
                  <span>{member.initials}</span>
                )}
              </div>
              <div className="member-carousel-copy">
                <em className="carousel-badge">{member.badge}</em>
                <strong>{member.name}</strong>
                <p className="member-company">{member.company}</p>
                <p>{member.address}</p>
                <p>{member.phone}</p>
                <p>{member.email}</p>
              </div>
            </article>
          ))}
        </div>
      </div>

      <div className="carousel-dots" aria-hidden="true">
        {items.map((member, index) => (
          <span
            key={`${member.id}-dot`}
            className={`carousel-dot ${index === 0 ? "is-active" : ""}`}
          />
        ))}
      </div>
    </section>
  );
}

function AssociationCrudHeader({
  activeTab,
  isAdmin,
  items,
  selectedIds,
  onToggleSelectAll,
  onDeleteSelected,
  onAddNew,
}) {
  const allSelected = items.length > 0 && selectedIds.length === items.length;

  return (
    <div className="association-crud-header">
      <div>
        <span className="mini-label">{activeTab}</span>
        <h2>{activeTab} Records</h2>
        <p>Each section is structured for future role-based CRUD visibility.</p>
      </div>

      {isAdmin ? (
        <div className="association-admin-actions">
          <label className="selection-chip">
            <input
              type="checkbox"
              checked={allSelected}
              onChange={onToggleSelectAll}
            />
            <span>Select multiple</span>
          </label>
          <button
            className="secondary-link secondary-button"
            type="button"
            onClick={onDeleteSelected}
          >
            Delete Selected
          </button>
          <button
            className="primary-link admin-action-button"
            type="button"
            onClick={onAddNew}
          >
            Add New
          </button>
        </div>
      ) : null}
    </div>
  );
}

function AssociationRecordGrid({
  activeTab,
  items,
  selectedIds,
  isAdmin,
  tone,
  onToggleSelect,
  onDeleteOne,
}) {
  return (
    <div className="association-record-grid">
      {items.map((item, index) => (
        <article key={item.id} className={`association-record-card ${tone}`}>
          <div className="association-record-visual">
            <span>{String(index + 1).padStart(2, "0")}</span>
          </div>
          <div className="association-record-copy">
            <div className="association-record-topline">
              <em className="carousel-badge">{item.badge}</em>
              {isAdmin ? (
                <label className="record-select-chip">
                  <input
                    type="checkbox"
                    checked={selectedIds.includes(item.id)}
                    onChange={() => onToggleSelect(item.id)}
                  />
                  <span>Select</span>
                </label>
              ) : null}
            </div>
            <strong>{item.title}</strong>
            <p>{item.meta}</p>
            <div className="record-actions">
              <button className="secondary-link secondary-button" type="button">
                See Detail
              </button>
              {isAdmin ? (
                <button
                  className="secondary-link secondary-button danger-button"
                  type="button"
                  onClick={() => onDeleteOne(item.id)}
                >
                  Delete
                </button>
              ) : null}
            </div>
          </div>
        </article>
      ))}
      {items.length === 0 ? (
        <article className="association-panel association-empty-state">
          <span className="mini-label">Empty</span>
          <h2>No {activeTab.toLowerCase()} records left.</h2>
          <p>Add a new record or switch to another tab to continue working.</p>
        </article>
      ) : null}
    </div>
  );
}

function FinanceStatementPanel({
  entries,
  filterType,
  dateFrom,
  dateTo,
  onFilterTypeChange,
  onDateFromChange,
  onDateToChange,
}) {
  return (
    <section className="association-tab-section">
      <section className="member-table-panel">
        <div className="panel-topline">
          <h2>Passbook Statement</h2>
          <span className="mini-label">Date and Entry Filters</span>
        </div>

        <div className="admin-member-toolbar">
          <label className="content-control-field">
            <span>From Date</span>
            <input
              type="date"
              value={dateFrom}
              onChange={(event) => onDateFromChange(event.target.value)}
            />
          </label>
          <label className="content-control-field">
            <span>To Date</span>
            <input
              type="date"
              value={dateTo}
              onChange={(event) => onDateToChange(event.target.value)}
            />
          </label>
          <label className="content-control-field">
            <span>Entry Type</span>
            <select
              value={filterType}
              onChange={(event) => onFilterTypeChange(event.target.value)}
            >
              <option value="">All Entries</option>
              <option value="Credit">Credit</option>
              <option value="Debit">Debit</option>
              <option value="Journal">Journal</option>
              <option value="Membership Payment">Membership Payment</option>
            </select>
          </label>
        </div>

        <div className="member-table-wrap">
          <table className="member-table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Particulars</th>
                <th>Reference</th>
                <th>Type</th>
                <th>Direction</th>
                <th>Amount</th>
              </tr>
            </thead>
            <tbody>
              {entries.map((entry) => (
                <tr key={entry.id}>
                  <td>{entry.date}</td>
                  <td>{entry.particulars}</td>
                  <td>{entry.reference}</td>
                  <td>{entry.entryType}</td>
                  <td>
                    <span className="access-status-chip">
                      {entry.direction}
                    </span>
                  </td>
                  <td>{entry.amount}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>
    </section>
  );
}

function AssociationTabContent({
  activeTab,
  activeFinanceTab,
  financeStatementEntries,
  financeStatementFilterType,
  financeStatementDateFrom,
  financeStatementDateTo,
  isAdmin,
  tabItems,
  selectedIds,
  onToggleSelect,
  onToggleSelectAll,
  onDeleteSelected,
  onDeleteOne,
  onAddNew,
  onFinanceTabChange,
  onFinanceStatementFilterTypeChange,
  onFinanceStatementDateFromChange,
  onFinanceStatementDateToChange,
  associationProfile,
  associationProfileForm,
  isEditingAssociationProfile,
  onEditAssociationProfile,
  onAssociationProfileFieldChange,
  onAssociationRegionalFieldChange,
  onAddRegionalAddress,
  onRemoveRegionalAddress,
  onCancelAssociationProfileEdit,
  onSaveAssociationProfile,
  isSavingAssociationProfile,
  associationProfileFeedback,
  associationAbout,
  associationAboutForm,
  isEditingAssociationAbout,
  onEditAssociationAbout,
  onAssociationAboutFieldChange,
  onAssociationAboutImageChange,
  onCancelAssociationAboutEdit,
  onSaveAssociationAbout,
  isSavingAssociationAbout,
  associationAboutFeedback,
  committeeMembers,
  allMembers,
  membershipTypeOptions,
  editingCommitteeMemberId,
  committeeMemberForm,
  isSavingCommitteeMember,
  committeeMemberFeedback,
  onOpenCommitteeMemberEditor,
  onCommitteeMemberFormChange,
  onCommitteeMemberImageChange,
  onCancelCommitteeMemberEdit,
  onSaveCommitteeMember,
  onRemoveCommitteeMember,
  committeePostOptions,
  masterDraftValue,
  masterFeedbackMessage,
  editingMasterPostValue,
  editMasterPostDraftValue,
  membershipTypeDraftValue,
  membershipTypeFeedbackMessage,
  editingMembershipTypeValue,
  editMembershipTypeDraftValue,
  onMasterDraftChange,
  onSaveMasterDraft,
  onEditMasterPostChange,
  onEditMasterPost,
  onDeleteMasterPost,
  onSaveMasterPostEdit,
  onCancelMasterPostEdit,
  onMembershipTypeDraftChange,
  onSaveMembershipTypeDraft,
  onEditMembershipTypeDraftChange,
  onEditMembershipType,
  onDeleteMembershipType,
  onSaveMembershipTypeEdit,
  onCancelMembershipTypeEdit,
  galleryItems,
  galleryFolders,
  activeGalleryFolderId,
  editingGalleryFolderId,
  galleryFolderForm,
  isSavingGalleryFolder,
  galleryFolderFeedback,
  onOpenGalleryFolder,
  onOpenGalleryFolderEditor,
  onGalleryFolderFieldChange,
  onGalleryFolderFilesChange,
  onCancelGalleryFolderEdit,
  onSaveGalleryFolder,
  onDeleteGalleryFolder,
  onDeleteGalleryPhoto,
  onUploadGalleryFolderPhotos,
  selectedGalleryFolderIds,
  selectedGalleryPhotoIds,
  onToggleGalleryFolderSelect,
  onDeleteSelectedGalleryFolders,
  onToggleGalleryPhotoSelect,
  onDeleteSelectedGalleryPhotos,
  onCloseGalleryFolder,
  galleryFolderEditorRef,
  galleryFolderNameInputRef,
  circularDocuments,
  selectedCircularIds,
  editingCircularDocumentId,
  circularDocumentForm,
  onOpenCircularDocumentEditor,
  onToggleCircularSelect,
  onDeleteSelectedCirculars,
  onCircularDocumentFieldChange,
  onCircularDocumentFileChange,
  onCancelCircularDocumentEdit,
  onSaveCircularDocument,
  onDeleteCircularDocument,
  isSavingCircularDocument,
  circularDocumentFeedback,
}) {
  const toneMap = {
    Profile: "tone-circular",
    "About Us": "tone-advertisement",
    Finance: "tone-advertisement",
    Committee: "tone-gallery",
    Circulars: "tone-circular",
    Gallery: "tone-gallery",
    Master: "tone-advertisement",
  };

  if (activeTab === "Profile") {
    return (
      <AssociationProfilePanel
        associationProfile={associationProfile}
        formData={associationProfileForm}
        isEditing={isEditingAssociationProfile}
        onEdit={onEditAssociationProfile}
        onFieldChange={onAssociationProfileFieldChange}
        onRegionalFieldChange={onAssociationRegionalFieldChange}
        onAddRegionalAddress={onAddRegionalAddress}
        onRemoveRegionalAddress={onRemoveRegionalAddress}
        onCancel={onCancelAssociationProfileEdit}
        onSave={onSaveAssociationProfile}
        isSaving={isSavingAssociationProfile}
        feedbackMessage={associationProfileFeedback}
      />
    );
  }

  if (activeTab === "About Us") {
    return (
      <AssociationAboutPanel
        aboutData={associationAbout}
        formData={associationAboutForm}
        isEditing={isEditingAssociationAbout}
        onEdit={onEditAssociationAbout}
        onFieldChange={onAssociationAboutFieldChange}
        onImageChange={onAssociationAboutImageChange}
        onCancel={onCancelAssociationAboutEdit}
        onSave={onSaveAssociationAbout}
        isSaving={isSavingAssociationAbout}
        feedbackMessage={associationAboutFeedback}
      />
    );
  }

  if (activeTab === "Committee") {
    return (
      <ManagementCommitteePanel
        committeeMembers={committeeMembers}
        allMembers={allMembers}
        membershipTypeOptions={membershipTypeOptions}
        committeePostOptions={committeePostOptions}
        isAdmin={isAdmin}
        editingMemberId={editingCommitteeMemberId}
        formData={committeeMemberForm}
        isSaving={isSavingCommitteeMember}
        feedbackMessage={committeeMemberFeedback}
        onOpenEditor={onOpenCommitteeMemberEditor}
        onFormChange={onCommitteeMemberFormChange}
        onImageChange={onCommitteeMemberImageChange}
        onCancelEdit={onCancelCommitteeMemberEdit}
        onSave={onSaveCommitteeMember}
        onRemove={onRemoveCommitteeMember}
      />
    );
  }

  if (activeTab === "Gallery") {
    return (
      <AssociationGalleryPanel
        folders={galleryFolders}
        isAdmin={isAdmin}
        activeFolderId={activeGalleryFolderId}
        editingFolderId={editingGalleryFolderId}
        formData={galleryFolderForm}
        isSaving={isSavingGalleryFolder}
        feedbackMessage={galleryFolderFeedback}
        onOpenFolder={onOpenGalleryFolder}
        onOpenEditor={onOpenGalleryFolderEditor}
        onFieldChange={onGalleryFolderFieldChange}
        onFilesChange={onGalleryFolderFilesChange}
        onCancelEdit={onCancelGalleryFolderEdit}
        onSave={onSaveGalleryFolder}
        onDeleteFolder={onDeleteGalleryFolder}
        onDeletePhoto={onDeleteGalleryPhoto}
        onUploadPhotos={onUploadGalleryFolderPhotos}
        selectedFolderIds={selectedGalleryFolderIds}
        selectedPhotoIds={selectedGalleryPhotoIds}
        onToggleFolderSelect={onToggleGalleryFolderSelect}
        onDeleteSelectedFolders={onDeleteSelectedGalleryFolders}
        onTogglePhotoSelect={onToggleGalleryPhotoSelect}
        onDeleteSelectedPhotos={onDeleteSelectedGalleryPhotos}
        onCloseFolder={onCloseGalleryFolder}
        editorRef={galleryFolderEditorRef}
        nameInputRef={galleryFolderNameInputRef}
      />
    );
  }

  if (activeTab === "Circulars") {
    return (
      <AssociationCircularsPanel
        items={circularDocuments}
        isAdmin={isAdmin}
        selectedIds={selectedCircularIds}
        editingItemId={editingCircularDocumentId}
        formData={circularDocumentForm}
        isSaving={isSavingCircularDocument}
        feedbackMessage={circularDocumentFeedback}
        onOpenEditor={onOpenCircularDocumentEditor}
        onToggleSelect={onToggleCircularSelect}
        onDeleteSelected={onDeleteSelectedCirculars}
        onFieldChange={onCircularDocumentFieldChange}
        onFileChange={onCircularDocumentFileChange}
        onCancelEdit={onCancelCircularDocumentEdit}
        onSave={onSaveCircularDocument}
        onDelete={onDeleteCircularDocument}
      />
    );
  }

  if (activeTab === "Master") {
    return (
      <AssociationMasterPanel
        committeeMembers={committeeMembers}
        allMembers={allMembers}
        committeePostOptions={committeePostOptions}
        membershipTypeOptions={membershipTypeOptions}
        newCommitteePost={masterDraftValue}
        editCommitteePostDraft={editMasterPostDraftValue}
        newMembershipType={membershipTypeDraftValue}
        editMembershipTypeDraft={editMembershipTypeDraftValue}
        committeeFeedbackMessage={masterFeedbackMessage}
        membershipTypeFeedbackMessage={membershipTypeFeedbackMessage}
        editingPost={editingMasterPostValue}
        editingMembershipType={editingMembershipTypeValue}
        isAdmin={isAdmin}
        onNewCommitteePostChange={onMasterDraftChange}
        onEditCommitteePostChange={onEditMasterPostChange}
        onAddCommitteePost={onSaveMasterDraft}
        onEditCommitteePost={onEditMasterPost}
        onDeleteCommitteePost={onDeleteMasterPost}
        onSaveCommitteePostEdit={onSaveMasterPostEdit}
        onCancelCommitteePostEdit={onCancelMasterPostEdit}
        onNewMembershipTypeChange={onMembershipTypeDraftChange}
        onEditMembershipTypeChange={onEditMembershipTypeDraftChange}
        onAddMembershipType={onSaveMembershipTypeDraft}
        onEditMembershipType={onEditMembershipType}
        onDeleteMembershipType={onDeleteMembershipType}
        onSaveMembershipTypeEdit={onSaveMembershipTypeEdit}
        onCancelMembershipTypeEdit={onCancelMembershipTypeEdit}
      />
    );
  }

  return (
    <section className="association-tab-section">
      {activeTab === "Finance" ? (
        <nav className="association-tabbar" aria-label="Finance sections">
          {financeTabs.map((tab) => (
            <button
              key={tab}
              type="button"
              className={`association-tab ${tab === activeFinanceTab ? "active" : ""}`}
              onClick={() => onFinanceTabChange(tab)}
            >
              {tab}
            </button>
          ))}
        </nav>
      ) : null}

      {activeTab === "Finance" && activeFinanceTab === "Statement" ? (
        <FinanceStatementPanel
          entries={financeStatementEntries}
          filterType={financeStatementFilterType}
          dateFrom={financeStatementDateFrom}
          dateTo={financeStatementDateTo}
          onFilterTypeChange={onFinanceStatementFilterTypeChange}
          onDateFromChange={onFinanceStatementDateFromChange}
          onDateToChange={onFinanceStatementDateToChange}
        />
      ) : (
        <>
          <AssociationCrudHeader
            activeTab={
              activeTab === "Finance"
                ? `Finance · ${activeFinanceTab}`
                : activeTab
            }
            isAdmin={isAdmin}
            items={tabItems}
            selectedIds={selectedIds}
            onToggleSelectAll={onToggleSelectAll}
            onDeleteSelected={onDeleteSelected}
            onAddNew={onAddNew}
          />

          <AssociationRecordGrid
            activeTab={activeTab}
            items={tabItems}
            selectedIds={selectedIds}
            isAdmin={isAdmin}
            tone={toneMap[activeTab] ?? "tone-circular"}
            onToggleSelect={onToggleSelect}
            onDeleteOne={onDeleteOne}
          />
        </>
      )}
    </section>
  );
}

function AssociationProfilePanel({
  associationProfile,
  formData,
  isEditing,
  isSaving,
  feedbackMessage,
  onEdit,
  onFieldChange,
  onRegionalFieldChange,
  onAddRegionalAddress,
  onRemoveRegionalAddress,
  onCancel,
  onSave,
}) {
  const headOfficeCities = getIndianCities(formData.state);

  if (isEditing) {
    return (
      <section className="association-tab-section">
        <section className="member-table-panel">
          <div className="panel-topline">
            <h2>Edit Association Profile</h2>
            <span className="mini-label">Profile</span>
          </div>

          <div className="profile-form-grid">
            <label className="profile-field">
              <span>Association Name</span>
              <input
                type="text"
                value={formData.name}
                onChange={(event) => onFieldChange("name", event.target.value)}
              />
            </label>
            <label className="profile-field">
              <span>Registration Number</span>
              <input
                type="text"
                value={formData.registrationNumber}
                onChange={(event) =>
                  onFieldChange("registrationNumber", event.target.value)
                }
              />
            </label>
            <label className="profile-field profile-field-wide">
              <span>Head Office Address</span>
              <textarea
                rows="3"
                value={formData.headOfficeAddress}
                onChange={(event) =>
                  onFieldChange("headOfficeAddress", event.target.value)
                }
              />
            </label>
            <label className="profile-field">
              <span>City</span>
              <select
                value={formData.city}
                onChange={(event) => onFieldChange("city", event.target.value)}
                disabled={!formData.state}
              >
                <option value="">
                  {formData.state ? "Select city" : "Select state first"}
                </option>
                {headOfficeCities.map((city) => (
                  <option key={city} value={city}>
                    {city}
                  </option>
                ))}
              </select>
            </label>
            <label className="profile-field">
              <span>State</span>
              <select
                value={formData.state}
                onChange={(event) => onFieldChange("state", event.target.value)}
              >
                <option value="">Select state</option>
                {INDIA_STATES.map((state) => (
                  <option key={state} value={state}>
                    {state}
                  </option>
                ))}
              </select>
            </label>
            <label className="profile-field">
              <span>Pincode</span>
              <input
                type="text"
                value={formData.pincode}
                onChange={(event) =>
                  onFieldChange("pincode", event.target.value)
                }
              />
            </label>
            <label className="profile-field">
              <span>GST Number</span>
              <input
                type="text"
                value={formData.gstNumber}
                onChange={(event) =>
                  onFieldChange("gstNumber", event.target.value)
                }
              />
            </label>
            <label className="profile-field">
              <span>Website</span>
              <input
                type="text"
                value={formData.website}
                onChange={(event) =>
                  onFieldChange("website", event.target.value)
                }
              />
            </label>
            <label className="profile-field">
              <span>Helpdesk Number</span>
              <input
                type="text"
                value={formData.helpdeskNumber}
                onChange={(event) =>
                  onFieldChange("helpdeskNumber", event.target.value)
                }
              />
            </label>
            <label className="profile-field profile-field-wide">
              <span>Contact Numbers</span>
              <input
                type="text"
                value={formData.contactNumbers}
                placeholder="Comma separated numbers"
                onChange={(event) =>
                  onFieldChange("contactNumbers", event.target.value)
                }
              />
            </label>
            <label className="profile-field profile-field-wide">
              <span>Google Map Access Location</span>
              <input
                type="text"
                value={formData.googleMapsLink}
                placeholder="Google Maps URL"
                onChange={(event) =>
                  onFieldChange("googleMapsLink", event.target.value)
                }
              />
            </label>
          </div>

          <div className="association-regional-header">
            <div>
              <span className="mini-label">Regional Offices</span>
              <h3>Regional Address List</h3>
            </div>
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={onAddRegionalAddress}
            >
              Add Regional Address
            </button>
          </div>

          <div className="association-profile-stack">
            {formData.regionalAddresses.map((address, index) => {
              const regionalCities = getIndianCities(address.state);

              return (
                <article
                  key={address.id || `regional-${index}`}
                  className="association-profile-card"
                >
                  <div className="panel-topline">
                    <h3>Regional Office {index + 1}</h3>
                    <button
                      className="secondary-link secondary-button danger-button"
                      type="button"
                      onClick={() => onRemoveRegionalAddress(index)}
                    >
                      Remove
                    </button>
                  </div>

                  <div className="profile-form-grid">
                    <label className="profile-field">
                      <span>Label</span>
                      <input
                        type="text"
                        value={address.label}
                        onChange={(event) =>
                          onRegionalFieldChange(
                            index,
                            "label",
                            event.target.value,
                          )
                        }
                      />
                    </label>
                    <label className="profile-field">
                      <span>Registration Number</span>
                      <input
                        type="text"
                        value={address.registrationNumber}
                        onChange={(event) =>
                          onRegionalFieldChange(
                            index,
                            "registrationNumber",
                            event.target.value,
                          )
                        }
                      />
                    </label>
                    <label className="profile-field profile-field-wide">
                      <span>Office Address</span>
                      <textarea
                        rows="3"
                        value={address.officeAddress}
                        onChange={(event) =>
                          onRegionalFieldChange(
                            index,
                            "officeAddress",
                            event.target.value,
                          )
                        }
                      />
                    </label>
                    <label className="profile-field">
                      <span>City</span>
                      <select
                        value={address.city}
                        onChange={(event) =>
                          onRegionalFieldChange(
                            index,
                            "city",
                            event.target.value,
                          )
                        }
                        disabled={!address.state}
                      >
                        <option value="">
                          {address.state ? "Select city" : "Select state first"}
                        </option>
                        {regionalCities.map((city) => (
                          <option key={city} value={city}>
                            {city}
                          </option>
                        ))}
                      </select>
                    </label>
                    <label className="profile-field">
                      <span>State</span>
                      <select
                        value={address.state}
                        onChange={(event) =>
                          onRegionalFieldChange(
                            index,
                            "state",
                            event.target.value,
                          )
                        }
                      >
                        <option value="">Select state</option>
                        {INDIA_STATES.map((state) => (
                          <option key={state} value={state}>
                            {state}
                          </option>
                        ))}
                      </select>
                    </label>
                    <label className="profile-field">
                      <span>Pincode</span>
                      <input
                        type="text"
                        value={address.pincode}
                        onChange={(event) =>
                          onRegionalFieldChange(
                            index,
                            "pincode",
                            event.target.value,
                          )
                        }
                      />
                    </label>
                    <label className="profile-field">
                      <span>GST Number</span>
                      <input
                        type="text"
                        value={address.gstNumber}
                        onChange={(event) =>
                          onRegionalFieldChange(
                            index,
                            "gstNumber",
                            event.target.value,
                          )
                        }
                      />
                    </label>
                    <label className="profile-field">
                      <span>Website</span>
                      <input
                        type="text"
                        value={address.website}
                        onChange={(event) =>
                          onRegionalFieldChange(
                            index,
                            "website",
                            event.target.value,
                          )
                        }
                      />
                    </label>
                    <label className="profile-field">
                      <span>Helpdesk Number</span>
                      <input
                        type="text"
                        value={address.helpdeskNumber}
                        onChange={(event) =>
                          onRegionalFieldChange(
                            index,
                            "helpdeskNumber",
                            event.target.value,
                          )
                        }
                      />
                    </label>
                    <label className="profile-field profile-field-wide">
                      <span>Contact Numbers</span>
                      <input
                        type="text"
                        value={address.contactNumbers}
                        placeholder="Comma separated numbers"
                        onChange={(event) =>
                          onRegionalFieldChange(
                            index,
                            "contactNumbers",
                            event.target.value,
                          )
                        }
                      />
                    </label>
                    <label className="profile-field profile-field-wide">
                      <span>Google Map Access Location</span>
                      <input
                        type="text"
                        value={address.googleMapsLink}
                        onChange={(event) =>
                          onRegionalFieldChange(
                            index,
                            "googleMapsLink",
                            event.target.value,
                          )
                        }
                      />
                    </label>
                  </div>
                </article>
              );
            })}
          </div>

          <div className="profile-action-row">
            {feedbackMessage ? (
              <p className="admin-access-feedback">{feedbackMessage}</p>
            ) : null}
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={onCancel}
              disabled={isSaving}
            >
              Cancel
            </button>
            <button
              className="primary-link admin-action-button"
              type="button"
              onClick={onSave}
              disabled={isSaving}
            >
              {isSaving ? "Saving..." : "Save Profile"}
            </button>
          </div>
        </section>
      </section>
    );
  }

  return (
    <section className="association-tab-section">
      <section className="association-profile-stack">
        <article className="association-profile-card">
          <div className="panel-topline">
            <h2>{associationProfile.name || "Association Profile"}</h2>
            <button
              className="primary-link admin-action-button"
              type="button"
              onClick={onEdit}
            >
              Edit
            </button>
          </div>

          <div className="association-profile-grid">
            <div>
              <span className="mini-label">Head Office Address</span>
              <p>{associationProfile.headOfficeAddress || "Not added yet"}</p>
            </div>
            <div>
              <span className="mini-label">City, State with Pincode</span>
              <p>
                {[
                  associationProfile.city,
                  associationProfile.state,
                  associationProfile.pincode,
                ]
                  .filter(Boolean)
                  .join(", ") || "Not added yet"}
              </p>
            </div>
            <div>
              <span className="mini-label">Registration Number</span>
              <p>{associationProfile.registrationNumber || "Not added yet"}</p>
            </div>
            <div>
              <span className="mini-label">GST Number</span>
              <p>{associationProfile.gstNumber || "Not added yet"}</p>
            </div>
            <div>
              <span className="mini-label">Website</span>
              <p>{associationProfile.website || "Not added yet"}</p>
            </div>
            <div>
              <span className="mini-label">Helpdesk Number</span>
              <p>{associationProfile.helpdeskNumber || "Not added yet"}</p>
            </div>
            <div className="association-profile-wide">
              <span className="mini-label">Contact Numbers</span>
              <p>{associationProfile.contactNumbers || "Not added yet"}</p>
            </div>
            <AssociationMapPreview
              label="Google Map Access Location"
              value={associationProfile.googleMapsLink}
            />
          </div>
        </article>

        {associationProfile.regionalAddresses.length > 0 ? (
          <div className="association-profile-stack">
            {associationProfile.regionalAddresses.map((address, index) => (
              <article
                key={address.id || `regional-card-${index}`}
                className="association-profile-card"
              >
                <div className="panel-topline">
                  <h3>{address.label || `Regional Office ${index + 1}`}</h3>
                  <span className="mini-label">Regional Address</span>
                </div>

                <div className="association-profile-grid">
                  <div className="association-profile-wide">
                    <span className="mini-label">Office Address</span>
                    <p>{address.officeAddress || "Not added yet"}</p>
                  </div>
                  <div>
                    <span className="mini-label">City, State with Pincode</span>
                    <p>
                      {[address.city, address.state, address.pincode]
                        .filter(Boolean)
                        .join(", ") || "Not added yet"}
                    </p>
                  </div>
                  <div>
                    <span className="mini-label">Registration Number</span>
                    <p>{address.registrationNumber || "Not added yet"}</p>
                  </div>
                  <div>
                    <span className="mini-label">GST Number</span>
                    <p>{address.gstNumber || "Not added yet"}</p>
                  </div>
                  <div>
                    <span className="mini-label">Website</span>
                    <p>{address.website || "Not added yet"}</p>
                  </div>
                  <div>
                    <span className="mini-label">Helpdesk Number</span>
                    <p>{address.helpdeskNumber || "Not added yet"}</p>
                  </div>
                  <div className="association-profile-wide">
                    <span className="mini-label">Contact Numbers</span>
                    <p>{address.contactNumbers || "Not added yet"}</p>
                  </div>
                  <AssociationMapPreview
                    label="Google Map Access Location"
                    value={address.googleMapsLink}
                  />
                </div>
              </article>
            ))}
          </div>
        ) : null}
      </section>
    </section>
  );
}

function AssociationAboutPanel({
  aboutData,
  formData,
  isEditing,
  isSaving,
  feedbackMessage,
  onEdit,
  onFieldChange,
  onImageChange,
  onCancel,
  onSave,
}) {
  if (isEditing) {
    return (
      <section className="association-tab-section">
        <section className="member-table-panel">
          <div className="panel-topline">
            <h2>Edit About Us</h2>
            <span className="mini-label">Landing Page Content</span>
          </div>

          <div className="profile-form-grid">
            <label className="profile-field profile-field-wide">
              <span>Hero Title</span>
              <input
                type="text"
                value={formData.heroTitle}
                onChange={(event) =>
                  onFieldChange("heroTitle", event.target.value)
                }
              />
            </label>
            <label className="profile-field profile-field-wide">
              <span>Hero Intro</span>
              <textarea
                rows="3"
                value={formData.heroIntro}
                onChange={(event) =>
                  onFieldChange("heroIntro", event.target.value)
                }
              />
            </label>
            <label className="profile-field">
              <span>Mission Title</span>
              <input
                type="text"
                value={formData.missionTitle}
                onChange={(event) =>
                  onFieldChange("missionTitle", event.target.value)
                }
              />
            </label>
            <label className="profile-field">
              <span>Goals Title</span>
              <input
                type="text"
                value={formData.goalsTitle}
                onChange={(event) =>
                  onFieldChange("goalsTitle", event.target.value)
                }
              />
            </label>
            <label className="profile-field profile-field-wide">
              <span>Mission Text</span>
              <textarea
                rows="4"
                value={formData.missionText}
                onChange={(event) =>
                  onFieldChange("missionText", event.target.value)
                }
              />
            </label>
            <label className="profile-field profile-field-wide">
              <span>Goals Text</span>
              <textarea
                rows="4"
                value={formData.goalsText}
                onChange={(event) =>
                  onFieldChange("goalsText", event.target.value)
                }
              />
            </label>
            <label className="profile-field">
              <span>Journey Title</span>
              <input
                type="text"
                value={formData.journeyTitle}
                onChange={(event) =>
                  onFieldChange("journeyTitle", event.target.value)
                }
              />
            </label>
            <label className="profile-field profile-field-wide">
              <span>Journey Text</span>
              <textarea
                rows="4"
                value={formData.journeyText}
                onChange={(event) =>
                  onFieldChange("journeyText", event.target.value)
                }
              />
            </label>
            <label className="profile-field">
              <span>Head Office Image</span>
              <input
                type="file"
                accept="image/*"
                onChange={(event) =>
                  onImageChange(
                    "headOfficeImage",
                    event.target.files?.[0] ?? null,
                  )
                }
              />
            </label>
            <label className="profile-field">
              <span>Gallery Image One</span>
              <input
                type="file"
                accept="image/*"
                onChange={(event) =>
                  onImageChange(
                    "galleryImageOne",
                    event.target.files?.[0] ?? null,
                  )
                }
              />
            </label>
            <label className="profile-field">
              <span>Gallery Image Two</span>
              <input
                type="file"
                accept="image/*"
                onChange={(event) =>
                  onImageChange(
                    "galleryImageTwo",
                    event.target.files?.[0] ?? null,
                  )
                }
              />
            </label>
            <div className="about-edit-preview-row profile-field-wide">
              <img src={formData.headOfficeImage} alt="Head office preview" />
              <img src={formData.galleryImageOne} alt="Gallery preview one" />
              <img src={formData.galleryImageTwo} alt="Gallery preview two" />
            </div>
          </div>

          <div className="profile-action-row">
            {feedbackMessage ? (
              <p className="admin-access-feedback">{feedbackMessage}</p>
            ) : null}
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={onCancel}
              disabled={isSaving}
            >
              Cancel
            </button>
            <button
              className="primary-link admin-action-button"
              type="button"
              onClick={onSave}
              disabled={isSaving}
            >
              {isSaving ? "Saving..." : "Save About Us"}
            </button>
          </div>
        </section>
      </section>
    );
  }

  return (
    <section className="association-tab-section">
      <section className="about-landing-shell">
        <article className="about-hero-card">
          <div className="about-hero-copy">
            <span className="mini-label">Head Office Story</span>
            <h2>{aboutData.heroTitle}</h2>
            <p>{aboutData.heroIntro}</p>
            <div className="about-stat-row">
              {aboutData.stats.map((item) => (
                <article key={item.label} className="about-stat-card">
                  <strong>{item.value}</strong>
                  <span>{item.label}</span>
                </article>
              ))}
            </div>
          </div>
          <div className="about-hero-visual">
            <img
              src={aboutData.headOfficeImage}
              alt="Association head office"
            />
          </div>
        </article>

        <div className="about-story-grid">
          <article className="about-story-card">
            <span className="mini-label">Mission</span>
            <h3>{aboutData.missionTitle}</h3>
            <p>{aboutData.missionText}</p>
          </article>
          <article className="about-story-card">
            <span className="mini-label">Goals</span>
            <h3>{aboutData.goalsTitle}</h3>
            <p>{aboutData.goalsText}</p>
          </article>
        </div>

        <article className="about-journey-card">
          <div className="about-journey-copy">
            <span className="mini-label">So Far</span>
            <h3>{aboutData.journeyTitle}</h3>
            <p>{aboutData.journeyText}</p>
            <button
              className="primary-link admin-action-button"
              type="button"
              onClick={onEdit}
            >
              Edit
            </button>
          </div>
          <div className="about-gallery-grid">
            <img
              src={aboutData.galleryImageOne}
              alt="Association community event"
            />
            <img
              src={aboutData.galleryImageTwo}
              alt="Association industry journey"
            />
          </div>
        </article>
      </section>
    </section>
  );
}

function ManagementCommitteePanel({
  committeeMembers,
  allMembers,
  committeePostOptions,
  isAdmin,
  editingMemberId,
  formData,
  isSaving,
  feedbackMessage,
  onOpenEditor,
  onCancelEdit,
  onFormChange,
  onImageChange,
  onSave,
  onRemove,
}) {
  const availableMembers = allMembers.filter((member) => {
    if (member.id === editingMemberId) {
      return true;
    }

    return !member.isCommitteeMember;
  });
  const selectedMember = allMembers.find(
    (member) => member.id === formData.memberId,
  );
  const memberPreviewName = selectedMember?.name || "Committee member";
  const memberPreviewInitials =
    memberPreviewName
      .split(" ")
      .filter(Boolean)
      .slice(0, 2)
      .map((part) => part[0]?.toUpperCase() ?? "")
      .join("") || "CM";
  const normalizedSelectedPost = normalizeCommitteePostLabel(
    formData.committeePost || "",
  );
  const selectedPostIsReusable = isReusableCommitteePost(normalizedSelectedPost);
  const occupiedSingleSeatPosts = new Set(
    committeeMembers
      .filter(
        (member) =>
          member.id !== editingMemberId &&
          !isReusableCommitteePost(member.committeePost || ""),
      )
      .map((member) => normalizeCommitteePostLabel(member.committeePost || ""))
      .filter(Boolean),
  );

  return (
    <section className="association-tab-section">
      <section className="association-profile-stack">
        <article className="association-profile-card committee-hero-card">
          <div className="panel-topline">
            <div>
              <span className="mini-label">Management Committee</span>
              <h2>Leadership Panel</h2>
            </div>
            {isAdmin ? (
              <button
                className="primary-link admin-action-button"
                type="button"
                onClick={() => onOpenEditor("")}
                disabled={isSaving}
              >
                Add Committee Member
              </button>
            ) : null}
          </div>
          <p className="committee-hero-copy">
            Leadership cards are driven from the member table. Admins can assign
            a post, set tenure, and update a short bio for each committee
            representative.
          </p>
        </article>

        {editingMemberId !== null ? (
          <article className="association-profile-card">
            <div className="panel-topline">
              <h3>
                {editingMemberId
                  ? "Edit Committee Member"
                  : "Assign Committee Member"}
              </h3>
              <span className="mini-label">Admin Editor</span>
            </div>

            <div className="profile-form-grid">
              <div className="profile-avatar-panel profile-field-wide member-photo-field">
                <div className="profile-avatar-wrap">
                  {formData.photoUrl ? (
                    <img
                      className="profile-avatar-image"
                      src={formData.photoUrl}
                      alt={`${memberPreviewName} preview`}
                    />
                  ) : (
                    <span className="profile-avatar-placeholder">
                      {memberPreviewInitials}
                    </span>
                  )}
                </div>
                <button
                  className="secondary-link secondary-button profile-upload-button"
                  type="button"
                >
                  Upload Member Picture
                  <input
                    type="file"
                    accept="image/*"
                    onChange={(event) =>
                      onImageChange?.(event.target.files?.[0] ?? null)
                    }
                  />
                </button>
              </div>
              <label className="profile-field profile-field-wide">
                <span>Member</span>
                <select
                  value={formData.memberId}
                  onChange={(event) =>
                    onFormChange("memberId", event.target.value)
                  }
                >
                  <option value="">Select member</option>
                  {availableMembers.map((member) => (
                    <option key={member.id} value={member.id}>
                      {member.name} · {member.company || "No company"}
                    </option>
                  ))}
                </select>
              </label>
              <label className="profile-field">
                <span>Post</span>
                <select
                  value={formData.committeePost}
                  onChange={(event) =>
                    onFormChange("committeePost", event.target.value)
                  }
                >
                  <option value="">Select post</option>
                  {committeePostOptions.map((post) => (
                    <option
                      key={post}
                      value={post}
                      disabled={
                        occupiedSingleSeatPosts.has(post) &&
                        normalizeCommitteePostLabel(post) !== normalizedSelectedPost
                      }
                    >
                      {post}
                    </option>
                  ))}
                </select>
              </label>
              {normalizedSelectedPost &&
              !selectedPostIsReusable &&
              occupiedSingleSeatPosts.has(normalizedSelectedPost) ? (
                <p className="profile-field-note">
                  This committee post is already assigned to another member.
                </p>
              ) : null}
              <label className="profile-field">
                <span>Tenure Start</span>
                <input
                  type="date"
                  value={formData.committeeTenureStart}
                  onChange={(event) =>
                    onFormChange("committeeTenureStart", event.target.value)
                  }
                />
              </label>
              <label className="profile-field">
                <span>Tenure End</span>
                <input
                  type="date"
                  value={formData.committeeTenureEnd}
                  onChange={(event) =>
                    onFormChange("committeeTenureEnd", event.target.value)
                  }
                />
              </label>
              <label className="profile-field profile-field-wide">
                <span>Brief About Member</span>
                <textarea
                  rows="4"
                  value={formData.memberBio}
                  onChange={(event) =>
                    onFormChange("memberBio", event.target.value)
                  }
                />
              </label>
            </div>

            <div className="profile-action-row">
              <button
                className="secondary-link secondary-button"
                type="button"
                onClick={onCancelEdit}
                disabled={isSaving}
              >
                Cancel
              </button>
              <button
                className="primary-link admin-action-button"
                type="button"
                onClick={onSave}
                disabled={isSaving}
              >
                {isSaving ? "Saving..." : "Save Committee Details"}
              </button>
            </div>
          </article>
        ) : null}

        {feedbackMessage ? (
          <p className="admin-access-feedback">{feedbackMessage}</p>
        ) : null}

        {committeeMembers.length > 0 ? (
          <div className="committee-card-grid">
            {committeeMembers.map((member) => (
              <article key={member.id} className="committee-member-card">
                <div className="committee-member-head">
                  <div className="member-record-photo committee-member-photo">
                    {member.photoUrl ? (
                      <img
                        className="member-record-photo-image"
                        src={member.photoUrl}
                        alt={member.name}
                      />
                    ) : (
                      <span>{member.initials}</span>
                    )}
                  </div>
                  <div>
                    <span className="mini-label">
                      {member.committeePost || "Committee"}
                    </span>
                    <h3>{member.name}</h3>
                    <p className="member-company">
                      {member.company || "Company not added yet"}
                    </p>
                  </div>
                </div>

                <div className="committee-member-meta">
                  <p>
                    <strong>Membership Type:</strong> {member.membershipType}
                  </p>
                  <p>
                    <strong>Tenure:</strong> {member.committeeTenure}
                  </p>
                </div>

                <p className="committee-member-bio">
                  {member.memberBio || "Brief introduction not added yet."}
                </p>

                {isAdmin ? (
                  <div className="record-actions">
                    <button
                      className="secondary-link secondary-button"
                      type="button"
                      onClick={() => onOpenEditor(member.id)}
                      disabled={isSaving}
                    >
                      Edit
                    </button>
                    <button
                      className="secondary-link secondary-button danger-button"
                      type="button"
                      onClick={() => onRemove(member.id)}
                      disabled={isSaving}
                    >
                      Remove From Committee
                    </button>
                  </div>
                ) : null}
              </article>
            ))}
          </div>
        ) : (
          <article className="association-profile-card committee-empty-card">
            <span className="mini-label">Management Committee</span>
            <h3>No committee members assigned yet</h3>
            <p>
              Assign members to posts like Chairman, Secretary, Treasurer, or
              Committee Member to populate this section.
            </p>
          </article>
        )}
      </section>
    </section>
  );
}

function AssociationGalleryPanel({
  folders,
  isAdmin,
  activeFolderId,
  editingFolderId,
  formData,
  isSaving,
  feedbackMessage,
  onOpenFolder,
  onOpenEditor,
  onFieldChange,
  onFilesChange,
  onCancelEdit,
  onSave,
  onDeleteFolder,
  onDeletePhoto,
  onUploadPhotos,
  selectedFolderIds,
  selectedPhotoIds,
  onToggleFolderSelect,
  onDeleteSelectedFolders,
  onTogglePhotoSelect,
  onDeleteSelectedPhotos,
  onCloseFolder,
  editorRef,
  nameInputRef,
}) {
  const activeFolder =
    folders.find((folder) => folder.id === activeFolderId) ?? null;

  const formatGalleryStamp = (value) => {
    if (!value) {
      return "";
    }

    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime())) {
      return "";
    }

    return parsed.toLocaleString("en-IN", {
      day: "2-digit",
      month: "short",
      year: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  if (activeFolder) {
    return (
      <section className="association-tab-section">
        <section className="association-profile-stack">
          {feedbackMessage ? (
            <p className="admin-access-feedback">{feedbackMessage}</p>
          ) : null}

          <article className="association-profile-card">
            <div className="panel-topline">
              <div>
                <span className="mini-label">Gallery Folder</span>
                <h2>{activeFolder.name}</h2>
                <p className="committee-hero-copy">
                  {activeFolder.photoCount} photo
                  {activeFolder.photoCount === 1 ? "" : "s"} ·{" "}
                  {formatGalleryStamp(activeFolder.createdAt) || "No timestamp"}
                </p>
              </div>
              <div className="record-actions">
                <button
                  className="secondary-link secondary-button"
                  type="button"
                  onClick={onCloseFolder}
                  disabled={isSaving}
                >
                  Back To Folders
                </button>
                {isAdmin ? (
                  <>
                    <button
                      className="secondary-link secondary-button danger-button"
                      type="button"
                      onClick={onDeleteSelectedPhotos}
                      disabled={isSaving || selectedPhotoIds.length === 0}
                    >
                      Delete Selected
                    </button>
                    <button
                      className="secondary-link secondary-button profile-upload-button"
                      type="button"
                      disabled={isSaving}
                    >
                      Upload Images
                      <input
                        type="file"
                        accept="image/*"
                        multiple
                        onChange={(event) =>
                          onUploadPhotos(
                            activeFolder.id,
                            Array.from(event.target.files ?? []),
                          )
                        }
                      />
                    </button>
                  </>
                ) : null}
              </div>
            </div>
          </article>

          {activeFolder.photos.length > 0 ? (
            <div className="association-gallery-grid">
              {activeFolder.photos.map((photo) => (
                <article key={photo.id} className="association-gallery-card">
                  <div className="association-gallery-visual">
                    <img src={photo.imageUrl} alt={activeFolder.name} />
                  </div>
                  <div className="association-gallery-copy">
                    <h3>{activeFolder.name}</h3>
                    <span className="mini-label">
                      {formatGalleryStamp(photo.createdAt) || "No timestamp"}
                    </span>
                  </div>
                  {isAdmin ? (
                    <div className="record-actions">
                      <label className="association-card-selector">
                        <input
                          type="checkbox"
                          checked={selectedPhotoIds.includes(photo.id)}
                          onChange={() => onTogglePhotoSelect(photo.id)}
                          disabled={isSaving}
                        />
                        <span>Select</span>
                      </label>
                      <button
                        className="secondary-link secondary-button danger-button"
                        type="button"
                        onClick={() => onDeletePhoto(activeFolder.id, photo.id)}
                        disabled={isSaving}
                      >
                        Delete Photo
                      </button>
                    </div>
                  ) : null}
                </article>
              ))}
            </div>
          ) : (
            <article className="association-profile-card committee-empty-card">
              <span className="mini-label">Gallery Folder</span>
              <h3>No photos in this folder yet</h3>
              <p>Use Upload Images to add one or many photos into this folder.</p>
            </article>
          )}
        </section>
      </section>
    );
  }

  return (
    <section className="association-tab-section">
      <section className="association-profile-stack">
        <article className="association-profile-card">
          <div className="panel-topline">
            <div>
              <span className="mini-label">Gallery</span>
              <h2>Gallery Folders</h2>
            </div>
            {isAdmin ? (
              <div className="record-actions">
                <button
                  className="secondary-link secondary-button danger-button"
                  type="button"
                  onClick={onDeleteSelectedFolders}
                  disabled={isSaving || selectedFolderIds.length === 0}
                >
                  Delete Selected
                </button>
                <button
                  className="primary-link admin-action-button"
                  type="button"
                  onClick={() => onOpenEditor("")}
                  disabled={isSaving}
                >
                  Add Folder
                </button>
              </div>
            ) : null}
          </div>
          <p className="committee-hero-copy">
            Organize gallery photos into named folders. Newest folders and newest
            photos appear first.
          </p>
        </article>

        {editingFolderId !== null ? (
          <article className="association-profile-card" ref={editorRef}>
            <div className="panel-topline">
              <h3>
                {editingFolderId ? "Edit Gallery Folder" : "Add Gallery Folder"}
              </h3>
              <span className="mini-label">Folder CMS</span>
            </div>

            <div className="profile-form-grid">
              <label className="profile-field profile-field-wide">
                <span>Folder Name</span>
                <input
                  type="text"
                  value={formData.name}
                  ref={nameInputRef}
                  onChange={(event) =>
                    onFieldChange("name", event.target.value)
                  }
                />
              </label>
              {!editingFolderId ? (
                <div className="profile-avatar-panel profile-field-wide member-photo-field">
                  <div className="gallery-form-preview">
                    <div className="gallery-form-placeholder">
                      {formData.files.length > 0
                        ? `${formData.files.length} image${formData.files.length === 1 ? "" : "s"} selected`
                        : "No images selected yet"}
                    </div>
                  </div>
                  <button
                    className="secondary-link secondary-button profile-upload-button"
                    type="button"
                  >
                    Select Images (Optional)
                    <input
                      type="file"
                      accept="image/*"
                      multiple
                      onChange={(event) => onFilesChange(event.target.files)}
                    />
                  </button>
                </div>
              ) : null}
            </div>

            <div className="profile-action-row">
              <button
                className="secondary-link secondary-button"
                type="button"
                onClick={onCancelEdit}
                disabled={isSaving}
              >
                Cancel
              </button>
              <button
                className="primary-link admin-action-button"
                type="button"
                onClick={onSave}
                disabled={isSaving}
              >
                {isSaving ? "Saving..." : "Save Gallery Folder"}
              </button>
            </div>
          </article>
        ) : null}

        {feedbackMessage ? (
          <p className="admin-access-feedback">{feedbackMessage}</p>
        ) : null}

        {folders.length > 0 ? (
          <div className="association-gallery-grid">
            {folders.map((folder) => (
              <article
                key={folder.id}
                className="association-gallery-card"
                style={{ background: "rgba(255, 255, 255, 0.72)" }}
              >
                <button
                  className="association-gallery-visual"
                  type="button"
                  onClick={() => onOpenFolder(folder.id)}
                  style={{
                    border: "none",
                    padding: 0,
                    cursor: "pointer",
                    display: "grid",
                    gridTemplateColumns: "repeat(2, minmax(0, 1fr))",
                    gap: "6px",
                    paddingInline: "12px",
                    paddingTop: "12px",
                  }}
                >
                  {folder.previewPhotos.length > 0 ? (
                    folder.previewPhotos.map((photo) => (
                      <img
                        key={photo.id}
                        src={photo.thumbnailUrl || photo.imageUrl}
                        alt={folder.name}
                        style={{
                          width: "100%",
                          height: "100%",
                          minHeight: "92px",
                          objectFit: "cover",
                          borderRadius: "16px",
                          opacity: 0.92,
                        }}
                      />
                    ))
                  ) : (
                    <div className="gallery-form-placeholder">No images</div>
                  )}
                </button>
                <div className="association-gallery-copy">
                  <h3>{folder.name || "Gallery Folder"}</h3>
                  <span className="mini-label">
                    {folder.photoCount} photo{folder.photoCount === 1 ? "" : "s"}
                  </span>
                  <p>{formatGalleryStamp(folder.createdAt) || "No timestamp"}</p>
                </div>
                {isAdmin ? (
                  <div className="record-actions">
                    <label className="association-card-selector">
                      <input
                        type="checkbox"
                        checked={selectedFolderIds.includes(folder.id)}
                        onChange={() => onToggleFolderSelect(folder.id)}
                        disabled={isSaving}
                      />
                      <span>Select</span>
                    </label>
                    <button
                      className="secondary-link secondary-button"
                      type="button"
                      onClick={() => onOpenEditor(folder.id)}
                      disabled={isSaving}
                    >
                      Edit
                    </button>
                    <button
                      className="secondary-link secondary-button danger-button"
                      type="button"
                      onClick={() => onDeleteFolder(folder.id)}
                      disabled={isSaving}
                    >
                      Delete
                    </button>
                  </div>
                ) : null}
              </article>
            ))}
          </div>
        ) : (
          <article className="association-profile-card committee-empty-card">
            <span className="mini-label">Gallery</span>
            <h3>No gallery folders yet</h3>
            <p>
              Create an empty folder first, then open it and upload photos any
              time.
            </p>
          </article>
        )}

      </section>
    </section>
  );
}

function AssociationCircularsPanel({
  items,
  isAdmin,
  selectedIds,
  editingItemId,
  formData,
  isSaving,
  feedbackMessage,
  onOpenEditor,
  onToggleSelect,
  onDeleteSelected,
  onFieldChange,
  onFileChange,
  onCancelEdit,
  onSave,
  onDelete,
}) {
  return (
    <section className="association-tab-section">
      <section className="association-profile-stack">
        <article className="association-profile-card">
          <div className="panel-topline">
            <div>
              <span className="mini-label">Circulars</span>
              <h2>Document Library</h2>
            </div>
            {isAdmin ? (
              <div className="record-actions">
                <button
                  className="secondary-link secondary-button danger-button"
                  type="button"
                  onClick={onDeleteSelected}
                  disabled={isSaving || selectedIds.length === 0}
                >
                  Delete Selected
                </button>
                <button
                  className="primary-link admin-action-button"
                  type="button"
                  onClick={() => onOpenEditor("")}
                  disabled={isSaving}
                >
                  Add New
                </button>
              </div>
            ) : null}
          </div>
          <p className="committee-hero-copy">
            Upload PDFs, DOC files, or scanned items with a headline, tagline,
            and brief summary. Opening a card takes the user to the full
            document in a new tab.
          </p>
        </article>

        {editingItemId !== null ? (
          <article className="association-profile-card">
            <div className="panel-topline">
              <h3>{editingItemId ? "Edit Circular" : "Add Circular"}</h3>
              <span className="mini-label">Circular CMS</span>
            </div>

            <div className="profile-form-grid">
              <div className="profile-avatar-panel profile-field-wide member-photo-field">
                <div className="gallery-form-preview circular-preview-panel">
                  {formData.previewUrl ? (
                    <img src={formData.previewUrl} alt="Circular preview" />
                  ) : (
                    <div className="gallery-form-placeholder circular-file-placeholder">
                      <strong>{formData.fileExtension || "DOC"}</strong>
                      <span>
                        {formData.fileName || "Upload a PDF, DOC, or scan"}
                      </span>
                    </div>
                  )}
                </div>
                <button
                  className="secondary-link secondary-button profile-upload-button"
                  type="button"
                >
                  Upload Document
                  <input
                    type="file"
                    accept=".pdf,.doc,.docx,.png,.jpg,.jpeg,.webp,.tif,.tiff"
                    onChange={(event) =>
                      onFileChange(event.target.files?.[0] ?? null)
                    }
                  />
                </button>
              </div>
              <label className="profile-field profile-field-wide">
                <span>Headline</span>
                <input
                  type="text"
                  value={formData.headline}
                  onChange={(event) =>
                    onFieldChange("headline", event.target.value)
                  }
                />
              </label>
              <label className="profile-field profile-field-wide">
                <span>Tagline</span>
                <input
                  type="text"
                  value={formData.tagline}
                  onChange={(event) =>
                    onFieldChange("tagline", event.target.value)
                  }
                />
              </label>
              <label className="profile-field profile-field-wide">
                <span>Brief Text</span>
                <textarea
                  rows="5"
                  value={formData.summary}
                  onChange={(event) =>
                    onFieldChange("summary", event.target.value)
                  }
                />
              </label>
            </div>

            <div className="profile-action-row">
              <button
                className="secondary-link secondary-button"
                type="button"
                onClick={onCancelEdit}
                disabled={isSaving}
              >
                Cancel
              </button>
              <button
                className="primary-link admin-action-button"
                type="button"
                onClick={onSave}
                disabled={isSaving}
              >
                {isSaving ? "Saving..." : "Save Circular"}
              </button>
            </div>
          </article>
        ) : null}

        {feedbackMessage ? (
          <p className="admin-access-feedback">{feedbackMessage}</p>
        ) : null}

        {items.length > 0 ? (
          <div className="association-gallery-grid">
            {items.map((item) => (
              <article
                key={item.id}
                className="association-gallery-card circular-card"
              >
                {isAdmin ? (
                  <label className="association-card-selector">
                    <input
                      type="checkbox"
                      checked={selectedIds.includes(item.id)}
                      onChange={() => onToggleSelect(item.id)}
                    />
                    <span>Select</span>
                  </label>
                ) : null}
                <a
                  className="circular-card-link"
                  href={item.documentUrl}
                  target="_blank"
                  rel="noreferrer"
                >
                  <div className="association-gallery-visual">
                    {item.previewUrl ? (
                      <img src={item.previewUrl} alt={item.headline} />
                    ) : (
                      <div className="circular-file-placeholder">
                        <strong>{item.fileExtension || "DOC"}</strong>
                        <span>{item.fileName}</span>
                      </div>
                    )}
                  </div>
                  <div className="association-gallery-copy">
                    <h3>{item.headline}</h3>
                    <span className="mini-label">
                      {item.tagline || "No tagline added yet"}
                    </span>
                    <p>{item.summary || "No brief text added yet."}</p>
                  </div>
                </a>
                {isAdmin ? (
                  <div className="record-actions circular-card-actions">
                    <button
                      className="secondary-link secondary-button"
                      type="button"
                      onClick={() => onOpenEditor(item.id)}
                      disabled={isSaving}
                    >
                      Edit
                    </button>
                    <button
                      className="secondary-link secondary-button danger-button"
                      type="button"
                      onClick={() => onDelete(item.id)}
                      disabled={isSaving}
                    >
                      Delete
                    </button>
                  </div>
                ) : null}
              </article>
            ))}
          </div>
        ) : (
          <article className="association-profile-card committee-empty-card">
            <span className="mini-label">Circulars</span>
            <h3>No circular documents yet</h3>
            <p>
              Upload your first circular to start building the document library.
            </p>
          </article>
        )}
      </section>
    </section>
  );
}

function AssociationMasterPanel({
  committeeMembers,
  allMembers,
  committeePostOptions,
  membershipTypeOptions,
  newCommitteePost,
  editCommitteePostDraft,
  newMembershipType,
  editMembershipTypeDraft,
  committeeFeedbackMessage,
  membershipTypeFeedbackMessage,
  editingPost,
  editingMembershipType,
  isAdmin,
  onNewCommitteePostChange,
  onEditCommitteePostChange,
  onAddCommitteePost,
  onEditCommitteePost,
  onDeleteCommitteePost,
  onSaveCommitteePostEdit,
  onCancelCommitteePostEdit,
  onNewMembershipTypeChange,
  onEditMembershipTypeChange,
  onAddMembershipType,
  onEditMembershipType,
  onDeleteMembershipType,
  onSaveMembershipTypeEdit,
  onCancelMembershipTypeEdit,
}) {
  const [activeMasterTab, setActiveMasterTab] = useState("committee-posts");
  const postCards = committeePostOptions.map((post) => {
    const assignedMembers = committeeMembers.filter(
      (member) => normalizeCommitteePostLabel(member.committeePost || "") === post,
    );
    const assignedMember = assignedMembers[0] ?? null;
    const isDefaultPost = defaultCommitteePostOptions.includes(post);
    const isReusable = isReusableCommitteePost(post);

    return {
      post,
      assignedMember,
      assignedMembers,
      isEditable: assignedMembers.length === 0 && !isDefaultPost,
      isReusable,
    };
  });
  const membershipTypeCards = membershipTypeOptions.map((type) => {
    const assignedMembers = allMembers.filter(
      (member) => normalizeMembershipTypeLabel(member.membershipType || "") === type,
    );
    const isDefaultType = defaultMembershipTypeOptions.includes(type);

    return {
      type,
      assignedMembers,
      isEditable: assignedMembers.length === 0 && !isDefaultType,
    };
  });

  return (
    <section className="association-tab-section">
      <section className="association-profile-stack">
        <article className="association-profile-card">
          <div className="panel-topline">
            <div>
              <span className="mini-label">Association Master</span>
              <h2>Master Settings</h2>
            </div>
          </div>
          <p className="committee-hero-copy">
            Open one master at a time to manage committee posts and membership
            types without stacking both editors on a single page.
          </p>
        </article>

        <nav className="association-tabbar" aria-label="Association master sections">
          <button
            type="button"
            className={`association-tab ${activeMasterTab === "committee-posts" ? "active" : ""}`}
            onClick={() => setActiveMasterTab("committee-posts")}
          >
            Committee Post Master
          </button>
          <button
            type="button"
            className={`association-tab ${activeMasterTab === "membership-types" ? "active" : ""}`}
            onClick={() => setActiveMasterTab("membership-types")}
          >
            Membership Type Master
          </button>
        </nav>

        {activeMasterTab === "committee-posts" ? (
          <>
            <article className="association-profile-card">
              <div className="panel-topline">
                <div>
                  <span className="mini-label">Association Master</span>
                  <h2>Committee Post Master</h2>
                </div>
              </div>
              <p className="committee-hero-copy">
                Manage the available committee post names used during committee
                member assignment. Existing occupied posts like Chairman and
                Secretary are shown here automatically.
              </p>
              {committeeFeedbackMessage ? (
                <p className="admin-access-feedback">{committeeFeedbackMessage}</p>
              ) : null}
            </article>

            {isAdmin ? (
              <article className="association-profile-card">
                <div className="panel-topline">
                  <h3>Add Committee Post</h3>
                  <span className="mini-label">Master Setup</span>
                </div>
                <div className="profile-form-grid">
                  <label className="profile-field profile-field-wide">
                    <span>Committee Post Name</span>
                    <input
                      type="text"
                      value={newCommitteePost}
                      placeholder="Joint Secretary"
                      onChange={(event) =>
                        onNewCommitteePostChange(event.target.value)
                      }
                    />
                  </label>
                </div>
                <div className="profile-action-row">
                  <button
                    className="primary-link admin-action-button"
                    type="button"
                    onClick={onAddCommitteePost}
                  >
                    Add Committee Post
                  </button>
                </div>
              </article>
            ) : null}

            {editingPost ? (
              <article className="association-profile-card">
                <div className="panel-topline">
                  <h3>Edit Committee Post</h3>
                  <span className="mini-label">Master Setup</span>
                </div>
                <div className="profile-form-grid">
                  <label className="profile-field profile-field-wide">
                    <span>Committee Post Name</span>
                    <input
                      type="text"
                      value={editCommitteePostDraft}
                      placeholder="Joint Secretary"
                      onChange={(event) =>
                        onEditCommitteePostChange(event.target.value)
                      }
                    />
                  </label>
                </div>
                <div className="profile-action-row">
                  <button
                    className="secondary-link secondary-button"
                    type="button"
                    onClick={onCancelCommitteePostEdit}
                  >
                    Cancel
                  </button>
                  <button
                    className="primary-link admin-action-button"
                    type="button"
                    onClick={onSaveCommitteePostEdit}
                  >
                    Save Committee Post
                  </button>
                </div>
              </article>
            ) : null}

            <div className="association-gallery-grid">
              {postCards.map(
                ({
                  post,
                  assignedMember,
                  assignedMembers,
                  isEditable,
                  isReusable,
                }) => (
                  <article key={post} className="association-gallery-card">
                    <div className="association-gallery-copy">
                      <span className="mini-label">Committee Post</span>
                      <h3>{post}</h3>
                      <p>
                        {assignedMembers.length > 0
                          ? isReusable
                            ? `${assignedMembers.length} members assigned`
                            : `${assignedMember.name}${assignedMember.company ? ` · ${assignedMember.company}` : ""}`
                          : "No committee member assigned yet."}
                      </p>
                    </div>
                    <div className="record-actions">
                      <span className="access-status-chip">
                        {assignedMembers.length > 0
                          ? isReusable
                            ? `${assignedMembers.length} Assigned`
                            : "Assigned"
                          : "Vacant"}
                      </span>
                      {isAdmin ? (
                        <>
                          <button
                            className="secondary-link secondary-button"
                            type="button"
                            onClick={() => onEditCommitteePost(post)}
                            disabled={!isEditable}
                            title={
                              isEditable
                                ? "Edit this committee post"
                                : "Only custom vacant posts can be edited"
                            }
                          >
                            Edit
                          </button>
                          <button
                            className="secondary-link secondary-button danger-button"
                            type="button"
                            onClick={() => onDeleteCommitteePost(post)}
                            disabled={!isEditable}
                            title={
                              isEditable
                                ? "Delete this committee post"
                                : "Only custom vacant posts can be deleted"
                            }
                          >
                            Delete
                          </button>
                        </>
                      ) : null}
                    </div>
                  </article>
                ),
              )}
            </div>
          </>
        ) : (
          <>
            <article className="association-profile-card">
              <div className="panel-topline">
                <div>
                  <span className="mini-label">Association Master</span>
                  <h2>Membership Type Master</h2>
                </div>
              </div>
              <p className="committee-hero-copy">
                Manage the current membership types used in Member Master. Current
                defaults include Primary, Associate, and Guest.
              </p>
              {membershipTypeFeedbackMessage ? (
                <p className="admin-access-feedback">
                  {membershipTypeFeedbackMessage}
                </p>
              ) : null}
            </article>

            {isAdmin ? (
              <article className="association-profile-card">
                <div className="panel-topline">
                  <h3>Add Membership Type</h3>
                  <span className="mini-label">Master Setup</span>
                </div>
                <div className="profile-form-grid">
                  <label className="profile-field profile-field-wide">
                    <span>Membership Type Name</span>
                    <input
                      type="text"
                      value={newMembershipType}
                      placeholder="Student"
                      onChange={(event) =>
                        onNewMembershipTypeChange(event.target.value)
                      }
                    />
                  </label>
                </div>
                <div className="profile-action-row">
                  <button
                    className="primary-link admin-action-button"
                    type="button"
                    onClick={onAddMembershipType}
                  >
                    Add Membership Type
                  </button>
                </div>
              </article>
            ) : null}

            {editingMembershipType ? (
              <article className="association-profile-card">
                <div className="panel-topline">
                  <h3>Edit Membership Type</h3>
                  <span className="mini-label">Master Setup</span>
                </div>
                <div className="profile-form-grid">
                  <label className="profile-field profile-field-wide">
                    <span>Membership Type Name</span>
                    <input
                      type="text"
                      value={editMembershipTypeDraft}
                      placeholder="Student"
                      onChange={(event) =>
                        onEditMembershipTypeChange(event.target.value)
                      }
                    />
                  </label>
                </div>
                <div className="profile-action-row">
                  <button
                    className="secondary-link secondary-button"
                    type="button"
                    onClick={onCancelMembershipTypeEdit}
                  >
                    Cancel
                  </button>
                  <button
                    className="primary-link admin-action-button"
                    type="button"
                    onClick={onSaveMembershipTypeEdit}
                  >
                    Save Membership Type
                  </button>
                </div>
              </article>
            ) : null}

            <div className="association-gallery-grid">
              {membershipTypeCards.map(({ type, assignedMembers, isEditable }) => (
                <article key={type} className="association-gallery-card">
                  <div className="association-gallery-copy">
                    <span className="mini-label">Membership Type</span>
                    <h3>{getMembershipTypeDisplayLabel(type)}</h3>
                    <p>
                      {assignedMembers.length > 0
                        ? `${assignedMembers.length} member${assignedMembers.length === 1 ? "" : "s"} assigned`
                        : "No members are using this membership type yet."}
                    </p>
                  </div>
                  <div className="record-actions">
                    <span className="access-status-chip">
                      {assignedMembers.length > 0
                        ? `${assignedMembers.length} Assigned`
                        : "Vacant"}
                    </span>
                    {isAdmin ? (
                      <>
                        <button
                          className="secondary-link secondary-button"
                          type="button"
                          onClick={() => onEditMembershipType(type)}
                          disabled={!isEditable}
                          title={
                            isEditable
                              ? "Edit this membership type"
                              : "Only custom vacant membership types can be edited"
                          }
                        >
                          Edit
                        </button>
                        <button
                          className="secondary-link secondary-button danger-button"
                          type="button"
                          onClick={() => onDeleteMembershipType(type)}
                          disabled={!isEditable}
                          title={
                            isEditable
                              ? "Delete this membership type"
                              : "Only custom vacant membership types can be deleted"
                          }
                        >
                          Delete
                        </button>
                      </>
                    ) : null}
                  </div>
                </article>
              ))}
            </div>
          </>
        )}
      </section>
    </section>
  );
}

function MemberCrudHeader({
  activeTab,
  isAdmin,
  items,
  selectedIds,
  isSaving,
  feedbackMessage,
  isReminderPanelOpen,
  onToggleReminderPanel,
  onApplyReminderFilter,
  onToggleSelectAll,
  onDeleteSelected,
  onAddNew,
  onContactSelected,
  onSendNotice,
}) {
  const allSelected = items.length > 0 && selectedIds.length === items.length;

  return (
    <div className="association-crud-header">
      <div>
        <span className="mini-label">{activeTab}</span>
        <h2>{activeTab} Directory</h2>
        <p>
          CRUD and communication controls are kept behind an admin flag for
          future auth roles.
        </p>
        {feedbackMessage ? (
          <p className="admin-access-feedback">{feedbackMessage}</p>
        ) : null}
      </div>

      {isAdmin ? (
        <div className="association-admin-actions">
          <div className="reminder-filter-wrap">
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={onToggleReminderPanel}
              disabled={isSaving}
            >
              Reminders
            </button>
            {isReminderPanelOpen ? (
              <div className="reminder-filter-panel">
                <button
                  type="button"
                  onClick={() => onApplyReminderFilter("expiring-soon")}
                >
                  Expiring Soon
                </button>
                <button
                  type="button"
                  onClick={() => onApplyReminderFilter("Temporary Visitors")}
                >
                  Temporary Visitors
                </button>
                <button
                  type="button"
                  onClick={() => onApplyReminderFilter("Primary Members")}
                >
                  Primary Members
                </button>
                <button
                  type="button"
                  onClick={() => onApplyReminderFilter("Associate Members")}
                >
                  Associate Members
                </button>
                <button
                  type="button"
                  onClick={() => onApplyReminderFilter("Committee Members")}
                >
                  Committee Members
                </button>
              </div>
            ) : null}
          </div>
          <label className="selection-chip">
            <input
              type="checkbox"
              checked={allSelected}
              onChange={onToggleSelectAll}
              disabled={isSaving}
            />
            <span>Select multiple</span>
          </label>
          <button
            className="secondary-link secondary-button"
            type="button"
            onClick={onContactSelected}
            disabled={isSaving}
          >
            Contact
          </button>
          <button
            className="secondary-link secondary-button"
            type="button"
            onClick={onSendNotice}
            disabled={isSaving}
          >
            Send Notice
          </button>
          <button
            className="secondary-link secondary-button"
            type="button"
            onClick={onDeleteSelected}
            disabled={isSaving}
          >
            {isSaving ? "Deleting..." : "Delete Selected"}
          </button>
          <button
            className="primary-link admin-action-button"
            type="button"
            onClick={onAddNew}
            disabled={isSaving}
          >
            Add Member
          </button>
        </div>
      ) : null}
    </div>
  );
}

function MemberCardGrid({
  items,
  selectedIds,
  isAdmin,
  isSaving,
  onToggleSelect,
  onEditOne,
  onDeleteOne,
}) {
  return (
    <div className="member-record-grid">
      {items.map((member) => (
        <article key={member.id} className="member-record-card">
          <div className="member-record-head">
            <div className="member-record-photo">
              {member.photoUrl ? (
                <img
                  className="member-record-photo-image"
                  src={member.photoUrl}
                  alt={member.name}
                />
              ) : (
                <span>{member.initials}</span>
              )}
            </div>
            <div className="member-record-heading">
              <em className="carousel-badge">{member.badge}</em>
              <strong>{member.name}</strong>
              <p className="member-company">{member.company}</p>
            </div>
            {isAdmin ? (
              <label className="record-select-chip">
                <input
                  type="checkbox"
                  checked={selectedIds.includes(member.id)}
                  onChange={() => onToggleSelect(member.id)}
                  disabled={isSaving}
                />
                <span>Select</span>
              </label>
            ) : null}
          </div>

          <div className="member-record-details">
            <p>{member.address}</p>
            <p>{member.phone}</p>
            <p>{member.email}</p>
            <p>WhatsApp: +{member.whatsapp}</p>
            <p>Membership Type: {member.membershipType}</p>
            <p>Membership Period: {member.membershipPeriod}</p>
          </div>

          <div className="record-actions">
            <a
              className="secondary-link"
              href={`https://wa.me/${member.whatsapp}`}
              target="_blank"
              rel="noreferrer"
            >
              WhatsApp
            </a>
            <a className="secondary-link" href={`mailto:${member.email}`}>
              Mail
            </a>
            {isAdmin ? (
              <button
                className="secondary-link secondary-button"
                type="button"
                onClick={() => onEditOne(member.id)}
                disabled={isSaving}
              >
                Edit
              </button>
            ) : (
              <button className="secondary-link secondary-button" type="button">
                See Detail
              </button>
            )}
            {isAdmin ? (
              <button
                className="secondary-link secondary-button danger-button"
                type="button"
                onClick={() => onDeleteOne(member.id)}
                disabled={isSaving}
              >
                Delete
              </button>
            ) : null}
          </div>
        </article>
      ))}
    </div>
  );
}

function MemberTable({
  items,
  selectedIds,
  isAdmin,
  isSaving,
  onToggleSelect,
  onEditOne,
  onDeleteOne,
}) {
  return (
    <section className="member-table-panel">
      <div className="panel-topline">
        <h2>Member Table</h2>
        <span className="mini-label">Bulk Actions Ready</span>
      </div>

      <div className="member-table-wrap">
        <table className="member-table">
          <thead>
            <tr>
              {isAdmin ? <th>Select</th> : null}
              <th>Name</th>
              <th>Company</th>
              <th>Membership Type</th>
              <th>Membership Period</th>
              <th>Contact</th>
              <th>WhatsApp</th>
              <th>Notice</th>
              {isAdmin ? <th>Actions</th> : null}
            </tr>
          </thead>
          <tbody>
            {items.map((member) => (
              <tr
                key={member.id}
                className={
                  member.expiryStatus === "expiring-soon"
                    ? "member-row-expiring"
                    : "member-row-active"
                }
              >
                {isAdmin ? (
                  <td>
                    <input
                      type="checkbox"
                      checked={selectedIds.includes(member.id)}
                      onChange={() => onToggleSelect(member.id)}
                      disabled={isSaving}
                    />
                  </td>
                ) : null}
                <td>{member.name}</td>
                <td>{member.company}</td>
                <td>{member.membershipType}</td>
                <td>
                  <div className="member-period-cell">
                    <span>{member.membershipPeriod}</span>
                    {member.expiryStatus === "expiring-soon" ? (
                      <span className="expiry-chip">Expiring Soon</span>
                    ) : (
                      <span className="expiry-chip expiry-chip-active">
                        Active
                      </span>
                    )}
                  </div>
                </td>
                <td>
                  <div className="member-table-contact">
                    <a href={`mailto:${member.email}`}>{member.email}</a>
                    <span>{member.phone}</span>
                  </div>
                </td>
                <td>
                  <a
                    className="table-action-link"
                    href={`https://wa.me/${member.whatsapp}`}
                    target="_blank"
                    rel="noreferrer"
                  >
                    Open Chat
                  </a>
                </td>
                <td>
                  {member.expiryStatus === "expiring-soon" ? (
                    <button
                      className="secondary-link secondary-button table-button reminder-button"
                      type="button"
                      disabled={isSaving}
                    >
                      Send Reminder
                    </button>
                  ) : (
                    <button
                      className="secondary-link secondary-button table-button"
                      type="button"
                      disabled={isSaving}
                    >
                      Send Notice
                    </button>
                  )}
                </td>
                {isAdmin ? (
                  <td>
                    <div className="member-master-actions">
                      <button
                        className="secondary-link secondary-button table-button"
                        type="button"
                        onClick={() => onEditOne(member.id)}
                        disabled={isSaving}
                      >
                        Edit
                      </button>
                      <button
                        className="secondary-link secondary-button danger-button table-button"
                        type="button"
                        onClick={() => onDeleteOne(member.id)}
                        disabled={isSaving}
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                ) : null}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

function MemberArenaContent({
  activeTab,
  isAdmin,
  tabItems,
  allMembers,
  memberPosts,
  memberPostForm,
  isSavingMemberPost,
  memberPostFeedback,
  isSavingMemberDirectory,
  memberDirectoryFeedback,
  selectedIds,
  membershipFormFields,
  membershipFieldDraft,
  bulkMemberFile,
  isBulkMemberUploading,
  bulkMemberError,
  bulkMemberResult,
  isReminderPanelOpen,
  onToggleReminderPanel,
  onApplyReminderFilter,
  onToggleSelect,
  onToggleSelectAll,
  onDeleteSelected,
  onDeleteOne,
  onOpenMemberForm,
  onEditMember,
  onDeleteMember,
  onMembershipFieldDraftChange,
  onAddMembershipField,
  onUpdateMembershipField,
  onDeleteMembershipField,
  onBulkMemberFileChange,
  onUploadBulkMembers,
  onMemberPostFieldChange,
  onMemberPostImageChange,
  onClearMemberPostImage,
  onSubmitMemberPost,
  onUpdateMemberPostStatus,
}) {
  if (activeTab === "Media") {
    return (
      <MemberMediaPanel
        isAdmin={isAdmin}
        members={allMembers}
        posts={memberPosts}
        form={memberPostForm}
        isSaving={isSavingMemberPost}
        feedbackMessage={memberPostFeedback}
        onFieldChange={onMemberPostFieldChange}
        onImageChange={onMemberPostImageChange}
        onSubmit={onSubmitMemberPost}
        onClearImage={onClearMemberPostImage}
        onStatusChange={onUpdateMemberPostStatus}
      />
    );
  }

  if (activeTab === "Master") {
    return (
      <MemberMasterPanel
        isAdmin={isAdmin}
        members={tabItems}
        membershipFormFields={membershipFormFields}
        fieldDraft={membershipFieldDraft}
        bulkMemberFile={bulkMemberFile}
        isBulkMemberUploading={isBulkMemberUploading}
        bulkMemberError={bulkMemberError}
        bulkMemberResult={bulkMemberResult}
        onOpenMemberForm={onOpenMemberForm}
        onEditMember={onEditMember}
        onDeleteMember={onDeleteMember}
        onFieldDraftChange={onMembershipFieldDraftChange}
        onAddField={onAddMembershipField}
        onUpdateField={onUpdateMembershipField}
        onDeleteField={onDeleteMembershipField}
        onBulkMemberFileChange={onBulkMemberFileChange}
        onUploadBulkMembers={onUploadBulkMembers}
      />
    );
  }

  if (activeTab === "Primary Members") {
    return (
      <section className="association-tab-section">
        <MemberTable
          items={tabItems}
          selectedIds={selectedIds}
          isAdmin={isAdmin}
          isSaving={isSavingMemberDirectory}
          onToggleSelect={onToggleSelect}
          onEditOne={onEditMember}
          onDeleteOne={onDeleteOne}
        />
      </section>
    );
  }

  if (activeTab === "Associate Members" || activeTab === "Guest") {
    return (
      <section className="association-tab-section">
        <MemberTable
          items={tabItems}
          selectedIds={selectedIds}
          isAdmin={isAdmin}
          isSaving={isSavingMemberDirectory}
          onToggleSelect={onToggleSelect}
          onEditOne={onEditMember}
          onDeleteOne={onDeleteOne}
        />
      </section>
    );
  }

  return (
    <section className="association-tab-section">
      <MemberCrudHeader
        activeTab={activeTab}
        isAdmin={isAdmin}
        items={tabItems}
        selectedIds={selectedIds}
        isSaving={isSavingMemberDirectory}
        feedbackMessage={memberDirectoryFeedback}
        isReminderPanelOpen={isReminderPanelOpen}
        onToggleReminderPanel={onToggleReminderPanel}
        onApplyReminderFilter={onApplyReminderFilter}
        onToggleSelectAll={onToggleSelectAll}
        onDeleteSelected={onDeleteSelected}
        onAddNew={onOpenMemberForm}
        onContactSelected={() => {}}
        onSendNotice={() => {}}
      />

      <MemberCardGrid
        items={tabItems}
        selectedIds={selectedIds}
        isAdmin={isAdmin}
        isSaving={isSavingMemberDirectory}
        onToggleSelect={onToggleSelect}
        onEditOne={onEditMember}
        onDeleteOne={onDeleteOne}
      />

      <MemberTable
        items={tabItems}
        selectedIds={selectedIds}
        isAdmin={isAdmin}
        isSaving={isSavingMemberDirectory}
        onToggleSelect={onToggleSelect}
        onEditOne={onEditMember}
        onDeleteOne={onDeleteOne}
      />
    </section>
  );
}

function getMemberFormValue(formData, field) {
  if (field.key && field.key in formData) {
    return formData[field.key] ?? "";
  }

  return formData.customFieldValues?.[field.id] ?? "";
}

function MemberMembershipForm({
  fields,
  formData,
  editingId,
  membershipTypeOptions,
  isSaving,
  feedbackMessage,
  onFieldChange,
  onImageChange,
  onSave,
  onCancel,
}) {
  return (
    <section className="member-table-panel">
      <div className="panel-topline">
        <h2>{editingId ? "Modify User" : "Add User"}</h2>
        <span className="mini-label">Membership Form</span>
      </div>

      <div className="profile-form-grid">
        <div className="profile-avatar-panel profile-field-wide member-photo-field">
          <div className="profile-avatar-wrap">
            {formData.photoUrl ? (
              <img
                className="profile-avatar-image"
                src={formData.photoUrl}
                alt="Member preview"
              />
            ) : (
              <span className="profile-avatar-placeholder">
                {formData.name
                  .split(" ")
                  .filter(Boolean)
                  .slice(0, 2)
                  .map((part) => part[0]?.toUpperCase() ?? "")
                  .join("") || "MB"}
              </span>
            )}
          </div>
          <button
            className="secondary-link secondary-button profile-upload-button"
            type="button"
          >
            Upload Member Picture
            <input
              type="file"
              accept="image/*"
              onChange={(event) =>
                onImageChange(event.target.files?.[0] ?? null)
              }
            />
          </button>
        </div>

        <label className="profile-field">
          <span>Company</span>
          <input
            type="text"
            value={formData.company}
            onChange={(event) => onFieldChange("company", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Email</span>
          <input
            type="email"
            value={formData.email}
            onChange={(event) => onFieldChange("email", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Phone</span>
          <input
            type="text"
            value={formData.phone}
            onChange={(event) => onFieldChange("phone", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Membership Type</span>
          <select
            value={formData.membershipType}
            onChange={(event) =>
              onFieldChange("membershipType", event.target.value)
            }
          >
            {membershipTypeOptions.map((type) => (
              <option key={type} value={type}>
                {getMembershipTypeDisplayLabel(type)}
              </option>
            ))}
          </select>
        </label>

        {fields.map((field) => {
          const label = `${field.label}${field.required ? " *" : ""}`;
          const value = getMemberFormValue(formData, field);

          if (field.type === "textarea") {
            return (
              <label
                key={field.id}
                className="profile-field profile-field-wide"
              >
                <span>{label}</span>
                <textarea
                  rows="3"
                  value={value}
                  onChange={(event) =>
                    onFieldChange(field.id, event.target.value)
                  }
                />
              </label>
            );
          }

          return (
            <label key={field.id} className="profile-field">
              <span>{label}</span>
              <input
                type={field.type === "date" ? "date" : "text"}
                value={value}
                onChange={(event) =>
                  onFieldChange(field.id, event.target.value)
                }
              />
            </label>
          );
        })}

        <label className="profile-field">
          <span>Membership Start</span>
          <input
            type="date"
            value={formData.membershipStartDate}
            onChange={(event) =>
              onFieldChange("membershipStartDate", event.target.value)
            }
          />
        </label>
        <label className="profile-field">
          <span>Membership End</span>
          <input
            type="date"
            value={formData.membershipEndDate}
            onChange={(event) =>
              onFieldChange("membershipEndDate", event.target.value)
            }
          />
        </label>
        <label className="profile-field">
          <span>Payment Amount</span>
          <input
            type="text"
            placeholder="Rs. 48,000"
            value={formData.paymentAmount}
            onChange={(event) =>
              onFieldChange("paymentAmount", event.target.value)
            }
          />
        </label>
        <label className="profile-field">
          <span>Payment Status</span>
          <select
            value={formData.paymentStatus}
            onChange={(event) =>
              onFieldChange("paymentStatus", event.target.value)
            }
          >
            <option value="Pending">Pending</option>
            <option value="Paid">Paid</option>
            <option value="Overdue">Overdue</option>
            <option value="Waived">Waived</option>
          </select>
        </label>
      </div>

      <div className="profile-action-row">
        {feedbackMessage ? (
          <p className="admin-access-feedback">{feedbackMessage}</p>
        ) : null}
        <button
          className="secondary-link secondary-button"
          type="button"
          onClick={onCancel}
          disabled={isSaving}
        >
          Cancel
        </button>
        <button
          className="primary-link admin-action-button"
          type="button"
          onClick={onSave}
          disabled={isSaving}
        >
          {isSaving ? "Saving..." : editingId ? "Update User" : "Save User"}
        </button>
      </div>
    </section>
  );
}

function MembershipFormPreview({ fields }) {
  return (
    <div className="profile-form-grid">
      {fields.map((field) => {
        const label = `${field.label}${field.required ? " *" : ""}`;

        if (field.type === "textarea") {
          return (
            <label key={field.id} className="profile-field profile-field-wide">
              <span>{label}</span>
              <textarea
                rows="3"
                placeholder={`Preview for ${field.label}`}
                disabled
              />
            </label>
          );
        }

        return (
          <label key={field.id} className="profile-field">
            <span>{label}</span>
            <input
              type={field.type === "date" ? "date" : "text"}
              placeholder={`Preview for ${field.label}`}
              disabled
            />
          </label>
        );
      })}
      <label className="profile-field">
        <span>Membership Start</span>
        <input type="date" disabled />
      </label>
      <label className="profile-field">
        <span>Membership End</span>
        <input type="date" disabled />
      </label>
      <label className="profile-field">
        <span>Payment Amount</span>
        <input type="text" placeholder="Rs. 48,000" disabled />
      </label>
      <label className="profile-field">
        <span>Payment Status</span>
        <select disabled>
          <option>Pending</option>
        </select>
      </label>
    </div>
  );
}

function MemberMasterPanel({
  isAdmin,
  members,
  membershipFormFields,
  fieldDraft,
  bulkMemberFile,
  isBulkMemberUploading,
  bulkMemberError,
  bulkMemberResult,
  onOpenMemberForm,
  onEditMember,
  onDeleteMember,
  onFieldDraftChange,
  onAddField,
  onUpdateField,
  onDeleteField,
  onBulkMemberFileChange,
  onUploadBulkMembers,
}) {
  if (!isAdmin) {
    return (
      <article className="association-empty-state">
        <span className="mini-label">Member Master</span>
        <h2>Only admins can update the membership master.</h2>
        <p>
          Switch to an admin login to manage users and the membership form
          fields.
        </p>
      </article>
    );
  }

  return (
    <section className="association-tab-section member-master-layout">
      <section className="member-table-panel">
        <div className="panel-topline">
          <h2>Membership Master</h2>
          <span className="mini-label">Admin CRUD</span>
        </div>

        <div className="profile-action-row">
          <button
            className="primary-link admin-action-button"
            type="button"
            onClick={onOpenMemberForm}
          >
            Add User
          </button>
        </div>
      </section>

      <AdminBulkMemberPanel
        selectedFile={bulkMemberFile}
        isUploading={isBulkMemberUploading}
        errorMessage={bulkMemberError}
        result={bulkMemberResult}
        onFileChange={onBulkMemberFileChange}
        onUpload={onUploadBulkMembers}
      />

    </section>
  );
}

function VendorStatusGrid({ items, isSaving, onEdit }) {
  return (
    <div className="member-record-grid">
      {items.map((vendor) => (
        <article key={vendor.id} className="member-record-card">
          <div className="member-record-head">
            <div className="member-record-photo">
              <span>{vendor.initials}</span>
            </div>
            <div className="member-record-heading">
              <em className="carousel-badge">{vendor.badge}</em>
              <strong>{vendor.name}</strong>
              <p className="member-company">{vendor.company}</p>
            </div>
            <span className="access-status-chip">
              {vendor.registrationStatus}
            </span>
          </div>

          <div className="member-record-details">
            <p>{vendor.address}</p>
            <p>City: {vendor.city}</p>
            <p>{vendor.phone}</p>
            <p>{vendor.email}</p>
            <p>Category: {vendor.category}</p>
            <p>Vendor Type: {vendor.vendorType}</p>
            <p>Registration Period: {vendor.onboardingPeriod}</p>
          </div>

          <div className="record-actions">
            <a
              className="secondary-link"
              href={`https://wa.me/${vendor.whatsapp}`}
              target="_blank"
              rel="noreferrer"
            >
              WhatsApp
            </a>
            <a className="secondary-link" href={`mailto:${vendor.email}`}>
              Mail
            </a>
            {onEdit ? (
              <button
                className="secondary-link secondary-button"
                type="button"
                onClick={() => onEdit(vendor)}
                disabled={isSaving}
              >
                Edit
              </button>
            ) : (
              <button className="secondary-link secondary-button" type="button">
                See Detail
              </button>
            )}
          </div>
        </article>
      ))}
    </div>
  );
}

function VendorRegistrationTable({ items, onEdit }) {
  return (
    <section className="member-table-panel">
      <div className="panel-topline">
        <h2>Vendor Registration Status</h2>
        <span className="mini-label">
          Active, Suspended, Lapsed, and login IDs
        </span>
      </div>

      <div className="member-table-wrap">
        <table className="member-table">
          <thead>
            <tr>
              <th>Vendor</th>
              <th>Company</th>
              <th>Category</th>
              <th>City</th>
              <th>Type</th>
              <th>Vendor Logins</th>
              <th>Registration Period</th>
              <th>Status</th>
              <th>Contact</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {items.map((vendor) => (
              <tr key={vendor.id}>
                <td>{vendor.name}</td>
                <td>{vendor.company}</td>
                <td>{vendor.category}</td>
                <td>{vendor.city}</td>
                <td>{vendor.vendorType}</td>
                <td>
                  <div className="member-table-contact">
                    <span>{vendor.primaryLoginEmail || "--"}</span>
                    <span>
                      {vendor.secondaryLoginEmail || "No secondary login"}
                    </span>
                  </div>
                </td>
                <td>{vendor.onboardingPeriod}</td>
                <td>
                  <span className="access-status-chip">
                    {vendor.registrationStatus}
                  </span>
                </td>
                <td>
                  <div className="member-table-contact">
                    <a href={`mailto:${vendor.email}`}>{vendor.email}</a>
                    <span>{vendor.phone}</span>
                  </div>
                </td>
                <td>
                  <button
                    className="secondary-link secondary-button"
                    type="button"
                    onClick={() => onEdit(vendor)}
                  >
                    Edit
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

function VendorPaymentGrid({ items }) {
  return (
    <div className="association-record-grid">
      {items.map((vendor, index) => (
        <article
          key={vendor.id}
          className="association-record-card tone-advertisement"
        >
          <div className="association-record-visual">
            <span>{String(index + 1).padStart(2, "0")}</span>
          </div>
          <div className="association-record-copy">
            <div className="association-record-topline">
              <em className="carousel-badge">{vendor.membershipPlan}</em>
              <span className="access-status-chip">{vendor.paymentStatus}</span>
            </div>
            <strong>{vendor.name}</strong>
            <p>Category: {vendor.category}</p>
            <p>City: {vendor.city}</p>
            <p>Membership: {vendor.membershipPlan}</p>
            <p>Payment Amount: {vendor.paymentAmount}</p>
            <p>Payment Due: {vendor.paymentDue}</p>
            <p>App Access: {vendor.appAccessStatus}</p>
          </div>
        </article>
      ))}
    </div>
  );
}

function VendorPaymentTable({ items }) {
  return (
    <section className="member-table-panel">
      <div className="panel-topline">
        <h2>Vendor Membership and Payment</h2>
        <span className="mini-label">Commercial Status</span>
      </div>

      <div className="member-table-wrap">
        <table className="member-table">
          <thead>
            <tr>
              <th>Vendor</th>
              <th>Category</th>
              <th>City</th>
              <th>Membership</th>
              <th>Payment Status</th>
              <th>Amount</th>
              <th>Due Date</th>
              <th>Registration Status</th>
            </tr>
          </thead>
          <tbody>
            {items.map((vendor) => (
              <tr key={vendor.id}>
                <td>{vendor.name}</td>
                <td>{vendor.category}</td>
                <td>{vendor.city}</td>
                <td>{vendor.membershipPlan}</td>
                <td>
                  <span className="access-status-chip">
                    {vendor.paymentStatus}
                  </span>
                </td>
                <td>{vendor.paymentAmount}</td>
                <td>{vendor.paymentDue}</td>
                <td>{vendor.registrationStatus}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

function VendorRegistrationForm({
  formData,
  onChange,
  onFileChange,
  categories,
  subCategories,
  countryOptions,
  stateOptions,
  cityOptions,
  phoneCodeOptions,
  newCategory,
  onNewCategoryChange,
  onAddCategory,
  onReset,
  onSubmit,
  errorMessage,
  successMessage,
  isSaving,
}) {
  return (
    <section className="member-table-panel">
      <div className="panel-topline">
        <h2>{formData.id ? "Update Vendor" : "Add / Update Vendor"}</h2>
        <span className="mini-label">Admin Vendor Desk</span>
      </div>

      <div className="admin-member-toolbar">
        <div className="search-wrap admin-member-search">
          <input
            className="search-input"
            type="text"
            placeholder="Create a category like Logistics, Packaging, Automation..."
            value={newCategory}
            onChange={(event) => onNewCategoryChange(event.target.value)}
          />
        </div>
        <button
          className="secondary-link secondary-button"
          type="button"
          onClick={onAddCategory}
        >
          Add Category
        </button>
      </div>

      <div className="content-member-selector">
        {categories.map((category) => (
          <span key={category} className="content-member-chip active">
            {category}
          </span>
        ))}
      </div>

      <div className="profile-form-grid">
        <label className="profile-field">
          <span>Company Name *</span>
          <input
            type="text"
            value={formData.company}
            onChange={(event) => onChange("company", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Contact Person Name *</span>
          <input
            type="text"
            value={formData.contactPerson}
            onChange={(event) => onChange("contactPerson", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Mobile *</span>
          <div className="split-inline-fields">
            <select
              value={formData.phoneCode}
              onChange={(event) => onChange("phoneCode", event.target.value)}
            >
              {phoneCodeOptions.map((phoneCode) => (
                <option key={phoneCode} value={phoneCode}>
                  {phoneCode}
                </option>
              ))}
            </select>
            <input
              type="text"
              value={formData.phone}
              onChange={(event) => onChange("phone", event.target.value)}
            />
          </div>
        </label>
        <label className="profile-field">
          <span>WhatsApp Number</span>
          <div className="split-inline-fields">
            <select
              value={formData.whatsappCode}
              onChange={(event) => onChange("whatsappCode", event.target.value)}
            >
              {phoneCodeOptions.map((phoneCode) => (
                <option key={phoneCode} value={phoneCode}>
                  {phoneCode}
                </option>
              ))}
            </select>
            <input
              type="text"
              value={formData.whatsapp}
              onChange={(event) => onChange("whatsapp", event.target.value)}
            />
          </div>
        </label>
        <label className="profile-field">
          <span>Email *</span>
          <input
            type="email"
            value={formData.email}
            onChange={(event) => onChange("email", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Primary Login ID *</span>
          <input
            type="email"
            value={formData.primaryLoginEmail}
            onChange={(event) =>
              onChange("primaryLoginEmail", event.target.value)
            }
          />
        </label>
        <label className="profile-field">
          <span>Secondary Login ID</span>
          <input
            type="email"
            value={formData.secondaryLoginEmail}
            onChange={(event) =>
              onChange("secondaryLoginEmail", event.target.value)
            }
          />
        </label>
        <label className="profile-field">
          <span>Category *</span>
          <select
            value={formData.category}
            onChange={(event) => onChange("category", event.target.value)}
          >
            <option value="">Select category</option>
            {categories.map((category) => (
              <option key={category} value={category}>
                {category}
              </option>
            ))}
          </select>
        </label>
        <label className="profile-field">
          <span>Sub Category *</span>
          <select
            value={formData.subCategory}
            onChange={(event) => onChange("subCategory", event.target.value)}
          >
            <option value="">Select sub category</option>
            {subCategories.map((subCategory) => (
              <option key={subCategory} value={subCategory}>
                {subCategory}
              </option>
            ))}
          </select>
        </label>
        <label className="profile-field">
          <span>Country</span>
          <select
            value={formData.country}
            onChange={(event) => onChange("country", event.target.value)}
          >
            <option value="">Select country</option>
            {countryOptions.map((country) => (
              <option key={country} value={country}>
                {country}
              </option>
            ))}
          </select>
        </label>
        <label className="profile-field">
          <span>State</span>
          <select
            value={formData.state}
            onChange={(event) => onChange("state", event.target.value)}
          >
            <option value="">Select state</option>
            {stateOptions.map((state) => (
              <option key={state} value={state}>
                {state}
              </option>
            ))}
          </select>
        </label>
        <label className="profile-field">
          <span>City</span>
          <select
            value={formData.city}
            onChange={(event) => onChange("city", event.target.value)}
          >
            <option value="">Select city</option>
            {cityOptions.map((city) => (
              <option key={city} value={city}>
                {city}
              </option>
            ))}
          </select>
        </label>
        <label className="profile-field">
          <span>Website</span>
          <input
            type="text"
            value={formData.website}
            onChange={(event) => onChange("website", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Facebook Page</span>
          <input
            type="text"
            value={formData.facebookUrl}
            onChange={(event) => onChange("facebookUrl", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Instagram Page</span>
          <input
            type="text"
            value={formData.instagramUrl}
            onChange={(event) => onChange("instagramUrl", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>YouTube Channel</span>
          <input
            type="text"
            value={formData.youtubeUrl}
            onChange={(event) => onChange("youtubeUrl", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>LinkedIn Page</span>
          <input
            type="text"
            value={formData.linkedinUrl}
            onChange={(event) => onChange("linkedinUrl", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>X / Twitter Page</span>
          <input
            type="text"
            value={formData.xUrl}
            onChange={(event) => onChange("xUrl", event.target.value)}
          />
        </label>
        <label className="profile-field profile-field-wide">
          <span>Address *</span>
          <textarea
            rows="3"
            value={formData.address}
            onChange={(event) => onChange("address", event.target.value)}
          />
        </label>
        <label className="profile-field profile-field-wide">
          <span>Work Description</span>
          <textarea
            rows="3"
            value={formData.workDescription}
            onChange={(event) =>
              onChange("workDescription", event.target.value)
            }
          />
        </label>
        <label className="profile-field">
          <span>Zipcode</span>
          <input
            type="text"
            value={formData.zipcode}
            onChange={(event) => onChange("zipcode", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Company Logo</span>
          <input
            type="file"
            accept="image/*"
            onChange={(event) =>
              onFileChange("companyLogo", event.target.files?.[0] ?? null)
            }
          />
        </label>
        <div className="profile-field profile-field-wide vendor-admin-note">
          <span>Admin Review Fields</span>
          <p>
            Plan, commercial, schedule, proof, and approval details are
            completed by the admin during vendor status review.
          </p>
        </div>
      </div>

      <div className="profile-action-row">
        {errorMessage ? (
          <p className="form-helper-error">{errorMessage}</p>
        ) : successMessage ? (
          <p className="form-helper success-text">{successMessage}</p>
        ) : (
          <p className="form-helper">
            Save the vendor only after the login IDs, category, location, and
            contact details are complete.
          </p>
        )}
      </div>

      <div className="profile-action-row">
        <button
          className="secondary-link secondary-button"
          type="button"
          onClick={onReset}
          disabled={isSaving}
        >
          {formData.id ? "Cancel Edit" : "Reset"}
        </button>
        <button
          className="primary-link admin-action-button"
          type="button"
          onClick={onSubmit}
          disabled={isSaving}
        >
          {isSaving
            ? "Saving..."
            : formData.id
              ? "Update Vendor"
              : "Save Vendor"}
        </button>
      </div>
    </section>
  );
}

function VendorCategoryPanel({
  categories,
  subCategoryMap,
  draftValue,
  editingValue,
  errorMessage,
  successMessage,
  onDraftChange,
  onStartEdit,
  onCancelEdit,
  onSave,
  onDelete,
}) {
  return (
    <section className="association-tab-section">
      <section className="association-profile-stack">
        <article className="association-profile-card">
          <div className="panel-topline">
            <div>
              <span className="mini-label">Vendor Category</span>
              <h2>Category Master</h2>
            </div>
            <button
              className="primary-link admin-action-button"
              type="button"
              onClick={() => onStartEdit("")}
            >
              Add Category
            </button>
          </div>
          <p className="committee-hero-copy">
            Create and maintain the main vendor categories used by registration
            and sub-category mapping.
          </p>
          {errorMessage ? (
            <p className="form-error-message">{errorMessage}</p>
          ) : null}
          {successMessage ? (
            <p className="form-success-message">{successMessage}</p>
          ) : null}
        </article>

        {editingValue !== null ? (
          <article className="association-profile-card">
            <div className="panel-topline">
              <h3>{editingValue ? "Edit Category" : "Add Category"}</h3>
              <span className="mini-label">Vendor Master</span>
            </div>

            <div className="profile-form-grid">
              <label className="profile-field profile-field-wide">
                <span>Category Name</span>
                <input
                  type="text"
                  value={draftValue}
                  onChange={(event) => onDraftChange(event.target.value)}
                />
              </label>
            </div>

            <div className="profile-action-row">
              <button
                className="secondary-link secondary-button"
                type="button"
                onClick={onCancelEdit}
              >
                Cancel
              </button>
              <button
                className="primary-link admin-action-button"
                type="button"
                onClick={onSave}
              >
                Save Category
              </button>
            </div>
          </article>
        ) : null}

        {categories.length > 0 ? (
          <div className="association-gallery-grid">
            {categories.map((category) => (
              <article key={category} className="association-gallery-card">
                <div className="association-gallery-copy">
                  <span className="mini-label">Category</span>
                  <h3>{category}</h3>
                  <p>
                    {(subCategoryMap[category] ?? []).length} sub categories
                    mapped under this category.
                  </p>
                </div>
                <div className="record-actions">
                  <button
                    className="secondary-link secondary-button"
                    type="button"
                    onClick={() => onStartEdit(category)}
                  >
                    Edit
                  </button>
                  <button
                    className="secondary-link secondary-button danger-button"
                    type="button"
                    onClick={() => onDelete(category)}
                  >
                    Delete
                  </button>
                </div>
              </article>
            ))}
          </div>
        ) : (
          <article className="association-profile-card committee-empty-card">
            <span className="mini-label">Category</span>
            <h3>No vendor categories yet</h3>
            <p>
              Add your first category to begin structuring vendor registration.
            </p>
          </article>
        )}
      </section>
    </section>
  );
}

function VendorSubCategoryPanel({
  categories,
  subCategoryMap,
  selectedCategory,
  editingValue,
  draftValue,
  errorMessage,
  successMessage,
  onSelectCategory,
  onStartEdit,
  onDraftChange,
  onCancelEdit,
  onSave,
  onDelete,
}) {
  const items = selectedCategory
    ? (subCategoryMap[selectedCategory] ?? [])
    : [];

  return (
    <section className="association-tab-section">
      <section className="association-profile-stack">
        <article className="association-profile-card">
          <div className="panel-topline">
            <div>
              <span className="mini-label">Vendor Sub Category</span>
              <h2>Sub Category Master</h2>
            </div>
            <button
              className="primary-link admin-action-button"
              type="button"
              onClick={() => onStartEdit("")}
            >
              Add Sub Category
            </button>
          </div>
          <div className="profile-form-grid">
            <label className="profile-field profile-field-wide">
              <span>Main Category</span>
              <select
                value={selectedCategory}
                onChange={(event) => onSelectCategory(event.target.value)}
              >
                <option value="">Select category</option>
                {categories.map((category) => (
                  <option key={category} value={category}>
                    {category}
                  </option>
                ))}
              </select>
            </label>
          </div>
          {errorMessage ? (
            <p className="form-error-message">{errorMessage}</p>
          ) : null}
          {successMessage ? (
            <p className="form-success-message">{successMessage}</p>
          ) : null}
        </article>

        {editingValue !== null ? (
          <article className="association-profile-card">
            <div className="panel-topline">
              <h3>{editingValue ? "Edit Sub Category" : "Add Sub Category"}</h3>
              <span className="mini-label">Mapped To Category</span>
            </div>

            <div className="profile-form-grid">
              <label className="profile-field">
                <span>Main Category</span>
                <select
                  value={selectedCategory}
                  onChange={(event) => onSelectCategory(event.target.value)}
                >
                  <option value="">Select category</option>
                  {categories.map((category) => (
                    <option key={category} value={category}>
                      {category}
                    </option>
                  ))}
                </select>
              </label>
              <label className="profile-field">
                <span>Sub Category Name</span>
                <input
                  type="text"
                  value={draftValue}
                  onChange={(event) => onDraftChange(event.target.value)}
                />
              </label>
            </div>

            <div className="profile-action-row">
              <button
                className="secondary-link secondary-button"
                type="button"
                onClick={onCancelEdit}
              >
                Cancel
              </button>
              <button
                className="primary-link admin-action-button"
                type="button"
                onClick={onSave}
              >
                Save Sub Category
              </button>
            </div>
          </article>
        ) : null}

        {selectedCategory ? (
          items.length > 0 ? (
            <div className="association-gallery-grid">
              {items.map((item) => (
                <article
                  key={`${selectedCategory}-${item}`}
                  className="association-gallery-card"
                >
                  <div className="association-gallery-copy">
                    <span className="mini-label">{selectedCategory}</span>
                    <h3>{item}</h3>
                    <p>
                      Linked to the selected main category and available for
                      vendor registration.
                    </p>
                  </div>
                  <div className="record-actions">
                    <button
                      className="secondary-link secondary-button"
                      type="button"
                      onClick={() => onStartEdit(item)}
                    >
                      Edit
                    </button>
                    <button
                      className="secondary-link secondary-button danger-button"
                      type="button"
                      onClick={() => onDelete(item)}
                    >
                      Delete
                    </button>
                  </div>
                </article>
              ))}
            </div>
          ) : (
            <article className="association-profile-card committee-empty-card">
              <span className="mini-label">{selectedCategory}</span>
              <h3>No sub categories yet</h3>
              <p>
                Add a sub category for the selected main category to continue
                configuring the vendor master.
              </p>
            </article>
          )
        ) : (
          <article className="association-profile-card committee-empty-card">
            <span className="mini-label">Sub Category</span>
            <h3>Select a main category first</h3>
            <p>
              Choose a category above to fetch and manage its sub categories.
            </p>
          </article>
        )}
      </section>
    </section>
  );
}

function VendorStatusPanel({
  items,
  selectedIds,
  searchQuery,
  selectedVendor,
  reviewForm,
  isSaving,
  approvalError,
  onSearchChange,
  onToggleSelect,
  onToggleSelectAll,
  onSelectVendor,
  onReviewFieldChange,
  onReviewFileChange,
  onApplyBulkDecision,
  onApproveOne,
  onRejectOne,
  planOptions,
  paymentModeOptions,
}) {
  const allSelected = items.length > 0 && selectedIds.length === items.length;

  return (
    <article className="admin-access-panel">
      <div className="panel-topline">
        <h2>Vendor Registration Requests</h2>
        <span className="mini-label">Approve Or Reject</span>
      </div>

      <div className="admin-member-toolbar">
        <div className="search-wrap admin-member-search">
          <input
            className="search-input"
            type="search"
            placeholder="Search vendor, company, category..."
            value={searchQuery}
            onChange={(event) => onSearchChange(event.target.value)}
          />
        </div>
        <label className="selection-chip">
          <input
            type="checkbox"
            checked={allSelected}
            onChange={onToggleSelectAll}
            disabled={isSaving}
          />
          <span>Select filtered</span>
        </label>
        <button
          className="secondary-link secondary-button"
          type="button"
          onClick={() => onApplyBulkDecision("APPROVED")}
          disabled={isSaving}
        >
          Approve Selected Individually
        </button>
        <button
          className="secondary-link secondary-button danger-button"
          type="button"
          onClick={() => onApplyBulkDecision("CANCELLED")}
          disabled={isSaving}
        >
          Reject Selected
        </button>
      </div>

      {approvalError ? (
        <p className="vendor-admin-note">{approvalError}</p>
      ) : null}

      <div className="member-table-wrap">
        <table className="member-table">
          <thead>
            <tr>
              <th>Select</th>
              <th>Vendor</th>
              <th>Category</th>
              <th>Mobile</th>
              <th>Email</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {items.map((vendor) => (
              <tr key={vendor.id}>
                <td>
                  <input
                    type="checkbox"
                    checked={selectedIds.includes(vendor.id)}
                    onChange={() => onToggleSelect(vendor.id)}
                    disabled={isSaving}
                  />
                </td>
                <td>
                  <div className="member-table-contact">
                    <strong>{vendor.name}</strong>
                    <span>{vendor.company}</span>
                  </div>
                </td>
                <td>
                  <div className="member-table-contact">
                    <span>{vendor.category || "Uncategorized"}</span>
                    <span>{vendor.vendorType || "No sub category"}</span>
                  </div>
                </td>
                <td>{vendor.phone || "--"}</td>
                <td>{vendor.email || "--"}</td>
                <td>
                  <span className="access-status-chip">
                    {vendor.appAccessStatus}
                  </span>
                </td>
                <td>
                  <div className="record-actions">
                    <button
                      className="secondary-link secondary-button"
                      type="button"
                      onClick={() => onSelectVendor(vendor.id)}
                      disabled={isSaving}
                    >
                      Review
                    </button>
                    <button
                      className="secondary-link secondary-button"
                      type="button"
                      onClick={() => onApproveOne(vendor.id)}
                      disabled={isSaving}
                    >
                      Approve With Details
                    </button>
                    <button
                      className="secondary-link secondary-button danger-button"
                      type="button"
                      onClick={() => onRejectOne(vendor.id)}
                      disabled={isSaving}
                    >
                      Quick Reject
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {items.length === 0 ? (
        <article className="association-empty-state">
          <span className="mini-label">No Requests</span>
          <h2>No vendor registration requests match the current filter.</h2>
          <p>
            New pending vendor registrations will appear here for admin review.
          </p>
        </article>
      ) : null}

      {selectedVendor ? (
        <article className="association-profile-card">
          <div className="panel-topline">
            <div>
              <span className="mini-label">Admin Decision Form</span>
              <h3>{selectedVendor.company}</h3>
            </div>
            <span className="access-status-chip">
              {selectedVendor.appAccessStatus}
            </span>
          </div>

          <div className="profile-form-grid">
            <label className="profile-field">
              <span>Plan Name *</span>
              <select
                value={reviewForm.planName}
                onChange={(event) =>
                  onReviewFieldChange("planName", event.target.value)
                }
                disabled={isSaving}
              >
                <option value="">Select Plan</option>
                {planOptions.map((plan) => (
                  <option key={plan} value={plan}>
                    {plan}
                  </option>
                ))}
              </select>
            </label>
            <label className="profile-field">
              <span>Membership Plan</span>
              <input
                type="text"
                value={reviewForm.membershipPlan}
                onChange={(event) =>
                  onReviewFieldChange("membershipPlan", event.target.value)
                }
                disabled={isSaving}
              />
            </label>
            <label className="profile-field">
              <span>Opening Time</span>
              <input
                type="time"
                value={reviewForm.openingTime}
                onChange={(event) =>
                  onReviewFieldChange("openingTime", event.target.value)
                }
                disabled={isSaving}
              />
            </label>
            <label className="profile-field">
              <span>Closing Time</span>
              <input
                type="time"
                value={reviewForm.closingTime}
                onChange={(event) =>
                  onReviewFieldChange("closingTime", event.target.value)
                }
                disabled={isSaving}
              />
            </label>
            <label className="profile-field">
              <span>Payment Amount</span>
              <input
                type="text"
                value={reviewForm.paymentAmount}
                onChange={(event) =>
                  onReviewFieldChange("paymentAmount", event.target.value)
                }
                disabled={isSaving}
              />
            </label>
            <label className="profile-field">
              <span>GST Number</span>
              <input
                type="text"
                value={reviewForm.gstNumber}
                onChange={(event) =>
                  onReviewFieldChange("gstNumber", event.target.value)
                }
                disabled={isSaving}
              />
            </label>
            <label className="profile-field">
              <span>Start Date *</span>
              <input
                type="date"
                value={reviewForm.onboardingStartAt}
                onChange={(event) =>
                  onReviewFieldChange("onboardingStartAt", event.target.value)
                }
                disabled={isSaving}
              />
            </label>
            <label className="profile-field">
              <span>End Date *</span>
              <input
                type="date"
                value={reviewForm.onboardingEndAt}
                onChange={(event) =>
                  onReviewFieldChange("onboardingEndAt", event.target.value)
                }
                disabled={isSaving}
              />
            </label>
            <label className="profile-field">
              <span>Payment Due</span>
              <input
                type="date"
                value={reviewForm.paymentDueDate}
                onChange={(event) =>
                  onReviewFieldChange("paymentDueDate", event.target.value)
                }
                disabled={isSaving}
              />
            </label>
            <label className="profile-field">
              <span>Payment Mode *</span>
              <select
                value={reviewForm.paymentMode}
                onChange={(event) =>
                  onReviewFieldChange("paymentMode", event.target.value)
                }
                disabled={isSaving}
              >
                {paymentModeOptions.map((mode) => (
                  <option key={mode} value={mode}>
                    {mode}
                  </option>
                ))}
              </select>
            </label>
            <label className="profile-field">
              <span>Bank Name *</span>
              <input
                type="text"
                value={reviewForm.bankName}
                onChange={(event) =>
                  onReviewFieldChange("bankName", event.target.value)
                }
                disabled={isSaving}
              />
            </label>
            <label className="profile-field">
              <span>Transaction ID *</span>
              <input
                type="text"
                value={reviewForm.transactionId}
                onChange={(event) =>
                  onReviewFieldChange("transactionId", event.target.value)
                }
                disabled={isSaving}
              />
            </label>
            <label className="profile-field">
              <span>ID Proof</span>
              <input
                type="file"
                onChange={(event) =>
                  onReviewFileChange("idProof", event.target.files?.[0] ?? null)
                }
                disabled={isSaving}
              />
            </label>
            <label className="profile-field">
              <span>Location Proof</span>
              <input
                type="file"
                onChange={(event) =>
                  onReviewFileChange(
                    "locationProof",
                    event.target.files?.[0] ?? null,
                  )
                }
                disabled={isSaving}
              />
            </label>
            <label className="profile-field">
              <span>Company Profile / Brochure</span>
              <input
                type="file"
                onChange={(event) =>
                  onReviewFileChange(
                    "companyBrochure",
                    event.target.files?.[0] ?? null,
                  )
                }
                disabled={isSaving}
              />
            </label>
            <label className="profile-field">
              <span>Profile Photo</span>
              <input
                type="file"
                accept="image/*"
                onChange={(event) =>
                  onReviewFileChange(
                    "profilePhoto",
                    event.target.files?.[0] ?? null,
                  )
                }
                disabled={isSaving}
              />
            </label>
            <label className="profile-field">
              <span>Visiting Card</span>
              <input
                type="file"
                accept="image/*,.pdf"
                onChange={(event) =>
                  onReviewFileChange(
                    "visitingCard",
                    event.target.files?.[0] ?? null,
                  )
                }
                disabled={isSaving}
              />
            </label>
            <label className="profile-field">
              <span>Is Restaurant?</span>
              <div className="inline-choice-row">
                <label className="inline-choice-option">
                  <input
                    type="radio"
                    name="status-isRestaurant"
                    checked={reviewForm.isRestaurant === true}
                    onChange={() => onReviewFieldChange("isRestaurant", true)}
                    disabled={isSaving}
                  />
                  <span>Yes</span>
                </label>
                <label className="inline-choice-option">
                  <input
                    type="radio"
                    name="status-isRestaurant"
                    checked={reviewForm.isRestaurant === false}
                    onChange={() => onReviewFieldChange("isRestaurant", false)}
                    disabled={isSaving}
                  />
                  <span>No</span>
                </label>
              </div>
            </label>
            <label className="profile-field profile-field-wide">
              <span>Payment Description</span>
              <textarea
                rows="3"
                value={reviewForm.paymentDescription}
                onChange={(event) =>
                  onReviewFieldChange("paymentDescription", event.target.value)
                }
                disabled={isSaving}
              />
            </label>
            <label className="profile-field profile-field-wide">
              <span>Google Location</span>
              <input
                type="text"
                value={reviewForm.googleLocation}
                onChange={(event) =>
                  onReviewFieldChange("googleLocation", event.target.value)
                }
                disabled={isSaving}
              />
            </label>
          </div>

          <div className="profile-action-row">
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={() => onApproveOne(selectedVendor.id)}
              disabled={isSaving}
            >
              {isSaving ? "Saving..." : "Save And Approve"}
            </button>
            <button
              className="secondary-link secondary-button danger-button"
              type="button"
              onClick={() => onRejectOne(selectedVendor.id)}
              disabled={isSaving}
            >
              {isSaving ? "Saving..." : "Save And Reject"}
            </button>
          </div>
        </article>
      ) : null}
    </article>
  );
}

function VendorArenaContent({
  activeTab,
  items,
  formData,
  categories,
  subCategories,
  countryOptions,
  stateOptions,
  cityOptions,
  phoneCodeOptions,
  planOptions,
  paymentModeOptions,
  newCategory,
  filterState,
  onFormChange,
  onFileChange,
  onFilterChange,
  onNewCategoryChange,
  onAddCategory,
  onReset,
  onEditVendor,
  onSubmit,
  errorMessage,
  successMessage,
  isSaving,
}) {
  const filteredItems = items.filter((vendor) => {
    const matchesName =
      !filterState.name ||
      `${vendor.name} ${vendor.company}`
        .toLowerCase()
        .includes(filterState.name.toLowerCase());
    const matchesCategory =
      !filterState.category || vendor.category === filterState.category;
    const matchesCity = !filterState.city || vendor.city === filterState.city;
    return matchesName && matchesCategory && matchesCity;
  });

  if (activeTab === "Registration") {
    return (
      <section className="association-tab-section">
        <div className="admin-access-panel">
          <div className="panel-topline">
            <h2>Vendor Filters</h2>
            <span className="mini-label">Category, Name, City</span>
          </div>

          <div className="admin-member-toolbar">
            <div className="search-wrap admin-member-search">
              <input
                className="search-input"
                type="search"
                placeholder="Search vendor name or company..."
                value={filterState.name}
                onChange={(event) => onFilterChange("name", event.target.value)}
              />
            </div>
            <label className="content-control-field">
              <span>Category</span>
              <select
                value={filterState.category}
                onChange={(event) =>
                  onFilterChange("category", event.target.value)
                }
              >
                <option value="">All Categories</option>
                {categories.map((category) => (
                  <option key={category} value={category}>
                    {category}
                  </option>
                ))}
              </select>
            </label>
            <label className="content-control-field">
              <span>City</span>
              <select
                value={filterState.city}
                onChange={(event) => onFilterChange("city", event.target.value)}
              >
                <option value="">All Cities</option>
                {[...new Set(items.map((vendor) => vendor.city))].map(
                  (city) => (
                    <option key={city} value={city}>
                      {city}
                    </option>
                  ),
                )}
              </select>
            </label>
          </div>
        </div>

        <VendorStatusGrid
          items={filteredItems}
          isSaving={isSaving}
          onEdit={onEditVendor}
        />
        <VendorRegistrationTable items={filteredItems} onEdit={onEditVendor} />
      </section>
    );
  }

  if (activeTab === "Membership & Payment") {
    return (
      <section className="association-tab-section">
        <VendorPaymentGrid items={filteredItems} />
        <VendorPaymentTable items={filteredItems} />
      </section>
    );
  }

  return (
    <section className="association-tab-section">
      <VendorRegistrationForm
        formData={formData}
        onChange={onFormChange}
        categories={categories}
        subCategories={subCategories}
        countryOptions={countryOptions}
        stateOptions={stateOptions}
        cityOptions={cityOptions}
        phoneCodeOptions={phoneCodeOptions}
        planOptions={planOptions}
        paymentModeOptions={paymentModeOptions}
        newCategory={newCategory}
        onFileChange={onFileChange}
        onNewCategoryChange={onNewCategoryChange}
        onAddCategory={onAddCategory}
        onReset={onReset}
        onSubmit={onSubmit}
        errorMessage={errorMessage}
        successMessage={successMessage}
        isSaving={isSaving}
      />
    </section>
  );
}

function TimelinePanel({
  formData,
  posts,
  memberOptions,
  vendorOptions,
  associationLabel,
  isSaving,
  feedback,
  onChange,
  onFileChange,
  onSubmit,
}) {
  return (
    <section className="association-tab-section member-media-layout">
      <article className="member-media-composer">
        <div className="panel-topline">
          <h2>Create Timeline Post</h2>
          <span className="mini-label">Independent Ad Timeline</span>
        </div>

        <div className="profile-form-grid">
          <label className="profile-field">
            <span>Source Type</span>
            <select
              value={formData.sourceType}
              onChange={(event) => onChange("sourceType", event.target.value)}
            >
              <option value="ASSOCIATION">Association</option>
              <option value="MEMBER">Member</option>
              <option value="VENDOR">Vendor</option>
            </select>
          </label>
          {formData.sourceType === "ASSOCIATION" ? (
            <label className="profile-field">
              <span>Association</span>
              <input type="text" value={associationLabel} readOnly />
            </label>
          ) : null}
          {formData.sourceType === "MEMBER" ? (
            <label className="profile-field">
              <span>Select Member</span>
              <select
                value={formData.memberId}
                onChange={(event) => onChange("memberId", event.target.value)}
              >
                <option value="">Select member</option>
                {memberOptions.map((option) => (
                  <option key={option.id} value={option.id}>
                    {option.label}
                  </option>
                ))}
              </select>
            </label>
          ) : null}
          {formData.sourceType === "VENDOR" ? (
            <label className="profile-field">
              <span>Select Vendor</span>
              <select
                value={formData.vendorId}
                onChange={(event) => onChange("vendorId", event.target.value)}
              >
                <option value="">Select vendor</option>
                {vendorOptions.map((option) => (
                  <option key={option.id} value={option.id}>
                    {option.label}
                  </option>
                ))}
              </select>
            </label>
          ) : null}
          <label className="profile-field">
            <span>Posted By</span>
            <input
              type="text"
              value={formData.postedBy}
              onChange={(event) => onChange("postedBy", event.target.value)}
            />
          </label>
          <label className="profile-field profile-field-wide">
            <span>Post Copy *</span>
            <textarea
              rows="4"
              value={formData.caption}
              onChange={(event) => onChange("caption", event.target.value)}
            />
          </label>
          <label className="profile-field">
            <span>Contact Number</span>
            <input
              type="text"
              value={formData.contactNumber}
              onChange={(event) =>
                onChange("contactNumber", event.target.value)
              }
            />
          </label>
          <label className="profile-field">
            <span>Landing Page Website</span>
            <input
              type="text"
              value={formData.landingPageUrl}
              onChange={(event) =>
                onChange("landingPageUrl", event.target.value)
              }
            />
          </label>
          <label className="profile-field">
            <span>YouTube Link</span>
            <input
              type="text"
              value={formData.youtubeUrl}
              onChange={(event) => onChange("youtubeUrl", event.target.value)}
            />
          </label>
          <label className="profile-field">
            <span>Facebook Page</span>
            <input
              type="text"
              value={formData.facebookUrl}
              onChange={(event) => onChange("facebookUrl", event.target.value)}
            />
          </label>
          <label className="profile-field">
            <span>Post Picture</span>
            <input
              type="file"
              accept="image/*"
              onChange={(event) =>
                onFileChange("imageFile", event.target.files?.[0] ?? null)
              }
            />
          </label>
          <label className="profile-field">
            <span>PDF Brochure</span>
            <input
              type="file"
              accept="application/pdf"
              onChange={(event) =>
                onFileChange("brochureFile", event.target.files?.[0] ?? null)
              }
            />
          </label>
        </div>

        <div className="profile-action-row">
          <button
            className="primary-link admin-action-button"
            type="button"
            onClick={onSubmit}
            disabled={isSaving}
          >
            {isSaving ? "Saving Timeline..." : "Save Timeline Post"}
          </button>
        </div>
        {feedback ? <p className="member-access-feedback">{feedback}</p> : null}
      </article>

      <section className="member-content-grid">
        {posts.map((post) => (
          <article key={post.id} className="timeline-feed-card">
            <div
              className="timeline-feed-header"
              style={{
                background: `linear-gradient(135deg, ${getTimelineSourceTheme(post.sourceType).start}, ${getTimelineSourceTheme(post.sourceType).end})`,
              }}
            >
              <div className="timeline-feed-avatar">
                <span>{getInitialsLabel(post.sourceName || post.postedBy)}</span>
              </div>
              <div className="timeline-feed-header-copy">
                <strong>{post.sourceName}</strong>
                <p>
                  {post.postedBy?.trim()
                    ? `${post.postedBy} • ${post.postedOn}`
                    : post.postedOn}
                </p>
              </div>
            </div>

            <div className="timeline-feed-body">
              <div className="timeline-feed-pills">
                <span className="timeline-feed-pill">{post.sourceType}</span>
                <span className="timeline-feed-pill">{post.status}</span>
              </div>

              <p className="timeline-feed-caption">{post.caption}</p>

              {post.imageUrl ? (
                <div className="timeline-feed-visual">
                  <img
                    src={post.imageUrl}
                    alt={post.caption.slice(0, 60) || "Timeline post"}
                  />
                </div>
              ) : null}
            </div>

            <div className="timeline-feed-footer">
              <div className="timeline-feed-actions">
                {post.landingPageUrl ? (
                  <a
                    className="timeline-feed-action"
                    href={post.landingPageUrl}
                    target="_blank"
                    rel="noreferrer"
                  >
                    Website
                  </a>
                ) : null}
                {post.youtubeUrl ? (
                  <a
                    className="timeline-feed-action"
                    href={post.youtubeUrl}
                    target="_blank"
                    rel="noreferrer"
                  >
                    YouTube
                  </a>
                ) : null}
                {post.facebookUrl ? (
                  <a
                    className="timeline-feed-action"
                    href={post.facebookUrl}
                    target="_blank"
                    rel="noreferrer"
                  >
                    Facebook
                  </a>
                ) : null}
                {post.contactNumber ? (
                  <a
                    className="timeline-feed-action"
                    href={`tel:${post.contactNumber}`}
                  >
                    Call
                  </a>
                ) : null}
                {post.brochureUrl ? (
                  <a
                    className="timeline-feed-action"
                    href={post.brochureUrl}
                    target="_blank"
                    rel="noreferrer"
                  >
                    Brochure
                  </a>
                ) : null}
              </div>
              <span className="timeline-feed-arrow">›</span>
            </div>
          </article>
        ))}
        {posts.length === 0 ? (
          <article className="association-empty-state">
            <span className="mini-label">Timeline</span>
            <h2>No timeline posts yet.</h2>
            <p>
              Create the first vendor, member, or association campaign post
              here.
            </p>
          </article>
        ) : null}
      </section>
    </section>
  );
}

function AppBannerPanel({
  formData,
  items,
  vendorOptions,
  isSaving,
  errorMessage,
  onChange,
  onFileChange,
  onSubmit,
}) {
  return (
    <section className="association-tab-section member-media-layout">
      <article className="member-media-composer">
        <div className="panel-topline">
          <h2>Create App Banner</h2>
          <span className="mini-label">Paid Advertisement</span>
        </div>

        <div className="profile-form-grid">
          <label className="profile-field">
            <span>Select Vendor</span>
            <select
              value={formData.vendorId}
              onChange={(event) => onChange("vendorId", event.target.value)}
            >
              <option value="">Select vendor</option>
              {vendorOptions.map((option) => (
                <option key={option.id} value={option.id}>
                  {option.label}
                </option>
              ))}
            </select>
          </label>
          <label className="profile-field">
            <span>Contact Number</span>
            <input
              type="text"
              value={formData.contactNumber}
              onChange={(event) =>
                onChange("contactNumber", event.target.value)
              }
            />
          </label>
          <label className="profile-field profile-field-wide">
            <span>Small Text *</span>
            <textarea
              rows="3"
              value={formData.shortText}
              onChange={(event) => onChange("shortText", event.target.value)}
            />
          </label>
          <label className="profile-field">
            <span>Media Link</span>
            <input
              type="text"
              value={formData.socialMediaUrl}
              onChange={(event) =>
                onChange("socialMediaUrl", event.target.value)
              }
              placeholder="Facebook, Instagram, or other media page"
            />
          </label>
          <label className="profile-field">
            <span>Banner Media</span>
            <input
              type="file"
              accept="image/png,image/jpeg,image/webp"
              onChange={(event) =>
                onFileChange("mediaFile", event.target.files?.[0] ?? null)
              }
            />
            <small>{appBannerMediaRecommendation}</small>
          </label>
          <label className="profile-field">
            <span>PDF Attachment</span>
            <input
              type="file"
              accept="application/pdf"
              onChange={(event) =>
                onFileChange("brochureFile", event.target.files?.[0] ?? null)
              }
            />
            <small>{appBannerPdfRecommendation}</small>
          </label>
        </div>

        {errorMessage ? (
          <p className="form-helper-error">{errorMessage}</p>
        ) : null}

        <div className="profile-action-row">
          <button
            className="primary-link admin-action-button"
            type="button"
            onClick={onSubmit}
            disabled={isSaving}
          >
            {isSaving ? "Saving Banner..." : "Submit Paid Advertisement"}
          </button>
        </div>
      </article>

      <section className="member-content-grid">
        {items.map((item) => (
          <article key={item.id} className="member-content-card">
            <div className="member-content-banner">
              <span>Ad</span>
            </div>
            <div className="member-content-copy">
              <strong>{item.vendorName}</strong>
              <p>{item.shortText}</p>
              <div className="member-content-meta">
                <span>Date: {item.postedOn}</span>
                <span>Status: {item.status}</span>
                <span>Contact: {item.contactNumber || "--"}</span>
              </div>
              {item.mediaUrl ? (
                <div className="association-gallery-visual">
                  {item.mediaType.startsWith("video/") ? (
                    <video src={item.mediaUrl} controls playsInline />
                  ) : (
                    <img
                      src={item.mediaUrl}
                      alt={item.shortText.slice(0, 60) || "App banner"}
                    />
                  )}
                </div>
              ) : null}
              <div className="member-record-details">
                {item.socialMediaUrl ? (
                  <p>
                    Media Link:{" "}
                    <a
                      href={item.socialMediaUrl}
                      target="_blank"
                      rel="noreferrer"
                    >
                      {item.socialMediaUrl}
                    </a>
                  </p>
                ) : null}
                {item.brochureUrl ? (
                  <p>
                    PDF:{" "}
                    <a href={item.brochureUrl} target="_blank" rel="noreferrer">
                      Open attachment
                    </a>
                  </p>
                ) : null}
              </div>
            </div>
          </article>
        ))}
        {items.length === 0 ? (
          <article className="association-empty-state">
            <span className="mini-label">App Banner</span>
            <h2>No app banner ads yet.</h2>
            <p>Submit the first paid advertisement here for admin review.</p>
          </article>
        ) : null}
      </section>
    </section>
  );
}

function EventTimelineCards({ groups = [], onSelectEvent }) {
  if (!groups.length) {
    return (
      <div className="association-record-grid">
        <article className="association-record-card tone-upcoming">
          <div className="association-record-visual">
            <span>Events</span>
          </div>
          <div className="association-record-copy">
            <div className="association-record-topline">
              <em className="carousel-badge">No events yet</em>
            </div>
            <p>
              Create an event or add an event type to start building the events
              desk.
            </p>
          </div>
        </article>
      </div>
    );
  }

  return (
    <div className="association-record-grid">
      {groups.map((group) => (
        <article
          key={group.title}
          className={`association-record-card ${group.tone}`}
        >
          <div className="association-record-visual">
            <span>{group.title.split(" ")[0]}</span>
          </div>
          <div className="association-record-copy">
            <div className="association-record-topline">
              <em className="carousel-badge">{group.title}</em>
            </div>
            {group.items.map((item) => (
              <button
                key={item.id}
                type="button"
                className="event-card-entry"
                onClick={() => onSelectEvent?.(item.id)}
              >
                <strong>{item.title}</strong>
                <p>{item.meta}</p>
              </button>
            ))}
          </div>
        </article>
      ))}
    </div>
  );
}

function EventMasterPanel({ groups = [], eventTypes = [], onSelectEvent }) {
  const totalEvents = groups.reduce(
    (count, group) => count + group.items.length,
    0,
  );
  const pastCount = groups.find((group) => group.title === "Past Events")?.items
    .length ?? 0;
  const currentCount = groups.find(
    (group) => group.title === "Current Events",
  )?.items.length ?? 0;
  const upcomingCount = groups.find(
    (group) => group.title === "Coming Events",
  )?.items.length ?? 0;

  return (
    <section className="association-tab-section">
      <section className="association-header">
        <div>
          <span className="eyebrow">Events Master</span>
          <h1>Live Events Overview</h1>
          <p>
            A backend-driven summary of scheduled events and event types, with
            quick access into the event timeline.
          </p>
        </div>

        <div className="association-header-meta">
          <div className="association-dashboard-grid">
            <article className="association-dashboard-card">
              <strong>{totalEvents}</strong>
              <span>Total Events</span>
            </article>
            <article className="association-dashboard-card">
              <strong>{upcomingCount}</strong>
              <span>Upcoming</span>
            </article>
            <article className="association-dashboard-card">
              <strong>{currentCount}</strong>
              <span>Current</span>
            </article>
            <article className="association-dashboard-card">
              <strong>{eventTypes.length}</strong>
              <span>Event Types</span>
            </article>
          </div>
        </div>
      </section>

      {pastCount > 0 ? (
        <p className="admin-access-helper-copy">
          {pastCount} completed event{pastCount === 1 ? "" : "s"} remain
          available in the timeline archive.
        </p>
      ) : null}

      <EventTimelineCards groups={groups} onSelectEvent={onSelectEvent} />
    </section>
  );
}

function EventCreateForm({
  formData,
  mediaState,
  isSaving = false,
  feedbackMessage = "",
  onChange,
  onMediaChange,
  eventTypes,
  onSave,
  onCancel,
}) {
  return (
    <section className="member-table-panel">
      <div className="panel-topline">
        <h2>{formData.id ? "Edit Event" : "Create New Event"}</h2>
        <span className="mini-label">Event Setup</span>
      </div>

      <div className="profile-form-grid">
        <label className="profile-field">
          <span>Event Name</span>
          <input
            type="text"
            value={formData.name}
            onChange={(event) => onChange("name", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Type of Event</span>
          <select
            value={formData.type}
            onChange={(event) => onChange("type", event.target.value)}
          >
            <option value="">Select event type</option>
            {eventTypes.map((eventType) => (
              <option key={eventType.id} value={eventType.title}>
                {eventType.title}
              </option>
            ))}
          </select>
        </label>
        <label className="profile-field">
          <span>Audience</span>
          <select
            value={formData.audience}
            onChange={(event) => onChange("audience", event.target.value)}
          >
            <option value="">Select audience</option>
            <option value="Primary Members">Primary Members</option>
            <option value="Associate Members">Associate Members</option>
            <option value="Guest">Guest</option>
            <option value="Open for All">Open for All</option>
          </select>
        </label>
        <label className="profile-field">
          <span>Entry Type</span>
          <select
            value={formData.entryType}
            onChange={(event) => onChange("entryType", event.target.value)}
          >
            <option value="">Select entry type</option>
            <option value="Free">Free</option>
            <option value="Paid">Paid</option>
          </select>
        </label>
        <label className="profile-field">
          <span>Charges for Entry</span>
          <input
            type="text"
            value={formData.entryCharges}
            onChange={(event) => onChange("entryCharges", event.target.value)}
            placeholder="Rs. 0 or ticket amount"
          />
        </label>
        <label className="profile-field">
          <span>Charges for Participation</span>
          <input
            type="text"
            value={formData.participationCharges}
            onChange={(event) =>
              onChange("participationCharges", event.target.value)
            }
            placeholder="Rs. 0 or participation fee"
          />
        </label>
        <label className="profile-field">
          <span>Event Date</span>
          <input
            type="date"
            value={formData.date}
            onChange={(event) => onChange("date", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Venue</span>
          <input
            type="text"
            value={formData.venue}
            onChange={(event) => onChange("venue", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Start Time</span>
          <input
            type="time"
            value={formData.startTime}
            onChange={(event) => onChange("startTime", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>End Time</span>
          <input
            type="time"
            value={formData.endTime}
            onChange={(event) => onChange("endTime", event.target.value)}
          />
        </label>
        <label className="profile-field profile-field-wide">
          <span>Event Summary</span>
          <textarea
            rows="3"
            value={formData.summary}
            onChange={(event) => onChange("summary", event.target.value)}
          />
        </label>
        <label className="profile-field profile-field-wide">
          <span>Event Banner Picture</span>
          <input
            type="file"
            accept="image/*"
            onChange={(event) =>
              onMediaChange("imageFile", event.target.files?.[0] ?? null)
            }
          />
        </label>
        <label className="profile-field profile-field-wide">
          <span>Event Promo Video</span>
          <input
            type="file"
            accept="video/*"
            onChange={(event) =>
              onMediaChange("videoFile", event.target.files?.[0] ?? null)
            }
          />
        </label>
      </div>

      <div className="content-member-selector">
        {mediaState.imageName ? (
          <span className="content-member-chip active">
            Image: {mediaState.imageName}
          </span>
        ) : null}
        {mediaState.videoName ? (
          <span className="content-member-chip active">
            Video: {mediaState.videoName}
          </span>
        ) : null}
        {mediaState.bannerUrl && !mediaState.imageFile ? (
          <span className="content-member-chip">Current banner attached</span>
        ) : null}
        {mediaState.promoVideoUrl && !mediaState.videoFile ? (
          <span className="content-member-chip">
            Current promo video attached
          </span>
        ) : null}
      </div>

      <div className="profile-action-row">
        {feedbackMessage ? (
          <p className="admin-access-feedback">{feedbackMessage}</p>
        ) : null}
        {formData.id ? (
          <button
            className="secondary-link secondary-button"
            type="button"
            onClick={onCancel}
            disabled={isSaving}
          >
            Cancel Edit
          </button>
        ) : null}
        <button
          className="primary-link admin-action-button"
          type="button"
          onClick={onSave}
          disabled={isSaving}
        >
          {isSaving
            ? "Saving..."
            : formData.id
              ? "Save Event Changes"
              : "Save Event Draft"}
        </button>
      </div>
    </section>
  );
}

function EventTypeManager({
  items,
  draftType,
  isSaving,
  feedbackMessage,
  onDraftChange,
  onAddType,
  onUpdateType,
}) {
  return (
    <section className="association-tab-section">
      <section className="member-table-panel">
        <div className="panel-topline">
          <h2>Type of Event</h2>
          <span className="mini-label">Add or Modify</span>
        </div>

        <div className="admin-member-toolbar">
          <label className="content-control-field admin-member-search">
            <span>New Event Type</span>
            <input
              type="text"
              value={draftType.title}
              placeholder="Add a new event type"
              onChange={(event) => onDraftChange("title", event.target.value)}
            />
          </label>
          <label className="content-control-field admin-member-search">
            <span>Description</span>
            <input
              type="text"
              value={draftType.meta}
              placeholder="Short description for this type"
              onChange={(event) => onDraftChange("meta", event.target.value)}
            />
          </label>
          <button
            className="secondary-link secondary-button"
            type="button"
            onClick={onAddType}
            disabled={isSaving}
          >
            {isSaving ? "Saving..." : "Add Type"}
          </button>
        </div>

        {feedbackMessage ? (
          <p className="admin-access-feedback">{feedbackMessage}</p>
        ) : null}

        <div className="member-content-grid">
          {items.map((item) => (
            <article key={item.id} className="member-content-card">
              <div className="member-content-banner">
                <span>{item.badge}</span>
              </div>
              <div className="member-content-copy">
                <label className="content-control-field">
                  <span>Type Name</span>
                  <input
                    type="text"
                    value={item.title}
                    onChange={(event) =>
                      onUpdateType(item.id, "title", event.target.value)
                    }
                    disabled={isSaving}
                  />
                </label>
                <label className="content-control-field">
                  <span>Description</span>
                  <input
                    type="text"
                    value={item.meta}
                    onChange={(event) =>
                      onUpdateType(item.id, "meta", event.target.value)
                    }
                    disabled={isSaving}
                  />
                </label>
              </div>
            </article>
          ))}
        </div>
      </section>
    </section>
  );
}

function EventsArenaContent({
  activeTab,
  formData,
  mediaState,
  events,
  eventTimelineGroups,
  savingEventId,
  feedbackMessage,
  onFormChange,
  onMediaChange,
  onSaveEvent,
  onCancelEventEdit,
  onEditEvent,
  eventTypes,
  eventTypeDraft,
  onEventTypeDraftChange,
  onAddEventType,
  onUpdateEventType,
}) {
  if (activeTab === "Master") {
    return (
      <EventMasterPanel
        groups={eventTimelineGroups}
        eventTypes={eventTypes}
        onSelectEvent={onEditEvent}
      />
    );
  }

  if (activeTab === "Type of Event") {
    return (
      <EventTypeManager
        items={eventTypes}
        draftType={eventTypeDraft}
        isSaving={isSavingEventType}
        feedbackMessage={eventTypeFeedback}
        onDraftChange={onEventTypeDraftChange}
        onAddType={onAddEventType}
        onUpdateType={onUpdateEventType}
      />
    );
  }

  if (activeTab === "Event") {
    return (
      <section className="association-tab-section">
        <EventTimelineCards
          groups={eventTimelineGroups}
          onSelectEvent={onEditEvent}
        />
      </section>
    );
  }

  return (
    <section className="association-tab-section">
      <EventCreateForm
        formData={formData}
        mediaState={mediaState}
        isSaving={Boolean(savingEventId)}
        feedbackMessage={feedbackMessage}
        eventTypes={eventTypes}
        onChange={onFormChange}
        onMediaChange={onMediaChange}
        onSave={onSaveEvent}
        onCancel={onCancelEventEdit}
      />
    </section>
  );
}

function AdminEventAccessPanel({
  items,
  searchQuery,
  formData,
  mediaState,
  savingEventId,
  feedbackMessage,
  eventTypes,
  onSearchChange,
  onEditEvent,
  onDeleteEvent,
  onFormChange,
  onMediaChange,
  onSaveEvent,
  onCancelEventEdit,
}) {
  return (
    <article className="admin-access-panel">
      <div className="panel-topline">
        <h2>Event Access Controls</h2>
        <span className="mini-label">Search, Edit, Delete</span>
      </div>

      <div className="admin-member-toolbar">
        <div className="search-wrap admin-member-search">
          <input
            className="search-input"
            type="search"
            placeholder="Search event name, type, venue, date..."
            value={searchQuery}
            onChange={(event) => onSearchChange(event.target.value)}
          />
        </div>
      </div>

      <div className="member-table-wrap">
        <table className="member-table">
          <thead>
            <tr>
              <th>Event</th>
              <th>Type</th>
              <th>Date</th>
              <th>Venue</th>
              <th>Audience</th>
              <th>Entry</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {items.map((eventItem) => (
              <tr key={eventItem.id}>
                <td>{eventItem.name}</td>
                <td>{eventItem.type || "Not set"}</td>
                <td>{eventItem.date || "Not set"}</td>
                <td>{eventItem.venue || "Not set"}</td>
                <td>{eventItem.audience || "Not set"}</td>
                <td>{eventItem.entryType || "Not set"}</td>
                <td>
                  <div className="member-master-actions">
                    <button
                      className="secondary-link secondary-button table-button"
                      type="button"
                      onClick={() => onEditEvent(eventItem.id)}
                      disabled={Boolean(savingEventId)}
                    >
                      Edit
                    </button>
                    <button
                      className="secondary-link secondary-button danger-button table-button"
                      type="button"
                      onClick={() => onDeleteEvent(eventItem.id)}
                      disabled={Boolean(savingEventId)}
                    >
                      {savingEventId === eventItem.id ? "Deleting..." : "Delete"}
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {items.length === 0 ? (
              <tr>
                <td colSpan="7">No events match the current search.</td>
              </tr>
            ) : null}
          </tbody>
        </table>
      </div>

      <EventCreateForm
        formData={formData}
        mediaState={mediaState}
        isSaving={Boolean(savingEventId)}
        feedbackMessage={feedbackMessage}
        eventTypes={eventTypes}
        onChange={onFormChange}
        onMediaChange={onMediaChange}
        onSave={onSaveEvent}
        onCancel={onCancelEventEdit}
      />
    </article>
  );
}

function AdminTimelineAccessPanel({
  items,
  searchQuery,
  edits,
  isSaving,
  feedbackMessage,
  onSearchChange,
  onUpdatePost,
  onSaveTimelineAccessChanges,
}) {
  return (
    <article className="admin-access-panel">
      <div className="panel-topline">
        <h2>Timeline Access Controls</h2>
        <span className="mini-label">Approve, Reject, Hold</span>
      </div>

      <div className="admin-member-toolbar">
        <div className="search-wrap admin-member-search">
          <input
            className="search-input"
            type="search"
            placeholder="Search caption, vendor, posted by..."
            value={searchQuery}
            onChange={(event) => onSearchChange(event.target.value)}
          />
        </div>
      </div>

      <div className="member-content-grid">
        {items.map((post) => (
          <article key={post.id} className="member-content-card">
            <div className="member-content-banner">
              <span>{post.sourceType}</span>
            </div>
            <div className="member-content-copy">
              <strong>{post.sourceName}</strong>
              <p>{post.caption}</p>
              <div className="member-content-meta">
                <span>Posted By: {post.postedBy || post.sourceName}</span>
                <span>Date: {post.postedOn}</span>
                <span>Status: {edits[post.id]?.status ?? post.status}</span>
                <span>Contact: {post.contactNumber || "--"}</span>
              </div>
              {post.imageUrl ? (
                <div className="association-gallery-visual">
                  <img
                    src={post.imageUrl}
                    alt={post.caption.slice(0, 60) || "Timeline post"}
                  />
                </div>
              ) : null}
              <div className="member-content-controls">
                <label className="content-control-field">
                  <span>Status</span>
                  <select
                    value={edits[post.id]?.status ?? post.status}
                    onChange={(event) =>
                      onUpdatePost(post.id, "status", event.target.value)
                    }
                  >
                    <option value="Approved">Approved</option>
                    <option value="Rejected">Rejected</option>
                    <option value="Hold">Hold</option>
                    <option value="Pending Review">Pending Review</option>
                  </select>
                </label>
                <label className="content-control-field">
                  <span>Display Start</span>
                  <input
                    type="date"
                    value={edits[post.id]?.displayStart ?? post.displayStart}
                    onChange={(event) =>
                      onUpdatePost(post.id, "displayStart", event.target.value)
                    }
                  />
                </label>
                <label className="content-control-field">
                  <span>Display End</span>
                  <input
                    type="date"
                    value={edits[post.id]?.displayEnd ?? post.displayEnd}
                    onChange={(event) =>
                      onUpdatePost(post.id, "displayEnd", event.target.value)
                    }
                  />
                </label>
              </div>
            </div>
          </article>
        ))}
        {items.length === 0 ? (
          <article className="association-empty-state">
            <span className="mini-label">No Timeline Posts</span>
            <h2>No timeline posts match the current search.</h2>
            <p>Create timeline posts first, then manage approval here.</p>
          </article>
        ) : null}
      </div>

      <div className="profile-action-row">
        {feedbackMessage ? (
          <p className="admin-access-feedback">{feedbackMessage}</p>
        ) : null}
        <button
          className="primary-link admin-action-button"
          type="button"
          onClick={onSaveTimelineAccessChanges}
          disabled={isSaving}
        >
          {isSaving ? "Saving..." : "Save Timeline Access Changes"}
        </button>
      </div>
    </article>
  );
}

function AdminAppBannerAccessPanel({
  items,
  searchQuery,
  edits,
  isSaving,
  feedbackMessage,
  onSearchChange,
  onUpdateBanner,
  onSaveAppBannerAccessChanges,
}) {
  return (
    <article className="admin-access-panel">
      <div className="panel-topline">
        <h2>App Banner Submissions</h2>
        <span className="mini-label">Approve, Payment, Sequence</span>
      </div>

      <div className="admin-member-toolbar">
        <div className="search-wrap admin-member-search">
          <input
            className="search-input"
            type="search"
            placeholder="Search vendor, text, contact..."
            value={searchQuery}
            onChange={(event) => onSearchChange(event.target.value)}
          />
        </div>
      </div>

      <div className="member-content-grid">
        {items.map((item) => (
          <article key={item.id} className="member-content-card">
            <div className="member-content-banner">
              <span>Banner</span>
            </div>
            <div className="member-content-copy">
              <strong>{item.vendorName}</strong>
              <p>{item.shortText}</p>
              <div className="member-content-meta">
                <span>Date: {item.postedOn}</span>
                <span>Status: {edits[item.id]?.status ?? item.status}</span>
                <span>Contact: {item.contactNumber || "--"}</span>
                <span>
                  Sequence:{" "}
                  {(edits[item.id]?.displayIndex ?? item.displayIndex) || "--"}
                </span>
              </div>
              {item.mediaUrl ? (
                <div className="association-gallery-visual">
                  <img
                    src={item.mediaUrl}
                    alt={item.shortText.slice(0, 60) || "App banner"}
                  />
                </div>
              ) : null}
              <div className="member-record-details">
                {item.socialMediaUrl ? (
                  <p>
                    Media Link:{" "}
                    <a
                      href={item.socialMediaUrl}
                      target="_blank"
                      rel="noreferrer"
                    >
                      {item.socialMediaUrl}
                    </a>
                  </p>
                ) : null}
                {item.brochureUrl ? (
                  <p>
                    PDF:{" "}
                    <a href={item.brochureUrl} target="_blank" rel="noreferrer">
                      Open attachment
                    </a>
                  </p>
                ) : null}
              </div>
              <div className="member-content-controls">
                <label className="content-control-field">
                  <span>Status</span>
                  <select
                    value={edits[item.id]?.status ?? item.status}
                    onChange={(event) =>
                      onUpdateBanner(item.id, "status", event.target.value)
                    }
                  >
                    <option value="Approved">Approved</option>
                    <option value="Rejected">Rejected</option>
                    <option value="Hold">Hold</option>
                    <option value="Pending Review">Pending Review</option>
                  </select>
                </label>
                <label className="content-control-field">
                  <span>Payment Received</span>
                  <select
                    value={
                      (edits[item.id]?.paymentReceived ?? item.paymentReceived)
                        ? "Yes"
                        : "No"
                    }
                    onChange={(event) =>
                      onUpdateBanner(
                        item.id,
                        "paymentReceived",
                        event.target.value === "Yes",
                      )
                    }
                  >
                    <option value="No">No</option>
                    <option value="Yes">Yes</option>
                  </select>
                </label>
                <label className="content-control-field">
                  <span>Payment Mode</span>
                  <select
                    value={edits[item.id]?.paymentMode ?? item.paymentMode}
                    onChange={(event) =>
                      onUpdateBanner(item.id, "paymentMode", event.target.value)
                    }
                  >
                    <option value="">Select mode</option>
                    <option value="Bank">Bank</option>
                    <option value="Cash">Cash</option>
                    <option value="UPI">UPI</option>
                  </select>
                </label>
                <label className="content-control-field">
                  <span>Display Start</span>
                  <input
                    type="date"
                    value={edits[item.id]?.displayStart ?? item.displayStart}
                    onChange={(event) =>
                      onUpdateBanner(
                        item.id,
                        "displayStart",
                        event.target.value,
                      )
                    }
                  />
                </label>
                <label className="content-control-field">
                  <span>Display End</span>
                  <input
                    type="date"
                    value={edits[item.id]?.displayEnd ?? item.displayEnd}
                    onChange={(event) =>
                      onUpdateBanner(item.id, "displayEnd", event.target.value)
                    }
                  />
                </label>
                <label className="content-control-field">
                  <span>Carousel Sequence</span>
                  <select
                    value={
                      edits[item.id]?.displayIndex ?? item.displayIndex ?? ""
                    }
                    onChange={(event) =>
                      onUpdateBanner(
                        item.id,
                        "displayIndex",
                        event.target.value,
                      )
                    }
                  >
                    <option value="">Select slot</option>
                    {Array.from({ length: 50 }, (_, index) => index + 1).map(
                      (slot) => (
                        <option key={slot} value={slot}>
                          {slot}
                        </option>
                      ),
                    )}
                  </select>
                </label>
                <label className="content-control-field content-control-field-wide">
                  <span>Remarks</span>
                  <textarea
                    rows="2"
                    value={
                      edits[item.id]?.paymentRemarks ?? item.paymentRemarks
                    }
                    onChange={(event) =>
                      onUpdateBanner(
                        item.id,
                        "paymentRemarks",
                        event.target.value,
                      )
                    }
                  />
                </label>
              </div>
            </div>
          </article>
        ))}
        {items.length === 0 ? (
          <article className="association-empty-state">
            <span className="mini-label">No App Banners</span>
            <h2>No paid advertisements have been submitted yet.</h2>
            <p>New app banner requests from Vendor Arena will appear here.</p>
          </article>
        ) : null}
      </div>

      <div className="profile-action-row">
        {feedbackMessage ? (
          <p className="admin-access-feedback">{feedbackMessage}</p>
        ) : null}
        <button
          className="primary-link admin-action-button"
          type="button"
          onClick={onSaveAppBannerAccessChanges}
          disabled={isSaving}
        >
          {isSaving ? "Saving..." : "Save App Banner Access Changes"}
        </button>
      </div>
    </article>
  );
}

function AdminBulkMemberPanel({
  selectedFile,
  isUploading,
  errorMessage,
  result,
  onFileChange,
  onUpload,
}) {
  return (
    <article className="admin-access-panel">
      <div className="panel-topline">
        <h2>Add Bulk Member</h2>
        <span className="mini-label">Excel Import + App Login</span>
      </div>

      <div className="profile-form-grid">
        <label className="profile-field profile-field-wide">
          <span>Upload Excel File</span>
          <input
            type="file"
            accept=".xlsx,.xls,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet,application/vnd.ms-excel"
            onChange={(event) => onFileChange(event.target.files?.[0] ?? null)}
          />
          <small>
            Imported members will use their email as login and default password
            `Nima@123`.
          </small>
          <small>
            Members can log in with that password first and then change it
            later from their account settings.
          </small>
          <small>
            Need the correct format first? Download the member import template
            and fill the same headers before uploading.
          </small>
        </label>
      </div>

      {selectedFile ? <p>Selected file: {selectedFile.name}</p> : null}
      {errorMessage ? (
        <p className="form-helper-error">{errorMessage}</p>
      ) : null}

      <div className="profile-action-row">
        <a
          className="secondary-link secondary-button"
          href="/templates/member-bulk-import-template.xlsx"
          download
        >
          Download Template
        </a>
        <button
          className="primary-link admin-action-button"
          type="button"
          onClick={onUpload}
          disabled={isUploading}
        >
          {isUploading ? "Importing Members..." : "Import Members"}
        </button>
      </div>

      {result ? (
        <section className="member-content-grid">
          <article className="member-content-card">
            <div className="member-content-banner">
              <span>Summary</span>
            </div>
            <div className="member-content-copy">
              <strong>Import Result</strong>
              <div className="member-content-meta">
                <span>Total Rows: {result.summary?.totalRows ?? 0}</span>
                <span>Imported: {result.summary?.importedCount ?? 0}</span>
                <span>Skipped: {result.summary?.skippedCount ?? 0}</span>
                <span>
                  Default Password:{" "}
                  {result.summary?.defaultLoginPassword ?? "Nima@123"}
                </span>
              </div>
            </div>
          </article>

          <article className="member-content-card">
            <div className="member-content-banner">
              <span>Imported</span>
            </div>
            <div className="member-content-copy">
              <strong>Imported Members</strong>
              {(result.imported ?? []).length > 0 ? (
                <div className="member-record-details">
                  {(result.imported ?? []).map((item) => (
                    <p key={`${item.rowNumber}-${item.email}`}>
                      Row {item.rowNumber}: {item.companyName || "--"} (
                      {item.email})
                    </p>
                  ))}
                </div>
              ) : (
                <p>No rows were imported.</p>
              )}
            </div>
          </article>

          <article className="member-content-card">
            <div className="member-content-banner">
              <span>Skipped</span>
            </div>
            <div className="member-content-copy">
              <strong>Skipped Rows</strong>
              {(result.skipped ?? []).length > 0 ? (
                <div className="member-record-details">
                  {(result.skipped ?? []).map((item) => (
                    <p
                      key={`${item.rowNumber}-${item.email || item.companyName || item.reason}`}
                    >
                      Row {item.rowNumber}: {item.reason}
                    </p>
                  ))}
                </div>
              ) : (
                <p>No rows were skipped.</p>
              )}
            </div>
          </article>
        </section>
      ) : null}
    </article>
  );
}

function AdminMemberAccessPanel({
  items,
  searchQuery,
  activeFilter,
  activeView,
  selectedIds,
  contentSearchQuery,
  memberSearchMatches,
  selectedContentMemberIds,
  filteredPosts,
  contentPostEdits,
  onSearchChange,
  onFilterChange,
  onViewChange,
  onContentSearchChange,
  onToggleSelect,
  onToggleSelectAll,
  onToggleContentMember,
  onUpdateMemberAccessStatus,
  onApplyBulkMemberAccessStatus,
  onSaveMemberAccessChanges,
  onSaveContentAccessChanges,
  onSelectAllContentMembers,
  onClearContentMemberSelection,
  onUpdateContentPost,
  onUpdateAdminRole,
  superAdminInviteForm,
  onSuperAdminInviteFieldChange,
  onSubmitSuperAdminInvite,
  isCreatingSuperAdmin,
  superAdminInviteFeedback,
  updatingAdminUserIds,
  currentUserId,
  canManageSuperAdmins,
  isSaving,
  feedbackMessage,
}) {
  const allSelected =
    items.length > 0 && items.every((member) => selectedIds.includes(member.id));

  return (
    <article className="admin-access-panel">
      <div className="panel-topline">
        <h2>Member Access Controls</h2>
        <span className="mini-label">Primary, Associate, Guest</span>
      </div>

      <div className="admin-member-filterbar">
        {adminMemberAccessViews.map((view) => (
          <button
            key={view.key}
            type="button"
            className={`admin-member-filter-button ${activeView === view.key ? "active" : ""}`}
            onClick={() => onViewChange(view.key)}
          >
            {view.label}
          </button>
        ))}
      </div>

      {activeView === "app" ? (
        <>
          {canManageSuperAdmins ? (
            <div className="admin-super-admin-card">
              <div className="panel-topline">
                <h3>Create Super Admin</h3>
                <span className="mini-label">Email Access</span>
              </div>
              <p className="admin-access-helper-copy">
                Create or upgrade any email as a super admin without requiring
                member registration. Default login password: `Admin@123`.
              </p>
              <div className="profile-form-grid admin-super-admin-grid">
                <label className="profile-field">
                  <span>Email</span>
                  <input
                    type="email"
                    value={superAdminInviteForm.email}
                    onChange={(event) =>
                      onSuperAdminInviteFieldChange("email", event.target.value)
                    }
                    placeholder="client@example.com"
                  />
                </label>
                <label className="profile-field">
                  <span>First Name</span>
                  <input
                    type="text"
                    value={superAdminInviteForm.firstName}
                    onChange={(event) =>
                      onSuperAdminInviteFieldChange(
                        "firstName",
                        event.target.value,
                      )
                    }
                    placeholder="Optional"
                  />
                </label>
                <label className="profile-field">
                  <span>Last Name</span>
                  <input
                    type="text"
                    value={superAdminInviteForm.lastName}
                    onChange={(event) =>
                      onSuperAdminInviteFieldChange(
                        "lastName",
                        event.target.value,
                      )
                    }
                    placeholder="Optional"
                  />
                </label>
              </div>
              <div className="profile-action-row">
                {superAdminInviteFeedback ? (
                  <p className="admin-access-feedback">
                    {superAdminInviteFeedback}
                  </p>
                ) : null}
                <button
                  className="primary-link admin-action-button"
                  type="button"
                  disabled={isCreatingSuperAdmin}
                  onClick={onSubmitSuperAdminInvite}
                >
                  {isCreatingSuperAdmin
                    ? "Creating..."
                    : "Create Super Admin"}
                </button>
              </div>
            </div>
          ) : null}

          <div className="admin-member-toolbar">
            <div className="search-wrap admin-member-search">
              <input
                className="search-input"
                type="search"
                placeholder="Search name, company, membership type..."
                value={searchQuery}
                onChange={(event) => onSearchChange(event.target.value)}
              />
            </div>
            <label className="selection-chip">
              <input
                type="checkbox"
                checked={allSelected}
                onChange={onToggleSelectAll}
              />
              <span>Select filtered</span>
            </label>
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={() => onApplyBulkMemberAccessStatus("APPROVED")}
            >
              Approve Membership
            </button>
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={() => onApplyBulkMemberAccessStatus("SUSPENDED")}
            >
              Suspend Membership
            </button>
            <button
              className="secondary-link secondary-button danger-button"
              type="button"
              onClick={() => onApplyBulkMemberAccessStatus("CANCELLED")}
            >
              Cancel Membership
            </button>
          </div>

          <div className="admin-member-filterbar">
            {adminMemberAccessFilters.map((filter) => (
              <button
                key={filter.key}
                type="button"
                className={`admin-member-filter-button ${
                  activeFilter === filter.key ? "active" : ""
                }`}
                onClick={() => onFilterChange(filter.key)}
              >
                {filter.label}
              </button>
            ))}
          </div>

          <div className="member-table-wrap">
            <table className="member-table">
              <thead>
                <tr>
                  <th>Select</th>
                  <th>Name</th>
                  <th>Company</th>
                  <th>Member Type</th>
                  <th>Membership Period</th>
                  <th>App Access</th>
                  <th>Admin Role</th>
                  <th>Contact</th>
                </tr>
              </thead>
              <tbody>
                {items.map((member) => (
                  <tr key={member.id}>
                    <td>
                      <input
                        type="checkbox"
                        checked={selectedIds.includes(member.id)}
                        onChange={() => onToggleSelect(member.id)}
                      />
                    </td>
                    <td>{member.name}</td>
                    <td>{member.company}</td>
                    <td>{member.membershipType}</td>
                    <td>{member.membershipPeriod}</td>
                    <td>
                      <select
                        className="member-access-select"
                        value={member.appAccessStatus}
                        onChange={(event) =>
                          onUpdateMemberAccessStatus(
                            member.id,
                            event.target.value,
                          )
                        }
                      >
                        <option value="Pending Approval">
                          Pending Approval
                        </option>
                        <option value="Approved">Approved</option>
                        <option value="Suspended">Suspended</option>
                        <option value="Cancelled">Cancelled</option>
                      </select>
                    </td>
                    <td>
                      <div className="member-table-contact">
                        <span>{getMemberAdminLabel(member)}</span>
                        <div className="member-admin-actions">
                          <button
                            className={`secondary-link secondary-button ${
                              !member.isAdmin ? "danger-button" : ""
                            }`}
                            type="button"
                            disabled={
                              !member.accessUserId ||
                              updatingAdminUserIds.includes(
                                member.accessUserId,
                              )
                            }
                            onClick={() => onUpdateAdminRole(member, "admin")}
                          >
                            {updatingAdminUserIds.includes(member.accessUserId)
                              ? "Saving..."
                              : member.isAdmin && !member.isSuperAdmin
                                ? "Keep Admin"
                                : "Make Admin"}
                          </button>
                          {canManageSuperAdmins ? (
                            <button
                              className="secondary-link secondary-button"
                              type="button"
                              disabled={
                                !member.accessUserId ||
                                updatingAdminUserIds.includes(
                                  member.accessUserId,
                                )
                              }
                              onClick={() =>
                                onUpdateAdminRole(member, "superAdmin")
                              }
                            >
                              {updatingAdminUserIds.includes(
                                member.accessUserId,
                              )
                                ? "Saving..."
                                : member.isSuperAdmin
                                  ? "Keep Super Admin"
                                  : "Make Super Admin"}
                            </button>
                          ) : null}
                          <button
                            className="secondary-link secondary-button danger-button"
                            type="button"
                            disabled={
                              !member.accessUserId ||
                              updatingAdminUserIds.includes(
                                member.accessUserId,
                              ) ||
                              (member.isSuperAdmin &&
                                member.accessUserId === currentUserId)
                            }
                            onClick={() => onUpdateAdminRole(member, "member")}
                          >
                            {updatingAdminUserIds.includes(member.accessUserId)
                              ? "Saving..."
                              : member.isSuperAdmin &&
                                  member.accessUserId === currentUserId
                                ? "Current Super Admin"
                                : "Make Member"}
                          </button>
                        </div>
                      </div>
                    </td>
                    <td>
                      <div className="member-table-contact">
                        <a href={`mailto:${member.email}`}>{member.email}</a>
                        <span>{member.phone}</span>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      ) : (
        <>
          <div className="admin-member-toolbar">
            <div className="search-wrap admin-member-search">
              <input
                className="search-input"
                type="search"
                placeholder="Search member to filter content..."
                value={contentSearchQuery}
                onChange={(event) => onContentSearchChange(event.target.value)}
              />
            </div>
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={onSelectAllContentMembers}
            >
              Select All Matched Members
            </button>
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={onClearContentMemberSelection}
            >
              Clear Selection
            </button>
          </div>

          <div className="content-member-selector">
            {memberSearchMatches.map((member) => (
              <button
                key={member.id}
                type="button"
                className={`content-member-chip ${
                  selectedContentMemberIds.includes(member.id) ? "active" : ""
                }`}
                onClick={() => onToggleContentMember(member.id)}
              >
                {member.name}
              </button>
            ))}
          </div>

          <div className="member-content-grid">
            {filteredPosts.map((post) => (
              <article key={post.id} className="member-content-card">
                <div className="member-content-banner">
                  <span>{post.badge}</span>
                </div>
                <div className="member-content-copy">
                  <strong>{post.title}</strong>
                  <p>{post.summary}</p>
                  <div className="member-content-meta">
                    <span>Member: {post.postedBy}</span>
                    <span>Date: {post.postedOn}</span>
                    <span>
                      Status: {contentPostEdits[post.id]?.status ?? post.status}
                    </span>
                    <span>
                      Display:{" "}
                      {(contentPostEdits[post.id]?.displayStart ??
                        post.displayStart) &&
                      (contentPostEdits[post.id]?.displayEnd ?? post.displayEnd)
                        ? `${contentPostEdits[post.id]?.displayStart ?? post.displayStart} to ${
                            contentPostEdits[post.id]?.displayEnd ??
                            post.displayEnd
                          }`
                        : post.displayPeriod}
                    </span>
                  </div>
                  <div className="member-content-controls">
                    <label className="content-control-field">
                      <span>Status</span>
                      <select
                        value={contentPostEdits[post.id]?.status ?? post.status}
                        onChange={(event) =>
                          onUpdateContentPost(
                            post.id,
                            "status",
                            event.target.value,
                          )
                        }
                      >
                        <option value="Approved">Approved</option>
                        <option value="Rejected">Rejected</option>
                        <option value="Pending Review">Pending Review</option>
                      </select>
                    </label>
                    <label className="content-control-field">
                      <span>Display Start</span>
                      <input
                        type="date"
                        value={
                          contentPostEdits[post.id]?.displayStart ??
                          post.displayStart
                        }
                        onChange={(event) =>
                          onUpdateContentPost(
                            post.id,
                            "displayStart",
                            event.target.value,
                          )
                        }
                      />
                    </label>
                    <label className="content-control-field">
                      <span>Display End</span>
                      <input
                        type="date"
                        value={
                          contentPostEdits[post.id]?.displayEnd ??
                          post.displayEnd
                        }
                        onChange={(event) =>
                          onUpdateContentPost(
                            post.id,
                            "displayEnd",
                            event.target.value,
                          )
                        }
                      />
                    </label>
                  </div>
                </div>
              </article>
            ))}
            {filteredPosts.length === 0 ? (
              <article className="association-empty-state">
                <span className="mini-label">No Posts</span>
                <h2>No member posts match the current member selection.</h2>
                <p>
                  Select one or more members above to review content intended
                  for the Flutter app.
                </p>
              </article>
            ) : null}
          </div>
        </>
      )}

      <div className="profile-action-row">
        {feedbackMessage ? (
          <p className="admin-access-feedback">{feedbackMessage}</p>
        ) : null}
        <button
          className="primary-link admin-action-button"
          type="button"
          disabled={isSaving}
          onClick={
            activeView === "app"
              ? onSaveMemberAccessChanges
              : onSaveContentAccessChanges
          }
        >
          {isSaving
            ? "Saving..."
            : activeView === "app"
              ? "Save Member Access Changes"
              : "Save Content Access Changes"}
        </button>
      </div>
    </article>
  );
}

function AdminRegistrationRequestsPanel({
  items,
  selectedIds,
  feedbackMessage,
  isSaving,
  onToggleSelect,
  onToggleSelectAll,
  onApplyBulkMemberAccessStatus,
  onUpdateMemberAccessStatus,
  onSaveMemberAccessChanges,
}) {
  const allSelected =
    items.length > 0 && items.every((member) => selectedIds.includes(member.id));

  return (
    <article className="admin-access-panel">
      <div className="panel-topline">
        <h2>Registration Requests</h2>
        <span className="mini-label">Approve Or Reject</span>
      </div>

      <p className="admin-access-helper-copy">
        Review new member login requests from the web admin. Approving grants
        app access, while cancelling rejects the registration request.
      </p>

      <div className="admin-member-toolbar">
        <label className="selection-chip">
          <input
            type="checkbox"
            checked={allSelected}
            onChange={onToggleSelectAll}
          />
          <span>Select pending</span>
        </label>
        <button
          className="secondary-link secondary-button"
          type="button"
          onClick={() => onApplyBulkMemberAccessStatus("APPROVED")}
        >
          Approve Selected
        </button>
        <button
          className="secondary-link secondary-button danger-button"
          type="button"
          onClick={() => onApplyBulkMemberAccessStatus("CANCELLED")}
        >
          Reject Selected
        </button>
      </div>

      <div className="member-table-wrap">
        <table className="member-table">
          <thead>
            <tr>
              <th>Select</th>
              <th>Name</th>
              <th>Company</th>
              <th>Member Type</th>
              <th>Membership Period</th>
              <th>Request Status</th>
              <th>Contact</th>
            </tr>
          </thead>
          <tbody>
            {items.map((member) => (
              <tr key={member.id}>
                <td>
                  <input
                    type="checkbox"
                    checked={selectedIds.includes(member.id)}
                    onChange={() => onToggleSelect(member.id)}
                  />
                </td>
                <td>{member.name}</td>
                <td>{member.company}</td>
                <td>{member.membershipType}</td>
                <td>{member.membershipPeriod}</td>
                <td>
                  <select
                    className="member-access-select"
                    value={member.appAccessStatus}
                    onChange={(event) =>
                      onUpdateMemberAccessStatus(member.id, event.target.value)
                    }
                  >
                    <option value="Pending Approval">Pending Approval</option>
                    <option value="Approved">Approved</option>
                    <option value="Cancelled">Rejected</option>
                  </select>
                </td>
                <td>
                  <div className="member-table-contact">
                    <a href={`mailto:${member.email}`}>{member.email}</a>
                    <span>{member.phone}</span>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {items.length === 0 ? (
        <article className="association-empty-state">
          <span className="mini-label">All Clear</span>
          <h2>No pending registration requests right now.</h2>
          <p>
            New member login requests will appear here whenever registration
            approval is required.
          </p>
        </article>
      ) : null}

      <div className="profile-action-row">
        {feedbackMessage ? (
          <p className="admin-access-feedback">{feedbackMessage}</p>
        ) : null}
        <button
          className="primary-link admin-action-button"
          type="button"
          disabled={isSaving}
          onClick={onSaveMemberAccessChanges}
        >
          {isSaving ? "Saving..." : "Save Registration Decisions"}
        </button>
      </div>
    </article>
  );
}

function AdminVendorAccessPanel({
  items,
  activeView,
  searchQuery,
  selectedIds,
  selectedVendorIds,
  vendorSearchMatches,
  filteredPosts,
  contentPostEdits,
  onSearchChange,
  onViewChange,
  onToggleSelect,
  onToggleSelectAll,
  onToggleVendor,
  onUpdateContentPost,
  onApplyAccessStatus,
  onSaveVendorAccessChanges,
}) {
  const allSelected = items.length > 0 && selectedIds.length === items.length;

  return (
    <article className="admin-access-panel">
      <div className="panel-topline">
        <h2>Vendor Access Controls</h2>
        <span className="mini-label">Vendors and Ads</span>
      </div>

      <div className="admin-member-filterbar">
        {adminVendorAccessViews.map((view) => (
          <button
            key={view.key}
            type="button"
            className={`admin-member-filter-button ${activeView === view.key ? "active" : ""}`}
            onClick={() => onViewChange(view.key)}
          >
            {view.label}
          </button>
        ))}
      </div>

      {activeView === "app" ? (
        <>
          <div className="admin-member-toolbar">
            <div className="search-wrap admin-member-search">
              <input
                className="search-input"
                type="search"
                placeholder="Search vendor name, company, type..."
                value={searchQuery}
                onChange={(event) => onSearchChange(event.target.value)}
              />
            </div>
            <label className="selection-chip">
              <input
                type="checkbox"
                checked={allSelected}
                onChange={onToggleSelectAll}
              />
              <span>Select filtered</span>
            </label>
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={() => onApplyAccessStatus("PENDING")}
            >
              Restrict App Usage
            </button>
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={() => onApplyAccessStatus("SUSPENDED")}
            >
              Suspend Access
            </button>
            <button
              className="secondary-link secondary-button danger-button"
              type="button"
              onClick={() => onApplyAccessStatus("CANCELLED")}
            >
              Remove App Usage
            </button>
          </div>

          <div className="member-table-wrap">
            <table className="member-table">
              <thead>
                <tr>
                  <th>Select</th>
                  <th>Vendor</th>
                  <th>Company</th>
                  <th>Type</th>
                  <th>Access Period</th>
                  <th>App Access</th>
                  <th>Contact</th>
                </tr>
              </thead>
              <tbody>
                {items.map((vendor) => (
                  <tr key={vendor.id}>
                    <td>
                      <input
                        type="checkbox"
                        checked={selectedIds.includes(vendor.id)}
                        onChange={() => onToggleSelect(vendor.id)}
                      />
                    </td>
                    <td>{vendor.name}</td>
                    <td>{vendor.company}</td>
                    <td>{vendor.vendorType}</td>
                    <td>{vendor.onboardingPeriod}</td>
                    <td>
                      <span className="access-status-chip">
                        {vendor.appAccessStatus}
                      </span>
                    </td>
                    <td>
                      <div className="member-table-contact">
                        <a href={`mailto:${vendor.email}`}>{vendor.email}</a>
                        <span>{vendor.phone}</span>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      ) : (
        <>
          <div className="admin-member-toolbar">
            <div className="search-wrap admin-member-search">
              <input
                className="search-input"
                type="search"
                placeholder="Search vendor to filter ads..."
                value={searchQuery}
                onChange={(event) => onSearchChange(event.target.value)}
              />
            </div>
          </div>

          <div className="content-member-selector">
            {vendorSearchMatches.map((vendor) => (
              <button
                key={vendor.id}
                type="button"
                className={`content-member-chip ${selectedVendorIds.includes(vendor.id) ? "active" : ""}`}
                onClick={() => onToggleVendor(vendor.id)}
              >
                {vendor.name}
              </button>
            ))}
          </div>

          <div className="member-content-grid">
            {filteredPosts.map((post) => (
              <article key={post.id} className="member-content-card">
                <div className="member-content-banner">
                  <span>{post.badge}</span>
                </div>
                <div className="member-content-copy">
                  <strong>{post.title}</strong>
                  <p>{post.summary}</p>
                  <div className="member-content-meta">
                    <span>Vendor: {post.postedBy}</span>
                    <span>Date: {post.postedOn}</span>
                    <span>
                      Status: {contentPostEdits[post.id]?.status ?? post.status}
                    </span>
                    <span>
                      Display:{" "}
                      {(contentPostEdits[post.id]?.displayStart ??
                        post.displayStart) &&
                      (contentPostEdits[post.id]?.displayEnd ?? post.displayEnd)
                        ? `${contentPostEdits[post.id]?.displayStart ?? post.displayStart} to ${
                            contentPostEdits[post.id]?.displayEnd ??
                            post.displayEnd
                          }`
                        : post.displayPeriod}
                    </span>
                  </div>
                  <div className="member-content-controls">
                    <label className="content-control-field">
                      <span>Status</span>
                      <select
                        value={contentPostEdits[post.id]?.status ?? post.status}
                        onChange={(event) =>
                          onUpdateContentPost(
                            post.id,
                            "status",
                            event.target.value,
                          )
                        }
                      >
                        <option value="Approved">Approved</option>
                        <option value="Rejected">Rejected</option>
                        <option value="Pending Review">Pending Review</option>
                      </select>
                    </label>
                    <label className="content-control-field">
                      <span>Display Start</span>
                      <input
                        type="date"
                        value={
                          contentPostEdits[post.id]?.displayStart ??
                          post.displayStart
                        }
                        onChange={(event) =>
                          onUpdateContentPost(
                            post.id,
                            "displayStart",
                            event.target.value,
                          )
                        }
                      />
                    </label>
                    <label className="content-control-field">
                      <span>Display End</span>
                      <input
                        type="date"
                        value={
                          contentPostEdits[post.id]?.displayEnd ??
                          post.displayEnd
                        }
                        onChange={(event) =>
                          onUpdateContentPost(
                            post.id,
                            "displayEnd",
                            event.target.value,
                          )
                        }
                      />
                    </label>
                  </div>
                </div>
              </article>
            ))}
            {filteredPosts.length === 0 ? (
              <article className="association-empty-state">
                <span className="mini-label">No Ads</span>
                <h2>No vendor ads match the current vendor selection.</h2>
                <p>
                  Select one or more vendors above to review ad content intended
                  for the Flutter app.
                </p>
              </article>
            ) : null}
          </div>
        </>
      )}

      <div className="profile-action-row">
        <button
          className="primary-link admin-action-button"
          type="button"
          onClick={onSaveVendorAccessChanges}
        >
          {activeView === "app"
            ? "Save Vendor Access Changes"
            : "Save Vendor Content Changes"}
        </button>
      </div>
    </article>
  );
}

function WebAdminLoginScreen({
  form,
  errorMessage,
  isSubmitting,
  onFieldChange,
  onSubmit,
}) {
  return (
    <main className="dashboard-shell">
      <section className="content-shell">
        <section className="welcome-hero">
          <div>
            <span className="eyebrow">NIMA Admin Login</span>
            <h1>Sign in with an admin account.</h1>
            <p>
              Use the backend admin credentials to open member access controls,
              promote members to admin, and manage the association workspace
              from the laptop.
            </p>
          </div>

          <div className="hero-spotlight">
            <span className="spotlight-label">Default bootstrap admin</span>
            <strong>ritsman@gmail.com</strong>
            <p>Password: Admin@123</p>
          </div>
        </section>

        <section className="association-tab-section">
          <article className="welcome-panel">
            <div className="panel-topline">
              <h2>Admin Session</h2>
              <span className="mini-label">Backend Auth</span>
            </div>

            <div className="profile-form-grid">
              <label className="profile-field">
                <span>Email</span>
                <input
                  type="email"
                  value={form.email}
                  onChange={(event) =>
                    onFieldChange("email", event.target.value)
                  }
                />
              </label>

              <label className="profile-field">
                <span>Password</span>
                <input
                  type="password"
                  value={form.password}
                  onChange={(event) =>
                    onFieldChange("password", event.target.value)
                  }
                  onKeyDown={(event) => {
                    if (event.key === "Enter") {
                      event.preventDefault();
                      onSubmit();
                    }
                  }}
                />
              </label>
            </div>

            {errorMessage ? (
              <p className="form-helper error-text">{errorMessage}</p>
            ) : null}

            <div className="profile-action-row">
              <button
                className="primary-link admin-action-button"
                type="button"
                onClick={onSubmit}
              >
                {isSubmitting ? "Signing in..." : "Sign in as Admin"}
              </button>
            </div>
          </article>
        </section>
      </section>
    </main>
  );
}

export default function HomePage() {
  const [authReady, setAuthReady] = useState(false);
  const [authSession, setAuthSession] = useState(null);
  const [sessionReportSummary, setSessionReportSummary] = useState({
    activeUsers: 0,
    activeUsersThisMonth: 0,
    activeUsersLastSixMonths: 0,
  });
  const [loginForm, setLoginForm] = useState({
    email: "ritsman@gmail.com",
    password: "Admin@123",
  });
  const [loginError, setLoginError] = useState("");
  const [isLoggingIn, setIsLoggingIn] = useState(false);
  const [updatingAdminUserIds, setUpdatingAdminUserIds] = useState([]);
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [isMobileViewport, setIsMobileViewport] = useState(false);
  const [topbarSearchQuery, setTopbarSearchQuery] = useState("");
  const [dashboardApprovalTab, setDashboardApprovalTab] = useState("Primary");
  const [vendorOverviewStatusFilter, setVendorOverviewStatusFilter] =
    useState("");
  const [activeSection, setActiveSection] = useState(topLevelSections.dashboard);
  const [activeAssociationTab, setActiveAssociationTab] = useState("Profile");
  const [activeFinanceTab, setActiveFinanceTab] = useState("Income");
  const [activeEventsTab, setActiveEventsTab] = useState("Master");
  const [financeStatementFilterType, setFinanceStatementFilterType] =
    useState("");
  const [financeStatementDateFrom, setFinanceStatementDateFrom] = useState("");
  const [financeStatementDateTo, setFinanceStatementDateTo] = useState("");
  const [activeMemberTab, setActiveMemberTab] = useState("Primary Members");
  const [activeVendorTab, setActiveVendorTab] = useState("Registration");
  const [activeAdminAccessSection, setActiveAdminAccessSection] =
    useState("App Access");
  const [isSavingAppAccess, setIsSavingAppAccess] = useState(false);
  const [appAccessFeedback, setAppAccessFeedback] = useState("");
  const [isSavingMemberAccess, setIsSavingMemberAccess] = useState(false);
  const [memberAccessFeedback, setMemberAccessFeedback] = useState("");
  const [superAdminInviteForm, setSuperAdminInviteForm] = useState({
    email: "",
    firstName: "",
    lastName: "",
  });
  const [isCreatingSuperAdmin, setIsCreatingSuperAdmin] = useState(false);
  const [superAdminInviteFeedback, setSuperAdminInviteFeedback] =
    useState("");
  const [appPermissions, setAppPermissions] = useState({
    approveMembersLogin: true,
    disableScreenshots: false,
    approveMembership: true,
    approveRegistrationRequest: true,
    disableAdminFunctionsFromApp: false,
  });
  const [associationTabData, setAssociationTabData] = useState(
    initialAssociationTabData,
  );
  const [associationProfile, setAssociationProfile] = useState(
    defaultAssociationProfile,
  );
  const [associationProfileForm, setAssociationProfileForm] = useState(
    defaultAssociationProfile,
  );
  const [isEditingAssociationProfile, setIsEditingAssociationProfile] =
    useState(false);
  const [isSavingAssociationProfile, setIsSavingAssociationProfile] =
    useState(false);
  const [associationProfileFeedback, setAssociationProfileFeedback] =
    useState("");
  const [associationAbout, setAssociationAbout] = useState(
    defaultAssociationAbout,
  );
  const [associationAboutForm, setAssociationAboutForm] = useState(
    defaultAssociationAbout,
  );
  const [isEditingAssociationAbout, setIsEditingAssociationAbout] =
    useState(false);
  const [isSavingAssociationAbout, setIsSavingAssociationAbout] =
    useState(false);
  const [associationAboutFeedback, setAssociationAboutFeedback] = useState("");
  const [galleryItems, setGalleryItems] = useState([]);
  const [galleryFolders, setGalleryFolders] = useState([]);
  const [activeGalleryFolderId, setActiveGalleryFolderId] = useState("");
  const [editingGalleryFolderId, setEditingGalleryFolderId] = useState(null);
  const [selectedGalleryFolderIds, setSelectedGalleryFolderIds] = useState([]);
  const [selectedGalleryPhotoIds, setSelectedGalleryPhotoIds] = useState([]);
  const [galleryFolderForm, setGalleryFolderForm] = useState(
    defaultGalleryFolderForm,
  );
  const [isSavingGalleryFolder, setIsSavingGalleryFolder] = useState(false);
  const [galleryFolderFeedback, setGalleryFolderFeedback] = useState("");
  const galleryFolderEditorRef = useRef(null);
  const galleryFolderNameInputRef = useRef(null);
  const [editingGalleryItemId, setEditingGalleryItemId] = useState(null);
  const [galleryItemForm, setGalleryItemForm] = useState(
    defaultGalleryItemForm,
  );
  const galleryEditorRef = useRef(null);
  const galleryHeadlineInputRef = useRef(null);
  const [selectedGalleryItemIds, setSelectedGalleryItemIds] = useState([]);
  const [isSavingGalleryItem, setIsSavingGalleryItem] = useState(false);
  const [galleryItemFeedback, setGalleryItemFeedback] = useState("");
  const [circularDocuments, setCircularDocuments] = useState([]);
  const [editingCircularDocumentId, setEditingCircularDocumentId] =
    useState(null);
  const [circularDocumentForm, setCircularDocumentForm] = useState(
    defaultCircularDocumentForm,
  );
  const [selectedCircularDocumentIds, setSelectedCircularDocumentIds] =
    useState([]);
  const [isSavingCircularDocument, setIsSavingCircularDocument] =
    useState(false);
  const [circularDocumentFeedback, setCircularDocumentFeedback] = useState("");
  const [memberTabData, setMemberTabData] = useState(initialMemberTabData);
  const [editingCommitteeMemberId, setEditingCommitteeMemberId] =
    useState(null);
  const [committeeMemberForm, setCommitteeMemberForm] = useState(
    defaultCommitteeMemberForm,
  );
  const [isSavingCommitteeMember, setIsSavingCommitteeMember] =
    useState(false);
  const [committeeMemberFeedback, setCommitteeMemberFeedback] = useState("");
  const [committeePostMasterList, setCommitteePostMasterList] = useState(
    defaultCommitteePostOptions,
  );
  const [committeePostMasterDraft, setCommitteePostMasterDraft] =
    useState("");
  const [editingCommitteePostMaster, setEditingCommitteePostMaster] =
    useState("");
  const [committeePostMasterEditDraft, setCommitteePostMasterEditDraft] =
    useState("");
  const [committeePostMasterFeedback, setCommitteePostMasterFeedback] =
    useState("");
  const [membershipTypeMasterList, setMembershipTypeMasterList] = useState(
    defaultMembershipTypeOptions,
  );
  const [membershipTypeMasterDraft, setMembershipTypeMasterDraft] =
    useState("");
  const [editingMembershipTypeMaster, setEditingMembershipTypeMaster] =
    useState("");
  const [membershipTypeMasterEditDraft, setMembershipTypeMasterEditDraft] =
    useState("");
  const [membershipTypeMasterFeedback, setMembershipTypeMasterFeedback] =
    useState("");
  const [memberMasterForm, setMemberMasterForm] = useState(
    defaultMemberAdminForm,
  );
  const [isSavingMemberMaster, setIsSavingMemberMaster] = useState(false);
  const [memberMasterFeedback, setMemberMasterFeedback] = useState("");
  const [isSavingMemberDirectory, setIsSavingMemberDirectory] = useState(false);
  const [memberDirectoryFeedback, setMemberDirectoryFeedback] = useState("");
  const [editingMemberId, setEditingMemberId] = useState("");
  const [isMemberFormOpen, setIsMemberFormOpen] = useState(false);
  const [membershipFormFields, setMembershipFormFields] = useState(
    initialMembershipFormFields,
  );
  const [membershipFieldDraft, setMembershipFieldDraft] = useState({
    label: "",
    type: "text",
    required: false,
  });
  const [selectedRecords, setSelectedRecords] = useState(
    Object.fromEntries(associationTabs.map((tab) => [tab, []])),
  );
  const [selectedMemberRecords, setSelectedMemberRecords] = useState(
    Object.fromEntries(memberArenaTabs.map((tab) => [tab, []])),
  );
  const [isReminderPanelOpen, setIsReminderPanelOpen] = useState(false);
  const [adminMemberSearch, setAdminMemberSearch] = useState("");
  const [adminMemberAccessView, setAdminMemberAccessView] = useState("app");
  const [adminContentMemberSearch, setAdminContentMemberSearch] = useState("");
  const [activeAdminMemberFilter, setActiveAdminMemberFilter] = useState("All");
  const [selectedAdminMembers, setSelectedAdminMembers] = useState([]);
  const [memberAccessEdits, setMemberAccessEdits] = useState({});
  const [selectedContentMemberIds, setSelectedContentMemberIds] = useState([]);
  const [memberContentPosts, setMemberContentPosts] = useState([]);
  const [memberMediaPostForm, setMemberMediaPostForm] = useState(
    defaultMemberMediaPostForm,
  );
  const [isSavingMemberMediaPost, setIsSavingMemberMediaPost] = useState(false);
  const [memberMediaPostFeedback, setMemberMediaPostFeedback] = useState("");
  const [timelinePosts, setTimelinePosts] = useState([]);
  const [timelinePostForm, setTimelinePostForm] = useState(
    defaultTimelinePostForm,
  );
  const [isSavingTimelinePost, setIsSavingTimelinePost] = useState(false);
  const [timelinePostFeedback, setTimelinePostFeedback] = useState("");
  const [appBanners, setAppBanners] = useState([]);
  const [appBannerForm, setAppBannerForm] = useState(defaultAppBannerForm);
  const [isSavingAppBanner, setIsSavingAppBanner] = useState(false);
  const [appBannerError, setAppBannerError] = useState("");
  const [adminAppBannerSearch, setAdminAppBannerSearch] = useState("");
  const [appBannerAccessEdits, setAppBannerAccessEdits] = useState({});
  const [isSavingBannerAccess, setIsSavingBannerAccess] = useState(false);
  const [bannerAccessFeedback, setBannerAccessFeedback] = useState("");
  const [bulkMemberFile, setBulkMemberFile] = useState(null);
  const [isBulkMemberUploading, setIsBulkMemberUploading] = useState(false);
  const [bulkMemberError, setBulkMemberError] = useState("");
  const [bulkMemberResult, setBulkMemberResult] = useState(null);
  const [adminTimelineSearch, setAdminTimelineSearch] = useState("");
  const [timelineAccessEdits, setTimelineAccessEdits] = useState({});
  const [isSavingTimelineAccess, setIsSavingTimelineAccess] = useState(false);
  const [timelineAccessFeedback, setTimelineAccessFeedback] = useState("");
  const [adminVendorSearch, setAdminVendorSearch] = useState("");
  const [adminVendorAccessView, setAdminVendorAccessView] = useState("app");
  const [selectedAdminVendors, setSelectedAdminVendors] = useState([]);
  const [selectedContentVendorIds, setSelectedContentVendorIds] = useState([]);
  const committeeMembers = getCommitteeMembers(
    memberTabData["All Members"] ?? [],
  );
  const committeePostOptions = buildCommitteePostOptions(
    committeeMembers,
    committeePostMasterList,
  );
  const membershipTypeOptions = buildMembershipTypeOptions(
    memberTabData["All Members"] ?? [],
    membershipTypeMasterList,
  );
  const [vendorStatusSearch, setVendorStatusSearch] = useState("");
  const [selectedVendorRequests, setSelectedVendorRequests] = useState([]);
  const [selectedVendorReviewId, setSelectedVendorReviewId] = useState("");
  const [vendorApprovalForm, setVendorApprovalForm] = useState(
    buildVendorApprovalForm(null),
  );
  const [vendorApprovalError, setVendorApprovalError] = useState("");
  const [isSavingVendorApproval, setIsSavingVendorApproval] = useState(false);
  const [vendorRecords, setVendorRecords] = useState(initialVendorRecords);
  const [vendorAccessEdits, setVendorAccessEdits] = useState({});
  const [adminEventSearch, setAdminEventSearch] = useState("");
  const [contentPostEdits, setContentPostEdits] = useState({});
  const [vendorContentPostEdits, setVendorContentPostEdits] = useState(
    Object.fromEntries(
      vendorContentPosts.map((post) => [
        post.id,
        {
          status: post.status,
          displayStart: post.displayStart,
          displayEnd: post.displayEnd,
        },
      ]),
    ),
  );
  const [vendorRegistrationForm, setVendorRegistrationForm] = useState(
    buildVendorRegistrationForm(null),
  );
  const [vendorRegistrationError, setVendorRegistrationError] = useState("");
  const [vendorRegistrationSuccess, setVendorRegistrationSuccess] =
    useState("");
  const [isSavingVendorRegistration, setIsSavingVendorRegistration] =
    useState(false);
  const [vendorCategories, setVendorCategories] = useState(
    initialVendorCategories,
  );
  const [vendorSubCategoryRecords, setVendorSubCategoryRecords] =
    useState(vendorSubCategoryMap);
  const [vendorCategoryIdMap, setVendorCategoryIdMap] = useState(
    initialVendorCategoryIdMap,
  );
  const [vendorSubCategoryIdMap, setVendorSubCategoryIdMap] = useState(
    initialVendorSubCategoryIdMap,
  );
  const [newVendorCategory, setNewVendorCategory] = useState("");
  const [vendorCategoryDraft, setVendorCategoryDraft] = useState("");
  const [editingVendorCategory, setEditingVendorCategory] = useState(null);
  const [selectedVendorParentCategory, setSelectedVendorParentCategory] =
    useState("");
  const [vendorSubCategoryDraft, setVendorSubCategoryDraft] = useState("");
  const [editingVendorSubCategory, setEditingVendorSubCategory] =
    useState(null);
  const [vendorTaxonomyError, setVendorTaxonomyError] = useState("");
  const [vendorTaxonomySuccess, setVendorTaxonomySuccess] = useState("");
  const [vendorFilters, setVendorFilters] = useState({
    name: "",
    category: "",
    city: "",
  });
  const vendorSubCategoryOptions =
    vendorSubCategoryRecords[vendorRegistrationForm.category] ?? [];
  const vendorStateOptions =
    vendorRegistrationForm.country === "India"
      ? INDIA_STATES
      : (vendorStateOptionsByCountry[vendorRegistrationForm.country] ?? []);
  const vendorCityOptions =
    vendorRegistrationForm.country === "India"
      ? getIndianCities(vendorRegistrationForm.state)
      : (vendorCityOptionsByState[vendorRegistrationForm.state] ?? []);
  const [eventForm, setEventForm] = useState({
    ...defaultEventForm,
    id: "",
  });
  const [eventMedia, setEventMedia] = useState(defaultEventMedia);
  const [eventTypes, setEventTypes] = useState(initialEventTypeRecords);
  const [createdEvents, setCreatedEvents] = useState(initialCreatedEvents);
  const [savingEventId, setSavingEventId] = useState(null);
  const [eventAccessFeedback, setEventAccessFeedback] = useState("");
  const [eventTypeDraft, setEventTypeDraft] = useState({
    title: "",
    meta: "",
  });
  const [isSavingEventType, setIsSavingEventType] = useState(false);
  const [eventTypeFeedback, setEventTypeFeedback] = useState("");
  const normalizedAuthEmail = authSession?.email?.trim().toLowerCase() || "";
  const isAssociationAdmin = isElevatedViewerRole(authSession?.viewerRole);
  const isMemberAdmin = isElevatedViewerRole(authSession?.viewerRole);
  const isSuperAdmin =
    authSession?.viewerRole === "superAdmin" ||
    normalizedAuthEmail === bootstrapSuperAdminEmail;

  useEffect(() => {
    if (editingGalleryItemId === null) {
      return;
    }

    galleryEditorRef.current?.scrollIntoView({
      behavior: "smooth",
      block: "start",
    });

    window.requestAnimationFrame(() => {
      galleryHeadlineInputRef.current?.focus();
      galleryHeadlineInputRef.current?.select();
    });
  }, [editingGalleryItemId]);

  useEffect(() => {
    if (editingGalleryFolderId === null) {
      return;
    }

    galleryFolderEditorRef.current?.scrollIntoView({
      behavior: "smooth",
      block: "start",
    });

    window.requestAnimationFrame(() => {
      galleryFolderNameInputRef.current?.focus();
      galleryFolderNameInputRef.current?.select();
    });
  }, [editingGalleryFolderId]);

  const updateLoginField = (field, value) => {
    setLoginForm((current) => ({
      ...current,
      [field]: value,
    }));
  };

  const updateSuperAdminInviteField = (field, value) => {
    setSuperAdminInviteFeedback("");
    setSuperAdminInviteForm((current) => ({
      ...current,
      [field]: value,
    }));
  };

  const logoutAdmin = async () => {
    try {
      if (authSession?.authToken) {
        await fetch(`${apiBaseUrl}/auth/logout`, {
          method: "POST",
          headers: {
            Authorization: `Bearer ${authSession.authToken}`,
          },
        });
      }
    } catch {
      // Ignore logout transport failures and clear the local session anyway.
    }

    persistAdminSession(null);
    setAuthSession(null);
    setLoginError("");
  };

  const runAuthenticatedFetch = async (
    path,
    options = {},
    sessionOverride = authSession,
  ) => {
    const makeRequest = (resolvedSession) => {
      const headers = new Headers(options.headers || {});
      if (resolvedSession?.authToken) {
        headers.set("Authorization", `Bearer ${resolvedSession.authToken}`);
      }
      if (
        typeof options.body === "string" &&
        !headers.has("Content-Type")
      ) {
        headers.set("Content-Type", "application/json");
      }

      return fetch(`${apiBaseUrl}${path}`, {
        ...options,
        headers,
      });
    };

    let response = await makeRequest(sessionOverride);
    if (response.status !== 401 || !sessionOverride?.refreshToken) {
      return response;
    }

    const refreshResponse = await fetch(`${apiBaseUrl}/auth/refresh`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        refreshToken: sessionOverride.refreshToken,
      }),
    });

    if (!refreshResponse.ok) {
      persistAdminSession(null);
      setAuthSession(null);
      return response;
    }

    const refreshPayload = await refreshResponse.json();
    const nextSession = normalizeAuthSession(refreshPayload, sessionOverride);
    if (!nextSession || !isElevatedViewerRole(nextSession.viewerRole)) {
      persistAdminSession(null);
      setAuthSession(null);
      return response;
    }

    persistAdminSession(nextSession);
    setAuthSession(nextSession);
    response = await makeRequest(nextSession);
    return response;
  };

  const loadAppAccessSettings = async () => {
    const response = await runAuthenticatedFetch(
      "/associations/current/app-access",
      {
        method: "GET",
      },
    );

    if (!response.ok) {
      throw new Error("Unable to load app access settings.");
    }

    const payload = await response.json().catch(() => ({}));
    setAppPermissions(normalizeAppAccessSettings(payload?.appAccess));
  };

  const loadSessionReport = async () => {
    const response = await runAuthenticatedFetch(
      "/users/session-report?activeWindowMinutes=5",
      {
        method: "GET",
      },
    );

    if (!response.ok) {
      throw new Error("Unable to load session activity.");
    }

    const payload = await response.json().catch(() => ({}));
    setSessionReportSummary({
      activeUsers: Number(payload?.summary?.activeUsers || 0),
      activeUsersThisMonth: Number(payload?.summary?.activeUsersThisMonth || 0),
      activeUsersLastSixMonths: Number(
        payload?.summary?.activeUsersLastSixMonths || 0,
      ),
    });
  };

  const saveAppAccessChanges = () => {
    void (async () => {
      setIsSavingAppAccess(true);
      setAppAccessFeedback("");

      try {
        const response = await runAuthenticatedFetch(
          "/associations/current/app-access",
          {
            method: "PATCH",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify(appPermissions),
          },
        );

        if (!response.ok) {
          throw new Error("Unable to save app access settings.");
        }

        const payload = await response.json().catch(() => null);
        if (payload?.appAccess) {
          setAppPermissions(normalizeAppAccessSettings(payload.appAccess));
        }
        setAppAccessFeedback("App access settings saved.");
      } catch (error) {
        setAppAccessFeedback(
          error instanceof Error
            ? error.message
            : "Unable to save app access settings.",
        );
      } finally {
        setIsSavingAppAccess(false);
      }
    })();
  };

  const submitSuperAdminInvite = async () => {
    if (!superAdminInviteForm.email.trim()) {
      setSuperAdminInviteFeedback("Enter the email to create a super admin.");
      return;
    }

    setIsCreatingSuperAdmin(true);
    setSuperAdminInviteFeedback("");

    try {
      const response = await runAuthenticatedFetch("/users/super-admins", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          email: superAdminInviteForm.email.trim(),
          firstName: superAdminInviteForm.firstName.trim(),
          lastName: superAdminInviteForm.lastName.trim(),
        }),
      });

      const payload = await response.json().catch(() => null);
      if (!response.ok) {
        setSuperAdminInviteFeedback(
          payload?.error || "Unable to create super admin.",
        );
        return;
      }

      setSuperAdminInviteForm({
        email: "",
        firstName: "",
        lastName: "",
      });
      setSuperAdminInviteFeedback(
        `${payload?.user?.email || "The user"} is now a super admin. Default password: ${payload?.defaultPassword || "Admin@123"}.`,
      );
      await loadMembers();
    } catch {
      setSuperAdminInviteFeedback("Could not reach the backend service.");
    } finally {
      setIsCreatingSuperAdmin(false);
    }
  };

  const submitAdminLogin = async () => {
    if (!loginForm.email.trim() || !loginForm.password) {
      setLoginError("Enter the admin email and password to continue.");
      return;
    }

    setIsLoggingIn(true);
    setLoginError("");

    try {
      const response = await fetch(`${apiBaseUrl}/auth/login`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          username: loginForm.email.trim(),
          password: loginForm.password,
        }),
      });

      const payload = await response.json().catch(() => null);
      if (!response.ok) {
        setLoginError(payload?.error || "Admin login failed.");
        return;
      }

      const nextSession = normalizeAuthSession(payload);
      if (!nextSession || !isElevatedViewerRole(nextSession.viewerRole)) {
        setLoginError("This account does not have admin access.");
        return;
      }

      persistAdminSession(nextSession);
      setAuthSession(nextSession);
    } catch {
      setLoginError("Could not reach the backend login service.");
    } finally {
      setIsLoggingIn(false);
    }
  };

  useEffect(() => {
    let cancelled = false;

    const restoreSession = async () => {
      const storedSession = readStoredAdminSession();
      if (!storedSession) {
        if (!cancelled) {
          setAuthReady(true);
        }
        return;
      }

      try {
        const response = await runAuthenticatedFetch(
          "/auth/me",
          { method: "GET" },
          storedSession,
        );

        if (!response.ok) {
          persistAdminSession(null);
          if (!cancelled) {
            setAuthSession(null);
            setAuthReady(true);
          }
          return;
        }

        const payload = await response.json();
        const nextSession = normalizeAuthSession(payload, storedSession);
        if (!nextSession || !isElevatedViewerRole(nextSession.viewerRole)) {
          persistAdminSession(null);
          if (!cancelled) {
            setAuthSession(null);
            setAuthReady(true);
          }
          return;
        }

        persistAdminSession(nextSession);
        if (!cancelled) {
          setAuthSession(nextSession);
          setAuthReady(true);
        }
      } catch {
        persistAdminSession(null);
        if (!cancelled) {
          setAuthSession(null);
          setAuthReady(true);
        }
      }
    };

    void restoreSession();

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    const storedPosts = readStoredCommitteePostOptions();
    if (storedPosts.length === 0) {
      return;
    }

    setCommitteePostMasterList((current) =>
      buildCommitteePostOptions(committeeMembers, [...current, ...storedPosts]),
    );
  }, []);

  useEffect(() => {
    const storedTypes = readStoredMembershipTypeOptions();
    if (storedTypes.length === 0) {
      return;
    }

    setMembershipTypeMasterList((current) =>
      buildMembershipTypeOptions(
        memberTabData["All Members"] ?? [],
        [...current, ...storedTypes],
      ),
    );
  }, []);

  const loadMembers = async () => {
    const [membersResponse, usersResponse] = await Promise.all([
      fetch(`${apiBaseUrl}/members`),
      runAuthenticatedFetch("/users?role=member"),
    ]);

    if (!membersResponse.ok) {
      return;
    }

    const membersPayload = await membersResponse.json();
    const usersPayload = usersResponse.ok
      ? await usersResponse.json()
      : { users: [] };

    if (
      !Array.isArray(membersPayload.members) ||
      membersPayload.members.length === 0
    ) {
      return;
    }

    setMemberTabData(
      buildMemberTabData(
        mergeMemberUsers(
          membersPayload.members,
          Array.isArray(usersPayload.users) ? usersPayload.users : [],
        ),
      ),
    );
    setMemberAccessEdits({});
  };

  const loadMemberPosts = async () => {
    const response = await fetch(`${apiBaseUrl}/member-posts`);
    if (!response.ok) {
      return;
    }

    const payload = await response.json();
    const posts = Array.isArray(payload.posts)
      ? payload.posts.map(mapApiMemberPostToUi)
      : [];
    setMemberContentPosts(posts);
    setContentPostEdits(
      Object.fromEntries(
        posts.map((post) => [
          post.id,
          {
            status: post.status,
            displayStart: post.displayStart,
            displayEnd: post.displayEnd,
          },
        ]),
      ),
    );
  };

  const loadTimelinePosts = async () => {
    const response = await fetch(`${apiBaseUrl}/timeline-posts`);
    if (!response.ok) {
      return;
    }

    const payload = await response.json();
    const posts = Array.isArray(payload.posts)
      ? payload.posts.map(mapApiTimelinePostToUi)
      : [];
    setTimelinePosts(posts);
    setTimelineAccessEdits(
      Object.fromEntries(
        posts.map((post) => [
          post.id,
          {
            status: post.status,
            displayStart: post.displayStart || "",
            displayEnd: post.displayEnd || "",
          },
        ]),
      ),
    );
  };

  const loadAppBanners = async () => {
    const response = await fetch(`${apiBaseUrl}/app-banners`);
    if (!response.ok) {
      return;
    }

    const payload = await response.json();
    const banners = Array.isArray(payload.banners)
      ? payload.banners.map(mapApiAppBannerToUi)
      : [];
    setAppBanners(banners);
    setAppBannerAccessEdits(
      Object.fromEntries(
        banners.map((banner) => [
          banner.id,
          {
            status: banner.status,
            paymentReceived: banner.paymentReceived,
            paymentMode: banner.paymentMode,
            paymentRemarks: banner.paymentRemarks,
            displayStart: banner.displayStart || "",
            displayEnd: banner.displayEnd || "",
            displayIndex: banner.displayIndex || "",
          },
        ]),
      ),
    );
  };

  const loadAssociationProfile = async () => {
    const response = await fetch(`${apiBaseUrl}/associations/current`);
    if (!response.ok) {
      return;
    }

    const payload = await response.json();
    const nextProfile = mapAssociationProfileToForm(
      payload.association ?? defaultAssociationProfile,
    );
    setAssociationProfile(nextProfile);
    setAssociationProfileForm(nextProfile);
    const nextAbout = mapAssociationAboutToForm(
      payload.association?.aboutContent,
    );
    setAssociationAbout(nextAbout);
    setAssociationAboutForm(nextAbout);
    const nextGalleryFolders = mapAssociationGalleryFolders(
      payload.association?.galleryFolders,
    );
    setGalleryFolders(nextGalleryFolders);
    setSelectedGalleryFolderIds((current) =>
      current.filter((folderId) =>
        nextGalleryFolders.some((folder) => folder.id === folderId),
      ),
    );
    setSelectedGalleryPhotoIds((current) => {
      const nextActiveFolderId = nextGalleryFolders.some(
        (folder) => folder.id === activeGalleryFolderId,
      )
        ? activeGalleryFolderId
        : "";
      const nextActiveFolder =
        nextGalleryFolders.find((folder) => folder.id === nextActiveFolderId) ??
        null;

      return current.filter((photoId) =>
        nextActiveFolder?.photos?.some((photo) => photo.id === photoId),
      );
    });
    setActiveGalleryFolderId((current) =>
      nextGalleryFolders.some((folder) => folder.id === current)
        ? current
        : "",
    );
    setGalleryItems(
      mapAssociationGalleryItems(payload.association?.galleryItems),
    );
    setCircularDocuments(
      mapAssociationCircularDocuments(payload.association?.circularDocuments),
    );
  };

  const loadEventsArena = async () => {
    const [eventTypesResponse, eventsResponse] = await Promise.all([
      fetch(`${apiBaseUrl}/events/types`),
      fetch(`${apiBaseUrl}/events`),
    ]);

    if (eventTypesResponse.ok) {
      const payload = await eventTypesResponse.json();
      setEventTypes(
        Array.isArray(payload.eventTypes) ? payload.eventTypes : [],
      );
    }

    if (eventsResponse.ok) {
      const payload = await eventsResponse.json();
      setCreatedEvents(Array.isArray(payload.events) ? payload.events : []);
    }
  };

  const loadVendors = async () => {
    const response = await fetch(`${apiBaseUrl}/vendors`);
    if (!response.ok) {
      return;
    }

    const payload = await response.json();
    const vendors = Array.isArray(payload.vendors)
      ? payload.vendors.map(mapApiVendorToUi)
      : [];
    if (vendors.length === 0) {
      setVendorRecords([]);
      setVendorAccessEdits({});
      return;
    }

    setVendorRecords(vendors);
    setVendorAccessEdits({});
  };

  useEffect(() => {
    const mediaQuery = window.matchMedia("(max-width: 900px)");

    const syncSidebarViewportState = (event) => {
      const isMobile = event.matches;
      setIsMobileViewport(isMobile);
      setIsSidebarOpen(!isMobile);
    };

    syncSidebarViewportState(mediaQuery);
    mediaQuery.addEventListener("change", syncSidebarViewportState);

    return () =>
      mediaQuery.removeEventListener("change", syncSidebarViewportState);
  }, []);

  useEffect(() => {
    const firstMemberId = (memberTabData["All Members"] ?? [])[0]?.id ?? "";
    if (!firstMemberId) {
      return;
    }

    setMemberMediaPostForm((current) =>
      current.memberId
        ? current
        : {
            ...current,
            memberId: firstMemberId,
          },
    );
  }, [memberTabData]);

  useEffect(() => {
    setCommitteePostMasterList((current) => {
      const nextOptions = buildCommitteePostOptions(committeeMembers, current);
      return areStringListsEqual(current, nextOptions) ? current : nextOptions;
    });
  }, [committeeMembers]);

  useEffect(() => {
    persistCommitteePostOptions(committeePostMasterList);
  }, [committeePostMasterList]);

  useEffect(() => {
    setMembershipTypeMasterList((current) => {
      const nextOptions = buildMembershipTypeOptions(
        memberTabData["All Members"] ?? [],
        current,
      );
      return areStringListsEqual(current, nextOptions) ? current : nextOptions;
    });
  }, [memberTabData]);

  useEffect(() => {
    persistMembershipTypeOptions(membershipTypeMasterList);
  }, [membershipTypeMasterList]);

  useEffect(() => {
    let isActive = true;

    const loadMembersData = async () => {
      try {
        const [membersResponse, usersResponse, postsResponse] =
          await Promise.all([
            fetch(`${apiBaseUrl}/members`),
            runAuthenticatedFetch("/users?role=member"),
            fetch(`${apiBaseUrl}/member-posts`),
          ]);

        if (!membersResponse.ok) {
          return;
        }

        const membersPayload = await membersResponse.json();
        const usersPayload = usersResponse.ok
          ? await usersResponse.json()
          : { users: [] };

        if (
          !isActive ||
          !Array.isArray(membersPayload.members) ||
          membersPayload.members.length === 0
        ) {
          return;
        }

        setMemberTabData(
          buildMemberTabData(
            mergeMemberUsers(
              membersPayload.members,
              Array.isArray(usersPayload.users) ? usersPayload.users : [],
            ),
          ),
        );

        if (postsResponse.ok) {
          const postsPayload = await postsResponse.json();
          const posts = Array.isArray(postsPayload.posts)
            ? postsPayload.posts.map(mapApiMemberPostToUi)
            : [];
          setMemberContentPosts(posts);
          setContentPostEdits(
            Object.fromEntries(
              posts.map((post) => [
                post.id,
                {
                  status: post.status,
                  displayStart: post.displayStart,
                  displayEnd: post.displayEnd,
                },
              ]),
            ),
          );
        }
      } catch (_error) {
        // Keep seeded local data when the API is unavailable.
      }
    };

    loadMembersData();
    void loadEventsArena();
    void loadVendorTaxonomy();
    void loadVendors();
    void loadTimelinePosts();
    void loadAppBanners();

    return () => {
      isActive = false;
    };
  }, []);

  useEffect(() => {
    if (!authSession) {
      setSessionReportSummary({
        activeUsers: 0,
        activeUsersThisMonth: 0,
        activeUsersLastSixMonths: 0,
      });
      return;
    }

    void (async () => {
      try {
        await loadAppAccessSettings();
      } catch (_error) {
        setAppAccessFeedback("Unable to load app access settings.");
      }
    })();

    void (async () => {
      try {
        await loadSessionReport();
      } catch (_error) {
        setSessionReportSummary({
          activeUsers: 0,
          activeUsersThisMonth: 0,
          activeUsersLastSixMonths: 0,
        });
      }
    })();
  }, [authSession]);

  useEffect(() => {
    setTimelinePostForm((current) => {
      if (
        current.postedBy ||
        current.memberId ||
        current.vendorId ||
        current.sourceType !== "ASSOCIATION"
      ) {
        return current;
      }

      return {
        ...current,
        postedBy: associationProfile.name || defaultAssociationProfile.name,
        contactNumber:
          associationProfile.helpdeskNumber ||
          associationProfile.contactNumbers ||
          current.contactNumber,
      };
    });
  }, [associationProfile]);

  useEffect(() => {
    setAppBannerForm((current) => {
      if (current.vendorId) {
        return current;
      }

      const firstVendorId = vendorRecords[0]?.id ?? "";
      const firstVendor = vendorRecords.find(
        (vendor) => vendor.id === firstVendorId,
      );
      return firstVendorId
        ? {
            ...current,
            vendorId: firstVendorId,
            contactNumber: firstVendor?.phone || current.contactNumber,
          }
        : current;
    });
  }, [vendorRecords]);

  useEffect(() => {
    let isActive = true;

    const loadAssociationData = async () => {
      try {
        const response = await fetch(`${apiBaseUrl}/associations/current`);
        if (!response.ok) {
          return;
        }

        const payload = await response.json();
        if (!isActive) {
          return;
        }

        const nextProfile = mapAssociationProfileToForm(
          payload.association ?? defaultAssociationProfile,
        );
        setAssociationProfile(nextProfile);
        setAssociationProfileForm(nextProfile);
        const nextAbout = mapAssociationAboutToForm(
          payload.association?.aboutContent,
        );
        setAssociationAbout(nextAbout);
        setAssociationAboutForm(nextAbout);
        const nextGalleryFolders = mapAssociationGalleryFolders(
          payload.association?.galleryFolders,
        );
        setGalleryFolders(nextGalleryFolders);
        setSelectedGalleryFolderIds((current) =>
          current.filter((folderId) =>
            nextGalleryFolders.some((folder) => folder.id === folderId),
          ),
        );
        setSelectedGalleryPhotoIds((current) => {
          const nextActiveFolderId = nextGalleryFolders.some(
            (folder) => folder.id === activeGalleryFolderId,
          )
            ? activeGalleryFolderId
            : "";
          const nextActiveFolder =
            nextGalleryFolders.find(
              (folder) => folder.id === nextActiveFolderId,
            ) ?? null;

          return current.filter((photoId) =>
            nextActiveFolder?.photos?.some((photo) => photo.id === photoId),
          );
        });
        setActiveGalleryFolderId((current) =>
          nextGalleryFolders.some((folder) => folder.id === current)
            ? current
            : "",
        );
        setGalleryItems(
          mapAssociationGalleryItems(payload.association?.galleryItems),
        );
        setCircularDocuments(
          mapAssociationCircularDocuments(
            payload.association?.circularDocuments,
          ),
        );
      } catch (_error) {
        // Keep default local profile state when the API is unavailable.
      }
    };

    loadAssociationData();

    return () => {
      isActive = false;
    };
  }, []);

  const filteredFinanceStatementEntries = financeStatementEntries.filter(
    (entry) => {
      const matchesType =
        !financeStatementFilterType ||
        entry.entryType === financeStatementFilterType ||
        entry.direction === financeStatementFilterType;
      const matchesFrom =
        !financeStatementDateFrom || entry.date >= financeStatementDateFrom;
      const matchesTo =
        !financeStatementDateTo || entry.date <= financeStatementDateTo;
      return matchesType && matchesFrom && matchesTo;
    },
  );
  const activeTabItems =
    activeAssociationTab === "Finance"
      ? (financeRecords[activeFinanceTab] ?? [])
      : (associationTabData[activeAssociationTab] ?? []);
  const activeSelectedIds =
    activeAssociationTab === "Finance"
      ? []
      : (selectedRecords[activeAssociationTab] ?? []);
  const rawActiveMemberItems =
    activeMemberTab === "Master"
      ? (memberTabData["All Members"] ?? [])
      : (memberTabData[activeMemberTab] ?? []);
  const activeMemberItems = rawActiveMemberItems.filter((member) => {
    if (activeSection !== topLevelSections.members) {
      return true;
    }

    const query = topbarSearchQuery.trim().toLowerCase();
    if (!query) {
      return true;
    }

    return `${member.name} ${member.company} ${member.email} ${member.phone} ${member.gst} ${member.membershipType}`
      .toLowerCase()
      .includes(query);
  });
  const filteredVendorOverviewItems = vendorRecords.filter((vendor) => {
    const query = topbarSearchQuery.trim().toLowerCase();
    const matchesSearch =
      !query ||
      `${vendor.name} ${vendor.company} ${vendor.category} ${vendor.city} ${vendor.email} ${vendor.phone} ${vendor.registrationStatus}`
        .toLowerCase()
        .includes(query);
    const matchesStatus =
      !vendorOverviewStatusFilter ||
      vendor.registrationStatus === vendorOverviewStatusFilter;
    return matchesSearch && matchesStatus;
  });
  const eventTimelineData = buildEventTimelineGroups(createdEvents);
  const activeMemberSelectedIds = selectedMemberRecords[activeMemberTab] ?? [];
  const timelineMemberOptions = (memberTabData["All Members"] ?? []).map(
    (member) => ({
      id: member.id,
      label: `${member.name}${member.company ? ` - ${member.company}` : ""}`,
    }),
  );
  const timelineVendorOptions = vendorRecords.map((vendor) => ({
    id: vendor.id,
    label: `${vendor.company}${vendor.category ? ` - ${vendor.category}` : ""}`,
  }));
  const timelineAssociationLabel =
    associationProfile.name || defaultAssociationProfile.name;
  const appBannerVendorOptions = vendorRecords.map((vendor) => ({
    id: vendor.id,
    label: `${vendor.company}${vendor.category ? ` - ${vendor.category}` : ""}`,
  }));
  const dashboardTimelinePosts = timelinePosts
    .filter(isTimelinePostVisibleOnDashboard)
    .sort((left, right) =>
      String(right.createdAt || "").localeCompare(String(left.createdAt || "")),
    );
  const filteredAdminTimelinePosts = timelinePosts.filter((post) => {
    const query = adminTimelineSearch.trim().toLowerCase();
    if (!query) {
      return true;
    }

    return `${post.caption} ${post.sourceName} ${post.postedBy} ${post.status}`
      .toLowerCase()
      .includes(query);
  });
  const adminAppBannerItems = appBanners.filter((banner) => {
    const query = adminAppBannerSearch.trim().toLowerCase();
    if (!query) {
      return true;
    }

    return `${banner.vendorName} ${banner.shortText} ${banner.contactNumber} ${banner.status}`
      .toLowerCase()
      .includes(query);
  });
  const dashboardAppBanners = appBanners
    .filter(isAppBannerVisibleOnDashboard)
    .sort(
      (left, right) => Number(left.displayIndex) - Number(right.displayIndex),
    );
  const allMembers = memberTabData["All Members"] ?? [];
  const primaryMembersCount = allMembers.filter(
    (member) => normalizeMembershipTypeLabel(member.membershipType || "") === "Primary",
  ).length;
  const associateMembersCount = allMembers.filter(
    (member) => normalizeMembershipTypeLabel(member.membershipType || "") === "Associate",
  ).length;
  const guestMembersCount = allMembers.filter(
    (member) => normalizeMembershipTypeLabel(member.membershipType || "") === "Temporary Visit",
  ).length;
  const approvedVendorsCount = vendorRecords.filter(
    (vendor) => vendor.appAccessStatus === "Approved",
  ).length;
  const pendingVendorsCount = vendorRecords.filter(
    (vendor) => vendor.appAccessStatus === "Pending Approval",
  ).length;
  const suspendedVendorsCount = vendorRecords.filter(
    (vendor) => vendor.appAccessStatus === "Suspended",
  ).length;
  const activeUsersCount = sessionReportSummary.activeUsers;
  const activeUsersThisMonthCount =
    sessionReportSummary.activeUsersThisMonth;
  const activeUsersLastSixMonthsCount =
    sessionReportSummary.activeUsersLastSixMonths;
  const featuredDashboardVendors = vendorRecords
    .filter((vendor) => vendor.registrationStatus === "Active")
    .slice(0, 8);
  const dashboardShortcutItems = [
    {
      label: "Association",
      icon: "A",
      colors: ["#0F2D7A", "#1D4ED8"],
      onClick: () => {
        setActiveSection(topLevelSections.association);
        setActiveAssociationTab("Profile");
      },
    },
    {
      label: "Circulars",
      icon: "C",
      colors: ["#7C2D12", "#EA580C"],
      onClick: () => {
        setActiveSection(topLevelSections.association);
        setActiveAssociationTab("Circulars");
      },
    },
    {
      label: "Gallery",
      icon: "G",
      colors: ["#4338CA", "#7C3AED"],
      onClick: () => {
        setActiveSection(topLevelSections.association);
        setActiveAssociationTab("Gallery");
      },
    },
    {
      label: "Members",
      icon: "M",
      colors: ["#065F46", "#10B981"],
      onClick: () => {
        setActiveSection(topLevelSections.members);
        setActiveMemberTab("Primary Members");
      },
    },
    {
      label: "Vendors",
      icon: "V",
      colors: ["#9A3412", "#F59E0B"],
      onClick: () => {
        setActiveSection(topLevelSections.vendors);
      },
    },
    {
      label: "Events",
      icon: "E",
      colors: ["#7F1D1D", "#EF4444"],
      onClick: () => {
        setActiveSection(topLevelSections.events);
        setActiveEventsTab("Master");
      },
    },
    {
      label: "Timeline",
      icon: "T",
      colors: ["#312E81", "#6366F1"],
      onClick: () => {
        setActiveSection(topLevelSections.timeline);
      },
    },
    {
      label: "Profile",
      icon: "P",
      colors: ["#374151", "#111827"],
      onClick: () => {
        window.location.href = "/profile";
      },
    },
    {
      label: "Admin",
      icon: "D",
      colors: ["#581C87", "#A21CAF"],
      onClick: () => {
        setActiveSection(topLevelSections.admin);
        setActiveAdminAccessSection("App Access");
      },
    },
  ];
  const expiringMembersCount = (memberTabData["All Members"] ?? []).filter(
    (member) => member.expiryStatus === "expiring-soon",
  ).length;
  const filteredAdminMembers = (memberTabData["All Members"] ?? [])
    .filter((member) => {
      const query = adminMemberSearch.trim().toLowerCase();
      const matchesFilter =
        activeAdminMemberFilter === "All"
          ? ["Primary", "Associate", "Temporary Visit", "Committee"].includes(
              member.membershipType,
            )
          : activeAdminMemberFilter === "Guest"
            ? member.membershipType === "Temporary Visit"
            : activeAdminMemberFilter === "Committee"
              ? member.membershipType === "Committee"
              : member.membershipType === activeAdminMemberFilter;

      if (!matchesFilter) {
        return false;
      }

      if (!query) {
        return true;
      }

      return `${member.name} ${member.company} ${member.membershipType}`
        .toLowerCase()
        .includes(query);
    })
    .map((member) => ({
      ...member,
      appAccessStatus: memberAccessEdits[member.id] ?? member.appAccessStatus,
    }));
  const pendingRegistrationRequests = (memberTabData["All Members"] ?? [])
    .map((member) => ({
      ...member,
      appAccessStatus: memberAccessEdits[member.id] ?? member.appAccessStatus,
    }))
    .filter((member) => member.appAccessStatus === "Pending Approval");
  const dashboardPendingRegistrationRequests = pendingRegistrationRequests.filter(
    (member) => {
      if (dashboardApprovalTab === "Guest") {
        return member.membershipType === "Temporary Visit";
      }

      return member.membershipType === dashboardApprovalTab;
    },
  );
  const contentMemberMatches = (memberTabData["All Members"] ?? []).filter(
    (member) => {
      const query = adminContentMemberSearch.trim().toLowerCase();
      if (!query) {
        return true;
      }

      return `${member.name} ${member.company}`.toLowerCase().includes(query);
    },
  );
  const filteredMemberContentPosts = memberContentPosts.filter((post) => {
    const query = adminContentMemberSearch.trim().toLowerCase();
    const postStatus = (
      contentPostEdits[post.id]?.status ?? post.status
    ).toLowerCase();
    const matchesQuery =
      !query ||
      `${post.title} ${post.summary} ${post.postedBy} ${postStatus}`
        .toLowerCase()
        .includes(query);

    if (!matchesQuery) {
      return false;
    }

    if (selectedContentMemberIds.length === 0) {
      return true;
    }

    return selectedContentMemberIds.includes(post.memberId);
  });
  const vendorSummaryStats = [
    { value: vendorRecords.length.toString(), label: "Registered Vendors" },
    {
      value: vendorRecords
        .filter((vendor) => vendor.registrationStatus === "Active")
        .length.toString(),
      label: "Active",
    },
    {
      value: vendorRecords
        .filter((vendor) => vendor.registrationStatus === "Suspended")
        .length.toString(),
      label: "Suspended",
    },
    {
      value: vendorRecords
        .filter((vendor) => vendor.registrationStatus === "Lapsed")
        .length.toString(),
      label: "Lapsed",
    },
  ];
  const filteredAdminVendors = vendorRecords
    .filter((vendor) => {
      const query = adminVendorSearch.trim().toLowerCase();
      if (!query) {
        return true;
      }

      return `${vendor.name} ${vendor.company} ${vendor.vendorType}`
        .toLowerCase()
        .includes(query);
    })
    .map((vendor) => ({
      ...vendor,
      appAccessStatus: vendorAccessEdits[vendor.id] ?? vendor.appAccessStatus,
    }));
  const vendorStatusRequests = vendorRecords
    .filter((vendor) => vendor.appAccessStatus === "Pending Approval")
    .filter((vendor) => {
      const query = vendorStatusSearch.trim().toLowerCase();
      if (!query) {
        return true;
      }

      return `${vendor.name} ${vendor.company} ${vendor.category} ${vendor.vendorType} ${vendor.email}`
        .toLowerCase()
        .includes(query);
    });
  const selectedVendorReview =
    vendorStatusRequests.find(
      (vendor) => vendor.id === selectedVendorReviewId,
    ) ??
    vendorRecords.find((vendor) => vendor.id === selectedVendorReviewId) ??
    null;
  const filteredVendorContentPosts = vendorContentPosts.filter((post) => {
    const query = adminVendorSearch.trim().toLowerCase();
    const postStatus = (
      vendorContentPostEdits[post.id]?.status ?? post.status
    ).toLowerCase();
    const matchesQuery =
      !query ||
      `${post.title} ${post.summary} ${post.postedBy} ${postStatus}`
        .toLowerCase()
        .includes(query);

    if (!matchesQuery) {
      return false;
    }

    if (selectedContentVendorIds.length === 0) {
      return true;
    }

    return selectedContentVendorIds.includes(post.vendorId);
  });
  const filteredAdminEvents = createdEvents.filter((eventItem) => {
    const query = adminEventSearch.trim().toLowerCase();
    if (!query) {
      return true;
    }

    return `${eventItem.name} ${eventItem.type} ${eventItem.venue} ${eventItem.date} ${eventItem.audience}`
      .toLowerCase()
      .includes(query);
  });

  const toggleSelectRecord = (tab, recordId) => {
    setSelectedRecords((current) => {
      const currentSelection = current[tab] ?? [];
      const nextSelection = currentSelection.includes(recordId)
        ? currentSelection.filter((id) => id !== recordId)
        : [...currentSelection, recordId];

      return {
        ...current,
        [tab]: nextSelection,
      };
    });
  };

  const toggleSelectAllRecords = (tab) => {
    setSelectedRecords((current) => {
      const allIds = (associationTabData[tab] ?? []).map((item) => item.id);
      const currentSelection = current[tab] ?? [];

      return {
        ...current,
        [tab]: currentSelection.length === allIds.length ? [] : allIds,
      };
    });
  };

  const deleteSelectedRecords = (tab) => {
    const selectedIds = selectedRecords[tab] ?? [];
    if (selectedIds.length === 0) {
      return;
    }

    setAssociationTabData((current) => ({
      ...current,
      [tab]: (current[tab] ?? []).filter(
        (item) => !selectedIds.includes(item.id),
      ),
    }));

    setSelectedRecords((current) => ({
      ...current,
      [tab]: [],
    }));
  };

  const deleteSingleRecord = (tab, recordId) => {
    setAssociationTabData((current) => ({
      ...current,
      [tab]: (current[tab] ?? []).filter((item) => item.id !== recordId),
    }));

    setSelectedRecords((current) => ({
      ...current,
      [tab]: (current[tab] ?? []).filter((id) => id !== recordId),
    }));
  };

  const addNewRecord = (tab) => {
    const count = (associationTabData[tab] ?? []).length + 1;
    const draftItem = {
      id: `${tab.toLowerCase().replace(/\s+/g, "-")}-${Date.now()}`,
      title: `${tab} Draft ${count}`,
      meta: `New ${tab.toLowerCase()} record created for future form-driven CRUD flow.`,
      badge: "Draft",
    };

    setAssociationTabData((current) => ({
      ...current,
      [tab]: [draftItem, ...(current[tab] ?? [])],
    }));
  };

  const toggleSelectMemberRecord = (tab, recordId) => {
    setSelectedMemberRecords((current) => {
      const currentSelection = current[tab] ?? [];
      const nextSelection = currentSelection.includes(recordId)
        ? currentSelection.filter((id) => id !== recordId)
        : [...currentSelection, recordId];

      return {
        ...current,
        [tab]: nextSelection,
      };
    });
  };

  const toggleSelectAllMemberRecords = (tab) => {
    setSelectedMemberRecords((current) => {
      const allIds = (memberTabData[tab] ?? []).map((item) => item.id);
      const currentSelection = current[tab] ?? [];

      return {
        ...current,
        [tab]: currentSelection.length === allIds.length ? [] : allIds,
      };
    });
  };

  const deleteSelectedMemberRecords = (tab) => {
    void (async () => {
      const selectedIds = selectedMemberRecords[tab] ?? [];
      if (selectedIds.length === 0) {
        setMemberDirectoryFeedback("Select one or more members first.");
        return;
      }

      setIsSavingMemberDirectory(true);
      setMemberDirectoryFeedback("");

      try {
        await Promise.all(
          selectedIds.map(async (memberId) => {
            const response = await runAuthenticatedFetch(`/members/${memberId}`, {
              method: "DELETE",
            });

            if (!response.ok && response.status !== 204) {
              let message = "Unable to delete one or more selected members.";
              try {
                const result = await response.json();
                if (result?.error) {
                  message = result.error;
                }
              } catch {}
              throw new Error(message);
            }
          }),
        );

        setMemberTabData((current) =>
          buildMemberTabData(
            (current["All Members"] ?? []).filter(
              (item) => !selectedIds.includes(item.id),
            ),
          ),
        );

        setSelectedMemberRecords(
          Object.fromEntries(memberArenaTabs.map((memberTab) => [memberTab, []])),
        );
        setMemberDirectoryFeedback(
          `${selectedIds.length} member${selectedIds.length === 1 ? "" : "s"} deleted.`,
        );
      } catch (error) {
        setMemberDirectoryFeedback(
          error instanceof Error
            ? error.message
            : "Unable to delete the selected members right now.",
        );
      } finally {
        setIsSavingMemberDirectory(false);
      }
    })();
  };

  const deleteSingleMemberRecord = (tab, recordId) => {
    void (async () => {
      setIsSavingMemberDirectory(true);
      setMemberDirectoryFeedback("");

      try {
        const response = await runAuthenticatedFetch(`/members/${recordId}`, {
          method: "DELETE",
        });

        if (!response.ok && response.status !== 204) {
          let message = "Unable to delete the member right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setMemberDirectoryFeedback(message);
          return;
        }

        setMemberTabData((current) =>
          buildMemberTabData(
            (current["All Members"] ?? []).filter((item) => item.id !== recordId),
          ),
        );

        setSelectedMemberRecords((current) =>
          Object.fromEntries(
            memberArenaTabs.map((memberTab) => [
              memberTab,
              (current[memberTab] ?? []).filter((id) => id !== recordId),
            ]),
          ),
        );
        setMemberDirectoryFeedback("Member deleted.");
      } finally {
        setIsSavingMemberDirectory(false);
      }
    })();
  };

  const openMemberForm = () => {
    resetMemberMasterForm();
    setIsMemberFormOpen(true);
  };
  const updateMemberMasterForm = (field, value) => {
    setMemberMasterFeedback("");
    setMemberMasterForm((current) => {
      const matchingField = membershipFormFields.find(
        (item) => item.id === field,
      );
      if (matchingField && !matchingField.key) {
        return {
          ...current,
          customFieldValues: {
            ...current.customFieldValues,
            [field]: value,
          },
        };
      }

      const mappedKey = matchingField?.key ?? field;

      return {
        ...current,
        [mappedKey]: value,
      };
    });
  };
  const updateMemberMasterImage = (file) => {
    void (async () => {
      if (!file) {
        return;
      }

      const nextImage = await readFileAsDataUrl(file);
      setMemberMasterFeedback("");
      setMemberMasterForm((current) => ({
        ...current,
        photoUrl: nextImage,
      }));
    })();
  };
  const resetMemberMasterForm = () => {
    setMemberMasterFeedback("");
    setMemberMasterForm(defaultMemberAdminForm);
    setEditingMemberId("");
  };
  const editMemberRecord = (memberId) => {
    setMemberMasterFeedback("");
    const member = (memberTabData["All Members"] ?? []).find(
      (item) => item.id === memberId,
    );
    if (!member) {
      return;
    }

    setMemberMasterForm({
      name: member.name ?? "",
      company: member.company ?? "",
      companyAddress: member.address ?? "",
      gst: member.gst ?? "",
      photoUrl: member.photoUrl ?? "",
      membershipDetails: member.membershipDetails ?? "",
      email: member.email ?? "",
      phone: member.phone ?? "",
      membershipType: member.membershipType ?? "Primary",
      membershipStartDate: member.membershipStartDate ?? "",
      membershipEndDate: member.membershipEndDate ?? "",
      paymentAmount: member.paymentAmount ?? "",
      paymentStatus: member.paymentStatus ?? "Pending",
      badge: member.badge ?? "Draft",
      appAccessStatus: member.appAccessStatus ?? "Pending Approval",
      customFieldValues: member.customFieldValues ?? {},
    });
    setEditingMemberId(memberId);
    setIsMemberFormOpen(true);
  };
  const saveMemberRecord = () => {
    void (async () => {
      const normalizedName = memberMasterForm.name.trim();
      const normalizedCompany = memberMasterForm.company.trim();
      const normalizedEmail = memberMasterForm.email.trim();
      if (!normalizedName || !normalizedCompany || !normalizedEmail) {
        setMemberMasterFeedback(
          "Name, company, and email are required before saving.",
        );
        return;
      }

      const [firstName, ...restNameParts] = normalizedName
        .split(" ")
        .filter(Boolean);
      const payload = {
        firstName: firstName || normalizedName,
        lastName: restNameParts.join(" "),
        email: normalizedEmail,
        phone: memberMasterForm.phone.trim(),
        address: memberMasterForm.companyAddress.trim(),
        gst: memberMasterForm.gst.trim(),
        photoUrl: memberMasterForm.photoUrl,
        companyName: normalizedCompany,
        roleTitle: memberMasterForm.membershipType,
        membershipDetails: memberMasterForm.membershipDetails.trim(),
        membershipStartDate: memberMasterForm.membershipStartDate || undefined,
        membershipEndDate: memberMasterForm.membershipEndDate || undefined,
        paymentAmount: memberMasterForm.paymentAmount.trim(),
        paymentStatus:
          memberMasterForm.paymentStatus === "Paid"
            ? "PAID"
            : memberMasterForm.paymentStatus === "Overdue"
              ? "OVERDUE"
              : memberMasterForm.paymentStatus === "Waived"
                ? "WAIVED"
                : "PENDING",
        customFieldValues: memberMasterForm.customFieldValues,
      };

      setIsSavingMemberMaster(true);
      setMemberMasterFeedback("");

      try {
        const response = await runAuthenticatedFetch(
          `/members${editingMemberId ? `/${editingMemberId}` : ""}`,
          {
            method: editingMemberId ? "PATCH" : "POST",
            body: JSON.stringify(payload),
          },
        );

        if (!response.ok) {
          let message = "Unable to save the member record right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setMemberMasterFeedback(message);
          return;
        }

        const savedPayload = await response.json();
        const savedMember = mapApiMemberToUi(savedPayload.member);

        setMemberTabData((current) => {
          const allMembers = current["All Members"] ?? [];
          const nextMembers = editingMemberId
            ? allMembers.map((member) =>
                member.id === editingMemberId ? savedMember : member,
              )
            : [savedMember, ...allMembers];
          return buildMemberTabData(nextMembers);
        });
        await loadMembers();
        resetMemberMasterForm();
        setIsMemberFormOpen(false);
        setMemberMasterFeedback(
          editingMemberId
            ? "Member updated successfully."
            : "Member created successfully.",
        );
      } finally {
        setIsSavingMemberMaster(false);
      }
    })();
  };
  const removeMemberRecord = (memberId) => {
    void (async () => {
      setIsSavingMemberMaster(true);
      setMemberMasterFeedback("");

      try {
        const response = await runAuthenticatedFetch(`/members/${memberId}`, {
          method: "DELETE",
        });

        if (!response.ok && response.status !== 204) {
          let message = "Unable to delete the member record right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setMemberMasterFeedback(message);
          return;
        }

        setMemberTabData((current) =>
          buildMemberTabData(
            (current["All Members"] ?? []).filter(
              (item) => item.id !== memberId,
            ),
          ),
        );
        setSelectedMemberRecords((current) =>
          Object.fromEntries(
            memberArenaTabs.map((memberTab) => [
              memberTab,
              (current[memberTab] ?? []).filter((id) => id !== memberId),
            ]),
          ),
        );

        if (editingMemberId === memberId) {
          resetMemberMasterForm();
          setIsMemberFormOpen(false);
        }
        setMemberMasterFeedback("Member deleted.");
      } finally {
        setIsSavingMemberMaster(false);
      }
    })();
  };
  const updateMembershipFieldDraft = (field, value) => {
    setMembershipFieldDraft((current) => ({
      ...current,
      [field]: value,
    }));
  };
  const addMembershipField = () => {
    const label = membershipFieldDraft.label.trim();
    if (!label) {
      return;
    }

    setMembershipFormFields((current) => [
      ...current,
      {
        id: `membership-field-${Date.now()}`,
        label,
        key: "",
        type: membershipFieldDraft.type,
        required: membershipFieldDraft.required,
        isDefault: false,
      },
    ]);
    setMembershipFieldDraft({
      label: "",
      type: "text",
      required: false,
    });
  };
  const deleteMembershipField = (fieldId) => {
    setMembershipFormFields((current) =>
      current.filter((field) => field.id !== fieldId || field.isDefault),
    );
    setMemberMasterForm((current) => {
      const nextCustomValues = { ...current.customFieldValues };
      delete nextCustomValues[fieldId];

      return {
        ...current,
        customFieldValues: nextCustomValues,
      };
    });
  };
  const updateMembershipField = (fieldId, property, value) => {
    setMembershipFormFields((current) =>
      current.map((field) =>
        field.id === fieldId ? { ...field, [property]: value } : field,
      ),
    );
  };

  const applyMemberAccessStatusLocally = (memberIds, appAccessStatus) => {
    setMemberTabData((current) =>
      buildMemberTabData(
        (current["All Members"] ?? []).map((member) => {
          if (!memberIds.includes(member.id)) {
            return member;
          }

          return {
            ...member,
            appAccessStatus,
            membershipStatus:
              appAccessStatus === "Approved"
                ? "ACTIVE"
                : appAccessStatus === "Pending Approval"
                  ? "PENDING"
                  : "INACTIVE",
            expiryStatus:
              appAccessStatus === "Approved" ? "active" : "expiring-soon",
          };
        }),
      ),
    );
  };

  const updateMemberAccessStatus = (memberId, nextStatusLabel) => {
    setMemberAccessFeedback("");
    setMemberAccessEdits((current) => ({
      ...current,
      [memberId]: nextStatusLabel,
    }));
  };

  const applyBulkMemberAccessStatus = (accessStatus) => {
    setMemberAccessFeedback("");
    const nextStatusLabel =
      accessStatus === "APPROVED"
        ? "Approved"
        : accessStatus === "SUSPENDED"
          ? "Suspended"
          : accessStatus === "CANCELLED"
            ? "Cancelled"
            : "Pending Approval";

    setMemberAccessEdits((current) => ({
      ...current,
      ...Object.fromEntries(
        selectedAdminMembers.map((memberId) => [memberId, nextStatusLabel]),
      ),
    }));
  };

  const saveMemberAccessChanges = () => {
    void (async () => {
      setIsSavingMemberAccess(true);
      setMemberAccessFeedback("");
      const updates = Object.entries(memberAccessEdits);

      if (updates.length === 0) {
        setMemberAccessFeedback("No member access changes to save.");
        setIsSavingMemberAccess(false);
        return;
      }

      const memberLookup = new Map(
        (memberTabData["All Members"] ?? []).map((member) => [
          member.id,
          member,
        ]),
      );

      try {
        await Promise.all(
          updates.map(async ([memberId, nextStatusLabel]) => {
            const accessStatus =
              nextStatusLabel === "Approved"
                ? "APPROVED"
                : nextStatusLabel === "Suspended"
                  ? "SUSPENDED"
                  : nextStatusLabel === "Cancelled"
                    ? "CANCELLED"
                    : "PENDING";

            const response = await runAuthenticatedFetch(
              `/members/${memberId}/access`,
              {
                method: "PATCH",
                headers: {
                  "Content-Type": "application/json",
                },
                body: JSON.stringify({ accessStatus }),
              },
            );

            if (!response.ok) {
              throw new Error(`Unable to save access for member ${memberId}.`);
            }

            applyMemberAccessStatusLocally([memberId], nextStatusLabel);
          }),
        );

        setMemberAccessEdits({});
        setSelectedAdminMembers([]);
        await loadMembers();
        setMemberAccessFeedback("Member access changes saved.");
      } catch (error) {
        setMemberAccessFeedback(
          error instanceof Error
            ? error.message
            : "Unable to save member access changes.",
        );
      } finally {
        setIsSavingMemberAccess(false);
      }
    })();
  };

  const updateMemberAdminRole = (member, nextRole) => {
    if (!member.accessUserId) {
      return;
    }

    void (async () => {
      setUpdatingAdminUserIds((current) =>
        current.includes(member.accessUserId)
          ? current
          : [...current, member.accessUserId],
      );

      try {
        const response = await runAuthenticatedFetch(
          `/users/${member.accessUserId}/admin-role`,
          {
            method: "PATCH",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              role: nextRole,
            }),
          },
        );

        const payload = await response.json().catch(() => null);
        if (!response.ok) {
          setMemberAccessFeedback(
            payload?.error || "Unable to update admin role.",
          );
          return;
        }

        const nextRoleLabel =
          nextRole === "superAdmin"
            ? "super admin"
            : nextRole === "admin"
              ? "admin"
              : "member";

        setMemberTabData((current) =>
          buildMemberTabData(
            (current["All Members"] ?? []).map((item) =>
              item.id === member.id
                ? {
                    ...item,
                    isAdmin: nextRole !== "member",
                    isSuperAdmin: nextRole === "superAdmin",
                  }
                : item,
            ),
          ),
        );

        await loadMembers();
        setMemberAccessFeedback(
          `${member.name} is now set as ${nextRoleLabel}.`,
        );
      } finally {
        setUpdatingAdminUserIds((current) =>
          current.filter((userId) => userId !== member.accessUserId),
        );
      }
    })();
  };

  const toggleAdminMemberSelect = (memberId) => {
    setSelectedAdminMembers((current) =>
      current.includes(memberId)
        ? current.filter((id) => id !== memberId)
        : [...current, memberId],
    );
  };

  const toggleSelectAllAdminMembers = () => {
    const filteredIds =
      activeAdminAccessSection === "Registration Requests"
        ? pendingRegistrationRequests.map((member) => member.id)
        : filteredAdminMembers.map((member) => member.id);
    setSelectedAdminMembers((current) =>
      filteredIds.every((memberId) => current.includes(memberId))
        ? current.filter((memberId) => !filteredIds.includes(memberId))
        : Array.from(new Set([...current, ...filteredIds])),
    );
  };

  const toggleContentMember = (memberId) => {
    setSelectedContentMemberIds((current) =>
      current.includes(memberId)
        ? current.filter((id) => id !== memberId)
        : [...current, memberId],
    );
  };
  const selectAllContentMembers = () => {
    setSelectedContentMemberIds(
      contentMemberMatches.map((member) => member.id),
    );
  };
  const clearContentMemberSelection = () => {
    setSelectedContentMemberIds([]);
  };

  const updateContentPost = (postId, field, value) => {
    setMemberAccessFeedback("");
    setContentPostEdits((current) => ({
      ...current,
      [postId]: {
        ...current[postId],
        [field]: value,
      },
    }));
  };
  const resetMemberMediaPostForm = () => {
    setMemberMediaPostFeedback("");
    setMemberMediaPostForm({
      ...defaultMemberMediaPostForm,
      memberId: (memberTabData["All Members"] ?? [])[0]?.id ?? "",
    });
  };
  const updateMemberMediaPostForm = (field, value) => {
    setMemberMediaPostFeedback("");
    setMemberMediaPostForm((current) => ({
      ...current,
      [field]: value,
    }));
  };
  const updateMemberMediaPostImage = (file) => {
    void (async () => {
      if (!file) {
        setMemberMediaPostFeedback("");
        setMemberMediaPostForm((current) => ({
          ...current,
          imageFile: null,
          imagePreviewUrl: "",
          imageName: "",
        }));
        return;
      }

      const previewUrl = await readFileAsDataUrl(file);
      setMemberMediaPostFeedback("");
      setMemberMediaPostForm((current) => ({
        ...current,
        imageFile: file,
        imagePreviewUrl: previewUrl,
        imageName: file.name,
      }));
    })();
  };
  const clearMemberMediaPostImage = () => {
    setMemberMediaPostFeedback("");
    setMemberMediaPostForm((current) => ({
      ...current,
      imageFile: null,
      imagePreviewUrl: "",
      imageName: "",
    }));
  };
  const submitMemberMediaPost = () => {
    void (async () => {
      if (
        isSavingMemberMediaPost ||
        !memberMediaPostForm.memberId ||
        !memberMediaPostForm.title.trim() ||
        !memberMediaPostForm.summary.trim() ||
        !memberMediaPostForm.imageFile
      ) {
        setMemberMediaPostFeedback(
          "Member, headline, summary, and picture are required before publishing.",
        );
        return;
      }

      setIsSavingMemberMediaPost(true);
      setMemberMediaPostFeedback("");

      try {
        const payload = new FormData();
        payload.append("memberId", memberMediaPostForm.memberId);
        payload.append("title", memberMediaPostForm.title.trim());
        payload.append("summary", memberMediaPostForm.summary.trim());
        payload.append("body", memberMediaPostForm.body.trim());
        payload.append("postType", "Media");
        payload.append("imageFile", memberMediaPostForm.imageFile);

        const response = await runAuthenticatedFetch("/member-posts", {
          method: "POST",
          body: payload,
        });

        if (!response.ok) {
          let message = "Unable to publish the member post right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setMemberMediaPostFeedback(message);
          return;
        }

        await loadMemberPosts();
        resetMemberMediaPostForm();
        setMemberMediaPostFeedback("Member post submitted successfully.");
      } finally {
        setIsSavingMemberMediaPost(false);
      }
    })();
  };
  const updateMemberMediaPostStatus = (postId, nextStatusLabel) => {
    void (async () => {
      setMemberAccessFeedback("");
      setContentPostEdits((current) => ({
        ...current,
        [postId]: {
          ...current[postId],
          status: nextStatusLabel,
        },
      }));

      const currentPost = memberContentPosts.find((post) => post.id === postId);
      const reviewStatus =
        nextStatusLabel === "Approved"
          ? "APPROVED"
          : nextStatusLabel === "Rejected"
            ? "REJECTED"
            : "PENDING";

      const response = await runAuthenticatedFetch(
        `/member-posts/${postId}/moderation`,
        {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            reviewStatus,
            displayStart: currentPost?.displayStart || null,
            displayEnd: currentPost?.displayEnd || null,
          }),
        },
      );

      if (!response.ok) {
        return;
      }

      await loadMemberPosts();
    })();
  };
  const saveContentPostModeration = () => {
    void (async () => {
      setIsSavingMemberAccess(true);
      setMemberAccessFeedback("");

      try {
        await Promise.all(
          memberContentPosts.map((post) => {
            const nextEdit = contentPostEdits[post.id];
            if (!nextEdit) {
              return Promise.resolve();
            }

            const reviewStatus =
              nextEdit.status === "Approved"
                ? "APPROVED"
                : nextEdit.status === "Rejected"
                  ? "REJECTED"
                  : "PENDING";

            return runAuthenticatedFetch(`/member-posts/${post.id}/moderation`, {
              method: "PATCH",
              headers: {
                "Content-Type": "application/json",
              },
              body: JSON.stringify({
                reviewStatus,
                displayStart: nextEdit.displayStart || null,
                displayEnd: nextEdit.displayEnd || null,
              }),
            }).then((response) => {
              if (!response.ok) {
                throw new Error(`Unable to save content access for post ${post.id}.`);
              }
            });
          }),
        );

        await loadMemberPosts();
        setMemberAccessFeedback("Member content access changes saved.");
      } catch (error) {
        setMemberAccessFeedback(
          error instanceof Error
            ? error.message
            : "Unable to save member content access changes.",
        );
      } finally {
        setIsSavingMemberAccess(false);
      }
    })();
  };
  const toggleSelectAdminVendor = (vendorId) => {
    setSelectedAdminVendors((current) =>
      current.includes(vendorId)
        ? current.filter((id) => id !== vendorId)
        : [...current, vendorId],
    );
  };
  const toggleSelectAllAdminVendors = () => {
    const filteredIds = filteredAdminVendors.map((vendor) => vendor.id);
    setSelectedAdminVendors((current) =>
      current.length === filteredIds.length ? [] : filteredIds,
    );
  };
  const toggleContentVendor = (vendorId) => {
    setSelectedContentVendorIds((current) =>
      current.includes(vendorId)
        ? current.filter((id) => id !== vendorId)
        : [...current, vendorId],
    );
  };
  const updateVendorContentPost = (postId, field, value) => {
    setVendorContentPostEdits((current) => ({
      ...current,
      [postId]: {
        ...current[postId],
        [field]: value,
      },
    }));
  };
  const updateVendorRegistrationForm = (field, value) => {
    setVendorRegistrationError("");
    setVendorRegistrationSuccess("");
    setVendorRegistrationForm((current) => {
      if (field === "category") {
        return {
          ...current,
          category: value,
          subCategory: "",
        };
      }

      if (field === "country") {
        return {
          ...current,
          country: value,
          state: "",
          city: "",
        };
      }

      if (field === "state") {
        return {
          ...current,
          state: value,
          city: "",
        };
      }

      return {
        ...current,
        [field]: value,
      };
    });
  };
  const updateVendorRegistrationFile = (field, file) => {
    setVendorRegistrationError("");
    setVendorRegistrationSuccess("");
    setVendorRegistrationForm((current) => ({
      ...current,
      [field]: file,
    }));
  };
  const resetVendorRegistrationForm = () => {
    setVendorRegistrationError("");
    setVendorRegistrationSuccess("");
    setVendorRegistrationForm(buildVendorRegistrationForm(null));
  };
  const openVendorRegistrationEditor = (vendor) => {
    setVendorRegistrationError("");
    setVendorRegistrationSuccess("");
    setVendorRegistrationForm(buildVendorRegistrationForm(vendor));
  };
  const updateVendorFilter = (field, value) => {
    setVendorFilters((current) => ({
      ...current,
      [field]: value,
    }));
  };
  const applyVendorTaxonomyState = (categoriesPayload) => {
    const hydrated = hydrateVendorTaxonomy(categoriesPayload);
    setVendorCategories(hydrated.categories);
    setVendorSubCategoryRecords(hydrated.subCategoryMap);
    setVendorCategoryIdMap(hydrated.categoryIdMap);
    setVendorSubCategoryIdMap(hydrated.subCategoryIdMap);

    if (
      selectedVendorParentCategory &&
      !hydrated.categories.includes(selectedVendorParentCategory)
    ) {
      setSelectedVendorParentCategory("");
    }

    if (
      vendorRegistrationForm.category &&
      !hydrated.categories.includes(vendorRegistrationForm.category)
    ) {
      setVendorRegistrationForm((current) => ({
        ...current,
        category: "",
        subCategory: "",
      }));
      return;
    }

    if (
      vendorRegistrationForm.category &&
      vendorRegistrationForm.subCategory &&
      !(
        hydrated.subCategoryMap[vendorRegistrationForm.category] ?? []
      ).includes(vendorRegistrationForm.subCategory)
    ) {
      setVendorRegistrationForm((current) => ({
        ...current,
        subCategory: "",
      }));
    }
  };
  const loadVendorTaxonomy = async () => {
    const response = await fetch(`${apiBaseUrl}/vendor-taxonomy/categories`);
    if (!response.ok) {
      return false;
    }

    const payload = await response.json();
    applyVendorTaxonomyState(payload.categories);
    return true;
  };
  const addVendorCategory = () => {
    setVendorTaxonomyError("");
    setVendorTaxonomySuccess("");
    const nextCategory = newVendorCategory.trim();
    if (!nextCategory || vendorCategories.includes(nextCategory)) {
      return;
    }

    void (async () => {
      const response = await runAuthenticatedFetch(
        "/vendor-taxonomy/categories",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            name: nextCategory,
          }),
        },
      );

      if (!response.ok) {
        setVendorTaxonomyError("Could not add the vendor category right now.");
        return;
      }

      await loadVendorTaxonomy();
      setNewVendorCategory("");
      setVendorTaxonomySuccess("Vendor category added.");
    })();
  };
  const openVendorCategoryEditor = (categoryName) => {
    setVendorTaxonomyError("");
    setVendorTaxonomySuccess("");
    setEditingVendorCategory(categoryName);
    setVendorCategoryDraft(categoryName || "");
  };
  const cancelVendorCategoryEdit = () => {
    setEditingVendorCategory(null);
    setVendorCategoryDraft("");
  };
  const saveVendorCategory = () => {
    setVendorTaxonomyError("");
    setVendorTaxonomySuccess("");
    const nextName = vendorCategoryDraft.trim();
    if (!nextName) {
      return;
    }
    void (async () => {
      if (editingVendorCategory) {
        const categoryId = vendorCategoryIdMap[editingVendorCategory];
        if (!categoryId) {
          setVendorTaxonomyError(
            "Could not find that vendor category anymore.",
          );
          return;
        }

        const response = await runAuthenticatedFetch(
          `/vendor-taxonomy/categories/${categoryId}`,
          {
            method: "PATCH",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              name: nextName,
            }),
          },
        );

        if (!response.ok) {
          setVendorTaxonomyError(
            "Could not update the vendor category right now.",
          );
          return;
        }
      } else {
        const response = await runAuthenticatedFetch(
          "/vendor-taxonomy/categories",
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              name: nextName,
            }),
          },
        );

        if (!response.ok) {
          setVendorTaxonomyError(
            "Could not add the vendor category right now.",
          );
          return;
        }
      }

      await loadVendorTaxonomy();
      cancelVendorCategoryEdit();
      setVendorTaxonomySuccess(
        editingVendorCategory
          ? "Vendor category updated."
          : "Vendor category added.",
      );
    })();
  };
  const deleteVendorCategory = (categoryName) => {
    setVendorTaxonomyError("");
    setVendorTaxonomySuccess("");
    const categoryId = vendorCategoryIdMap[categoryName];
    if (!categoryId) {
      return;
    }

    void (async () => {
      const response = await runAuthenticatedFetch(
        `/vendor-taxonomy/categories/${categoryId}`,
        {
          method: "DELETE",
        },
      );

      if (!response.ok) {
        setVendorTaxonomyError(
          "Could not delete the vendor category right now.",
        );
        return;
      }

      await Promise.all([loadVendorTaxonomy(), loadVendors()]);
      if (vendorFilters.category === categoryName) {
        setVendorFilters((current) => ({
          ...current,
          category: "",
        }));
      }
      setVendorTaxonomySuccess("Vendor category removed.");
    })();
  };
  const openVendorSubCategoryEditor = (subCategoryName) => {
    setVendorTaxonomyError("");
    setVendorTaxonomySuccess("");
    setEditingVendorSubCategory(subCategoryName);
    setVendorSubCategoryDraft(subCategoryName || "");
  };
  const cancelVendorSubCategoryEdit = () => {
    setEditingVendorSubCategory(null);
    setVendorSubCategoryDraft("");
  };
  const saveVendorSubCategory = () => {
    setVendorTaxonomyError("");
    setVendorTaxonomySuccess("");
    const nextName = vendorSubCategoryDraft.trim();
    if (!selectedVendorParentCategory || !nextName) {
      return;
    }
    const categoryId = vendorCategoryIdMap[selectedVendorParentCategory];
    if (!categoryId) {
      setVendorTaxonomyError("Please select a valid parent category first.");
      return;
    }

    void (async () => {
      if (editingVendorSubCategory) {
        const subCategoryId =
          vendorSubCategoryIdMap[selectedVendorParentCategory]?.[
            editingVendorSubCategory
          ];
        if (!subCategoryId) {
          setVendorTaxonomyError(
            "Could not find that vendor sub category anymore.",
          );
          return;
        }

        const response = await runAuthenticatedFetch(
          `/vendor-taxonomy/sub-categories/${subCategoryId}`,
          {
            method: "PATCH",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              categoryId,
              name: nextName,
            }),
          },
        );

        if (!response.ok) {
          setVendorTaxonomyError(
            "Could not update the vendor sub category right now.",
          );
          return;
        }
      } else {
        const response = await runAuthenticatedFetch(
          "/vendor-taxonomy/sub-categories",
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              categoryId,
              name: nextName,
            }),
          },
        );

        if (!response.ok) {
          setVendorTaxonomyError(
            "Could not add the vendor sub category right now.",
          );
          return;
        }
      }

      await loadVendorTaxonomy();
      cancelVendorSubCategoryEdit();
      setVendorTaxonomySuccess(
        editingVendorSubCategory
          ? "Vendor sub category updated."
          : "Vendor sub category added.",
      );
    })();
  };
  const deleteVendorSubCategory = (subCategoryName) => {
    setVendorTaxonomyError("");
    setVendorTaxonomySuccess("");
    if (!selectedVendorParentCategory) {
      return;
    }
    const subCategoryId =
      vendorSubCategoryIdMap[selectedVendorParentCategory]?.[subCategoryName];
    if (!subCategoryId) {
      return;
    }

    void (async () => {
      const response = await runAuthenticatedFetch(
        `/vendor-taxonomy/sub-categories/${subCategoryId}`,
        {
          method: "DELETE",
        },
      );

      if (!response.ok) {
        setVendorTaxonomyError(
          "Could not delete the vendor sub category right now.",
        );
        return;
      }

      await Promise.all([loadVendorTaxonomy(), loadVendors()]);
      setVendorTaxonomySuccess("Vendor sub category removed.");
    })();
  };
  const saveVendorRecord = () => {
    void (async () => {
      const validationError = getVendorRegistrationValidationError(
        vendorRegistrationForm,
        vendorSubCategoryOptions,
      );
      if (validationError) {
        setVendorRegistrationError(validationError);
        setVendorRegistrationSuccess("");
        return;
      }

      setVendorRegistrationError("");
      setVendorRegistrationSuccess("");
      setIsSavingVendorRegistration(true);

      try {
        const isEditingVendor = Boolean(vendorRegistrationForm.id);
        const response = await runAuthenticatedFetch(
          `/vendors${isEditingVendor ? `/${vendorRegistrationForm.id}` : ""}`,
          {
            method: isEditingVendor ? "PATCH" : "POST",
            body: JSON.stringify({
            name: vendorRegistrationForm.company.trim(),
            companyName: vendorRegistrationForm.company.trim(),
            vendorType: vendorRegistrationForm.subCategory.trim(),
            category: vendorRegistrationForm.category.trim(),
            contactPerson: vendorRegistrationForm.contactPerson.trim(),
            membershipPlan: vendorRegistrationForm.membershipPlan.trim(),
            paymentAmount: vendorRegistrationForm.paymentAmount.trim(),
            address: vendorRegistrationForm.address.trim(),
            city: vendorRegistrationForm.city.trim(),
            phone:
              `${vendorRegistrationForm.phoneCode} ${vendorRegistrationForm.phone.trim()}`.trim(),
            email: vendorRegistrationForm.email.trim(),
            primaryLoginEmail: vendorRegistrationForm.primaryLoginEmail
              .trim()
              .toLowerCase(),
            secondaryLoginEmail:
              vendorRegistrationForm.secondaryLoginEmail.trim().toLowerCase() ||
              undefined,
            whatsapp:
              `${vendorRegistrationForm.whatsappCode} ${vendorRegistrationForm.whatsapp.trim()}`.trim(),
            facebookUrl: vendorRegistrationForm.facebookUrl.trim(),
            instagramUrl: vendorRegistrationForm.instagramUrl.trim(),
            youtubeUrl: vendorRegistrationForm.youtubeUrl.trim(),
            linkedinUrl: vendorRegistrationForm.linkedinUrl.trim(),
            xUrl: vendorRegistrationForm.xUrl.trim(),
            onboardingStartAt:
              vendorRegistrationForm.onboardingStartAt || undefined,
            onboardingEndAt:
              vendorRegistrationForm.onboardingEndAt || undefined,
            paymentDueDate: vendorRegistrationForm.paymentDueDate || undefined,
            paymentStatus: "PENDING",
            status: "PENDING",
            badge:
              vendorRegistrationForm.subCategory.trim() ||
              vendorRegistrationForm.category.trim() ||
              "Vendor",
            notes: [
              vendorRegistrationForm.country
                ? `Country: ${vendorRegistrationForm.country}`
                : "",
              vendorRegistrationForm.state
                ? `State: ${vendorRegistrationForm.state}`
                : "",
              vendorRegistrationForm.zipcode
                ? `Zipcode: ${vendorRegistrationForm.zipcode}`
                : "",
              vendorRegistrationForm.website
                ? `Website: ${vendorRegistrationForm.website.trim()}`
                : "",
              vendorRegistrationForm.workDescription
                ? `Work Description: ${vendorRegistrationForm.workDescription.trim()}`
                : "",
              vendorRegistrationForm.companyLogo?.name
                ? `Company Logo: ${vendorRegistrationForm.companyLogo.name}`
                : "",
            ]
              .filter(Boolean)
              .join("\n"),
            }),
          },
        );

        if (!response.ok) {
          let message = "Unable to save the vendor record right now.";
          try {
            const payload = await response.json();
            if (payload?.error) {
              message = payload.error;
            }
          } catch {}
          setVendorRegistrationError(message);
          return;
        }

        await loadVendors();
        resetVendorRegistrationForm();
        setVendorRegistrationSuccess(
          isEditingVendor
            ? "Vendor record updated successfully."
            : "Vendor saved successfully. You can now review it in Vendor Status.",
        );
      } catch {
        setVendorRegistrationError(
          "Could not reach the vendor registration service right now.",
        );
      } finally {
        setIsSavingVendorRegistration(false);
      }
    })();
  };
  const applyVendorAccessStatusLocally = (vendorIds, nextStatusLabel) => {
    setVendorRecords((current) =>
      current.map((vendor) => {
        if (!vendorIds.includes(vendor.id)) {
          return vendor;
        }

        return {
          ...vendor,
          appAccessStatus: nextStatusLabel,
          registrationStatus:
            nextStatusLabel === "Approved"
              ? "Active"
              : nextStatusLabel === "Suspended"
                ? "Suspended"
                : nextStatusLabel === "Removed"
                  ? "Lapsed"
                  : "Pending",
        };
      }),
    );
  };
  const applyBulkVendorAccessStatus = (accessStatus) => {
    const nextStatusLabel =
      accessStatus === "APPROVED"
        ? "Approved"
        : accessStatus === "SUSPENDED"
          ? "Suspended"
          : accessStatus === "CANCELLED"
            ? "Removed"
            : "Pending Approval";

    setVendorAccessEdits((current) => ({
      ...current,
      ...Object.fromEntries(
        selectedAdminVendors.map((vendorId) => [vendorId, nextStatusLabel]),
      ),
    }));
  };
  const saveVendorAccessChanges = () => {
    void (async () => {
      const updates = Object.entries(vendorAccessEdits);

      if (updates.length === 0) {
        return;
      }

      await Promise.all(
        updates.map(async ([vendorId, nextStatusLabel]) => {
          const accessStatus =
            nextStatusLabel === "Approved"
              ? "APPROVED"
              : nextStatusLabel === "Suspended"
                ? "SUSPENDED"
                : nextStatusLabel === "Removed"
                  ? "CANCELLED"
                  : "PENDING";

          const response = await fetch(
            `${apiBaseUrl}/vendors/${vendorId}/access`,
            {
              method: "PATCH",
              headers: {
                "Content-Type": "application/json",
              },
              body: JSON.stringify({ accessStatus }),
            },
          );

          if (!response.ok) {
            return;
          }

          applyVendorAccessStatusLocally([vendorId], nextStatusLabel);
        }),
      );

      setVendorAccessEdits({});
      setSelectedAdminVendors([]);
      await loadVendors();
    })();
  };
  const toggleVendorRequestSelect = (vendorId) => {
    setSelectedVendorRequests((current) =>
      current.includes(vendorId)
        ? current.filter((id) => id !== vendorId)
        : [...current, vendorId],
    );
  };
  const toggleSelectAllVendorRequests = () => {
    const filteredIds = vendorStatusRequests.map((vendor) => vendor.id);
    setSelectedVendorRequests((current) =>
      current.length === filteredIds.length ? [] : filteredIds,
    );
  };
  const openVendorStatusReview = (vendorId) => {
    const vendor = vendorRecords.find((item) => item.id === vendorId);
    if (!vendor) {
      return;
    }

    setSelectedVendorReviewId(vendorId);
    setVendorApprovalForm(buildVendorApprovalForm(vendor));
    setVendorApprovalError("");
  };
  const updateVendorApprovalForm = (field, value) => {
    setVendorApprovalForm((current) => ({
      ...current,
      [field]: value,
    }));
    setVendorApprovalError("");
  };
  const updateVendorApprovalFile = (field, file) => {
    setVendorApprovalForm((current) => ({
      ...current,
      [field]: file,
    }));
    setVendorApprovalError("");
  };
  const applySingleVendorDecision = (vendorId, accessStatus) => {
    void (async () => {
      const reviewTarget =
        selectedVendorReviewId === vendorId
          ? vendorApprovalForm
          : buildVendorApprovalForm(
              vendorRecords.find((item) => item.id === vendorId) ?? null,
            );

      if (accessStatus === "APPROVED") {
        const validationError = getVendorApprovalValidationError(reviewTarget);

        if (validationError) {
          if (selectedVendorReviewId !== vendorId) {
            openVendorStatusReview(vendorId);
          }
          setVendorApprovalError(validationError);
          return;
        }
      }

      setIsSavingVendorApproval(true);
      setVendorApprovalError("");

      const notes = [
        reviewTarget.planName ? `Plan Name: ${reviewTarget.planName}` : "",
        reviewTarget.openingTime
          ? `Opening Time: ${reviewTarget.openingTime}`
          : "",
        reviewTarget.closingTime
          ? `Closing Time: ${reviewTarget.closingTime}`
          : "",
        reviewTarget.gstNumber ? `GST Number: ${reviewTarget.gstNumber}` : "",
        `Is Restaurant: ${reviewTarget.isRestaurant ? "Yes" : "No"}`,
        reviewTarget.paymentMode
          ? `Payment Mode: ${reviewTarget.paymentMode}`
          : "",
        reviewTarget.bankName ? `Bank Name: ${reviewTarget.bankName}` : "",
        reviewTarget.transactionId
          ? `Transaction ID: ${reviewTarget.transactionId}`
          : "",
        reviewTarget.paymentDescription
          ? `Payment Description: ${reviewTarget.paymentDescription}`
          : "",
        reviewTarget.googleLocation
          ? `Google Location: ${reviewTarget.googleLocation}`
          : "",
        reviewTarget.idProof?.name
          ? `ID Proof: ${reviewTarget.idProof.name}`
          : "",
        reviewTarget.locationProof?.name
          ? `Location Proof: ${reviewTarget.locationProof.name}`
          : "",
        reviewTarget.companyBrochure?.name
          ? `Company Profile/Brochure: ${reviewTarget.companyBrochure.name}`
          : "",
        reviewTarget.profilePhoto?.name
          ? `Profile Photo: ${reviewTarget.profilePhoto.name}`
          : "",
        reviewTarget.visitingCard?.name
          ? `Visiting Card: ${reviewTarget.visitingCard.name}`
          : "",
      ]
        .filter(Boolean)
        .join("\n");

      try {
        const vendorResponse = await runAuthenticatedFetch(`/vendors/${vendorId}`, {
          method: "PATCH",
          body: JSON.stringify({
            membershipPlan: reviewTarget.membershipPlan.trim(),
            paymentAmount: reviewTarget.paymentAmount.trim(),
            onboardingStartAt: reviewTarget.onboardingStartAt || undefined,
            onboardingEndAt: reviewTarget.onboardingEndAt || undefined,
            paymentDueDate: reviewTarget.paymentDueDate || undefined,
            notes,
          }),
        });

        if (!vendorResponse.ok) {
          let message = "Unable to save vendor approval details right now.";
          try {
            const payload = await vendorResponse.json();
            if (payload?.error) {
              message = payload.error;
            }
          } catch {}
          setVendorApprovalError(message);
          return;
        }

        const response = await runAuthenticatedFetch(`/vendors/${vendorId}/access`, {
          method: "PATCH",
          body: JSON.stringify({ accessStatus }),
        });

        if (!response.ok) {
          let message = "Unable to update vendor access right now.";
          try {
            const payload = await response.json();
            if (payload?.error) {
              message = payload.error;
            }
          } catch {}
          setVendorApprovalError(message);
          return;
        }

        setVendorApprovalError("");
        setSelectedVendorRequests((current) =>
          current.filter((id) => id !== vendorId),
        );
        if (selectedVendorReviewId === vendorId) {
          setSelectedVendorReviewId("");
          setVendorApprovalForm(buildVendorApprovalForm(null));
        }
        await loadVendors();
      } finally {
        setIsSavingVendorApproval(false);
      }
    })();
  };
  const applyBulkVendorRequestDecision = (accessStatus) => {
    void (async () => {
      if (selectedVendorRequests.length === 0) {
        return;
      }

      if (accessStatus === "APPROVED") {
        const firstVendorId = selectedVendorRequests[0];
        if (firstVendorId) {
          openVendorStatusReview(firstVendorId);
        }
        setVendorApprovalError(
          "Bulk approval is disabled because each vendor needs plan and billing details before approval.",
        );
        return;
      }

      setIsSavingVendorApproval(true);
      setVendorApprovalError("");

      try {
        await Promise.all(
          selectedVendorRequests.map(async (vendorId) => {
            const response = await runAuthenticatedFetch(
              `/vendors/${vendorId}/access`,
              {
                method: "PATCH",
                body: JSON.stringify({ accessStatus }),
              },
            );

            if (!response.ok) {
              let message = "Unable to update one or more vendor requests.";
              try {
                const payload = await response.json();
                if (payload?.error) {
                  message = payload.error;
                }
              } catch {}
              throw new Error(message);
            }
          }),
        );

        setSelectedVendorRequests([]);
        await loadVendors();
      } catch (error) {
        setVendorApprovalError(
          error instanceof Error
            ? error.message
            : "Unable to update the selected vendor requests right now.",
        );
      } finally {
        setIsSavingVendorApproval(false);
      }
    })();
  };
  const updateTimelinePostForm = (field, value) => {
    setTimelinePostFeedback("");
    setTimelinePostForm((current) => {
      if (field === "sourceType") {
        const associationName =
          associationProfile.name || defaultAssociationProfile.name;
        return {
          ...current,
          sourceType: value,
          memberId: "",
          vendorId: "",
          postedBy: value === "ASSOCIATION" ? associationName : "",
          contactNumber:
            value === "ASSOCIATION"
              ? associationProfile.helpdeskNumber ||
                associationProfile.contactNumbers ||
                ""
              : "",
        };
      }

      if (field === "memberId") {
        const selectedMember = (memberTabData["All Members"] ?? []).find(
          (member) => member.id === value,
        );
        return {
          ...current,
          memberId: value,
          vendorId: "",
          postedBy: selectedMember?.name || current.postedBy,
          contactNumber: selectedMember?.phone || current.contactNumber,
        };
      }

      if (field === "vendorId") {
        const selectedVendor = vendorRecords.find(
          (vendor) => vendor.id === value,
        );
        return {
          ...current,
          memberId: "",
          vendorId: value,
          postedBy:
            selectedVendor?.name || selectedVendor?.company || current.postedBy,
          contactNumber: selectedVendor?.phone || current.contactNumber,
        };
      }

      return {
        ...current,
        [field]: value,
      };
    });
  };
  const updateTimelinePostFile = (field, value) => {
    setTimelinePostFeedback("");
    setTimelinePostForm((current) => ({
      ...current,
      [field]: value,
    }));
  };
  const submitTimelinePost = () => {
    void (async () => {
      const normalizedSourceType = timelinePostForm.sourceType.trim().toUpperCase();
      const requiresMember =
        normalizedSourceType === "MEMBER" && !timelinePostForm.memberId;
      const requiresVendor =
        normalizedSourceType === "VENDOR" && !timelinePostForm.vendorId;

      if (
        !timelinePostForm.caption.trim() ||
        !timelinePostForm.postedBy.trim() ||
        requiresMember ||
        requiresVendor
      ) {
        setTimelinePostFeedback(
          requiresMember
            ? "Select a member and add post copy before saving."
            : requiresVendor
              ? "Select a vendor and add post copy before saving."
              : "Add posted by and post copy before saving.",
        );
        return;
      }

      const payload = new FormData();
      payload.append("sourceType", normalizedSourceType);
      payload.append("postedBy", timelinePostForm.postedBy.trim());
      payload.append("caption", timelinePostForm.caption.trim());
      payload.append("contactNumber", timelinePostForm.contactNumber.trim());
      payload.append("landingPageUrl", timelinePostForm.landingPageUrl.trim());
      payload.append("youtubeUrl", timelinePostForm.youtubeUrl.trim());
      payload.append("facebookUrl", timelinePostForm.facebookUrl.trim());

      if (timelinePostForm.memberId) {
        payload.append("memberId", timelinePostForm.memberId);
      }

      if (timelinePostForm.vendorId) {
        payload.append("vendorId", timelinePostForm.vendorId);
      }

      if (timelinePostForm.imageFile) {
        payload.append("imageFile", timelinePostForm.imageFile);
      }

      if (timelinePostForm.brochureFile) {
        payload.append("brochureFile", timelinePostForm.brochureFile);
      }

      setIsSavingTimelinePost(true);
      setTimelinePostFeedback("");

      try {
        const response = await runAuthenticatedFetch("/timeline-posts", {
          method: "POST",
          body: payload,
        });

        if (!response.ok) {
          const payload = await response.json().catch(() => null);
          throw new Error(
            payload?.error || payload?.message || "Unable to save timeline post.",
          );
        }

        await loadTimelinePosts();
        setTimelinePostForm({
          ...defaultTimelinePostForm,
          sourceType: timelinePostForm.sourceType,
          memberId:
            normalizedSourceType === "MEMBER" ? timelinePostForm.memberId : "",
          vendorId:
            normalizedSourceType === "VENDOR" ? timelinePostForm.vendorId : "",
          postedBy:
            normalizedSourceType === "ASSOCIATION"
              ? associationProfile.name || defaultAssociationProfile.name
              : timelinePostForm.postedBy,
          contactNumber: timelinePostForm.contactNumber,
        });
        setTimelinePostFeedback("Timeline post created.");
      } catch (error) {
        setTimelinePostFeedback(
          error instanceof Error ? error.message : "Unable to save timeline post.",
        );
      } finally {
        setIsSavingTimelinePost(false);
      }
    })();
  };
  const updateAppBannerForm = (field, value) => {
    setAppBannerError("");
    setAppBannerForm((current) => {
      if (field === "vendorId") {
        const selectedVendor = vendorRecords.find(
          (vendor) => vendor.id === value,
        );
        return {
          ...current,
          vendorId: value,
          contactNumber: selectedVendor?.phone || current.contactNumber,
        };
      }

      return {
        ...current,
        [field]: value,
      };
    });
  };
  const updateAppBannerFile = (field, value) => {
    setAppBannerError("");
    setAppBannerForm((current) => ({
      ...current,
      [field]: value,
    }));
  };
  const submitAppBanner = () => {
    void (async () => {
      if (!appBannerForm.shortText.trim() || !appBannerForm.vendorId) {
        setAppBannerError(
          "Select a vendor and add the banner message before submitting.",
        );
        return;
      }

      if (!appBannerForm.mediaFile) {
        setAppBannerError(
          "Attach a lightweight banner image for the Flutter app.",
        );
        return;
      }

      if (
        !["image/jpeg", "image/png", "image/webp"].includes(
          appBannerForm.mediaFile.type,
        )
      ) {
        setAppBannerError("Banner media must be JPG, PNG, or WebP.");
        return;
      }

      if (appBannerForm.mediaFile.size > 1024 * 1024) {
        setAppBannerError(
          "Banner image is too large. Keep it at or below 1 MB.",
        );
        return;
      }

      if (
        appBannerForm.brochureFile &&
        appBannerForm.brochureFile.size > 2 * 1024 * 1024
      ) {
        setAppBannerError(
          "Brochure PDF is too large. Keep it at or below 2 MB.",
        );
        return;
      }

      const payload = new FormData();
      payload.append("vendorId", appBannerForm.vendorId);
      payload.append("shortText", appBannerForm.shortText.trim());
      payload.append("contactNumber", appBannerForm.contactNumber.trim());
      payload.append("socialMediaUrl", appBannerForm.socialMediaUrl.trim());

      if (appBannerForm.mediaFile) {
        payload.append("mediaFile", appBannerForm.mediaFile);
      }

      if (appBannerForm.brochureFile) {
        payload.append("brochureFile", appBannerForm.brochureFile);
      }

      setIsSavingAppBanner(true);
      try {
        const response = await runAuthenticatedFetch("/app-banners", {
          method: "POST",
          body: payload,
        });

        if (!response.ok) {
          let message = "Unable to save the app banner right now.";
          try {
            const payload = await response.json();
            if (payload?.error) {
              message = payload.error;
            }
          } catch {}
          setAppBannerError(message);
          return;
        }

        await loadAppBanners();
        setAppBannerError("");
        setAppBannerForm({
          ...defaultAppBannerForm,
          vendorId: appBannerForm.vendorId,
          contactNumber: appBannerForm.contactNumber,
        });
      } finally {
        setIsSavingAppBanner(false);
      }
    })();
  };
  const updateAppBannerAccessItem = (bannerId, field, value) => {
    setBannerAccessFeedback("");
    setAppBannerAccessEdits((current) => ({
      ...current,
      [bannerId]: {
        ...(current[bannerId] ?? {}),
        [field]: value,
      },
    }));
  };
  const saveAppBannerAccessChanges = () => {
    void (async () => {
      const updates = Object.entries(appBannerAccessEdits);
      if (updates.length === 0) {
        setBannerAccessFeedback("No banner access changes to save.");
        return;
      }

      setIsSavingBannerAccess(true);
      setBannerAccessFeedback("");

      try {
        await Promise.all(
          updates.map(async ([bannerId, edit]) => {
            const banner = appBanners.find((item) => item.id === bannerId);
            const nextStatus = edit.status ?? banner?.status ?? "Pending Review";
            const reviewStatus =
              nextStatus === "Approved"
                ? "APPROVED"
                : nextStatus === "Rejected"
                  ? "REJECTED"
                  : nextStatus === "Hold"
                    ? "ON_HOLD"
                    : "PENDING";
            const isApproved = reviewStatus === "APPROVED";
            const paymentReceived =
              edit.paymentReceived ??
              (isApproved ? true : banner?.paymentReceived ?? false);
            const paymentMode =
              edit.paymentMode ??
              (isApproved
                ? (banner?.paymentMode || "").trim() || "Bank"
                : banner?.paymentMode || "");
            const paymentRemarks =
              edit.paymentRemarks ?? banner?.paymentRemarks ?? "";

            const response = await runAuthenticatedFetch(
              `/app-banners/${bannerId}/moderation`,
              {
                method: "PATCH",
                body: JSON.stringify({
                  reviewStatus,
                  paymentReceived: Boolean(paymentReceived),
                  paymentMode,
                  paymentRemarks,
                  displayIndex: isApproved
                    ? Number(
                        edit.displayIndex ?? banner?.displayIndex ?? 1,
                      ) || 1
                    : null,
                  displayStart: isApproved
                    ? edit.displayStart || banner?.displayStart || null
                    : null,
                  displayEnd: isApproved
                    ? edit.displayEnd || banner?.displayEnd || null
                    : null,
                }),
              },
            );

            if (!response.ok) {
              let message = "Unable to save banner access changes.";
              try {
                const payload = await response.json();
                if (payload?.error) {
                  message = payload.error;
                }
              } catch {}
              throw new Error(message);
            }
          }),
        );

        setAppBannerAccessEdits({});
        setBannerAccessFeedback("Banner access changes saved.");
        await loadAppBanners();
      } catch (error) {
        setBannerAccessFeedback(
          error instanceof Error
            ? error.message
            : "Could not reach the banner moderation service right now.",
        );
      } finally {
        setIsSavingBannerAccess(false);
      }
    })();
  };
  const uploadBulkMembers = () => {
    void (async () => {
      if (!bulkMemberFile) {
        setBulkMemberError("Choose an Excel file before importing.");
        return;
      }

      const payload = new FormData();
      payload.append("excelFile", bulkMemberFile);

      setIsBulkMemberUploading(true);
      setBulkMemberError("");
      const response = await fetch(`${apiBaseUrl}/members/bulk-import`, {
        method: "POST",
        body: payload,
      });
      setIsBulkMemberUploading(false);

      const result = await response.json().catch(() => null);

      if (!response.ok) {
        setBulkMemberResult(null);
        setBulkMemberError(
          result?.error || "Unable to import members from this file.",
        );
        return;
      }

      setBulkMemberResult(result);
      setBulkMemberFile(null);
      await loadMembers();
    })();
  };
  const updateTimelineAccessPost = (postId, field, value) => {
    setTimelineAccessFeedback("");
    setTimelineAccessEdits((current) => ({
      ...current,
      [postId]: {
        ...(current[postId] ?? {}),
        [field]: value,
      },
    }));
  };
  const saveTimelineAccessChanges = () => {
    void (async () => {
      const updates = Object.entries(timelineAccessEdits);
      if (updates.length === 0) {
        setTimelineAccessFeedback("No timeline access changes to save.");
        return;
      }

      setIsSavingTimelineAccess(true);
      setTimelineAccessFeedback("");

      try {
        await Promise.all(
          updates.map(async ([postId, edit]) => {
            const reviewStatus =
              edit.status === "Approved"
                ? "APPROVED"
                : edit.status === "Rejected"
                  ? "REJECTED"
                  : edit.status === "Hold"
                    ? "ON_HOLD"
                    : "PENDING";

            const response = await runAuthenticatedFetch(
              `/timeline-posts/${postId}/moderation`,
              {
                method: "PATCH",
                body: JSON.stringify({
                  reviewStatus,
                }),
              },
            );

            if (!response.ok) {
              let message = "Unable to save timeline access changes.";
              try {
                const payload = await response.json();
                if (payload?.error) {
                  message = payload.error;
                }
              } catch {}
              throw new Error(message);
            }
          }),
        );

        setTimelineAccessEdits({});
        setTimelineAccessFeedback("Timeline access changes saved.");
        await loadTimelinePosts();
      } catch (error) {
        setTimelineAccessFeedback(
          error instanceof Error
            ? error.message
            : "Could not reach the timeline moderation service right now.",
        );
      } finally {
        setIsSavingTimelineAccess(false);
      }
    })();
  };
  const updateEventForm = (field, value) => {
    setEventAccessFeedback("");
    setEventForm((current) => ({
      ...current,
      [field]: value,
    }));
  };
  const updateEventMedia = (field, value) => {
    setEventAccessFeedback("");
    setEventMedia((current) => ({
      ...current,
      ...(field === "imageFile"
        ? {
            imageFile: value,
            imageName: value?.name ?? "",
          }
        : field === "videoFile"
          ? {
              videoFile: value,
              videoName: value?.name ?? "",
            }
          : {
              [field]: value,
            }),
    }));
  };
  const resetEventEditor = () => {
    setEventForm({
      ...defaultEventForm,
      id: "",
    });
    setEventMedia(defaultEventMedia);
  };
  const editEventRecord = (eventId) => {
    setEventAccessFeedback("");
    const event = createdEvents.find((item) => item.id === eventId);
    if (!event) {
      return;
    }

    setEventForm({
      id: event.id,
      name: event.name ?? "",
      type: event.type ?? "",
      audience: event.audience ?? "",
      entryType: event.entryType ?? "",
      entryCharges: event.entryCharges ?? "",
      participationCharges: event.participationCharges ?? "",
      date: event.date ?? "",
      venue: event.venue ?? "",
      startTime: event.startTime ?? "",
      endTime: event.endTime ?? "",
      summary: event.summary ?? "",
    });
    setEventMedia({
      ...defaultEventMedia,
      imageName: event.imageName ?? "",
      videoName: event.videoName ?? "",
      bannerUrl: event.bannerUrl ?? "",
      promoVideoUrl: event.promoVideoUrl ?? "",
    });
    if (activeSection === topLevelSections.events) {
      setActiveEventsTab("Create New Event");
    }
  };
  const cancelEventEdit = () => {
    setEventAccessFeedback("");
    resetEventEditor();
  };
  const updateEventTypeDraft = (field, value) => {
    setEventTypeFeedback("");
    setEventTypeDraft((current) => ({
      ...current,
      [field]: value,
    }));
  };
  const addEventType = () => {
    void (async () => {
      const title = eventTypeDraft.title.trim();
      const meta = eventTypeDraft.meta.trim();
      if (!title || !meta) {
        setEventTypeFeedback(
          "Event type name and description are required before saving.",
        );
        return;
      }

      setIsSavingEventType(true);
      setEventTypeFeedback("");

      try {
        const response = await runAuthenticatedFetch("/events/types", {
          method: "POST",
          body: JSON.stringify({
            name: title,
            description: meta,
          }),
        });

        if (!response.ok) {
          let message = "Unable to add the event type right now.";
          try {
            const payload = await response.json();
            if (payload?.error) {
              message = payload.error;
            }
          } catch {}
          setEventTypeFeedback(message);
          return;
        }

        await loadEventsArena();
        setEventTypeDraft({ title: "", meta: "" });
        setEventTypeFeedback("Event type added successfully.");
      } finally {
        setIsSavingEventType(false);
      }
    })();
  };
  const updateEventType = (eventTypeId, field, value) => {
    setEventTypeFeedback("");
    setEventTypes((current) =>
      current.map((item) =>
        item.id === eventTypeId ? { ...item, [field]: value } : item,
      ),
    );
    void (async () => {
      const targetEventType = eventTypes.find(
        (item) => item.id === eventTypeId,
      );
      if (!targetEventType) {
        return;
      }

      const nextTitle = field === "title" ? value : targetEventType.title;
      const nextMeta = field === "meta" ? value : targetEventType.meta;
      if (!nextTitle.trim() || !nextMeta.trim()) {
        return;
      }

      setIsSavingEventType(true);

      try {
        const response = await runAuthenticatedFetch(
          `/events/types/${eventTypeId}`,
          {
            method: "PATCH",
            body: JSON.stringify({
              name: nextTitle.trim(),
              description: nextMeta.trim(),
            }),
          },
        );

        if (!response.ok) {
          let message = "Unable to update the event type right now.";
          try {
            const payload = await response.json();
            if (payload?.error) {
              message = payload.error;
            }
          } catch {}
          setEventTypeFeedback(message);
          await loadEventsArena();
          return;
        }

        setEventTypeFeedback("Event type updated successfully.");
      } finally {
        setIsSavingEventType(false);
      }
    })();
  };

  const saveEventDraft = () => {
    void (async () => {
      if (!eventForm.name.trim() || !eventForm.type.trim() || !eventForm.date) {
        setEventAccessFeedback(
          "Event name, type, and date are required before saving.",
        );
        return;
      }

      const currentSavingEventId = eventForm.id || "__new__";
      const payload = new FormData();
      payload.append("name", eventForm.name.trim());
      payload.append("type", eventForm.type.trim());
      payload.append("audience", eventForm.audience);
      payload.append("entryType", eventForm.entryType);
      payload.append("entryCharges", eventForm.entryCharges);
      payload.append("participationCharges", eventForm.participationCharges);
      payload.append("date", eventForm.date);
      payload.append("venue", eventForm.venue);
      payload.append("startTime", eventForm.startTime);
      payload.append("endTime", eventForm.endTime);
      payload.append("summary", eventForm.summary);
      if (eventMedia.imageFile) {
        payload.append("bannerFile", eventMedia.imageFile);
      }
      if (eventMedia.videoFile) {
        payload.append("videoFile", eventMedia.videoFile);
      }

      setSavingEventId(currentSavingEventId);
      setEventAccessFeedback("");

      try {
        const response = await runAuthenticatedFetch(
          `/events${eventForm.id ? `/${eventForm.id}` : ""}`,
          {
            method: eventForm.id ? "PATCH" : "POST",
            body: payload,
          },
        );

        if (!response.ok) {
          let message = "Unable to save the event right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setEventAccessFeedback(message);
          return;
        }

        await loadEventsArena();
        resetEventEditor();
        setActiveEventsTab("Event");
        setEventAccessFeedback(
          eventForm.id
            ? "Event changes saved successfully."
            : "Event created and added to the live schedule.",
        );
      } finally {
        setSavingEventId(null);
      }
    })();
  };
  const removeEventRecord = (eventId) => {
    void (async () => {
      setSavingEventId(eventId);
      setEventAccessFeedback("");

      try {
        const response = await runAuthenticatedFetch(`/events/${eventId}`, {
          method: "DELETE",
        });

        if (!response.ok && response.status !== 204) {
          let message = "Unable to delete the event right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setEventAccessFeedback(message);
          return;
        }

        await loadEventsArena();

        if (eventForm.id === eventId) {
          resetEventEditor();
        }

        setEventAccessFeedback("Event deleted.");
      } finally {
        setSavingEventId(null);
      }
    })();
  };

  const openAssociationProfileEditor = () => {
    setAssociationProfileFeedback("");
    setAssociationProfileForm(associationProfile);
    setIsEditingAssociationProfile(true);
  };

  const updateAssociationProfileField = (field, value) => {
    setAssociationProfileFeedback("");
    setAssociationProfileForm((current) => ({
      ...current,
      ...(field === "state" ? { city: "" } : {}),
      [field]: value,
    }));
  };

  const updateAssociationRegionalField = (index, field, value) => {
    setAssociationProfileFeedback("");
    setAssociationProfileForm((current) => ({
      ...current,
      regionalAddresses: current.regionalAddresses.map(
        (address, addressIndex) =>
          addressIndex === index
            ? {
                ...address,
                ...(field === "state" ? { city: "" } : {}),
                [field]: value,
              }
            : address,
      ),
    }));
  };

  const addAssociationRegionalAddress = () => {
    setAssociationProfileFeedback("");
    setAssociationProfileForm((current) => ({
      ...current,
      regionalAddresses: [
        ...current.regionalAddresses,
        { ...defaultRegionalAddress, id: `regional-${Date.now()}` },
      ],
    }));
  };

  const removeAssociationRegionalAddress = (index) => {
    setAssociationProfileFeedback("");
    setAssociationProfileForm((current) => ({
      ...current,
      regionalAddresses: current.regionalAddresses.filter(
        (_, addressIndex) => addressIndex !== index,
      ),
    }));
  };

  const cancelAssociationProfileEdit = () => {
    setAssociationProfileFeedback("");
    setAssociationProfileForm(associationProfile);
    setIsEditingAssociationProfile(false);
  };

  const saveAssociationProfile = () => {
    void (async () => {
      const normalizedName = associationProfileForm.name.trim();
      if (!normalizedName || !associationProfile.id) {
        setAssociationProfileFeedback(
          "Association name is required before saving.",
        );
        return;
      }

      const payload = {
        name: normalizedName,
        slug:
          associationProfileForm.slug.trim() ||
          normalizedName
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, "-")
            .replace(/^-|-$/g, ""),
        headOfficeAddress: associationProfileForm.headOfficeAddress.trim(),
        city: associationProfileForm.city.trim(),
        state: associationProfileForm.state.trim(),
        pincode: associationProfileForm.pincode.trim(),
        registrationNumber: associationProfileForm.registrationNumber.trim(),
        gstNumber: associationProfileForm.gstNumber.trim(),
        website: associationProfileForm.website.trim(),
        contactNumbers: splitContactNumbers(
          associationProfileForm.contactNumbers,
        ),
        helpdeskNumber: associationProfileForm.helpdeskNumber.trim(),
        googleMapsLink: associationProfileForm.googleMapsLink.trim(),
        regionalAddresses: associationProfileForm.regionalAddresses.map(
          (address) => ({
            label: address.label.trim(),
            officeAddress: address.officeAddress.trim(),
            city: address.city.trim(),
            state: address.state.trim(),
            pincode: address.pincode.trim(),
            registrationNumber: address.registrationNumber.trim(),
            gstNumber: address.gstNumber.trim(),
            website: address.website.trim(),
            contactNumbers: splitContactNumbers(address.contactNumbers),
            helpdeskNumber: address.helpdeskNumber.trim(),
            googleMapsLink: address.googleMapsLink.trim(),
          }),
        ),
      };

      setIsSavingAssociationProfile(true);
      setAssociationProfileFeedback("");

      try {
        const response = await runAuthenticatedFetch(
          `/associations/${associationProfile.id}`,
          {
            method: "PATCH",
            body: JSON.stringify(payload),
          },
        );

        if (!response.ok) {
          let message = "Unable to save the association profile right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setAssociationProfileFeedback(message);
          return;
        }

        await loadAssociationProfile();
        setIsEditingAssociationProfile(false);
        setAssociationProfileFeedback(
          "Association profile updated successfully.",
        );
      } finally {
        setIsSavingAssociationProfile(false);
      }
    })();
  };

  const openAssociationAboutEditor = () => {
    setAssociationAboutFeedback("");
    setAssociationAboutForm(associationAbout);
    setIsEditingAssociationAbout(true);
  };

  const updateAssociationAboutField = (field, value) => {
    setAssociationAboutFeedback("");
    setAssociationAboutForm((current) => ({
      ...current,
      [field]: value,
    }));
  };

  const updateAssociationAboutImage = (field, file) => {
    void (async () => {
      if (!file) {
        return;
      }

      const nextImage = await readFileAsDataUrl(file);
      setAssociationAboutFeedback("");
      setAssociationAboutForm((current) => ({
        ...current,
        [field]: nextImage,
      }));
    })();
  };

  const cancelAssociationAboutEdit = () => {
    setAssociationAboutFeedback("");
    setAssociationAboutForm(associationAbout);
    setIsEditingAssociationAbout(false);
  };

  const saveAssociationAbout = () => {
    void (async () => {
      if (!associationProfile.id) {
        setAssociationAboutFeedback(
          "Association profile must be available before saving About Us.",
        );
        return;
      }

      const payload = {
        heroTitle: associationAboutForm.heroTitle.trim(),
        heroIntro: associationAboutForm.heroIntro.trim(),
        missionTitle: associationAboutForm.missionTitle.trim(),
        missionText: associationAboutForm.missionText.trim(),
        goalsTitle: associationAboutForm.goalsTitle.trim(),
        goalsText: associationAboutForm.goalsText.trim(),
        journeyTitle: associationAboutForm.journeyTitle.trim(),
        journeyText: associationAboutForm.journeyText.trim(),
        headOfficeImage: associationAboutForm.headOfficeImage,
        galleryImageOne: associationAboutForm.galleryImageOne,
        galleryImageTwo: associationAboutForm.galleryImageTwo,
        stats: associationAboutForm.stats,
      };

      setIsSavingAssociationAbout(true);
      setAssociationAboutFeedback("");

      try {
        const response = await runAuthenticatedFetch(
          `/associations/${associationProfile.id}/about`,
          {
            method: "PATCH",
            body: JSON.stringify(payload),
          },
        );

        if (!response.ok) {
          let message = "Unable to save the About Us content right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setAssociationAboutFeedback(message);
          return;
        }

        const savedPayload = await response.json();
        const nextAbout = mapAssociationAboutToForm(savedPayload.aboutContent);
        setAssociationAbout(nextAbout);
        setAssociationAboutForm(nextAbout);
        setIsEditingAssociationAbout(false);
        setAssociationAboutFeedback("About Us updated successfully.");
      } finally {
        setIsSavingAssociationAbout(false);
      }
    })();
  };

  const openCommitteeMemberEditor = (memberId) => {
    setCommitteeMemberFeedback("");
    if (!memberId) {
      setEditingCommitteeMemberId("");
      setCommitteeMemberForm(defaultCommitteeMemberForm);
      return;
    }

    const member = (memberTabData["All Members"] ?? []).find(
      (item) => item.id === memberId,
    );
    if (!member) {
      return;
    }

    setEditingCommitteeMemberId(memberId);
    setCommitteeMemberForm({
      memberId: member.id,
      committeePost: member.committeePost ?? "",
      committeeTenureStart: member.committeeTenureStart ?? "",
      committeeTenureEnd: member.committeeTenureEnd ?? "",
      memberBio: member.memberBio ?? "",
      photoUrl: member.photoUrl ?? "",
    });
  };

  const updateCommitteeMemberForm = (field, value) => {
    setCommitteeMemberFeedback("");
    setCommitteeMemberForm((current) => ({
      ...current,
      ...(field === "memberId"
        ? {
            photoUrl:
              (memberTabData["All Members"] ?? []).find(
                (member) => member.id === value,
              )?.photoUrl ?? "",
          }
        : {}),
      [field]: value,
    }));
  };

  const updateCommitteeMemberImage = (file) => {
    void (async () => {
      if (!file) {
        return;
      }

      const nextImage = await readFileAsDataUrl(file);
      setCommitteeMemberFeedback("");
      setCommitteeMemberForm((current) => ({
        ...current,
        photoUrl: nextImage,
      }));
    })();
  };

  const closeCommitteeMemberEditor = () => {
    setCommitteeMemberFeedback("");
    setEditingCommitteeMemberId(null);
    setCommitteeMemberForm(defaultCommitteeMemberForm);
  };

  const addCommitteePostMaster = () => {
    const normalizedPost = normalizeCommitteePostLabel(committeePostMasterDraft);
    if (!normalizedPost) {
      setCommitteePostMasterFeedback("Enter a committee post name first.");
      return;
    }

    const alreadyExists = committeePostOptions.some(
      (post) => post.toLowerCase() === normalizedPost.toLowerCase(),
    );
    if (alreadyExists) {
      setCommitteePostMasterFeedback("That committee post already exists.");
      return;
    }

    setCommitteePostMasterList((current) =>
      buildCommitteePostOptions(committeeMembers, [...current, normalizedPost]),
    );
    setCommitteePostMasterFeedback(`Committee post "${normalizedPost}" added.`);

    setCommitteePostMasterDraft("");
  };

  const editCommitteePostMaster = (post) => {
    const normalizedPost = normalizeCommitteePostLabel(post);
    const isOccupied = committeeMembers.some(
      (member) =>
        normalizeCommitteePostLabel(member.committeePost || "") === normalizedPost,
    );
    const isDefaultPost = defaultCommitteePostOptions.includes(normalizedPost);

    if (isOccupied || isDefaultPost) {
      setCommitteePostMasterFeedback(
        "Only custom vacant committee posts can be edited.",
      );
      return;
    }

    setEditingCommitteePostMaster(normalizedPost);
    setCommitteePostMasterEditDraft(normalizedPost);
    setCommitteePostMasterFeedback("");
  };

  const cancelCommitteePostMasterEdit = () => {
    setEditingCommitteePostMaster("");
    setCommitteePostMasterEditDraft("");
    setCommitteePostMasterFeedback("");
  };

  const saveCommitteePostMasterEdit = () => {
    const normalizedPost = normalizeCommitteePostLabel(
      committeePostMasterEditDraft,
    );

    if (!editingCommitteePostMaster) {
      setCommitteePostMasterFeedback("Select a committee post to edit first.");
      return;
    }

    if (!normalizedPost) {
      setCommitteePostMasterFeedback("Enter a committee post name first.");
      return;
    }

    const isStillOccupied = committeeMembers.some(
      (member) =>
        normalizeCommitteePostLabel(member.committeePost || "") ===
        editingCommitteePostMaster,
    );
    const isDefaultPost = defaultCommitteePostOptions.includes(
      editingCommitteePostMaster,
    );

    if (isStillOccupied || isDefaultPost) {
      setCommitteePostMasterFeedback(
        "Vacate this committee post before editing it.",
      );
      return;
    }

    const alreadyExists = committeePostOptions.some(
      (post) =>
        post.toLowerCase() === normalizedPost.toLowerCase() &&
        post.toLowerCase() !== editingCommitteePostMaster.toLowerCase(),
    );
    if (alreadyExists) {
      setCommitteePostMasterFeedback("That committee post already exists.");
      return;
    }

    setCommitteePostMasterList((current) =>
      buildCommitteePostOptions(
        committeeMembers,
        current.map((post) =>
          post === editingCommitteePostMaster ? normalizedPost : post,
        ),
      ),
    );
    setCommitteePostMasterFeedback(
      `Committee post "${editingCommitteePostMaster}" updated to "${normalizedPost}".`,
    );
    setEditingCommitteePostMaster("");
    setCommitteePostMasterEditDraft("");
  };

  const deleteCommitteePostMaster = (post) => {
    const normalizedPost = normalizeCommitteePostLabel(post);
    const isOccupied = committeeMembers.some(
      (member) =>
        normalizeCommitteePostLabel(member.committeePost || "") === normalizedPost,
    );
    const isDefaultPost = defaultCommitteePostOptions.includes(normalizedPost);

    if (isOccupied || isDefaultPost) {
      setCommitteePostMasterFeedback(
        "Only custom vacant committee posts can be deleted.",
      );
      return;
    }

    setCommitteePostMasterList((current) =>
      current.filter((item) => item !== normalizedPost),
    );
    if (editingCommitteePostMaster === normalizedPost) {
      setEditingCommitteePostMaster("");
      setCommitteePostMasterEditDraft("");
    }
    setCommitteePostMasterFeedback(`Committee post "${normalizedPost}" deleted.`);
  };

  const addMembershipTypeMaster = () => {
    const normalizedType = normalizeMembershipTypeLabel(
      membershipTypeMasterDraft,
    );
    if (!normalizedType) {
      setMembershipTypeMasterFeedback("Enter a membership type name first.");
      return;
    }

    const alreadyExists = membershipTypeOptions.some(
      (type) => type.toLowerCase() === normalizedType.toLowerCase(),
    );
    if (alreadyExists) {
      setMembershipTypeMasterFeedback("That membership type already exists.");
      return;
    }

    setMembershipTypeMasterList((current) =>
      buildMembershipTypeOptions(memberTabData["All Members"] ?? [], [
        ...current,
        normalizedType,
      ]),
    );
    setMembershipTypeMasterFeedback(
      `Membership type "${getMembershipTypeDisplayLabel(normalizedType)}" added.`,
    );
    setMembershipTypeMasterDraft("");
  };

  const editMembershipTypeMaster = (type) => {
    const normalizedType = normalizeMembershipTypeLabel(type);
    const isOccupied = (memberTabData["All Members"] ?? []).some(
      (member) =>
        normalizeMembershipTypeLabel(member.membershipType || "") ===
        normalizedType,
    );
    const isDefaultType = defaultMembershipTypeOptions.includes(normalizedType);

    if (isOccupied || isDefaultType) {
      setMembershipTypeMasterFeedback(
        "Only custom vacant membership types can be edited.",
      );
      return;
    }

    setEditingMembershipTypeMaster(normalizedType);
    setMembershipTypeMasterEditDraft(normalizedType);
    setMembershipTypeMasterFeedback("");
  };

  const cancelMembershipTypeMasterEdit = () => {
    setEditingMembershipTypeMaster("");
    setMembershipTypeMasterEditDraft("");
    setMembershipTypeMasterFeedback("");
  };

  const saveMembershipTypeMasterEdit = () => {
    const normalizedType = normalizeMembershipTypeLabel(
      membershipTypeMasterEditDraft,
    );

    if (!editingMembershipTypeMaster) {
      setMembershipTypeMasterFeedback("Select a membership type to edit first.");
      return;
    }

    if (!normalizedType) {
      setMembershipTypeMasterFeedback("Enter a membership type name first.");
      return;
    }

    const isStillOccupied = (memberTabData["All Members"] ?? []).some(
      (member) =>
        normalizeMembershipTypeLabel(member.membershipType || "") ===
        editingMembershipTypeMaster,
    );
    const isDefaultType = defaultMembershipTypeOptions.includes(
      editingMembershipTypeMaster,
    );

    if (isStillOccupied || isDefaultType) {
      setMembershipTypeMasterFeedback(
        "Vacate this membership type before editing it.",
      );
      return;
    }

    const alreadyExists = membershipTypeOptions.some(
      (type) =>
        type.toLowerCase() === normalizedType.toLowerCase() &&
        type.toLowerCase() !== editingMembershipTypeMaster.toLowerCase(),
    );
    if (alreadyExists) {
      setMembershipTypeMasterFeedback("That membership type already exists.");
      return;
    }

    setMembershipTypeMasterList((current) =>
      buildMembershipTypeOptions(
        memberTabData["All Members"] ?? [],
        current.map((type) =>
          type === editingMembershipTypeMaster ? normalizedType : type,
        ),
      ),
    );
    setMembershipTypeMasterFeedback(
      `Membership type "${getMembershipTypeDisplayLabel(editingMembershipTypeMaster)}" updated to "${getMembershipTypeDisplayLabel(normalizedType)}".`,
    );
    setEditingMembershipTypeMaster("");
    setMembershipTypeMasterEditDraft("");
  };

  const deleteMembershipTypeMaster = (type) => {
    const normalizedType = normalizeMembershipTypeLabel(type);
    const isOccupied = (memberTabData["All Members"] ?? []).some(
      (member) =>
        normalizeMembershipTypeLabel(member.membershipType || "") ===
        normalizedType,
    );
    const isDefaultType = defaultMembershipTypeOptions.includes(normalizedType);

    if (isOccupied || isDefaultType) {
      setMembershipTypeMasterFeedback(
        "Only custom vacant membership types can be deleted.",
      );
      return;
    }

    setMembershipTypeMasterList((current) =>
      current.filter((item) => item !== normalizedType),
    );
    if (editingMembershipTypeMaster === normalizedType) {
      setEditingMembershipTypeMaster("");
      setMembershipTypeMasterEditDraft("");
    }
    setMembershipTypeMasterFeedback(
      `Membership type "${getMembershipTypeDisplayLabel(normalizedType)}" deleted.`,
    );
  };

  const saveCommitteeMember = () => {
    void (async () => {
      const targetMemberId = committeeMemberForm.memberId;
      const normalizedCommitteePost = normalizeCommitteePostLabel(
        committeeMemberForm.committeePost || "",
      );

      if (!targetMemberId || !normalizedCommitteePost) {
        setCommitteeMemberFeedback(
          "Select a member and committee post before saving.",
        );
        return;
      }

      const conflictingMember = committeeMembers.find(
        (member) =>
          member.id !== targetMemberId &&
          normalizeCommitteePostLabel(member.committeePost || "") ===
            normalizedCommitteePost &&
          !isReusableCommitteePost(normalizedCommitteePost),
      );

      if (conflictingMember) {
        setCommitteeMemberFeedback(
          `${normalizedCommitteePost} is already assigned to ${conflictingMember.name}. Vacate it first or choose another post.`,
        );
        return;
      }

      setIsSavingCommitteeMember(true);
      setCommitteeMemberFeedback("");

      try {
        const response = await runAuthenticatedFetch(
          `/members/${targetMemberId}`,
          {
            method: "PATCH",
            body: JSON.stringify({
              committeePost: normalizedCommitteePost,
              committeeTenureStart:
                committeeMemberForm.committeeTenureStart || null,
              committeeTenureEnd: committeeMemberForm.committeeTenureEnd || null,
              memberBio: committeeMemberForm.memberBio.trim(),
              photoUrl: committeeMemberForm.photoUrl || null,
            }),
          },
        );

        if (!response.ok) {
          let message = "Unable to save committee details right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setCommitteeMemberFeedback(message);
          return;
        }

        await loadMembers();
        closeCommitteeMemberEditor();
        setCommitteeMemberFeedback("Committee member updated successfully.");
      } finally {
        setIsSavingCommitteeMember(false);
      }
    })();
  };

  const removeCommitteeMember = (memberId) => {
    void (async () => {
      setIsSavingCommitteeMember(true);
      setCommitteeMemberFeedback("");

      try {
        const response = await runAuthenticatedFetch(`/members/${memberId}`, {
          method: "PATCH",
          body: JSON.stringify({
            committeePost: "",
            committeeTenureStart: null,
            committeeTenureEnd: null,
            memberBio: "",
          }),
        });

        if (!response.ok) {
          let message = "Unable to remove the committee member right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setCommitteeMemberFeedback(message);
          return;
        }

        await loadMembers();
        if (editingCommitteeMemberId === memberId) {
          closeCommitteeMemberEditor();
        }
        setCommitteeMemberFeedback("Committee assignment removed.");
      } finally {
        setIsSavingCommitteeMember(false);
      }
    })();
  };

  const openGalleryItemEditor = (itemId) => {
    setGalleryItemFeedback("");
    if (!itemId) {
      setEditingGalleryItemId("");
      setGalleryItemForm(defaultGalleryItemForm);
      return;
    }

    const item = galleryItems.find((galleryItem) => galleryItem.id === itemId);
    if (!item) {
      return;
    }

    setEditingGalleryItemId(itemId);
    setGalleryItemForm({
      id: item.id,
      imageUrl: item.imageUrl ?? "",
      headline: item.headline ?? "",
      tagline: item.tagline ?? "",
      description: item.description ?? "",
    });
  };

  const updateGalleryItemField = (field, value) => {
    setGalleryItemFeedback("");
    setGalleryItemForm((current) => ({
      ...current,
      [field]: value,
    }));
  };

  const updateGalleryItemImage = (file) => {
    void (async () => {
      if (!file) {
        return;
      }

      const nextImage = await readFileAsDataUrl(file);
      setGalleryItemFeedback("");
      setGalleryItemForm((current) => ({
        ...current,
        imageUrl: nextImage,
      }));
    })();
  };

  const cancelGalleryItemEdit = () => {
    setGalleryItemFeedback("");
    setEditingGalleryItemId(null);
    setGalleryItemForm(defaultGalleryItemForm);
  };

  const openGalleryFolderEditor = (folderId = "") => {
    setGalleryFolderFeedback("");
    if (!folderId) {
      setEditingGalleryFolderId("");
      setGalleryFolderForm(defaultGalleryFolderForm);
      return;
    }

    const folder = galleryFolders.find((item) => item.id === folderId);
    if (!folder) {
      return;
    }

    setEditingGalleryFolderId(folderId);
    setGalleryFolderForm({
      id: folder.id,
      name: folder.name ?? "",
      files: [],
    });
  };

  const cancelGalleryFolderEdit = () => {
    setGalleryFolderFeedback("");
    setEditingGalleryFolderId(null);
    setGalleryFolderForm(defaultGalleryFolderForm);
  };

  const updateGalleryFolderField = (field, value) => {
    setGalleryFolderFeedback("");
    setGalleryFolderForm((current) => ({
      ...current,
      [field]: value,
    }));
  };

  const updateGalleryFolderFiles = (files) => {
    setGalleryFolderFeedback("");
    setGalleryFolderForm((current) => ({
      ...current,
      files: Array.from(files ?? []).filter((file) =>
        file.type.startsWith("image/"),
      ),
    }));
  };

  const saveGalleryFolder = () => {
    void (async () => {
      if (!associationProfile.id || !galleryFolderForm.name.trim()) {
        setGalleryFolderFeedback("Folder name is required before saving.");
        return;
      }

      setIsSavingGalleryFolder(true);
      setGalleryFolderFeedback("");

      try {
        let response;
        if (editingGalleryFolderId) {
          response = await runAuthenticatedFetch(
            `/associations/${associationProfile.id}/gallery/folders/${editingGalleryFolderId}`,
            {
              method: "PATCH",
              body: JSON.stringify({
                name: galleryFolderForm.name.trim(),
              }),
            },
          );
        } else {
          const payload = new FormData();
          payload.append("name", galleryFolderForm.name.trim());
          galleryFolderForm.files.forEach((file) => {
            payload.append("files", file);
          });
          response = await runAuthenticatedFetch(
            `/associations/${associationProfile.id}/gallery/folders`,
            {
              method: "POST",
              body: payload,
            },
          );
        }

        if (!response.ok) {
          let message = editingGalleryFolderId
            ? "Unable to update the gallery folder right now."
            : "Unable to create the gallery folder right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setGalleryFolderFeedback(message);
          return;
        }

        const result = await response.json();
        const nextFolderId = result?.galleryFolder?.id ?? "";
        await loadAssociationProfile();
        setActiveGalleryFolderId(nextFolderId || activeGalleryFolderId);
        cancelGalleryFolderEdit();
        setGalleryFolderFeedback(
          editingGalleryFolderId
            ? "Gallery folder updated successfully."
            : "Gallery folder created successfully.",
        );
      } finally {
        setIsSavingGalleryFolder(false);
      }
    })();
  };

  const uploadGalleryFolderPhotos = (folderId, files) => {
    void (async () => {
      if (!associationProfile.id) {
        setGalleryFolderFeedback(
          "Association profile must be available before uploading photos.",
        );
        return;
      }

      const imageFiles = Array.from(files ?? []).filter((file) =>
        file.type.startsWith("image/"),
      );

      if (imageFiles.length === 0) {
        setGalleryFolderFeedback("Select one or more images before uploading.");
        return;
      }

      setIsSavingGalleryFolder(true);
      setGalleryFolderFeedback("");

      try {
        const payload = new FormData();
        imageFiles.forEach((file) => {
          payload.append("files", file);
        });

        const response = await runAuthenticatedFetch(
          `/associations/${associationProfile.id}/gallery/folders/${folderId}/photos`,
          {
            method: "POST",
            body: payload,
          },
        );

        if (!response.ok) {
          let message = "Unable to upload gallery photos right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setGalleryFolderFeedback(message);
          return;
        }

        await loadAssociationProfile();
        setActiveGalleryFolderId(folderId);
        setGalleryFolderFeedback(
          `${imageFiles.length} photo${imageFiles.length === 1 ? "" : "s"} uploaded successfully.`,
        );
      } finally {
        setIsSavingGalleryFolder(false);
      }
    })();
  };

  const toggleSelectGalleryFolder = (folderId) => {
    setSelectedGalleryFolderIds((current) =>
      current.includes(folderId)
        ? current.filter((id) => id !== folderId)
        : [...current, folderId],
    );
  };

  const toggleSelectGalleryPhoto = (photoId) => {
    setSelectedGalleryPhotoIds((current) =>
      current.includes(photoId)
        ? current.filter((id) => id !== photoId)
        : [...current, photoId],
    );
  };

  const deleteGalleryFolder = (folderId) => {
    void (async () => {
      if (!associationProfile.id) {
        setGalleryFolderFeedback(
          "Association profile must be available before deleting a folder.",
        );
        return;
      }

      setIsSavingGalleryFolder(true);
      setGalleryFolderFeedback("");

      try {
        const response = await runAuthenticatedFetch(
          `/associations/${associationProfile.id}/gallery/folders/${folderId}`,
          {
            method: "DELETE",
          },
        );

        if (!response.ok && response.status !== 204) {
          let message = "Unable to delete the gallery folder right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setGalleryFolderFeedback(message);
          return;
        }

        await loadAssociationProfile();
        setSelectedGalleryFolderIds((current) =>
          current.filter((id) => id !== folderId),
        );
        if (activeGalleryFolderId === folderId) {
          setActiveGalleryFolderId("");
          setSelectedGalleryPhotoIds([]);
        }
        if (editingGalleryFolderId === folderId) {
          cancelGalleryFolderEdit();
        }
        setGalleryFolderFeedback("Gallery folder deleted.");
      } finally {
        setIsSavingGalleryFolder(false);
      }
    })();
  };

  const deleteGalleryPhoto = (folderId, photoId) => {
    void (async () => {
      if (!associationProfile.id) {
        setGalleryFolderFeedback(
          "Association profile must be available before deleting a photo.",
        );
        return;
      }

      setIsSavingGalleryFolder(true);
      setGalleryFolderFeedback("");

      try {
        const response = await runAuthenticatedFetch(
          `/associations/${associationProfile.id}/gallery/folders/${folderId}/photos/${photoId}`,
          {
            method: "DELETE",
          },
        );

        if (!response.ok && response.status !== 204) {
          let message = "Unable to delete the gallery photo right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setGalleryFolderFeedback(message);
          return;
        }

        await loadAssociationProfile();
        setSelectedGalleryPhotoIds((current) =>
          current.filter((id) => id !== photoId),
        );
        setGalleryFolderFeedback("Gallery photo deleted.");
      } finally {
        setIsSavingGalleryFolder(false);
      }
    })();
  };

  const deleteSelectedGalleryFolders = () => {
    void (async () => {
      if (!associationProfile.id || selectedGalleryFolderIds.length === 0) {
        setGalleryFolderFeedback("Select one or more folders to delete.");
        return;
      }

      setIsSavingGalleryFolder(true);
      setGalleryFolderFeedback("");

      try {
        await Promise.all(
          selectedGalleryFolderIds.map(async (folderId) => {
            const response = await runAuthenticatedFetch(
              `/associations/${associationProfile.id}/gallery/folders/${folderId}`,
              {
                method: "DELETE",
              },
            );

            if (!response.ok && response.status !== 204) {
              throw new Error("Unable to delete selected gallery folders.");
            }
          }),
        );

        const deletedFolderIds = [...selectedGalleryFolderIds];
        await loadAssociationProfile();
        setSelectedGalleryFolderIds([]);
        if (deletedFolderIds.includes(activeGalleryFolderId)) {
          setActiveGalleryFolderId("");
          setSelectedGalleryPhotoIds([]);
        }
        setGalleryFolderFeedback(
          `${deletedFolderIds.length} folder${deletedFolderIds.length === 1 ? "" : "s"} deleted.`,
        );
      } catch (_error) {
        setGalleryFolderFeedback("Unable to delete selected gallery folders.");
      } finally {
        setIsSavingGalleryFolder(false);
      }
    })();
  };

  const deleteSelectedGalleryPhotos = () => {
    void (async () => {
      if (
        !associationProfile.id ||
        !activeGalleryFolderId ||
        selectedGalleryPhotoIds.length === 0
      ) {
        setGalleryFolderFeedback("Select one or more photos to delete.");
        return;
      }

      setIsSavingGalleryFolder(true);
      setGalleryFolderFeedback("");

      try {
        await Promise.all(
          selectedGalleryPhotoIds.map(async (photoId) => {
            const response = await runAuthenticatedFetch(
              `/associations/${associationProfile.id}/gallery/folders/${activeGalleryFolderId}/photos/${photoId}`,
              {
                method: "DELETE",
              },
            );

            if (!response.ok && response.status !== 204) {
              throw new Error("Unable to delete selected gallery photos.");
            }
          }),
        );

        const deletedPhotoIds = [...selectedGalleryPhotoIds];
        await loadAssociationProfile();
        setSelectedGalleryPhotoIds([]);
        setGalleryFolderFeedback(
          `${deletedPhotoIds.length} photo${deletedPhotoIds.length === 1 ? "" : "s"} deleted.`,
        );
      } catch (_error) {
        setGalleryFolderFeedback("Unable to delete selected gallery photos.");
      } finally {
        setIsSavingGalleryFolder(false);
      }
    })();
  };

  const openGalleryFolder = (folderId) => {
    setActiveGalleryFolderId(folderId);
    setSelectedGalleryPhotoIds([]);
  };

  const closeGalleryFolder = () => {
    setActiveGalleryFolderId("");
    setSelectedGalleryPhotoIds([]);
  };

  const toggleSelectGalleryItem = (itemId) => {
    setSelectedGalleryItemIds((current) =>
      current.includes(itemId)
        ? current.filter((id) => id !== itemId)
        : [...current, itemId],
    );
  };

  const saveGalleryItem = () => {
    void (async () => {
      if (!associationProfile.id || !galleryItemForm.headline.trim()) {
        setGalleryItemFeedback("Gallery headline is required before saving.");
        return;
      }

      const payload = {
        imageUrl: galleryItemForm.imageUrl,
        headline: galleryItemForm.headline.trim(),
        tagline: galleryItemForm.tagline.trim(),
        description: galleryItemForm.description.trim(),
      };

      setIsSavingGalleryItem(true);
      setGalleryItemFeedback("");

      try {
        const response = await runAuthenticatedFetch(
          `/associations/${associationProfile.id}/gallery${editingGalleryItemId ? `/${editingGalleryItemId}` : ""}`,
          {
            method: editingGalleryItemId ? "PATCH" : "POST",
            body: JSON.stringify(payload),
          },
        );

        if (!response.ok) {
          let message = "Unable to save the gallery item right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setGalleryItemFeedback(message);
          return;
        }

        await loadAssociationProfile();
        cancelGalleryItemEdit();
        setSelectedGalleryItemIds([]);
        setGalleryItemFeedback("Gallery item saved successfully.");
      } finally {
        setIsSavingGalleryItem(false);
      }
    })();
  };

  const deleteGalleryItem = (itemId) => {
    void (async () => {
      if (!associationProfile.id) {
        setGalleryItemFeedback(
          "Association profile must be available before deleting a gallery item.",
        );
        return;
      }

      setIsSavingGalleryItem(true);
      setGalleryItemFeedback("");

      try {
        const response = await runAuthenticatedFetch(
          `/associations/${associationProfile.id}/gallery/${itemId}`,
          {
            method: "DELETE",
          },
        );

        if (!response.ok && response.status !== 204) {
          let message = "Unable to delete the gallery item right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setGalleryItemFeedback(message);
          return;
        }

        await loadAssociationProfile();
        if (editingGalleryItemId === itemId) {
          cancelGalleryItemEdit();
        }
        setSelectedGalleryItemIds((current) =>
          current.filter((id) => id !== itemId),
        );
        setGalleryItemFeedback("Gallery item deleted.");
      } finally {
        setIsSavingGalleryItem(false);
      }
    })();
  };

  const deleteSelectedGalleryItems = () => {
    void (async () => {
      if (!associationProfile.id || selectedGalleryItemIds.length === 0) {
        setGalleryItemFeedback("Select one or more gallery items first.");
        return;
      }

      setIsSavingGalleryItem(true);
      setGalleryItemFeedback("");

      try {
        await Promise.all(
          selectedGalleryItemIds.map(async (itemId) => {
            const response = await runAuthenticatedFetch(
              `/associations/${associationProfile.id}/gallery/${itemId}`,
              {
                method: "DELETE",
              },
            );

            if (!response.ok && response.status !== 204) {
              let message = "Unable to delete one or more gallery items.";
              try {
                const result = await response.json();
                if (result?.error) {
                  message = result.error;
                }
              } catch {}
              throw new Error(message);
            }
          }),
        );

        await loadAssociationProfile();
        setSelectedGalleryItemIds([]);
        setGalleryItemFeedback(
          `${selectedGalleryItemIds.length} gallery item${selectedGalleryItemIds.length === 1 ? "" : "s"} deleted.`,
        );
      } catch (error) {
        setGalleryItemFeedback(
          error instanceof Error
            ? error.message
            : "Unable to delete the selected gallery items right now.",
        );
      } finally {
        setIsSavingGalleryItem(false);
      }
    })();
  };

  const openCircularDocumentEditor = (itemId) => {
    setCircularDocumentFeedback("");
    if (!itemId) {
      setEditingCircularDocumentId("");
      setCircularDocumentForm(defaultCircularDocumentForm);
      return;
    }

    const item = circularDocuments.find((document) => document.id === itemId);
    if (!item) {
      return;
    }

    setEditingCircularDocumentId(itemId);
    setCircularDocumentForm({
      id: item.id,
      headline: item.headline ?? "",
      tagline: item.tagline ?? "",
      summary: item.summary ?? "",
      file: null,
      fileName: item.fileName ?? "",
      documentUrl: item.documentUrl ?? "",
      previewUrl: item.previewUrl ?? "",
      mimeType: item.mimeType ?? "",
      fileExtension: item.fileExtension ?? "",
    });
  };

  const updateCircularDocumentField = (field, value) => {
    setCircularDocumentFeedback("");
    setCircularDocumentForm((current) => ({
      ...current,
      [field]: value,
    }));
  };

  const updateCircularDocumentFile = (file) => {
    void (async () => {
      if (!file) {
        return;
      }

      const previewUrl = file.type.startsWith("image/")
        ? await readFileAsDataUrl(file)
        : "";
      setCircularDocumentFeedback("");
      setCircularDocumentForm((current) => ({
        ...current,
        file,
        fileName: file.name,
        mimeType: file.type,
        fileExtension: file.name.split(".").pop()?.toUpperCase() ?? "FILE",
        previewUrl,
      }));
    })();
  };

  const cancelCircularDocumentEdit = () => {
    setCircularDocumentFeedback("");
    setEditingCircularDocumentId(null);
    setCircularDocumentForm(defaultCircularDocumentForm);
  };

  const toggleSelectCircularDocument = (itemId) => {
    setSelectedCircularDocumentIds((current) =>
      current.includes(itemId)
        ? current.filter((id) => id !== itemId)
        : [...current, itemId],
    );
  };

  const saveCircularDocument = () => {
    void (async () => {
      if (!associationProfile.id || !circularDocumentForm.headline.trim()) {
        setCircularDocumentFeedback(
          "Circular headline is required before saving.",
        );
        return;
      }

      if (!editingCircularDocumentId && !circularDocumentForm.file) {
        setCircularDocumentFeedback(
          "Upload a document before creating a new circular.",
        );
        return;
      }

      const payload = new FormData();
      payload.append("headline", circularDocumentForm.headline.trim());
      payload.append("tagline", circularDocumentForm.tagline.trim());
      payload.append("summary", circularDocumentForm.summary.trim());
      if (circularDocumentForm.file) {
        payload.append("file", circularDocumentForm.file);
      }

      setIsSavingCircularDocument(true);
      setCircularDocumentFeedback("");

      try {
        const response = await runAuthenticatedFetch(
          `/associations/${associationProfile.id}/circulars${editingCircularDocumentId ? `/${editingCircularDocumentId}` : ""}`,
          {
            method: editingCircularDocumentId ? "PATCH" : "POST",
            body: payload,
          },
        );

        if (!response.ok) {
          let message = "Unable to save the circular right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setCircularDocumentFeedback(message);
          return;
        }

        await loadAssociationProfile();
        cancelCircularDocumentEdit();
        setSelectedCircularDocumentIds([]);
        setCircularDocumentFeedback("Circular saved successfully.");
      } finally {
        setIsSavingCircularDocument(false);
      }
    })();
  };

  const deleteCircularDocument = (itemId) => {
    void (async () => {
      if (!associationProfile.id) {
        setCircularDocumentFeedback(
          "Association profile must be available before deleting a circular.",
        );
        return;
      }

      setIsSavingCircularDocument(true);
      setCircularDocumentFeedback("");

      try {
        const response = await runAuthenticatedFetch(
          `/associations/${associationProfile.id}/circulars/${itemId}`,
          {
            method: "DELETE",
          },
        );

        if (!response.ok && response.status !== 204) {
          let message = "Unable to delete the circular right now.";
          try {
            const result = await response.json();
            if (result?.error) {
              message = result.error;
            }
          } catch {}
          setCircularDocumentFeedback(message);
          return;
        }

        await loadAssociationProfile();
        if (editingCircularDocumentId === itemId) {
          cancelCircularDocumentEdit();
        }
        setSelectedCircularDocumentIds((current) =>
          current.filter((id) => id !== itemId),
        );
        setCircularDocumentFeedback("Circular deleted.");
      } finally {
        setIsSavingCircularDocument(false);
      }
    })();
  };

  const deleteSelectedCircularDocuments = () => {
    void (async () => {
      if (!associationProfile.id || selectedCircularDocumentIds.length === 0) {
        setCircularDocumentFeedback("Select one or more circulars first.");
        return;
      }

      setIsSavingCircularDocument(true);
      setCircularDocumentFeedback("");

      try {
        await Promise.all(
          selectedCircularDocumentIds.map(async (itemId) => {
            const response = await runAuthenticatedFetch(
              `/associations/${associationProfile.id}/circulars/${itemId}`,
              {
                method: "DELETE",
              },
            );

            if (!response.ok && response.status !== 204) {
              let message = "Unable to delete one or more circulars.";
              try {
                const result = await response.json();
                if (result?.error) {
                  message = result.error;
                }
              } catch {}
              throw new Error(message);
            }
          }),
        );

        await loadAssociationProfile();
        setSelectedCircularDocumentIds([]);
        setCircularDocumentFeedback(
          `${selectedCircularDocumentIds.length} circular${selectedCircularDocumentIds.length === 1 ? "" : "s"} deleted.`,
        );
      } catch (error) {
        setCircularDocumentFeedback(
          error instanceof Error
            ? error.message
            : "Unable to delete the selected circulars right now.",
        );
      } finally {
        setIsSavingCircularDocument(false);
      }
    })();
  };

  const toggleAppPermission = (permissionKey) => {
    setAppAccessFeedback("");
    setAppPermissions((current) => ({
      ...current,
      [permissionKey]: !current[permissionKey],
    }));
  };

  const applyReminderFilter = (filterKey) => {
    const filteredIds = activeMemberItems
      .filter((member) => {
        if (filterKey === "expiring-soon") {
          return member.expiryStatus === "expiring-soon";
        }

        return member.group === filterKey;
      })
      .map((member) => member.id);

    setSelectedMemberRecords((current) => ({
      ...current,
      [activeMemberTab]: filteredIds,
    }));
    setIsReminderPanelOpen(false);
  };

  if (!authReady) {
    return (
      <main className="dashboard-shell">
        <section className="content-shell">
          <section className="association-empty-state">
            <span className="mini-label">Admin Session</span>
            <h2>Restoring admin session...</h2>
            <p>
              Checking the backend token and refresh state for the laptop admin
              workspace.
            </p>
          </section>
        </section>
      </main>
    );
  }

  if (!authSession) {
    return (
      <WebAdminLoginScreen
        form={loginForm}
        errorMessage={loginError}
        isSubmitting={isLoggingIn}
        onFieldChange={updateLoginField}
        onSubmit={submitAdminLogin}
      />
    );
  }

  return (
    <main
      className={`admin-shell ${isSidebarOpen ? "sidebar-open" : "sidebar-collapsed"} relative min-h-screen`}
    >
      <aside className={`sidebar ${isSidebarOpen ? "" : "is-collapsed"}`}>
        <div className="sidebar-brand">
          <span className="brand-mark">S</span>
          <div
            className={`sidebar-brand-copy ${isSidebarOpen ? "" : "is-hidden"}`}
          >
            <strong>{authSession.displayName || "NIMA Admin"}</strong>
            <p>{authSession.email}</p>
          </div>
        </div>
        {isSidebarOpen ? (
          <div className="sidebar-brand-copy" style={{ paddingBottom: 16 }}>
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={logoutAdmin}
            >
              Logout
            </button>
          </div>
        ) : null}

        <nav className="sidebar-nav" aria-label="Sidebar">
          {navSections.map((item) => (
            <div key={item.label} className="sidebar-nav-group">
              {item.href ? (
                <Link
                  href={item.href}
                  className={`nav-item ${isSidebarOpen ? "" : "is-icon-mode"}`}
                >
                  <span className="nav-icon" aria-hidden="true">
                    {item.icon}
                  </span>
                  <span
                    className={`nav-label ${isSidebarOpen ? "" : "is-hidden"}`}
                  >
                    {item.label}
                  </span>
                </Link>
              ) : (
                <button
                  type="button"
                  className={`nav-item ${
                    item.label === activeSection ||
                    (item.label === topLevelSections.vendors &&
                      (activeSection === topLevelSections.vendors ||
                        vendorSubSections.includes(activeSection)))
                      ? "active"
                      : ""
                  } ${isSidebarOpen ? "" : "is-icon-mode"}`}
                  onClick={() => {
                    setActiveSection(item.label);
                  }}
                >
                  <span className="nav-icon" aria-hidden="true">
                    {item.icon}
                  </span>
                  <span
                    className={`nav-label ${isSidebarOpen ? "" : "is-hidden"}`}
                  >
                    {item.label}
                  </span>
                  {[
                    topLevelSections.admin,
                    topLevelSections.association,
                    topLevelSections.members,
                    topLevelSections.vendors,
                    topLevelSections.events,
                  ].includes(item.label) && isSidebarOpen ? (
                    <span className="nav-accordion-indicator" aria-hidden="true">
                      {item.label === activeSection ||
                      (item.label === topLevelSections.vendors &&
                        vendorSubSections.includes(activeSection))
                        ? "−"
                        : "+"}
                    </span>
                  ) : null}
                </button>
              )}

              {item.label === topLevelSections.admin &&
              isSidebarOpen &&
              activeSection === topLevelSections.admin ? (
                <div className="sidebar-subnav" aria-label="Admin access menu">
                  {adminAccessSections.map((section) => (
                    <div key={section} className="sidebar-subnav-group">
                      <button
                        type="button"
                        className="sidebar-subnav-item"
                        onClick={() => {
                          setActiveSection(topLevelSections.admin);
                          setActiveAdminAccessSection(section);
                        }}
                      >
                        <span>{section}</span>
                        {section === activeAdminAccessSection ? (
                          <span
                            className="sidebar-subnav-active-dot"
                            aria-hidden="true"
                          />
                        ) : null}
                      </button>
                    </div>
                  ))}
                </div>
              ) : item.label === topLevelSections.association &&
                isSidebarOpen &&
                activeSection === topLevelSections.association ? (
                <div className="sidebar-subnav" aria-label="Association menu">
                  {associationMenuSections.map((section) => (
                    <div key={section} className="sidebar-subnav-group">
                      <button
                        type="button"
                        className="sidebar-subnav-item"
                        onClick={() => {
                          setActiveSection(topLevelSections.association);
                          setActiveAssociationTab(section);
                        }}
                      >
                        <span>{section}</span>
                        {section === activeAssociationTab ? (
                          <span
                            className="sidebar-subnav-active-dot"
                            aria-hidden="true"
                          />
                        ) : null}
                      </button>
                    </div>
                  ))}
                </div>
              ) : item.label === topLevelSections.members &&
                isSidebarOpen &&
                activeSection === topLevelSections.members ? (
                <div className="sidebar-subnav" aria-label="Member menu">
                  {memberMenuSections.map((section) => (
                    <div key={section} className="sidebar-subnav-group">
                      <button
                        type="button"
                        className="sidebar-subnav-item"
                        onClick={() => {
                          setActiveSection(topLevelSections.members);
                          setActiveMemberTab(section);
                        }}
                      >
                        <span>{section}</span>
                        {section === activeMemberTab ? (
                          <span
                            className="sidebar-subnav-active-dot"
                            aria-hidden="true"
                          />
                        ) : null}
                      </button>
                    </div>
                  ))}
                </div>
              ) : item.label === topLevelSections.vendors &&
                isSidebarOpen &&
                (activeSection === topLevelSections.vendors ||
                  vendorSubSections.includes(activeSection)) ? (
                <div className="sidebar-subnav" aria-label="Vendor menu">
                  {vendorSubSections.map((section) => (
                    <div key={section} className="sidebar-subnav-group">
                      <button
                        type="button"
                        className="sidebar-subnav-item"
                        onClick={() => {
                          setActiveSection(
                            section === "Vendor"
                              ? topLevelSections.vendors
                              : section,
                          );
                        }}
                      >
                        <span>{section}</span>
                        {(section === "Vendor" &&
                          activeSection === topLevelSections.vendors) ||
                        section === activeSection ? (
                          <span
                            className="sidebar-subnav-active-dot"
                            aria-hidden="true"
                          />
                        ) : null}
                      </button>
                    </div>
                  ))}
                </div>
              ) : item.label === topLevelSections.events &&
                isSidebarOpen &&
                activeSection === topLevelSections.events ? (
                <div className="sidebar-subnav" aria-label="Events menu">
                  {eventsArenaTabs.map((section) => (
                    <div key={section} className="sidebar-subnav-group">
                      <button
                        type="button"
                        className="sidebar-subnav-item"
                        onClick={() => {
                          setActiveSection(topLevelSections.events);
                          setActiveEventsTab(section);
                        }}
                      >
                        <span>{section}</span>
                        {section === activeEventsTab ? (
                          <span
                            className="sidebar-subnav-active-dot"
                            aria-hidden="true"
                          />
                        ) : null}
                      </button>
                    </div>
                  ))}
                </div>
              ) : null}
            </div>
          ))}
        </nav>

        <div className={`sidebar-note ${isSidebarOpen ? "" : "is-hidden"}`}>
          <span className="mini-label">Current Scope</span>
          <p>
            Logged in as Association 1 Admin for one tenant-aware workspace.
          </p>
        </div>

        <div
          className={`sidebar-mobile-account ${isSidebarOpen ? "" : "is-hidden"}`}
        >
          <Link
            className="sidebar-profile-link"
            href="/profile"
            aria-label="Open profile settings"
          >
            <span className="avatar-circle">AU</span>
            <span className="sidebar-profile-copy">
              <strong>Admin Profile</strong>
              <span>Association 1 administrator</span>
            </span>
          </Link>

          <Link className="sidebar-logout-link" href="#">
            Logout
          </Link>
        </div>
      </aside>

      <button
        type="button"
        className={`sidebar-backdrop ${isSidebarOpen && isMobileViewport ? "is-visible" : ""}`}
        aria-label="Close sidebar"
        onClick={() => setIsSidebarOpen(false)}
      />

      <section className="content-area">
        <header className="topbar">
          <button
            className="icon-button"
            type="button"
            aria-label="Toggle sidebar"
            aria-expanded={isSidebarOpen}
            onClick={() => setIsSidebarOpen((current) => !current)}
          >
            <span />
            <span />
            <span />
          </button>

          <div className="search-wrap">
            <input
              className="search-input"
              type="search"
              value={topbarSearchQuery}
              placeholder="Search members, circulars, vendors, settings..."
              onChange={(event) => setTopbarSearchQuery(event.target.value)}
            />
          </div>

          <div className="topbar-actions">
            <button
              className="icon-chip"
              type="button"
              aria-label="Unread notifications"
            >
              <span className="icon-chip-symbol" aria-hidden="true">
                <svg
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="1.8"
                >
                  <path d="M7 10a5 5 0 1 1 10 0v4.2l1.4 2.3H5.6L7 14.2V10Z" />
                  <path d="M10 18.5a2.2 2.2 0 0 0 4 0" />
                </svg>
              </span>
              <span className="icon-chip-count">3</span>
            </button>

            <Link className="text-link top-link" href="#">
              Logout
            </Link>

            <Link
              className="avatar-link"
              href="/profile"
              aria-label="Open profile settings"
            >
              <span className="avatar-circle">AU</span>
              <span className="avatar-edit-badge">Edit</span>
            </Link>
          </div>
        </header>

        {activeSection === topLevelSections.dashboard ? (
          <section className="dashboard-home">
            <div className="dashboard-home-slot dashboard-home-slot-hero">
              <DashboardHeroStats
                primaryMembersCount={primaryMembersCount}
                associateMembersCount={associateMembersCount}
                guestMembersCount={guestMembersCount}
                totalVendorsCount={vendorRecords.length}
                approvedVendorsCount={approvedVendorsCount}
                pendingVendorsCount={pendingVendorsCount}
                suspendedVendorsCount={suspendedVendorsCount}
                activeUsersCount={activeUsersCount}
                activeUsersThisMonthCount={activeUsersThisMonthCount}
                activeUsersLastSixMonthsCount={
                  activeUsersLastSixMonthsCount
                }
                totalMembersCount={allMembers.length}
              />
            </div>

            <div className="dashboard-home-slot dashboard-home-slot-approvals">
              <DashboardPendingApprovalsPanel
                activeTab={dashboardApprovalTab}
                allItems={pendingRegistrationRequests}
                items={dashboardPendingRegistrationRequests}
                onTabChange={setDashboardApprovalTab}
                onOpenRequests={() => {
                  setActiveSection(topLevelSections.admin);
                  setActiveAdminAccessSection("Registration Requests");
                }}
              />
            </div>

            <div className="dashboard-home-slot dashboard-home-slot-vendor-approvals">
              <DashboardPendingVendorApprovalsPanel
                items={vendorStatusRequests}
                onOpenRequests={() => {
                  setActiveSection(topLevelSections.vendors);
                  setActiveVendorTab("Vendor Status");
                }}
              />
            </div>
            <div className="dashboard-home-slot dashboard-home-slot-banner">
              <DashboardAppBannerCarousel items={dashboardAppBanners} />
            </div>
          </section>
        ) : activeSection === topLevelSections.association ? (
          <section className="association-workspace">
            {activeAssociationTab === "Profile" ? (
              <div className="association-featured-stack">
                <CarouselSection
                  title="Latest Gallery"
                  items={galleryItems}
                  tone="tone-gallery"
                  compact
                  motionClass="carousel-row-moving-gallery"
                  compactLimit={8}
                />
                <CarouselSection
                  title="Latest Circulars"
                  items={associationTabData.Circulars}
                  tone="tone-circular"
                  compact
                  motionClass="carousel-row-moving-gallery"
                  compactLimit={6}
                />
              </div>
            ) : null}

            <nav
              className="association-tabbar"
              aria-label="Association sections"
            >
              {associationTabs.map((tab) => (
                <button
                  key={tab}
                  type="button"
                  className={`association-tab ${tab === activeAssociationTab ? "active" : ""}`}
                  onClick={() => setActiveAssociationTab(tab)}
                >
                  {tab}
                </button>
              ))}
            </nav>

            <div className="association-content">
              <AssociationTabContent
                activeTab={activeAssociationTab}
                activeFinanceTab={activeFinanceTab}
                financeStatementEntries={filteredFinanceStatementEntries}
                financeStatementFilterType={financeStatementFilterType}
                financeStatementDateFrom={financeStatementDateFrom}
                financeStatementDateTo={financeStatementDateTo}
                isAdmin={
                  activeAssociationTab === "Finance"
                    ? false
                    : isAssociationAdmin
                }
                tabItems={activeTabItems}
                selectedIds={activeSelectedIds}
                onToggleSelect={(recordId) =>
                  toggleSelectRecord(activeAssociationTab, recordId)
                }
                onToggleSelectAll={() =>
                  toggleSelectAllRecords(activeAssociationTab)
                }
                onDeleteSelected={() =>
                  deleteSelectedRecords(activeAssociationTab)
                }
                onDeleteOne={(recordId) =>
                  deleteSingleRecord(activeAssociationTab, recordId)
                }
                onAddNew={() => addNewRecord(activeAssociationTab)}
                onFinanceTabChange={setActiveFinanceTab}
                onFinanceStatementFilterTypeChange={
                  setFinanceStatementFilterType
                }
                onFinanceStatementDateFromChange={setFinanceStatementDateFrom}
                onFinanceStatementDateToChange={setFinanceStatementDateTo}
                associationProfile={associationProfile}
                associationProfileForm={associationProfileForm}
                isEditingAssociationProfile={isEditingAssociationProfile}
                onEditAssociationProfile={openAssociationProfileEditor}
                onAssociationProfileFieldChange={updateAssociationProfileField}
                onAssociationRegionalFieldChange={
                  updateAssociationRegionalField
                }
                onAddRegionalAddress={addAssociationRegionalAddress}
                onRemoveRegionalAddress={removeAssociationRegionalAddress}
                onCancelAssociationProfileEdit={cancelAssociationProfileEdit}
                onSaveAssociationProfile={saveAssociationProfile}
                isSavingAssociationProfile={isSavingAssociationProfile}
                associationProfileFeedback={associationProfileFeedback}
                associationAbout={associationAbout}
                associationAboutForm={associationAboutForm}
                isEditingAssociationAbout={isEditingAssociationAbout}
                onEditAssociationAbout={openAssociationAboutEditor}
                onAssociationAboutFieldChange={updateAssociationAboutField}
                onAssociationAboutImageChange={updateAssociationAboutImage}
                onCancelAssociationAboutEdit={cancelAssociationAboutEdit}
                onSaveAssociationAbout={saveAssociationAbout}
                isSavingAssociationAbout={isSavingAssociationAbout}
                associationAboutFeedback={associationAboutFeedback}
                committeeMembers={committeeMembers}
                allMembers={memberTabData["All Members"] ?? []}
                membershipTypeOptions={membershipTypeOptions}
                editingCommitteeMemberId={editingCommitteeMemberId}
                committeeMemberForm={committeeMemberForm}
                isSavingCommitteeMember={isSavingCommitteeMember}
                committeeMemberFeedback={committeeMemberFeedback}
                committeePostOptions={committeePostOptions}
                masterDraftValue={committeePostMasterDraft}
                masterFeedbackMessage={committeePostMasterFeedback}
                editingMasterPostValue={editingCommitteePostMaster}
                editMasterPostDraftValue={committeePostMasterEditDraft}
                membershipTypeDraftValue={membershipTypeMasterDraft}
                membershipTypeFeedbackMessage={membershipTypeMasterFeedback}
                editingMembershipTypeValue={editingMembershipTypeMaster}
                editMembershipTypeDraftValue={membershipTypeMasterEditDraft}
                onOpenCommitteeMemberEditor={openCommitteeMemberEditor}
                onCommitteeMemberFormChange={updateCommitteeMemberForm}
                onCommitteeMemberImageChange={updateCommitteeMemberImage}
                onCancelCommitteeMemberEdit={closeCommitteeMemberEditor}
                onSaveCommitteeMember={saveCommitteeMember}
                onRemoveCommitteeMember={removeCommitteeMember}
                onMasterDraftChange={setCommitteePostMasterDraft}
                onEditMasterPostChange={setCommitteePostMasterEditDraft}
                onSaveMasterDraft={addCommitteePostMaster}
                onEditMasterPost={editCommitteePostMaster}
                onDeleteMasterPost={deleteCommitteePostMaster}
                onSaveMasterPostEdit={saveCommitteePostMasterEdit}
                onCancelMasterPostEdit={cancelCommitteePostMasterEdit}
                onMembershipTypeDraftChange={setMembershipTypeMasterDraft}
                onSaveMembershipTypeDraft={addMembershipTypeMaster}
                onEditMembershipTypeDraftChange={
                  setMembershipTypeMasterEditDraft
                }
                onEditMembershipType={editMembershipTypeMaster}
                onDeleteMembershipType={deleteMembershipTypeMaster}
                onSaveMembershipTypeEdit={saveMembershipTypeMasterEdit}
                onCancelMembershipTypeEdit={cancelMembershipTypeMasterEdit}
                galleryItems={galleryItems}
                galleryFolders={galleryFolders}
                activeGalleryFolderId={activeGalleryFolderId}
                editingGalleryFolderId={editingGalleryFolderId}
                galleryFolderForm={galleryFolderForm}
                isSavingGalleryFolder={isSavingGalleryFolder}
                galleryFolderFeedback={galleryFolderFeedback}
                onOpenGalleryFolder={openGalleryFolder}
                onOpenGalleryFolderEditor={openGalleryFolderEditor}
                onGalleryFolderFieldChange={updateGalleryFolderField}
                onGalleryFolderFilesChange={updateGalleryFolderFiles}
                onCancelGalleryFolderEdit={cancelGalleryFolderEdit}
                onSaveGalleryFolder={saveGalleryFolder}
                onDeleteGalleryFolder={deleteGalleryFolder}
                onDeleteGalleryPhoto={deleteGalleryPhoto}
                onUploadGalleryFolderPhotos={uploadGalleryFolderPhotos}
                selectedGalleryFolderIds={selectedGalleryFolderIds}
                selectedGalleryPhotoIds={selectedGalleryPhotoIds}
                onToggleGalleryFolderSelect={toggleSelectGalleryFolder}
                onDeleteSelectedGalleryFolders={deleteSelectedGalleryFolders}
                onToggleGalleryPhotoSelect={toggleSelectGalleryPhoto}
                onDeleteSelectedGalleryPhotos={deleteSelectedGalleryPhotos}
                onCloseGalleryFolder={closeGalleryFolder}
                galleryFolderEditorRef={galleryFolderEditorRef}
                galleryFolderNameInputRef={galleryFolderNameInputRef}
                circularDocuments={circularDocuments}
                selectedCircularIds={selectedCircularDocumentIds}
                editingCircularDocumentId={editingCircularDocumentId}
                circularDocumentForm={circularDocumentForm}
                onOpenCircularDocumentEditor={openCircularDocumentEditor}
                onToggleCircularSelect={toggleSelectCircularDocument}
                onDeleteSelectedCirculars={deleteSelectedCircularDocuments}
                onCircularDocumentFieldChange={updateCircularDocumentField}
                onCircularDocumentFileChange={updateCircularDocumentFile}
                onCancelCircularDocumentEdit={cancelCircularDocumentEdit}
                onSaveCircularDocument={saveCircularDocument}
                onDeleteCircularDocument={deleteCircularDocument}
                isSavingCircularDocument={isSavingCircularDocument}
                circularDocumentFeedback={circularDocumentFeedback}
              />
            </div>
          </section>
        ) : activeSection === topLevelSections.members ? (
          <section className="association-workspace">
            {activeMemberTab !== "Master" &&
            activeMemberTab !== "Primary Members" &&
            activeMemberTab !== "Associate Members" &&
            activeMemberTab !== "Guest" ? (
              <>
                <div className="association-featured-stack member-featured-stack">
                  <MemberCarouselSection
                    title="Primary Members"
                    items={memberTabData["Primary Members"]}
                    tone="tone-gallery"
                  />
                  <MemberCarouselSection
                    title="Associate Members"
                    items={memberTabData["Associate Members"]}
                    tone="tone-advertisement"
                  />
                  <MemberCarouselSection
                    title="Guest"
                    items={memberTabData.Guest}
                    tone="tone-circular"
                  />
                </div>

                <nav className="association-tabbar" aria-label="Member sections">
                  {memberArenaTabs.map((tab) => (
                    <button
                      key={tab}
                      type="button"
                      className={`association-tab ${tab === activeMemberTab ? "active" : ""}`}
                      onClick={() => setActiveMemberTab(tab)}
                    >
                      <span>{tab}</span>
                    </button>
                  ))}
                </nav>
              </>
            ) : null}

            <div className="association-content">
              <MemberArenaContent
                activeTab={activeMemberTab}
                isAdmin={isMemberAdmin}
                tabItems={activeMemberItems}
                allMembers={memberTabData["All Members"] ?? []}
                memberPosts={memberContentPosts}
                memberPostForm={memberMediaPostForm}
                isSavingMemberPost={isSavingMemberMediaPost}
                memberPostFeedback={memberMediaPostFeedback}
                isSavingMemberDirectory={isSavingMemberDirectory}
                memberDirectoryFeedback={memberDirectoryFeedback}
                selectedIds={activeMemberSelectedIds}
                membershipFormFields={membershipFormFields}
                membershipFieldDraft={membershipFieldDraft}
                bulkMemberFile={bulkMemberFile}
                isBulkMemberUploading={isBulkMemberUploading}
                bulkMemberError={bulkMemberError}
                bulkMemberResult={bulkMemberResult}
                isReminderPanelOpen={isReminderPanelOpen}
                onToggleReminderPanel={() =>
                  setIsReminderPanelOpen((current) => !current)
                }
                onApplyReminderFilter={applyReminderFilter}
                onToggleSelect={(recordId) =>
                  toggleSelectMemberRecord(activeMemberTab, recordId)
                }
                onToggleSelectAll={() =>
                  toggleSelectAllMemberRecords(activeMemberTab)
                }
                onDeleteSelected={() =>
                  deleteSelectedMemberRecords(activeMemberTab)
                }
                onDeleteOne={(recordId) =>
                  deleteSingleMemberRecord(activeMemberTab, recordId)
                }
                onOpenMemberForm={openMemberForm}
                onEditMember={editMemberRecord}
                onDeleteMember={removeMemberRecord}
                onMembershipFieldDraftChange={updateMembershipFieldDraft}
                onAddMembershipField={addMembershipField}
                onUpdateMembershipField={updateMembershipField}
                onDeleteMembershipField={deleteMembershipField}
                onBulkMemberFileChange={setBulkMemberFile}
                onUploadBulkMembers={uploadBulkMembers}
                onMemberPostFieldChange={updateMemberMediaPostForm}
                onMemberPostImageChange={updateMemberMediaPostImage}
                onClearMemberPostImage={clearMemberMediaPostImage}
                onSubmitMemberPost={submitMemberMediaPost}
                onUpdateMemberPostStatus={updateMemberMediaPostStatus}
              />
            </div>

            {activeMemberTab !== "Master" &&
            activeMemberTab !== "Primary Members" &&
            activeMemberTab !== "Associate Members" &&
            activeMemberTab !== "Guest" ? (
              <section className="association-header">
                <div>
                  <span className="eyebrow">Members</span>
                  <h1>Association Member Directory</h1>
                  <p>
                    Member cards, bulk actions, and communication controls in one
                    workspace.
                  </p>
                </div>

                <div className="association-header-meta">
                  <div className="association-dashboard-grid">
                    {memberSummaryStats.map((item) => (
                      <article
                        key={item.label}
                        className="association-dashboard-card"
                      >
                        <strong>{item.value}</strong>
                        <span>{item.label}</span>
                      </article>
                    ))}
                  </div>

                  <div className="association-city-row">
                    {cityMemberships.map((item) => (
                      <span key={item.city} className="city-pill">
                        {item.city}({item.count})
                      </span>
                    ))}
                  </div>
                </div>
              </section>
            ) : null}
          </section>
        ) : activeSection === "Timeline" ? (
          <section className="association-workspace">
            <section className="association-header">
              <div>
                <span className="eyebrow">Timeline</span>
                <h1>Timeline Campaign Desk</h1>
                <p>
                  Create ad-style timeline posts for vendors, members, or the
                  association with media and landing links.
                </p>
              </div>

              <div className="association-header-meta">
                <div className="association-dashboard-grid">
                  <article className="association-dashboard-card">
                    <strong>{timelinePosts.length}</strong>
                    <span>Total Timeline Posts</span>
                  </article>
                  <article className="association-dashboard-card">
                    <strong>
                      {
                        timelinePosts.filter(
                          (post) => post.status === "Pending Review",
                        ).length
                      }
                    </strong>
                    <span>Pending Review</span>
                  </article>
                </div>
              </div>
            </section>

            <section className="association-content">
              <TimelinePanel
                formData={timelinePostForm}
                posts={timelinePosts}
                memberOptions={timelineMemberOptions}
                vendorOptions={timelineVendorOptions}
                associationLabel={timelineAssociationLabel}
                isSaving={isSavingTimelinePost}
                feedback={timelinePostFeedback}
                onChange={updateTimelinePostForm}
                onFileChange={updateTimelinePostFile}
                onSubmit={submitTimelinePost}
              />
            </section>
          </section>
        ) : activeSection === topLevelSections.vendors ? (
          <section className="association-workspace">
            <div className="association-content">
              <section className="association-tab-section">
                <article className="admin-access-panel">
                  <div className="panel-topline">
                    <h2>Vendor Status Filter</h2>
                    <span className="mini-label">Backend Registration Status</span>
                  </div>

                  <div className="admin-member-toolbar">
                    <label className="content-control-field">
                      <span>Status</span>
                      <select
                        value={vendorOverviewStatusFilter}
                        onChange={(event) =>
                          setVendorOverviewStatusFilter(event.target.value)
                        }
                      >
                        <option value="">All Statuses</option>
                        <option value="Active">Active</option>
                        <option value="Suspended">Suspended</option>
                        <option value="Lapsed">Lapsed</option>
                        <option value="Pending">Pending</option>
                      </select>
                    </label>
                  </div>
                </article>

                <VendorRegistrationTable
                  items={filteredVendorOverviewItems}
                  onEdit={openVendorRegistrationEditor}
                />
              </section>
            </div>
          </section>
        ) : activeSection === "Vendor Registration" ? (
          <section className="association-workspace">
            <section className="association-header">
              <div>
                <span className="eyebrow">Vendor Registration</span>
                <h1>Register a New Vendor</h1>
                <p>
                  Use this admin-only screen to onboard a new vendor and create
                  their base commercial record.
                </p>
              </div>

              <div className="association-header-meta">
                <div className="association-dashboard-grid">
                  <article className="association-dashboard-card">
                    <strong>Admin</strong>
                    <span>Current Role</span>
                  </article>
                  <article className="association-dashboard-card">
                    <strong>{vendorRecords.length}</strong>
                    <span>Total Vendors</span>
                  </article>
                  <article className="association-dashboard-card">
                    <strong>{vendorCategories.length}</strong>
                    <span>Categories</span>
                  </article>
                  <article className="association-dashboard-card">
                    <strong>Live</strong>
                    <span>Registration Desk</span>
                  </article>
                </div>
              </div>
            </section>

            <section className="association-content">
              {isAssociationAdmin ? (
                <>
                  <VendorRegistrationForm
                    formData={vendorRegistrationForm}
                    onChange={updateVendorRegistrationForm}
                    categories={vendorCategories}
                    subCategories={vendorSubCategoryOptions}
                    countryOptions={vendorCountryOptions}
                    stateOptions={vendorStateOptions}
                    cityOptions={vendorCityOptions}
                    phoneCodeOptions={vendorPhoneCodeOptions}
                    planOptions={vendorPlanOptions}
                    paymentModeOptions={vendorPaymentModeOptions}
                    newCategory={newVendorCategory}
                    onFileChange={updateVendorRegistrationFile}
                    onNewCategoryChange={setNewVendorCategory}
                    onAddCategory={addVendorCategory}
                    onReset={resetVendorRegistrationForm}
                    onSubmit={saveVendorRecord}
                    errorMessage={vendorRegistrationError}
                    successMessage={vendorRegistrationSuccess}
                    isSaving={isSavingVendorRegistration}
                  />
                  <VendorRegistrationTable
                    items={vendorRecords}
                    onEdit={openVendorRegistrationEditor}
                  />
                </>
              ) : (
                <article className="association-empty-state">
                  <span className="mini-label">Admin Access Required</span>
                  <h2>Only admins can register vendors.</h2>
                  <p>
                    Switch to an admin login to create vendor accounts and
                    manage onboarding details.
                  </p>
                </article>
              )}
            </section>
          </section>
        ) : activeSection === "Category" ? (
          <section className="association-workspace">
            <section className="association-header">
              <div>
                <span className="eyebrow">Vendors</span>
                <h1>Category</h1>
                <p>
                  Manage the main vendor categories used throughout registration
                  and vendor discovery.
                </p>
              </div>

              <div className="association-header-meta">
                <div className="association-dashboard-grid">
                  <article className="association-dashboard-card">
                    <strong>{vendorCategories.length}</strong>
                    <span>Total Categories</span>
                  </article>
                  <article className="association-dashboard-card">
                    <strong>
                      {Object.values(vendorSubCategoryRecords).reduce(
                        (sum, items) => sum + items.length,
                        0,
                      )}
                    </strong>
                    <span>Mapped Sub Categories</span>
                  </article>
                </div>
              </div>
            </section>

            <section className="association-content">
              <VendorCategoryPanel
                categories={vendorCategories}
                subCategoryMap={vendorSubCategoryRecords}
                draftValue={vendorCategoryDraft}
                editingValue={editingVendorCategory}
                errorMessage={vendorTaxonomyError}
                successMessage={vendorTaxonomySuccess}
                onDraftChange={setVendorCategoryDraft}
                onStartEdit={openVendorCategoryEditor}
                onCancelEdit={cancelVendorCategoryEdit}
                onSave={saveVendorCategory}
                onDelete={deleteVendorCategory}
              />
            </section>
          </section>
        ) : activeSection === "Sub-category" ? (
          <section className="association-workspace">
            <section className="association-header">
              <div>
                <span className="eyebrow">Vendors</span>
                <h1>Sub-category</h1>
                <p>
                  Select a main category, fetch its sub categories, and maintain
                  the list with full CRUD actions.
                </p>
              </div>

              <div className="association-header-meta">
                <div className="association-dashboard-grid">
                  <article className="association-dashboard-card">
                    <strong>{selectedVendorParentCategory || "--"}</strong>
                    <span>Selected Category</span>
                  </article>
                  <article className="association-dashboard-card">
                    <strong>
                      {selectedVendorParentCategory
                        ? (
                            vendorSubCategoryRecords[
                              selectedVendorParentCategory
                            ] ?? []
                          ).length
                        : 0}
                    </strong>
                    <span>Visible Sub-categories</span>
                  </article>
                </div>
              </div>
            </section>

            <section className="association-content">
              <VendorSubCategoryPanel
                categories={vendorCategories}
                subCategoryMap={vendorSubCategoryRecords}
                selectedCategory={selectedVendorParentCategory}
                editingValue={editingVendorSubCategory}
                draftValue={vendorSubCategoryDraft}
                errorMessage={vendorTaxonomyError}
                successMessage={vendorTaxonomySuccess}
                onSelectCategory={setSelectedVendorParentCategory}
                onStartEdit={openVendorSubCategoryEditor}
                onDraftChange={setVendorSubCategoryDraft}
                onCancelEdit={cancelVendorSubCategoryEdit}
                onSave={saveVendorSubCategory}
                onDelete={deleteVendorSubCategory}
              />
            </section>
          </section>
        ) : activeSection === "Vendor Status" ? (
          <section className="association-workspace">
            <section className="association-header">
              <div>
                <span className="eyebrow">Vendors</span>
                <h1>Vendor Status</h1>
                <p>
                  Review all vendor registration requests together and approve
                  or reject them from one admin desk.
                </p>
              </div>

              <div className="association-header-meta">
                <div className="association-dashboard-grid">
                  <article className="association-dashboard-card">
                    <strong>{vendorStatusRequests.length}</strong>
                    <span>Pending Requests</span>
                  </article>
                  <article className="association-dashboard-card">
                    <strong>{selectedVendorRequests.length}</strong>
                    <span>Selected</span>
                  </article>
                </div>
              </div>
            </section>

            <section className="association-content">
              <VendorStatusPanel
                items={vendorStatusRequests}
                selectedIds={selectedVendorRequests}
                searchQuery={vendorStatusSearch}
                selectedVendor={selectedVendorReview}
                reviewForm={vendorApprovalForm}
                isSaving={isSavingVendorApproval}
                onSearchChange={setVendorStatusSearch}
                onToggleSelect={toggleVendorRequestSelect}
                onToggleSelectAll={toggleSelectAllVendorRequests}
                onSelectVendor={openVendorStatusReview}
                onReviewFieldChange={updateVendorApprovalForm}
                onReviewFileChange={updateVendorApprovalFile}
                onApplyBulkDecision={applyBulkVendorRequestDecision}
                onApproveOne={(vendorId) =>
                  applySingleVendorDecision(vendorId, "APPROVED")
                }
                onRejectOne={(vendorId) =>
                  applySingleVendorDecision(vendorId, "CANCELLED")
                }
                planOptions={vendorPlanOptions}
                paymentModeOptions={vendorPaymentModeOptions}
                approvalError={vendorApprovalError}
              />
            </section>
          </section>
        ) : activeSection === "App Banner" ? (
          <section className="association-workspace">
            <section className="association-header">
              <div>
                <span className="eyebrow">Vendors</span>
                <h1>App Banner</h1>
                <p>
                  Create paid advertisement banners with media, contact details,
                  social media links, and brochure support.
                </p>
              </div>

              <div className="association-header-meta">
                <div className="association-dashboard-grid">
                  <article className="association-dashboard-card">
                    <strong>{appBanners.length}</strong>
                    <span>Total Banner Requests</span>
                  </article>
                  <article className="association-dashboard-card">
                    <strong>
                      {
                        appBanners.filter(
                          (item) => item.status === "Pending Review",
                        ).length
                      }
                    </strong>
                    <span>Pending Review</span>
                  </article>
                </div>
              </div>
            </section>

            <section className="association-content">
              <AppBannerPanel
                formData={appBannerForm}
                items={appBanners}
                vendorOptions={appBannerVendorOptions}
                isSaving={isSavingAppBanner}
                errorMessage={appBannerError}
                onChange={updateAppBannerForm}
                onFileChange={updateAppBannerFile}
                onSubmit={submitAppBanner}
              />
            </section>
          </section>
        ) : activeSection === topLevelSections.events ? (
          <section className="association-workspace">
            <nav className="association-tabbar" aria-label="Event sections">
              {eventsArenaTabs.map((tab) => (
                <button
                  key={tab}
                  type="button"
                  className={`association-tab ${tab === activeEventsTab ? "active" : ""}`}
                  onClick={() => setActiveEventsTab(tab)}
                >
                  {tab}
                </button>
              ))}
            </nav>

            <div className="association-content">
              <EventsArenaContent
                activeTab={activeEventsTab}
                formData={eventForm}
                mediaState={eventMedia}
                events={createdEvents}
                eventTimelineGroups={eventTimelineData}
                savingEventId={savingEventId}
                feedbackMessage={eventAccessFeedback}
                onFormChange={updateEventForm}
                onMediaChange={updateEventMedia}
                onSaveEvent={saveEventDraft}
                onCancelEventEdit={cancelEventEdit}
                onEditEvent={editEventRecord}
                eventTypes={eventTypes}
                eventTypeDraft={eventTypeDraft}
                onEventTypeDraftChange={updateEventTypeDraft}
                onAddEventType={addEventType}
                onUpdateEventType={updateEventType}
              />
            </div>

            <section className="association-header">
              <div>
                <span className="eyebrow">Events</span>
                <h1>Association Events Desk</h1>
                <p>
                  Track past, current, and coming events while preparing new
                  programs and event masters.
                </p>
              </div>

              <div className="association-header-meta">
                <div className="association-dashboard-grid">
                  <article className="association-dashboard-card">
                    <strong>12</strong>
                    <span>Past Events</span>
                  </article>
                  <article className="association-dashboard-card">
                    <strong>3</strong>
                    <span>Current Events</span>
                  </article>
                  <article className="association-dashboard-card">
                    <strong>7</strong>
                    <span>Coming Events</span>
                  </article>
                  <article className="association-dashboard-card">
                    <strong>5</strong>
                    <span>Event Types</span>
                  </article>
                </div>
              </div>
            </section>
          </section>
        ) : activeSection === topLevelSections.admin ? (
          <section className="association-workspace">
            <section className="association-header">
              <div>
                <span className="eyebrow">Admin</span>
                <h1>{activeAdminAccessSection}</h1>
                <p>
                  Open the selected access area here and configure permissions
                  in the main workspace.
                </p>
              </div>

              <div className="association-header-meta">
                <div className="association-dashboard-grid">
                  <article className="association-dashboard-card">
                    <strong>5</strong>
                    <span>Access Sections</span>
                  </article>
                  <article className="association-dashboard-card">
                    <strong>5</strong>
                    <span>Flutter Toggles</span>
                  </article>
                  <article className="association-dashboard-card">
                    <strong>1</strong>
                    <span>Save Action</span>
                  </article>
                  <article className="association-dashboard-card">
                    <strong>Live</strong>
                    <span>Desktop Config</span>
                  </article>
                </div>
              </div>
            </section>

            <section className="association-content">
              {activeAdminAccessSection === "App Access" ? (
                <article className="admin-access-panel">
                  <div className="panel-topline">
                    <h2>Flutter App Permissions</h2>
                    <span className="mini-label">Main Area Controls</span>
                  </div>

                  <p className="admin-access-helper-copy">
                    These switches now load from and save back to the backend,
                    matching the Flutter admin app access flow.
                  </p>

                  <div className="admin-access-grid">
                    {flutterAppPermissions.map((permission) => (
                      <label key={permission.key} className="admin-access-card">
                        <div>
                          <strong>{permission.label}</strong>
                          <p>
                            Enable or disable this permission for the Flutter
                            app experience.
                          </p>
                        </div>
                        <input
                          type="checkbox"
                          checked={appPermissions[permission.key]}
                          onChange={() => toggleAppPermission(permission.key)}
                        />
                      </label>
                    ))}
                  </div>

                  {appAccessFeedback ? (
                    <p className="admin-access-feedback">{appAccessFeedback}</p>
                  ) : null}

                  <div className="profile-action-row">
                    <button
                      className="primary-link admin-action-button"
                      type="button"
                      onClick={saveAppAccessChanges}
                      disabled={isSavingAppAccess}
                    >
                      {isSavingAppAccess ? "Saving..." : "Save App Access"}
                    </button>
                  </div>
                </article>
              ) : activeAdminAccessSection === "Registration Requests" ? (
                <AdminRegistrationRequestsPanel
                  items={pendingRegistrationRequests}
                  selectedIds={selectedAdminMembers}
                  feedbackMessage={memberAccessFeedback}
                  isSaving={isSavingMemberAccess}
                  onToggleSelect={toggleAdminMemberSelect}
                  onToggleSelectAll={toggleSelectAllAdminMembers}
                  onApplyBulkMemberAccessStatus={applyBulkMemberAccessStatus}
                  onUpdateMemberAccessStatus={updateMemberAccessStatus}
                  onSaveMemberAccessChanges={saveMemberAccessChanges}
                />
              ) : activeAdminAccessSection === "Member Access" ? (
                <AdminMemberAccessPanel
                  items={filteredAdminMembers}
                  searchQuery={adminMemberSearch}
                  activeFilter={activeAdminMemberFilter}
                  activeView={adminMemberAccessView}
                  selectedIds={selectedAdminMembers}
                  contentSearchQuery={adminContentMemberSearch}
                  memberSearchMatches={contentMemberMatches}
                  selectedContentMemberIds={selectedContentMemberIds}
                  filteredPosts={filteredMemberContentPosts}
                  contentPostEdits={contentPostEdits}
                  onSearchChange={setAdminMemberSearch}
                  onFilterChange={setActiveAdminMemberFilter}
                  onViewChange={setAdminMemberAccessView}
                  onContentSearchChange={setAdminContentMemberSearch}
                  onToggleSelect={toggleAdminMemberSelect}
                  onToggleSelectAll={toggleSelectAllAdminMembers}
                  onToggleContentMember={toggleContentMember}
                  onUpdateMemberAccessStatus={updateMemberAccessStatus}
                  onApplyBulkMemberAccessStatus={applyBulkMemberAccessStatus}
                  onSaveMemberAccessChanges={saveMemberAccessChanges}
                  onSaveContentAccessChanges={saveContentPostModeration}
                  onSelectAllContentMembers={selectAllContentMembers}
                  onClearContentMemberSelection={clearContentMemberSelection}
                  onUpdateContentPost={updateContentPost}
                  onUpdateAdminRole={updateMemberAdminRole}
                  superAdminInviteForm={superAdminInviteForm}
                  onSuperAdminInviteFieldChange={updateSuperAdminInviteField}
                  onSubmitSuperAdminInvite={submitSuperAdminInvite}
                  isCreatingSuperAdmin={isCreatingSuperAdmin}
                  superAdminInviteFeedback={superAdminInviteFeedback}
                  updatingAdminUserIds={updatingAdminUserIds}
                  currentUserId={authSession?.userId || ""}
                  canManageSuperAdmins={isSuperAdmin}
                  isSaving={isSavingMemberAccess}
                  feedbackMessage={memberAccessFeedback}
                />
              ) : activeAdminAccessSection === "Timeline Access" ? (
                <AdminTimelineAccessPanel
                  items={filteredAdminTimelinePosts}
                  searchQuery={adminTimelineSearch}
                  edits={timelineAccessEdits}
                  isSaving={isSavingTimelineAccess}
                  feedbackMessage={timelineAccessFeedback}
                  onSearchChange={setAdminTimelineSearch}
                  onUpdatePost={updateTimelineAccessPost}
                  onSaveTimelineAccessChanges={saveTimelineAccessChanges}
                />
              ) : activeAdminAccessSection === "Banner Access" ? (
                <AdminAppBannerAccessPanel
                  items={adminAppBannerItems}
                  searchQuery={adminAppBannerSearch}
                  edits={appBannerAccessEdits}
                  isSaving={isSavingBannerAccess}
                  feedbackMessage={bannerAccessFeedback}
                  onSearchChange={setAdminAppBannerSearch}
                  onUpdateBanner={updateAppBannerAccessItem}
                  onSaveAppBannerAccessChanges={saveAppBannerAccessChanges}
                />
              ) : activeAdminAccessSection === "Event Access" ? (
                <AdminEventAccessPanel
                  items={filteredAdminEvents}
                  searchQuery={adminEventSearch}
                  formData={eventForm}
                  mediaState={eventMedia}
                  savingEventId={savingEventId}
                  feedbackMessage={eventAccessFeedback}
                  eventTypes={eventTypes}
                  onSearchChange={setAdminEventSearch}
                  onEditEvent={editEventRecord}
                  onDeleteEvent={removeEventRecord}
                  onFormChange={updateEventForm}
                  onMediaChange={updateEventMedia}
                  onSaveEvent={saveEventDraft}
                  onCancelEventEdit={cancelEventEdit}
                />
              ) : (
                <article className="association-empty-state">
                  <span className="mini-label">{activeAdminAccessSection}</span>
                  <h2>
                    {activeAdminAccessSection} configuration will open here.
                  </h2>
                  <p>
                    This keeps the sidebar focused on navigation while the real
                    controls open in the main area.
                  </p>
                </article>
              )}
            </section>
          </section>
        ) : (
          <>
            <section className="welcome-hero">
              <div>
                <span className="eyebrow">Admin Welcome Page</span>
                <h1>Welcome back, Association 1 Admin.</h1>
                <p>
                  This is the post-login home for an admin user. From here we
                  can grow the member, association, vendor, and communication
                  flows without mixing multiple associations.
                </p>
              </div>

              <div className="hero-spotlight">
                <span className="spotlight-label">Today&apos;s focus</span>
                <strong>
                  Onboarding, circular publishing, and vendor visibility.
                </strong>
                <p>
                  All activity here stays inside the Association 1 tenant scope.
                </p>
              </div>

              <div className="hero-inline-actions">
                <Link
                  className="secondary-link"
                  href="/parent/associations/new"
                >
                  Add New Association
                </Link>
                <Link className="secondary-link" href="#">
                  Open Profile
                </Link>
              </div>
            </section>

            <div className="welcome-stack">
              <CarouselSection
                title="Gallery Pictures"
                items={galleryItems}
                tone="tone-gallery"
              />
              <CarouselSection
                title="Circulars"
                items={circularItems}
                tone="tone-circular"
              />
              <CarouselSection
                title="Advertisements"
                items={advertisementItems}
                tone="tone-advertisement"
              />
            </div>
          </>
        )}
      </section>

      {isMemberFormOpen ? (
        <div
          className="member-form-overlay"
          role="dialog"
          aria-modal="true"
          aria-label="Membership form"
        >
          <div className="member-form-dialog">
            <MemberMembershipForm
              fields={membershipFormFields}
              formData={memberMasterForm}
              editingId={editingMemberId}
              membershipTypeOptions={membershipTypeOptions}
              isSaving={isSavingMemberMaster}
              feedbackMessage={memberMasterFeedback}
              onFieldChange={updateMemberMasterForm}
              onImageChange={updateMemberMasterImage}
              onSave={saveMemberRecord}
              onCancel={() => {
                resetMemberMasterForm();
                setIsMemberFormOpen(false);
              }}
            />
          </div>
        </div>
      ) : null}
    </main>
  );
}
