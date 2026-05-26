"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

const apiBaseUrl =
  process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:8083/api";
const webAdminSessionStorageKey = "synetra_web.adminSession";

function normalizeAuthSession(payload) {
  if (!payload?.auth?.token || !payload?.user) {
    return null;
  }

  return {
    authToken: payload.auth.token,
    refreshToken: payload.auth.refreshToken || "",
    sessionId: payload.auth.sessionId || "",
    email: payload.user.email || "",
    viewerRole: payload.user.viewerRole || "viewOnly",
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
        email: parsed.email,
        viewerRole: parsed.viewerRole,
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

const navSections = [
  {
    label: "Dashboard",
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
    label: "Member Arena",
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
    label: "Association arena",
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
    label: "Admin arena",
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
    label: "Vendor Arena",
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
    label: "Timeline",
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
    label: "Events Arena",
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
];

const adminAccessSections = [
  "App Access",
  "Member Access",
  "Vendor Access",
  "Timeline Access",
  "App Banner Access",
  "Add Bulk Member",
  "Event Access",
];
const vendorSubSections = [
  "Category",
  "Sub Category",
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
  "Management Committee",
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
  "Media",
  "All Members",
  "Primary Members",
  "Associate Members",
  "Temporary Visitors",
  "Committee Members",
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

  return (
    <section className="welcome-panel welcome-panel-compact">
      <div className="panel-topline">
        <div>
          <span className="mini-label">App Banner Carousel</span>
          <h2>Paid Promotions</h2>
        </div>
        <span className="mini-label">Starts From Sequence 1</span>
      </div>

      <div className="carousel-viewport">
        <div className="carousel-row carousel-row-moving">
          {[...items, ...items].map((item, index) => (
            <article
              key={`${item.id}-${index}`}
              className="carousel-card tone-advertisement"
            >
              <div className="carousel-visual">
                {item.mediaUrl ? (
                  <img
                    src={item.mediaUrl}
                    alt={item.shortText.slice(0, 60) || "App banner"}
                  />
                ) : (
                  <span>Ad</span>
                )}
              </div>
              <div className="carousel-copy">
                <em className="carousel-badge">Slot {item.displayIndex}</em>
                <strong>{item.vendorName}</strong>
                <p>{item.shortText}</p>
              </div>
            </article>
          ))}
        </div>
      </div>
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

function mapApiVendorToUi(vendor) {
  const vendorStatus = vendor.status ?? "PENDING";
  const linkedUser = vendor.user ?? null;
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
    "Temporary Visitors": allMembers.filter(
      (member) => member.group === "Temporary Visitors",
    ),
    "Committee Members": allMembers.filter(
      (member) => member.group === "Committee Members",
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
  "Management Committee": managementCommittee.map((member) => ({
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
  vendorId: "",
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

function mapAssociationCircularDocuments(items) {
  if (!Array.isArray(items)) {
    return [];
  }

  return items.map((item) => ({
    id: item.id ?? "",
    headline: item.headline ?? "",
    tagline: item.tagline ?? "",
    summary: item.summary ?? "",
    fileName: item.originalFileName ?? "",
    mimeType: item.mimeType ?? "",
    fileExtension: item.fileExtension ?? "",
    documentUrl: item.documentUrl ?? "",
    previewUrl: item.previewUrl ?? "",
  }));
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
  Maharashtra: ["Mumbai", "Pune", "Nagpur", "Nashik", "Aurangabad"],
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

function CarouselSection({ title, items, tone, compact = false }) {
  const carouselItems = compact ? [...items, ...items] : items;

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
        <div className={`carousel-row ${compact ? "carousel-row-moving" : ""}`}>
          {carouselItems.map((item, index) => (
            <article
              key={`${item.id ?? item.title}-${compact ? index : "static"}`}
              className={`carousel-card ${tone}`}
            >
              <div className="carousel-visual">
                <span>
                  {String((index % items.length) + 1).padStart(2, "0")}
                </span>
              </div>
              <div className="carousel-copy">
                <em className="carousel-badge">{item.badge}</em>
                <strong>{item.title}</strong>
                <p>{item.meta}</p>
              </div>
            </article>
          ))}
        </div>
      </div>

      {compact ? (
        <div className="carousel-dots" aria-hidden="true">
          {items.map((item, index) => (
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
  associationAbout,
  associationAboutForm,
  isEditingAssociationAbout,
  onEditAssociationAbout,
  onAssociationAboutFieldChange,
  onAssociationAboutImageChange,
  onCancelAssociationAboutEdit,
  onSaveAssociationAbout,
  committeeMembers,
  allMembers,
  editingCommitteeMemberId,
  committeeMemberForm,
  onOpenCommitteeMemberEditor,
  onCommitteeMemberFormChange,
  onCancelCommitteeMemberEdit,
  onSaveCommitteeMember,
  onRemoveCommitteeMember,
  galleryItems,
  editingGalleryItemId,
  galleryItemForm,
  onOpenGalleryItemEditor,
  onGalleryItemFieldChange,
  onGalleryItemImageChange,
  onCancelGalleryItemEdit,
  onSaveGalleryItem,
  onDeleteGalleryItem,
  circularDocuments,
  editingCircularDocumentId,
  circularDocumentForm,
  onOpenCircularDocumentEditor,
  onCircularDocumentFieldChange,
  onCircularDocumentFileChange,
  onCancelCircularDocumentEdit,
  onSaveCircularDocument,
  onDeleteCircularDocument,
}) {
  const toneMap = {
    Profile: "tone-circular",
    "About Us": "tone-advertisement",
    Finance: "tone-advertisement",
    "Management Committee": "tone-gallery",
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
      />
    );
  }

  if (activeTab === "Management Committee") {
    return (
      <ManagementCommitteePanel
        committeeMembers={committeeMembers}
        allMembers={allMembers}
        isAdmin={isAdmin}
        editingMemberId={editingCommitteeMemberId}
        formData={committeeMemberForm}
        onOpenEditor={onOpenCommitteeMemberEditor}
        onFormChange={onCommitteeMemberFormChange}
        onCancelEdit={onCancelCommitteeMemberEdit}
        onSave={onSaveCommitteeMember}
        onRemove={onRemoveCommitteeMember}
      />
    );
  }

  if (activeTab === "Gallery") {
    return (
      <AssociationGalleryPanel
        items={galleryItems}
        isAdmin={isAdmin}
        editingItemId={editingGalleryItemId}
        formData={galleryItemForm}
        onOpenEditor={onOpenGalleryItemEditor}
        onFieldChange={onGalleryItemFieldChange}
        onImageChange={onGalleryItemImageChange}
        onCancelEdit={onCancelGalleryItemEdit}
        onSave={onSaveGalleryItem}
        onDelete={onDeleteGalleryItem}
      />
    );
  }

  if (activeTab === "Circulars") {
    return (
      <AssociationCircularsPanel
        items={circularDocuments}
        isAdmin={isAdmin}
        editingItemId={editingCircularDocumentId}
        formData={circularDocumentForm}
        onOpenEditor={onOpenCircularDocumentEditor}
        onFieldChange={onCircularDocumentFieldChange}
        onFileChange={onCircularDocumentFileChange}
        onCancelEdit={onCancelCircularDocumentEdit}
        onSave={onSaveCircularDocument}
        onDelete={onDeleteCircularDocument}
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
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={onCancel}
            >
              Cancel
            </button>
            <button
              className="primary-link admin-action-button"
              type="button"
              onClick={onSave}
            >
              Save Profile
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
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={onCancel}
            >
              Cancel
            </button>
            <button
              className="primary-link admin-action-button"
              type="button"
              onClick={onSave}
            >
              Save About Us
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
  isAdmin,
  editingMemberId,
  formData,
  onOpenEditor,
  onCancelEdit,
  onFormChange,
  onSave,
  onRemove,
}) {
  const availableMembers = allMembers.filter((member) => {
    if (member.id === editingMemberId) {
      return true;
    }

    return !member.isCommitteeMember;
  });

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
                  <option value="Chairman">Chairman</option>
                  <option value="Secretary">Secretary</option>
                  <option value="Treasurer">Treasurer</option>
                  <option value="Vice Chairman">Vice Chairman</option>
                  <option value="Member">Member</option>
                </select>
              </label>
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
              >
                Cancel
              </button>
              <button
                className="primary-link admin-action-button"
                type="button"
                onClick={onSave}
              >
                Save Committee Details
              </button>
            </div>
          </article>
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
                    >
                      Edit
                    </button>
                    <button
                      className="secondary-link secondary-button danger-button"
                      type="button"
                      onClick={() => onRemove(member.id)}
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
  items,
  isAdmin,
  editingItemId,
  formData,
  onOpenEditor,
  onFieldChange,
  onImageChange,
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
              <span className="mini-label">Gallery</span>
              <h2>Visual Stories</h2>
            </div>
            {isAdmin ? (
              <button
                className="primary-link admin-action-button"
                type="button"
                onClick={() => onOpenEditor("")}
              >
                Add New
              </button>
            ) : null}
          </div>
          <p className="committee-hero-copy">
            Each gallery entry uses one main image on top with a clear headline,
            short tagline, and full description below.
          </p>
        </article>

        {editingItemId !== null ? (
          <article className="association-profile-card">
            <div className="panel-topline">
              <h3>
                {editingItemId ? "Edit Gallery Item" : "Add Gallery Item"}
              </h3>
              <span className="mini-label">Gallery CMS</span>
            </div>

            <div className="profile-form-grid">
              <div className="profile-avatar-panel profile-field-wide member-photo-field">
                <div className="gallery-form-preview">
                  {formData.imageUrl ? (
                    <img src={formData.imageUrl} alt="Gallery preview" />
                  ) : (
                    <div className="gallery-form-placeholder">
                      Image preview
                    </div>
                  )}
                </div>
                <button
                  className="secondary-link secondary-button profile-upload-button"
                  type="button"
                >
                  Upload Gallery Picture
                  <input
                    type="file"
                    accept="image/*"
                    onChange={(event) =>
                      onImageChange(event.target.files?.[0] ?? null)
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
                <span>Description</span>
                <textarea
                  rows="5"
                  value={formData.description}
                  onChange={(event) =>
                    onFieldChange("description", event.target.value)
                  }
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
                Save Gallery Item
              </button>
            </div>
          </article>
        ) : null}

        {items.length > 0 ? (
          <div className="association-gallery-grid">
            {items.map((item) => (
              <article key={item.id} className="association-gallery-card">
                <div className="association-gallery-visual">
                  {item.imageUrl ? (
                    <img src={item.imageUrl} alt={item.headline} />
                  ) : (
                    <div className="gallery-form-placeholder">No image</div>
                  )}
                </div>
                <div className="association-gallery-copy">
                  <h3>{item.headline}</h3>
                  <span className="mini-label">
                    {item.tagline || "No tagline added yet"}
                  </span>
                  <p>{item.description || "No description added yet."}</p>
                </div>
                {isAdmin ? (
                  <div className="record-actions">
                    <button
                      className="secondary-link secondary-button"
                      type="button"
                      onClick={() => onOpenEditor(item.id)}
                    >
                      Edit
                    </button>
                    <button
                      className="secondary-link secondary-button danger-button"
                      type="button"
                      onClick={() => onDelete(item.id)}
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
            <h3>No gallery entries yet</h3>
            <p>
              Add a gallery item to start showing image-led stories for the
              association.
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
  editingItemId,
  formData,
  onOpenEditor,
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
              <button
                className="primary-link admin-action-button"
                type="button"
                onClick={() => onOpenEditor("")}
              >
                Add New
              </button>
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
              >
                Cancel
              </button>
              <button
                className="primary-link admin-action-button"
                type="button"
                onClick={onSave}
              >
                Save Circular
              </button>
            </div>
          </article>
        ) : null}

        {items.length > 0 ? (
          <div className="association-gallery-grid">
            {items.map((item) => (
              <article
                key={item.id}
                className="association-gallery-card circular-card"
              >
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
                    >
                      Edit
                    </button>
                    <button
                      className="secondary-link secondary-button danger-button"
                      type="button"
                      onClick={() => onDelete(item.id)}
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

function MemberCrudHeader({
  activeTab,
  isAdmin,
  items,
  selectedIds,
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
      </div>

      {isAdmin ? (
        <div className="association-admin-actions">
          <div className="reminder-filter-wrap">
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={onToggleReminderPanel}
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
            />
            <span>Select multiple</span>
          </label>
          <button
            className="secondary-link secondary-button"
            type="button"
            onClick={onContactSelected}
          >
            Contact
          </button>
          <button
            className="secondary-link secondary-button"
            type="button"
            onClick={onSendNotice}
          >
            Send Notice
          </button>
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
  onToggleSelect,
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
            <button className="secondary-link secondary-button" type="button">
              See Detail
            </button>
            {isAdmin ? (
              <button
                className="secondary-link secondary-button danger-button"
                type="button"
                onClick={() => onDeleteOne(member.id)}
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

function MemberTable({ items, selectedIds, isAdmin, onToggleSelect }) {
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
                    >
                      Send Reminder
                    </button>
                  ) : (
                    <button
                      className="secondary-link secondary-button table-button"
                      type="button"
                    >
                      Send Notice
                    </button>
                  )}
                </td>
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
  selectedIds,
  membershipFormFields,
  membershipFieldDraft,
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
        onOpenMemberForm={onOpenMemberForm}
        onEditMember={onEditMember}
        onDeleteMember={onDeleteMember}
        onFieldDraftChange={onMembershipFieldDraftChange}
        onAddField={onAddMembershipField}
        onUpdateField={onUpdateMembershipField}
        onDeleteField={onDeleteMembershipField}
      />
    );
  }

  return (
    <section className="association-tab-section">
      <MemberCrudHeader
        activeTab={activeTab}
        isAdmin={isAdmin}
        items={tabItems}
        selectedIds={selectedIds}
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
        onToggleSelect={onToggleSelect}
        onDeleteOne={onDeleteOne}
      />

      <MemberTable
        items={tabItems}
        selectedIds={selectedIds}
        isAdmin={isAdmin}
        onToggleSelect={onToggleSelect}
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
            <option value="Primary">Primary</option>
            <option value="Associate">Associate</option>
            <option value="Temporary Visit">Temporary Visit</option>
            <option value="Committee">Committee</option>
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
        <button
          className="secondary-link secondary-button"
          type="button"
          onClick={onCancel}
        >
          Cancel
        </button>
        <button
          className="primary-link admin-action-button"
          type="button"
          onClick={onSave}
        >
          {editingId ? "Update User" : "Save User"}
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
  onOpenMemberForm,
  onEditMember,
  onDeleteMember,
  onFieldDraftChange,
  onAddField,
  onUpdateField,
  onDeleteField,
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

      <section className="member-table-panel">
        <div className="panel-topline">
          <h2>Existing Users</h2>
          <span className="mini-label">Add, Modify, Delete</span>
        </div>

        <div className="member-table-wrap">
          <table className="member-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Company</th>
                <th>Membership</th>
                <th>GST</th>
                <th>Contact</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {members.map((member) => (
                <tr key={member.id}>
                  <td>{member.name}</td>
                  <td>{member.company}</td>
                  <td>{member.membershipType}</td>
                  <td>{member.gst || "Not set"}</td>
                  <td>
                    <div className="member-table-contact">
                      <a href={`mailto:${member.email}`}>{member.email}</a>
                      <span>{member.phone}</span>
                    </div>
                  </td>
                  <td>
                    <div className="member-master-actions">
                      <button
                        className="secondary-link secondary-button table-button"
                        type="button"
                        onClick={() => onEditMember(member.id)}
                      >
                        Edit
                      </button>
                      <button
                        className="secondary-link secondary-button danger-button table-button"
                        type="button"
                        onClick={() => onDeleteMember(member.id)}
                      >
                        Delete
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="member-table-panel">
        <div className="panel-topline">
          <h2>Membership Form Edit</h2>
          <span className="mini-label">Admin Field Master</span>
        </div>

        <div className="admin-member-toolbar">
          <label className="content-control-field admin-member-search">
            <span>Field Label</span>
            <input
              type="text"
              value={fieldDraft.label}
              placeholder="Add a custom field label"
              onChange={(event) =>
                onFieldDraftChange("label", event.target.value)
              }
            />
          </label>
          <label className="content-control-field">
            <span>Field Type</span>
            <select
              value={fieldDraft.type}
              onChange={(event) =>
                onFieldDraftChange("type", event.target.value)
              }
            >
              <option value="text">Text</option>
              <option value="textarea">Long Text</option>
              <option value="date">Date</option>
            </select>
          </label>
          <label className="selection-chip">
            <input
              type="checkbox"
              checked={fieldDraft.required}
              onChange={(event) =>
                onFieldDraftChange("required", event.target.checked)
              }
            />
            <span>Required</span>
          </label>
          <button
            className="secondary-link secondary-button"
            type="button"
            onClick={onAddField}
          >
            Add Field
          </button>
        </div>

        <div className="member-master-field-list">
          {membershipFormFields.map((field) => (
            <article key={field.id} className="member-master-field-card">
              <div className="member-master-field-edit-grid">
                <label className="content-control-field">
                  <span>Field Label</span>
                  <input
                    type="text"
                    value={field.label}
                    onChange={(event) =>
                      onUpdateField(field.id, "label", event.target.value)
                    }
                  />
                </label>
                <label className="content-control-field">
                  <span>Field Type</span>
                  <select
                    value={field.type}
                    onChange={(event) =>
                      onUpdateField(field.id, "type", event.target.value)
                    }
                  >
                    <option value="text">Text</option>
                    <option value="textarea">Long Text</option>
                    <option value="date">Date</option>
                  </select>
                </label>
                <label className="selection-chip">
                  <input
                    type="checkbox"
                    checked={field.required}
                    onChange={(event) =>
                      onUpdateField(field.id, "required", event.target.checked)
                    }
                  />
                  <span>Required</span>
                </label>
                {field.isDefault ? (
                  <span className="content-member-chip active">Default</span>
                ) : (
                  <button
                    className="secondary-link secondary-button danger-button"
                    type="button"
                    onClick={() => onDeleteField(field.id)}
                  >
                    Delete Field
                  </button>
                )}
              </div>
            </article>
          ))}
        </div>

        <div className="panel-topline member-master-preview-topline">
          <h2>Membership Form Preview</h2>
          <span className="mini-label">Default fields stay fixed</span>
        </div>
        <MembershipFormPreview fields={membershipFormFields} />
      </section>
    </section>
  );
}

function VendorStatusGrid({ items }) {
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
            <button className="secondary-link secondary-button" type="button">
              See Detail
            </button>
          </div>
        </article>
      ))}
    </div>
  );
}

function VendorRegistrationTable({ items }) {
  return (
    <section className="member-table-panel">
      <div className="panel-topline">
        <h2>Vendor Registration Status</h2>
        <span className="mini-label">Active, Suspended, Lapsed</span>
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
              <th>Registration Period</th>
              <th>Status</th>
              <th>Contact</th>
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
  onSubmit,
}) {
  return (
    <section className="member-table-panel">
      <div className="panel-topline">
        <h2>Add / Update Vendor</h2>
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
        <button
          className="primary-link admin-action-button"
          type="button"
          onClick={onSubmit}
        >
          Save Vendor
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
          />
          <span>Select filtered</span>
        </label>
        <button
          className="secondary-link secondary-button"
          type="button"
          onClick={() => onApplyBulkDecision("APPROVED")}
        >
          Approve Selected Individually
        </button>
        <button
          className="secondary-link secondary-button danger-button"
          type="button"
          onClick={() => onApplyBulkDecision("CANCELLED")}
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
                    >
                      Review
                    </button>
                    <button
                      className="secondary-link secondary-button"
                      type="button"
                      onClick={() => onApproveOne(vendor.id)}
                    >
                      Approve With Details
                    </button>
                    <button
                      className="secondary-link secondary-button danger-button"
                      type="button"
                      onClick={() => onRejectOne(vendor.id)}
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
              />
            </label>
            <label className="profile-field">
              <span>Payment Mode *</span>
              <select
                value={reviewForm.paymentMode}
                onChange={(event) =>
                  onReviewFieldChange("paymentMode", event.target.value)
                }
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
              />
            </label>
            <label className="profile-field">
              <span>ID Proof</span>
              <input
                type="file"
                onChange={(event) =>
                  onReviewFileChange("idProof", event.target.files?.[0] ?? null)
                }
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
                  />
                  <span>Yes</span>
                </label>
                <label className="inline-choice-option">
                  <input
                    type="radio"
                    name="status-isRestaurant"
                    checked={reviewForm.isRestaurant === false}
                    onChange={() => onReviewFieldChange("isRestaurant", false)}
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
              />
            </label>
          </div>

          <div className="profile-action-row">
            <button
              className="secondary-link secondary-button"
              type="button"
              onClick={() => onApproveOne(selectedVendor.id)}
            >
              Save And Approve
            </button>
            <button
              className="secondary-link secondary-button danger-button"
              type="button"
              onClick={() => onRejectOne(selectedVendor.id)}
            >
              Save And Reject
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
  onSubmit,
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

        <VendorStatusGrid items={filteredItems} />
        <VendorRegistrationTable items={filteredItems} />
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
        onSubmit={onSubmit}
      />
    </section>
  );
}

function TimelinePanel({
  formData,
  posts,
  vendorOptions,
  postedByLabel,
  isSaving,
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
            <span>Posted By</span>
            <input type="text" value={postedByLabel} readOnly />
          </label>
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
      </article>

      <section className="member-content-grid">
        {posts.map((post) => (
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
                <span>Status: {post.status}</span>
              </div>
              {post.contactNumber ? <p>Contact: {post.contactNumber}</p> : null}
              {post.imageUrl ? (
                <div className="association-gallery-visual">
                  <img
                    src={post.imageUrl}
                    alt={post.caption.slice(0, 60) || "Timeline post"}
                  />
                </div>
              ) : null}
              <div className="member-record-details">
                {post.landingPageUrl ? (
                  <p>
                    Landing Page:{" "}
                    <a
                      href={post.landingPageUrl}
                      target="_blank"
                      rel="noreferrer"
                    >
                      {post.landingPageUrl}
                    </a>
                  </p>
                ) : null}
                {post.youtubeUrl ? (
                  <p>
                    YouTube:{" "}
                    <a href={post.youtubeUrl} target="_blank" rel="noreferrer">
                      {post.youtubeUrl}
                    </a>
                  </p>
                ) : null}
                {post.facebookUrl ? (
                  <p>
                    Facebook:{" "}
                    <a href={post.facebookUrl} target="_blank" rel="noreferrer">
                      {post.facebookUrl}
                    </a>
                  </p>
                ) : null}
                {post.brochureUrl ? (
                  <p>
                    Brochure:{" "}
                    <a href={post.brochureUrl} target="_blank" rel="noreferrer">
                      Open PDF
                    </a>
                  </p>
                ) : null}
              </div>
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

function EventCreateForm({
  formData,
  mediaState,
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
        {formData.id ? (
          <button
            className="secondary-link secondary-button"
            type="button"
            onClick={onCancel}
          >
            Cancel Edit
          </button>
        ) : null}
        <button
          className="primary-link admin-action-button"
          type="button"
          onClick={onSave}
        >
          {formData.id ? "Save Event Changes" : "Save Event Draft"}
        </button>
      </div>
    </section>
  );
}

function EventTypeManager({
  items,
  draftType,
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
          >
            Add Type
          </button>
        </div>

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
  eventTimelineGroups,
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
      <section className="association-tab-section">
        <AssociationRecordGrid
          activeTab="Master"
          items={eventMasterRecords}
          selectedIds={[]}
          isAdmin={false}
          tone="tone-circular"
          onToggleSelect={() => {}}
          onDeleteOne={() => {}}
        />
      </section>
    );
  }

  if (activeTab === "Type of Event") {
    return (
      <EventTypeManager
        items={eventTypes}
        draftType={eventTypeDraft}
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
                    >
                      Edit
                    </button>
                    <button
                      className="secondary-link secondary-button danger-button table-button"
                      type="button"
                      onClick={() => onDeleteEvent(eventItem.id)}
                    >
                      Delete
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
        <button
          className="primary-link admin-action-button"
          type="button"
          onClick={onSaveTimelineAccessChanges}
        >
          Save Timeline Access Changes
        </button>
      </div>
    </article>
  );
}

function AdminAppBannerAccessPanel({
  items,
  searchQuery,
  edits,
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
        <button
          className="primary-link admin-action-button"
          type="button"
          onClick={onSaveAppBannerAccessChanges}
        >
          Save App Banner Access Changes
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
        </label>
      </div>

      {selectedFile ? <p>Selected file: {selectedFile.name}</p> : null}
      {errorMessage ? (
        <p className="form-helper-error">{errorMessage}</p>
      ) : null}

      <div className="profile-action-row">
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
  onToggleAdminRole,
  updatingAdminUserIds,
}) {
  const allSelected = items.length > 0 && selectedIds.length === items.length;

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
                        <span>{member.isAdmin ? "Admin" : "Member"}</span>
                        <button
                          className={`secondary-link secondary-button ${
                            member.isAdmin ? "danger-button" : ""
                          }`}
                          type="button"
                          disabled={
                            !member.accessUserId ||
                            updatingAdminUserIds.includes(member.accessUserId)
                          }
                          onClick={() => onToggleAdminRole(member)}
                        >
                          {updatingAdminUserIds.includes(member.accessUserId)
                            ? "Saving..."
                            : member.isAdmin
                              ? "Remove Admin"
                              : "Make Admin"}
                        </button>
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
        <button
          className="primary-link admin-action-button"
          type="button"
          onClick={
            activeView === "app"
              ? onSaveMemberAccessChanges
              : onSaveContentAccessChanges
          }
        >
          {activeView === "app"
            ? "Save Member Access Changes"
            : "Save Content Access Changes"}
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
  const [loginForm, setLoginForm] = useState({
    email: "ritsman@gmail.com",
    password: "Admin@123",
  });
  const [loginError, setLoginError] = useState("");
  const [isLoggingIn, setIsLoggingIn] = useState(false);
  const [updatingAdminUserIds, setUpdatingAdminUserIds] = useState([]);
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [isMobileViewport, setIsMobileViewport] = useState(false);
  const [activeSection, setActiveSection] = useState("Association arena");
  const [activeAssociationTab, setActiveAssociationTab] = useState("Profile");
  const [activeFinanceTab, setActiveFinanceTab] = useState("Income");
  const [activeEventsTab, setActiveEventsTab] = useState("Master");
  const [financeStatementFilterType, setFinanceStatementFilterType] =
    useState("");
  const [financeStatementDateFrom, setFinanceStatementDateFrom] = useState("");
  const [financeStatementDateTo, setFinanceStatementDateTo] = useState("");
  const [activeMemberTab, setActiveMemberTab] = useState("Media");
  const [activeVendorTab, setActiveVendorTab] = useState("Registration");
  const [isAdminAccessOpen, setIsAdminAccessOpen] = useState(false);
  const [isVendorNavOpen, setIsVendorNavOpen] = useState(false);
  const [activeAdminAccessSection, setActiveAdminAccessSection] =
    useState("App Access");
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
  const [associationAbout, setAssociationAbout] = useState(
    defaultAssociationAbout,
  );
  const [associationAboutForm, setAssociationAboutForm] = useState(
    defaultAssociationAbout,
  );
  const [isEditingAssociationAbout, setIsEditingAssociationAbout] =
    useState(false);
  const [galleryItems, setGalleryItems] = useState([]);
  const [editingGalleryItemId, setEditingGalleryItemId] = useState(null);
  const [galleryItemForm, setGalleryItemForm] = useState(
    defaultGalleryItemForm,
  );
  const [circularDocuments, setCircularDocuments] = useState([]);
  const [editingCircularDocumentId, setEditingCircularDocumentId] =
    useState(null);
  const [circularDocumentForm, setCircularDocumentForm] = useState(
    defaultCircularDocumentForm,
  );
  const [memberTabData, setMemberTabData] = useState(initialMemberTabData);
  const [editingCommitteeMemberId, setEditingCommitteeMemberId] =
    useState(null);
  const [committeeMemberForm, setCommitteeMemberForm] = useState(
    defaultCommitteeMemberForm,
  );
  const [memberMasterForm, setMemberMasterForm] = useState(
    defaultMemberAdminForm,
  );
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
  const [timelinePosts, setTimelinePosts] = useState([]);
  const [timelinePostForm, setTimelinePostForm] = useState(
    defaultTimelinePostForm,
  );
  const [isSavingTimelinePost, setIsSavingTimelinePost] = useState(false);
  const [appBanners, setAppBanners] = useState([]);
  const [appBannerForm, setAppBannerForm] = useState(defaultAppBannerForm);
  const [isSavingAppBanner, setIsSavingAppBanner] = useState(false);
  const [appBannerError, setAppBannerError] = useState("");
  const [adminAppBannerSearch, setAdminAppBannerSearch] = useState("");
  const [appBannerAccessEdits, setAppBannerAccessEdits] = useState({});
  const [bulkMemberFile, setBulkMemberFile] = useState(null);
  const [isBulkMemberUploading, setIsBulkMemberUploading] = useState(false);
  const [bulkMemberError, setBulkMemberError] = useState("");
  const [bulkMemberResult, setBulkMemberResult] = useState(null);
  const [adminTimelineSearch, setAdminTimelineSearch] = useState("");
  const [timelineAccessEdits, setTimelineAccessEdits] = useState({});
  const [adminVendorSearch, setAdminVendorSearch] = useState("");
  const [adminVendorAccessView, setAdminVendorAccessView] = useState("app");
  const [selectedAdminVendors, setSelectedAdminVendors] = useState([]);
  const [selectedContentVendorIds, setSelectedContentVendorIds] = useState([]);
  const [vendorStatusSearch, setVendorStatusSearch] = useState("");
  const [selectedVendorRequests, setSelectedVendorRequests] = useState([]);
  const [selectedVendorReviewId, setSelectedVendorReviewId] = useState("");
  const [vendorApprovalForm, setVendorApprovalForm] = useState(
    buildVendorApprovalForm(null),
  );
  const [vendorApprovalError, setVendorApprovalError] = useState("");
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
  const [vendorRegistrationForm, setVendorRegistrationForm] = useState({
    company: "",
    category: "",
    subCategory: "",
    contactPerson: "",
    phoneCode: "+91",
    whatsappCode: "+91",
    whatsapp: "",
    country: "India",
    state: "",
    membershipPlan: "",
    paymentAmount: "",
    address: "",
    city: "",
    phone: "",
    email: "",
    website: "",
    facebookUrl: "",
    instagramUrl: "",
    youtubeUrl: "",
    linkedinUrl: "",
    xUrl: "",
    workDescription: "",
    zipcode: "",
    planName: "",
    openingTime: "",
    closingTime: "",
    gstNumber: "",
    isRestaurant: false,
    paymentMode: "Online/NEFT/IMPS",
    bankName: "",
    transactionId: "",
    paymentDescription: "",
    googleLocation: "",
    companyLogo: null,
    idProof: null,
    locationProof: null,
    companyBrochure: null,
    profilePhoto: null,
    visitingCard: null,
    onboardingStartAt: "",
    onboardingEndAt: "",
    paymentDueDate: "",
  });
  const [vendorCategories, setVendorCategories] = useState(
    initialVendorCategories,
  );
  const [vendorSubCategoryRecords, setVendorSubCategoryRecords] =
    useState(vendorSubCategoryMap);
  const [newVendorCategory, setNewVendorCategory] = useState("");
  const [vendorCategoryDraft, setVendorCategoryDraft] = useState("");
  const [editingVendorCategory, setEditingVendorCategory] = useState(null);
  const [selectedVendorParentCategory, setSelectedVendorParentCategory] =
    useState("");
  const [vendorSubCategoryDraft, setVendorSubCategoryDraft] = useState("");
  const [editingVendorSubCategory, setEditingVendorSubCategory] =
    useState(null);
  const [vendorFilters, setVendorFilters] = useState({
    name: "",
    category: "",
    city: "",
  });
  const vendorSubCategoryOptions =
    vendorSubCategoryRecords[vendorRegistrationForm.category] ?? [];
  const vendorStateOptions =
    vendorStateOptionsByCountry[vendorRegistrationForm.country] ?? [];
  const vendorCityOptions =
    vendorCityOptionsByState[vendorRegistrationForm.state] ?? [];
  const [eventForm, setEventForm] = useState({
    ...defaultEventForm,
    id: "",
  });
  const [eventMedia, setEventMedia] = useState(defaultEventMedia);
  const [eventTypes, setEventTypes] = useState(initialEventTypeRecords);
  const [createdEvents, setCreatedEvents] = useState(initialCreatedEvents);
  const [eventTypeDraft, setEventTypeDraft] = useState({
    title: "",
    meta: "",
  });
  const isAssociationAdmin = authSession?.viewerRole === "admin";
  const isMemberAdmin = authSession?.viewerRole === "admin";

  const updateLoginField = (field, value) => {
    setLoginForm((current) => ({
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
    const nextSession = normalizeAuthSession(refreshPayload);
    if (!nextSession || nextSession.viewerRole !== "admin") {
      persistAdminSession(null);
      setAuthSession(null);
      return response;
    }

    persistAdminSession(nextSession);
    setAuthSession(nextSession);
    response = await makeRequest(nextSession);
    return response;
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
      if (!nextSession || nextSession.viewerRole !== "admin") {
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
        const nextSession = normalizeAuthSession(payload);
        if (!nextSession || nextSession.viewerRole !== "admin") {
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
    setVendorCategories([
      ...new Set(
        [
          ...vendors.map((vendor) => vendor.category).filter(Boolean),
          ...initialVendorCategories,
        ].sort((left, right) => left.localeCompare(right)),
      ),
    ]);
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
    void loadVendors();
    void loadTimelinePosts();
    void loadAppBanners();

    return () => {
      isActive = false;
    };
  }, []);

  useEffect(() => {
    setTimelinePostForm((current) => {
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
  const activeMemberItems =
    activeMemberTab === "Master"
      ? (memberTabData["All Members"] ?? [])
      : (memberTabData[activeMemberTab] ?? []);
  const committeeMembers = getCommitteeMembers(
    memberTabData["All Members"] ?? [],
  );
  const eventTimelineData = buildEventTimelineGroups(createdEvents);
  const activeMemberSelectedIds = selectedMemberRecords[activeMemberTab] ?? [];
  const timelineVendorOptions = vendorRecords.map((vendor) => ({
    id: vendor.id,
    label: `${vendor.company}${vendor.category ? ` - ${vendor.category}` : ""}`,
  }));
  const timelinePostedByLabel = "Association 1 Admin";
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
    const selectedIds = selectedMemberRecords[tab] ?? [];
    if (selectedIds.length === 0) {
      return;
    }

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
  };

  const deleteSingleMemberRecord = (tab, recordId) => {
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
  };

  const openMemberForm = () => {
    resetMemberMasterForm();
    setIsMemberFormOpen(true);
  };
  const updateMemberMasterForm = (field, value) => {
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
      setMemberMasterForm((current) => ({
        ...current,
        photoUrl: nextImage,
      }));
    })();
  };
  const resetMemberMasterForm = () => {
    setMemberMasterForm(defaultMemberAdminForm);
    setEditingMemberId("");
  };
  const editMemberRecord = (memberId) => {
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

      const response = await fetch(
        `${apiBaseUrl}/members${editingMemberId ? `/${editingMemberId}` : ""}`,
        {
          method: editingMemberId ? "PATCH" : "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(payload),
        },
      );

      if (!response.ok) {
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
    })();
  };
  const removeMemberRecord = (memberId) => {
    void (async () => {
      const response = await fetch(`${apiBaseUrl}/members/${memberId}`, {
        method: "DELETE",
      });

      if (!response.ok && response.status !== 204) {
        return;
      }

      setMemberTabData((current) =>
        buildMemberTabData(
          (current["All Members"] ?? []).filter((item) => item.id !== memberId),
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
    setMemberAccessEdits((current) => ({
      ...current,
      [memberId]: nextStatusLabel,
    }));
  };

  const applyBulkMemberAccessStatus = (accessStatus) => {
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
      const updates = Object.entries(memberAccessEdits);

      if (updates.length === 0) {
        return;
      }

      const memberLookup = new Map(
        (memberTabData["All Members"] ?? []).map((member) => [
          member.id,
          member,
        ]),
      );

      await Promise.all(
        updates.map(async ([memberId, nextStatusLabel]) => {
          const targetMember = memberLookup.get(memberId);
          if (!targetMember) {
            return;
          }

          const accessStatus =
            nextStatusLabel === "Approved"
              ? "APPROVED"
              : nextStatusLabel === "Suspended"
                ? "SUSPENDED"
                : nextStatusLabel === "Cancelled"
                  ? "CANCELLED"
                  : "PENDING";

          const response = await fetch(
            `${apiBaseUrl}/members/${memberId}/access`,
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

          applyMemberAccessStatusLocally([memberId], nextStatusLabel);
        }),
      );

      setMemberAccessEdits({});
      setSelectedAdminMembers([]);
      await loadMembers();
    })();
  };

  const toggleMemberAdminRole = (member) => {
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
              isAdmin: !member.isAdmin,
            }),
          },
        );

        if (!response.ok) {
          return;
        }

        setMemberTabData((current) =>
          buildMemberTabData(
            (current["All Members"] ?? []).map((item) =>
              item.id === member.id
                ? {
                    ...item,
                    isAdmin: !member.isAdmin,
                  }
                : item,
            ),
          ),
        );

        await loadMembers();
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
    const filteredIds = filteredAdminMembers.map((member) => member.id);
    setSelectedAdminMembers((current) =>
      current.length === filteredIds.length ? [] : filteredIds,
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
    setContentPostEdits((current) => ({
      ...current,
      [postId]: {
        ...current[postId],
        [field]: value,
      },
    }));
  };
  const resetMemberMediaPostForm = () => {
    setMemberMediaPostForm({
      ...defaultMemberMediaPostForm,
      memberId: (memberTabData["All Members"] ?? [])[0]?.id ?? "",
    });
  };
  const updateMemberMediaPostForm = (field, value) => {
    setMemberMediaPostForm((current) => ({
      ...current,
      [field]: value,
    }));
  };
  const updateMemberMediaPostImage = (file) => {
    void (async () => {
      if (!file) {
        setMemberMediaPostForm((current) => ({
          ...current,
          imageFile: null,
          imagePreviewUrl: "",
          imageName: "",
        }));
        return;
      }

      const previewUrl = await readFileAsDataUrl(file);
      setMemberMediaPostForm((current) => ({
        ...current,
        imageFile: file,
        imagePreviewUrl: previewUrl,
        imageName: file.name,
      }));
    })();
  };
  const clearMemberMediaPostImage = () => {
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
        return;
      }

      setIsSavingMemberMediaPost(true);

      try {
        const payload = new FormData();
        payload.append("memberId", memberMediaPostForm.memberId);
        payload.append("title", memberMediaPostForm.title.trim());
        payload.append("summary", memberMediaPostForm.summary.trim());
        payload.append("body", memberMediaPostForm.body.trim());
        payload.append("postType", "Media");
        payload.append("imageFile", memberMediaPostForm.imageFile);

        const response = await fetch(`${apiBaseUrl}/member-posts`, {
          method: "POST",
          body: payload,
        });

        if (!response.ok) {
          return;
        }

        await loadMemberPosts();
        resetMemberMediaPostForm();
      } finally {
        setIsSavingMemberMediaPost(false);
      }
    })();
  };
  const updateMemberMediaPostStatus = (postId, nextStatusLabel) => {
    void (async () => {
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

      const response = await fetch(
        `${apiBaseUrl}/member-posts/${postId}/moderation`,
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

          return fetch(`${apiBaseUrl}/member-posts/${post.id}/moderation`, {
            method: "PATCH",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              reviewStatus,
              displayStart: nextEdit.displayStart || null,
              displayEnd: nextEdit.displayEnd || null,
            }),
          });
        }),
      );

      await loadMemberPosts();
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
    setVendorRegistrationForm((current) => ({
      ...current,
      [field]: file,
    }));
  };
  const resetVendorRegistrationForm = () => {
    setVendorRegistrationForm({
      company: "",
      category: "",
      subCategory: "",
      contactPerson: "",
      phoneCode: "+91",
      whatsappCode: "+91",
      whatsapp: "",
      country: "India",
      state: "",
      membershipPlan: "",
      paymentAmount: "",
      address: "",
      city: "",
      phone: "",
      email: "",
      website: "",
      facebookUrl: "",
      instagramUrl: "",
      youtubeUrl: "",
      linkedinUrl: "",
      xUrl: "",
      workDescription: "",
      zipcode: "",
      planName: "",
      openingTime: "",
      closingTime: "",
      gstNumber: "",
      isRestaurant: false,
      paymentMode: "Online/NEFT/IMPS",
      bankName: "",
      transactionId: "",
      paymentDescription: "",
      googleLocation: "",
      companyLogo: null,
      idProof: null,
      locationProof: null,
      companyBrochure: null,
      profilePhoto: null,
      visitingCard: null,
      onboardingStartAt: "",
      onboardingEndAt: "",
      paymentDueDate: "",
    });
  };
  const updateVendorFilter = (field, value) => {
    setVendorFilters((current) => ({
      ...current,
      [field]: value,
    }));
  };
  const addVendorCategory = () => {
    const nextCategory = newVendorCategory.trim();
    if (!nextCategory || vendorCategories.includes(nextCategory)) {
      return;
    }

    setVendorCategories((current) => [...current, nextCategory]);
    setVendorSubCategoryRecords((current) => ({
      ...current,
      [nextCategory]: current[nextCategory] ?? [],
    }));
    setNewVendorCategory("");
  };
  const openVendorCategoryEditor = (categoryName) => {
    setEditingVendorCategory(categoryName);
    setVendorCategoryDraft(categoryName || "");
  };
  const cancelVendorCategoryEdit = () => {
    setEditingVendorCategory(null);
    setVendorCategoryDraft("");
  };
  const saveVendorCategory = () => {
    const nextName = vendorCategoryDraft.trim();
    if (!nextName) {
      return;
    }

    if (editingVendorCategory) {
      if (
        nextName !== editingVendorCategory &&
        vendorCategories.includes(nextName)
      ) {
        return;
      }

      setVendorCategories((current) =>
        current.map((category) =>
          category === editingVendorCategory ? nextName : category,
        ),
      );
      setVendorSubCategoryRecords((current) => {
        const nextRecord = { ...current };
        const existingSubCategories = nextRecord[editingVendorCategory] ?? [];
        delete nextRecord[editingVendorCategory];
        nextRecord[nextName] = existingSubCategories;
        return nextRecord;
      });
      if (selectedVendorParentCategory === editingVendorCategory) {
        setSelectedVendorParentCategory(nextName);
      }
      if (vendorRegistrationForm.category === editingVendorCategory) {
        setVendorRegistrationForm((current) => ({
          ...current,
          category: nextName,
        }));
      }
    } else {
      if (vendorCategories.includes(nextName)) {
        return;
      }
      setVendorCategories((current) => [...current, nextName]);
      setVendorSubCategoryRecords((current) => ({
        ...current,
        [nextName]: current[nextName] ?? [],
      }));
    }

    cancelVendorCategoryEdit();
  };
  const deleteVendorCategory = (categoryName) => {
    setVendorCategories((current) =>
      current.filter((category) => category !== categoryName),
    );
    setVendorSubCategoryRecords((current) => {
      const nextRecord = { ...current };
      delete nextRecord[categoryName];
      return nextRecord;
    });
    if (selectedVendorParentCategory === categoryName) {
      setSelectedVendorParentCategory("");
    }
    if (vendorRegistrationForm.category === categoryName) {
      setVendorRegistrationForm((current) => ({
        ...current,
        category: "",
        subCategory: "",
      }));
    }
    if (vendorFilters.category === categoryName) {
      setVendorFilters((current) => ({
        ...current,
        category: "",
      }));
    }
  };
  const openVendorSubCategoryEditor = (subCategoryName) => {
    setEditingVendorSubCategory(subCategoryName);
    setVendorSubCategoryDraft(subCategoryName || "");
  };
  const cancelVendorSubCategoryEdit = () => {
    setEditingVendorSubCategory(null);
    setVendorSubCategoryDraft("");
  };
  const saveVendorSubCategory = () => {
    const nextName = vendorSubCategoryDraft.trim();
    if (!selectedVendorParentCategory || !nextName) {
      return;
    }

    const currentItems =
      vendorSubCategoryRecords[selectedVendorParentCategory] ?? [];
    if (editingVendorSubCategory) {
      if (
        nextName !== editingVendorSubCategory &&
        currentItems.includes(nextName)
      ) {
        return;
      }

      setVendorSubCategoryRecords((current) => ({
        ...current,
        [selectedVendorParentCategory]: (
          current[selectedVendorParentCategory] ?? []
        ).map((item) => (item === editingVendorSubCategory ? nextName : item)),
      }));
      if (
        vendorRegistrationForm.category === selectedVendorParentCategory &&
        vendorRegistrationForm.subCategory === editingVendorSubCategory
      ) {
        setVendorRegistrationForm((current) => ({
          ...current,
          subCategory: nextName,
        }));
      }
    } else {
      if (currentItems.includes(nextName)) {
        return;
      }
      setVendorSubCategoryRecords((current) => ({
        ...current,
        [selectedVendorParentCategory]: [
          ...(current[selectedVendorParentCategory] ?? []),
          nextName,
        ],
      }));
    }

    cancelVendorSubCategoryEdit();
  };
  const deleteVendorSubCategory = (subCategoryName) => {
    if (!selectedVendorParentCategory) {
      return;
    }

    setVendorSubCategoryRecords((current) => ({
      ...current,
      [selectedVendorParentCategory]: (
        current[selectedVendorParentCategory] ?? []
      ).filter((item) => item !== subCategoryName),
    }));
    if (
      vendorRegistrationForm.category === selectedVendorParentCategory &&
      vendorRegistrationForm.subCategory === subCategoryName
    ) {
      setVendorRegistrationForm((current) => ({
        ...current,
        subCategory: "",
      }));
    }
  };
  const saveVendorRecord = () => {
    void (async () => {
      if (
        !vendorRegistrationForm.company.trim() ||
        !vendorRegistrationForm.contactPerson.trim() ||
        !vendorRegistrationForm.phone.trim() ||
        !vendorRegistrationForm.email.trim() ||
        !vendorRegistrationForm.category.trim() ||
        !vendorRegistrationForm.subCategory.trim() ||
        !vendorRegistrationForm.address.trim()
      ) {
        return;
      }

      const response = await fetch(`${apiBaseUrl}/vendors`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
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
          whatsapp:
            `${vendorRegistrationForm.whatsappCode} ${vendorRegistrationForm.whatsapp.trim()}`.trim(),
          facebookUrl: vendorRegistrationForm.facebookUrl.trim(),
          instagramUrl: vendorRegistrationForm.instagramUrl.trim(),
          youtubeUrl: vendorRegistrationForm.youtubeUrl.trim(),
          linkedinUrl: vendorRegistrationForm.linkedinUrl.trim(),
          xUrl: vendorRegistrationForm.xUrl.trim(),
          onboardingStartAt:
            vendorRegistrationForm.onboardingStartAt || undefined,
          onboardingEndAt: vendorRegistrationForm.onboardingEndAt || undefined,
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
      });

      if (!response.ok) {
        return;
      }

      await loadVendors();
      resetVendorRegistrationForm();
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

      await fetch(`${apiBaseUrl}/vendors/${vendorId}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          membershipPlan: reviewTarget.membershipPlan.trim(),
          paymentAmount: reviewTarget.paymentAmount.trim(),
          onboardingStartAt: reviewTarget.onboardingStartAt || undefined,
          onboardingEndAt: reviewTarget.onboardingEndAt || undefined,
          paymentDueDate: reviewTarget.paymentDueDate || undefined,
          notes,
        }),
      });

      const response = await fetch(`${apiBaseUrl}/vendors/${vendorId}/access`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ accessStatus }),
      });

      if (!response.ok) {
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

      await Promise.all(
        selectedVendorRequests.map((vendorId) =>
          fetch(`${apiBaseUrl}/vendors/${vendorId}/access`, {
            method: "PATCH",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ accessStatus }),
          }),
        ),
      );

      setSelectedVendorRequests([]);
      await loadVendors();
    })();
  };
  const updateTimelinePostForm = (field, value) => {
    setTimelinePostForm((current) => {
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
  const updateTimelinePostFile = (field, value) => {
    setTimelinePostForm((current) => ({
      ...current,
      [field]: value,
    }));
  };
  const submitTimelinePost = () => {
    void (async () => {
      if (!timelinePostForm.caption.trim() || !timelinePostForm.vendorId) {
        return;
      }

      const payload = new FormData();
      payload.append("sourceType", "VENDOR");
      payload.append("vendorId", timelinePostForm.vendorId);
      payload.append("postedBy", timelinePostedByLabel);
      payload.append("caption", timelinePostForm.caption.trim());
      payload.append("contactNumber", timelinePostForm.contactNumber.trim());
      payload.append("landingPageUrl", timelinePostForm.landingPageUrl.trim());
      payload.append("youtubeUrl", timelinePostForm.youtubeUrl.trim());
      payload.append("facebookUrl", timelinePostForm.facebookUrl.trim());

      if (timelinePostForm.imageFile) {
        payload.append("imageFile", timelinePostForm.imageFile);
      }

      if (timelinePostForm.brochureFile) {
        payload.append("brochureFile", timelinePostForm.brochureFile);
      }

      setIsSavingTimelinePost(true);
      const response = await fetch(`${apiBaseUrl}/timeline-posts`, {
        method: "POST",
        body: payload,
      });
      setIsSavingTimelinePost(false);

      if (!response.ok) {
        return;
      }

      await loadTimelinePosts();
      setTimelinePostForm({
        ...defaultTimelinePostForm,
        vendorId: timelinePostForm.vendorId,
        contactNumber: timelinePostForm.contactNumber,
      });
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
      const response = await fetch(`${apiBaseUrl}/app-banners`, {
        method: "POST",
        body: payload,
      });
      setIsSavingAppBanner(false);

      if (!response.ok) {
        setAppBannerError("Unable to save the app banner right now.");
        return;
      }

      await loadAppBanners();
      setAppBannerError("");
      setAppBannerForm({
        ...defaultAppBannerForm,
        vendorId: appBannerForm.vendorId,
        contactNumber: appBannerForm.contactNumber,
      });
    })();
  };
  const updateAppBannerAccessItem = (bannerId, field, value) => {
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
        return;
      }

      await Promise.all(
        updates.map(async ([bannerId, edit]) => {
          const reviewStatus =
            edit.status === "Approved"
              ? "APPROVED"
              : edit.status === "Rejected"
                ? "REJECTED"
                : edit.status === "Hold"
                  ? "ON_HOLD"
                  : "PENDING";

          await fetch(`${apiBaseUrl}/app-banners/${bannerId}/moderation`, {
            method: "PATCH",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              reviewStatus,
              paymentReceived: Boolean(edit.paymentReceived),
              paymentMode: edit.paymentMode || undefined,
              paymentRemarks: edit.paymentRemarks || undefined,
              displayStart: edit.displayStart || undefined,
              displayEnd: edit.displayEnd || undefined,
              displayIndex: edit.displayIndex
                ? Number(edit.displayIndex)
                : undefined,
            }),
          });
        }),
      );

      await loadAppBanners();
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
        return;
      }

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

          await fetch(`${apiBaseUrl}/timeline-posts/${postId}/moderation`, {
            method: "PATCH",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              reviewStatus,
              displayStart: edit.displayStart || undefined,
              displayEnd: edit.displayEnd || undefined,
            }),
          });
        }),
      );

      await loadTimelinePosts();
    })();
  };
  const updateEventForm = (field, value) => {
    setEventForm((current) => ({
      ...current,
      [field]: value,
    }));
  };
  const updateEventMedia = (field, value) => {
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
    if (activeSection === "Events Arena") {
      setActiveEventsTab("Create New Event");
    }
  };
  const cancelEventEdit = () => {
    resetEventEditor();
  };
  const updateEventTypeDraft = (field, value) => {
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
        return;
      }

      const response = await fetch(`${apiBaseUrl}/events/types`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          name: title,
          description: meta,
        }),
      });

      if (!response.ok) {
        return;
      }

      await loadEventsArena();
      setEventTypeDraft({ title: "", meta: "" });
    })();
  };
  const updateEventType = (eventTypeId, field, value) => {
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

      await fetch(`${apiBaseUrl}/events/types/${eventTypeId}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          name: nextTitle.trim(),
          description: nextMeta.trim(),
        }),
      });
    })();
  };

  const saveEventDraft = () => {
    void (async () => {
      if (!eventForm.name.trim() || !eventForm.type.trim() || !eventForm.date) {
        return;
      }

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

      const response = await fetch(
        `${apiBaseUrl}/events${eventForm.id ? `/${eventForm.id}` : ""}`,
        {
          method: eventForm.id ? "PATCH" : "POST",
          body: payload,
        },
      );

      if (!response.ok) {
        return;
      }

      await loadEventsArena();
      resetEventEditor();
      setActiveEventsTab("Event");
    })();
  };
  const removeEventRecord = (eventId) => {
    void (async () => {
      const response = await fetch(`${apiBaseUrl}/events/${eventId}`, {
        method: "DELETE",
      });

      if (!response.ok && response.status !== 204) {
        return;
      }

      await loadEventsArena();

      if (eventForm.id === eventId) {
        resetEventEditor();
      }
    })();
  };

  const openAssociationProfileEditor = () => {
    setAssociationProfileForm(associationProfile);
    setIsEditingAssociationProfile(true);
  };

  const updateAssociationProfileField = (field, value) => {
    setAssociationProfileForm((current) => ({
      ...current,
      ...(field === "state" ? { city: "" } : {}),
      [field]: value,
    }));
  };

  const updateAssociationRegionalField = (index, field, value) => {
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
    setAssociationProfileForm((current) => ({
      ...current,
      regionalAddresses: [
        ...current.regionalAddresses,
        { ...defaultRegionalAddress, id: `regional-${Date.now()}` },
      ],
    }));
  };

  const removeAssociationRegionalAddress = (index) => {
    setAssociationProfileForm((current) => ({
      ...current,
      regionalAddresses: current.regionalAddresses.filter(
        (_, addressIndex) => addressIndex !== index,
      ),
    }));
  };

  const cancelAssociationProfileEdit = () => {
    setAssociationProfileForm(associationProfile);
    setIsEditingAssociationProfile(false);
  };

  const saveAssociationProfile = () => {
    void (async () => {
      const normalizedName = associationProfileForm.name.trim();
      if (!normalizedName || !associationProfile.id) {
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

      const response = await fetch(
        `${apiBaseUrl}/associations/${associationProfile.id}`,
        {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(payload),
        },
      );

      if (!response.ok) {
        return;
      }

      await loadAssociationProfile();
      setIsEditingAssociationProfile(false);
    })();
  };

  const openAssociationAboutEditor = () => {
    setAssociationAboutForm(associationAbout);
    setIsEditingAssociationAbout(true);
  };

  const updateAssociationAboutField = (field, value) => {
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
      setAssociationAboutForm((current) => ({
        ...current,
        [field]: nextImage,
      }));
    })();
  };

  const cancelAssociationAboutEdit = () => {
    setAssociationAboutForm(associationAbout);
    setIsEditingAssociationAbout(false);
  };

  const saveAssociationAbout = () => {
    void (async () => {
      if (!associationProfile.id) {
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

      const response = await fetch(
        `${apiBaseUrl}/associations/${associationProfile.id}/about`,
        {
          method: "PATCH",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(payload),
        },
      );

      if (!response.ok) {
        return;
      }

      const savedPayload = await response.json();
      const nextAbout = mapAssociationAboutToForm(savedPayload.aboutContent);
      setAssociationAbout(nextAbout);
      setAssociationAboutForm(nextAbout);
      setIsEditingAssociationAbout(false);
    })();
  };

  const openCommitteeMemberEditor = (memberId) => {
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
    });
  };

  const updateCommitteeMemberForm = (field, value) => {
    setCommitteeMemberForm((current) => ({
      ...current,
      [field]: value,
    }));
  };

  const closeCommitteeMemberEditor = () => {
    setEditingCommitteeMemberId(null);
    setCommitteeMemberForm(defaultCommitteeMemberForm);
  };

  const saveCommitteeMember = () => {
    void (async () => {
      const targetMemberId = committeeMemberForm.memberId;
      if (!targetMemberId || !committeeMemberForm.committeePost.trim()) {
        return;
      }

      const response = await fetch(`${apiBaseUrl}/members/${targetMemberId}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          committeePost: committeeMemberForm.committeePost.trim(),
          committeeTenureStart:
            committeeMemberForm.committeeTenureStart || null,
          committeeTenureEnd: committeeMemberForm.committeeTenureEnd || null,
          memberBio: committeeMemberForm.memberBio.trim(),
        }),
      });

      if (!response.ok) {
        return;
      }

      await loadMembers();
      closeCommitteeMemberEditor();
    })();
  };

  const removeCommitteeMember = (memberId) => {
    void (async () => {
      const response = await fetch(`${apiBaseUrl}/members/${memberId}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          committeePost: "",
          committeeTenureStart: null,
          committeeTenureEnd: null,
          memberBio: "",
        }),
      });

      if (!response.ok) {
        return;
      }

      await loadMembers();
      if (editingCommitteeMemberId === memberId) {
        closeCommitteeMemberEditor();
      }
    })();
  };

  const openGalleryItemEditor = (itemId) => {
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
      setGalleryItemForm((current) => ({
        ...current,
        imageUrl: nextImage,
      }));
    })();
  };

  const cancelGalleryItemEdit = () => {
    setEditingGalleryItemId(null);
    setGalleryItemForm(defaultGalleryItemForm);
  };

  const saveGalleryItem = () => {
    void (async () => {
      if (!associationProfile.id || !galleryItemForm.headline.trim()) {
        return;
      }

      const payload = {
        imageUrl: galleryItemForm.imageUrl,
        headline: galleryItemForm.headline.trim(),
        tagline: galleryItemForm.tagline.trim(),
        description: galleryItemForm.description.trim(),
      };

      const response = await fetch(
        `${apiBaseUrl}/associations/${associationProfile.id}/gallery${editingGalleryItemId ? `/${editingGalleryItemId}` : ""}`,
        {
          method: editingGalleryItemId ? "PATCH" : "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(payload),
        },
      );

      if (!response.ok) {
        return;
      }

      await loadAssociationProfile();
      cancelGalleryItemEdit();
    })();
  };

  const deleteGalleryItem = (itemId) => {
    void (async () => {
      if (!associationProfile.id) {
        return;
      }

      const response = await fetch(
        `${apiBaseUrl}/associations/${associationProfile.id}/gallery/${itemId}`,
        {
          method: "DELETE",
        },
      );

      if (!response.ok && response.status !== 204) {
        return;
      }

      await loadAssociationProfile();
      if (editingGalleryItemId === itemId) {
        cancelGalleryItemEdit();
      }
    })();
  };

  const openCircularDocumentEditor = (itemId) => {
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
    setEditingCircularDocumentId(null);
    setCircularDocumentForm(defaultCircularDocumentForm);
  };

  const saveCircularDocument = () => {
    void (async () => {
      if (!associationProfile.id || !circularDocumentForm.headline.trim()) {
        return;
      }

      if (!editingCircularDocumentId && !circularDocumentForm.file) {
        return;
      }

      const payload = new FormData();
      payload.append("headline", circularDocumentForm.headline.trim());
      payload.append("tagline", circularDocumentForm.tagline.trim());
      payload.append("summary", circularDocumentForm.summary.trim());
      if (circularDocumentForm.file) {
        payload.append("file", circularDocumentForm.file);
      }

      const response = await fetch(
        `${apiBaseUrl}/associations/${associationProfile.id}/circulars${editingCircularDocumentId ? `/${editingCircularDocumentId}` : ""}`,
        {
          method: editingCircularDocumentId ? "PATCH" : "POST",
          body: payload,
        },
      );

      if (!response.ok) {
        return;
      }

      await loadAssociationProfile();
      cancelCircularDocumentEdit();
    })();
  };

  const deleteCircularDocument = (itemId) => {
    void (async () => {
      if (!associationProfile.id) {
        return;
      }

      const response = await fetch(
        `${apiBaseUrl}/associations/${associationProfile.id}/circulars/${itemId}`,
        {
          method: "DELETE",
        },
      );

      if (!response.ok && response.status !== 204) {
        return;
      }

      await loadAssociationProfile();
      if (editingCircularDocumentId === itemId) {
        cancelCircularDocumentEdit();
      }
    })();
  };

  const toggleAppPermission = (permissionKey) => {
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
              <button
                type="button"
                className={`nav-item ${
                  item.label === activeSection ||
                  (item.label === "Vendor Arena" &&
                    vendorSubSections.includes(activeSection))
                    ? "active"
                    : ""
                } ${isSidebarOpen ? "" : "is-icon-mode"}`}
                onClick={() => {
                  setActiveSection(item.label);
                  if (item.label === "Admin arena") {
                    setIsAdminAccessOpen((current) => !current);
                  }
                  if (item.label === "Vendor Arena") {
                    setIsVendorNavOpen((current) => !current);
                  }
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
                {item.label === "Admin arena" && isSidebarOpen ? (
                  <span className="nav-accordion-indicator" aria-hidden="true">
                    {isAdminAccessOpen ? "−" : "+"}
                  </span>
                ) : item.label === "Vendor Arena" && isSidebarOpen ? (
                  <span className="nav-accordion-indicator" aria-hidden="true">
                    {isVendorNavOpen ? "−" : "+"}
                  </span>
                ) : null}
              </button>

              {item.label === "Admin arena" &&
              isSidebarOpen &&
              isAdminAccessOpen ? (
                <div className="sidebar-subnav" aria-label="Admin access menu">
                  {adminAccessSections.map((section) => (
                    <div key={section} className="sidebar-subnav-group">
                      <button
                        type="button"
                        className="sidebar-subnav-item"
                        onClick={() => {
                          setActiveSection("Admin arena");
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
              ) : item.label === "Vendor Arena" &&
                isSidebarOpen &&
                isVendorNavOpen ? (
                <div className="sidebar-subnav" aria-label="Vendor menu">
                  {vendorSubSections.map((section) => (
                    <div key={section} className="sidebar-subnav-group">
                      <button
                        type="button"
                        className="sidebar-subnav-item"
                        onClick={() => {
                          setActiveSection(section);
                          setIsVendorNavOpen(true);
                        }}
                      >
                        <span>{section}</span>
                        {section === activeSection ? (
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
              placeholder="Search members, circulars, vendors, settings..."
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

        {activeSection === "Association arena" ? (
          <section className="association-workspace">
            <div className="association-featured-stack">
              <CarouselSection
                title="Latest Gallery"
                items={galleryItems}
                tone="tone-gallery"
                compact
              />
              <CarouselSection
                title="Latest Circulars"
                items={associationTabData.Circulars}
                tone="tone-circular"
                compact
              />
            </div>

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
                associationAbout={associationAbout}
                associationAboutForm={associationAboutForm}
                isEditingAssociationAbout={isEditingAssociationAbout}
                onEditAssociationAbout={openAssociationAboutEditor}
                onAssociationAboutFieldChange={updateAssociationAboutField}
                onAssociationAboutImageChange={updateAssociationAboutImage}
                onCancelAssociationAboutEdit={cancelAssociationAboutEdit}
                onSaveAssociationAbout={saveAssociationAbout}
                committeeMembers={committeeMembers}
                allMembers={memberTabData["All Members"] ?? []}
                editingCommitteeMemberId={editingCommitteeMemberId}
                committeeMemberForm={committeeMemberForm}
                onOpenCommitteeMemberEditor={openCommitteeMemberEditor}
                onCommitteeMemberFormChange={updateCommitteeMemberForm}
                onCancelCommitteeMemberEdit={closeCommitteeMemberEditor}
                onSaveCommitteeMember={saveCommitteeMember}
                onRemoveCommitteeMember={removeCommitteeMember}
                galleryItems={galleryItems}
                editingGalleryItemId={editingGalleryItemId}
                galleryItemForm={galleryItemForm}
                onOpenGalleryItemEditor={openGalleryItemEditor}
                onGalleryItemFieldChange={updateGalleryItemField}
                onGalleryItemImageChange={updateGalleryItemImage}
                onCancelGalleryItemEdit={cancelGalleryItemEdit}
                onSaveGalleryItem={saveGalleryItem}
                onDeleteGalleryItem={deleteGalleryItem}
                circularDocuments={circularDocuments}
                editingCircularDocumentId={editingCircularDocumentId}
                circularDocumentForm={circularDocumentForm}
                onOpenCircularDocumentEditor={openCircularDocumentEditor}
                onCircularDocumentFieldChange={updateCircularDocumentField}
                onCircularDocumentFileChange={updateCircularDocumentFile}
                onCancelCircularDocumentEdit={cancelCircularDocumentEdit}
                onSaveCircularDocument={saveCircularDocument}
                onDeleteCircularDocument={deleteCircularDocument}
              />
            </div>

            <section className="association-header">
              <div>
                <span className="eyebrow">Association Dashboard</span>
                <h1>Association 1</h1>
                <p>General information header for the association arena.</p>
              </div>

              <div className="association-header-meta">
                <div className="association-dashboard-grid">
                  {associationOverviewStats.map((item) => (
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

            <section className="association-overview-grid">
              <article className="hero-spotlight association-spotlight-card">
                <span className="spotlight-label">Committee Board</span>
                <div className="committee-avatar-row">
                  {committeeHighlights.map((member) => (
                    <div
                      key={member.name}
                      className="committee-avatar-chip"
                      title={member.name}
                    >
                      <span className="committee-avatar">
                        {member.initials}
                      </span>
                      <div>
                        <strong>{member.name}</strong>
                        <p>{member.role}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </article>

              <article className="hero-spotlight association-spotlight-card latest-gallery-card">
                <span className="spotlight-label">Latest In Gallery</span>
                <strong>Plant Visit 2026</strong>
                <p>
                  28 new images added from the manufacturing excellence tour
                  this week.
                </p>
                <div className="latest-gallery-strip" aria-hidden="true">
                  <span />
                  <span />
                  <span />
                </div>
              </article>
            </section>

            <DashboardAppBannerCarousel items={dashboardAppBanners} />
            <DashboardTimelineFeed posts={dashboardTimelinePosts} />
          </section>
        ) : activeSection === "Member Arena" ? (
          <section className="association-workspace">
            <div className="association-featured-stack member-featured-stack">
              <MemberCarouselSection
                title="Committee Members"
                items={memberTabData["Committee Members"]}
                tone="tone-gallery"
              />
              <MemberCarouselSection
                title="Primary Members"
                items={memberTabData["Primary Members"]}
                tone="tone-circular"
              />
              <MemberCarouselSection
                title="Associate Members"
                items={memberTabData["Associate Members"]}
                tone="tone-advertisement"
              />
              <MemberCarouselSection
                title="Temporary Visitors"
                items={memberTabData["Temporary Visitors"]}
                tone="tone-gallery"
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
                  {tab === "All Members" && expiringMembersCount > 0 ? (
                    <span className="tab-notification-chip">
                      {expiringMembersCount} expiring
                    </span>
                  ) : null}
                </button>
              ))}
            </nav>

            <div className="association-content">
              <MemberArenaContent
                activeTab={activeMemberTab}
                isAdmin={isMemberAdmin}
                tabItems={activeMemberItems}
                allMembers={memberTabData["All Members"] ?? []}
                memberPosts={memberContentPosts}
                memberPostForm={memberMediaPostForm}
                isSavingMemberPost={isSavingMemberMediaPost}
                selectedIds={activeMemberSelectedIds}
                membershipFormFields={membershipFormFields}
                membershipFieldDraft={membershipFieldDraft}
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
                onMemberPostFieldChange={updateMemberMediaPostForm}
                onMemberPostImageChange={updateMemberMediaPostImage}
                onClearMemberPostImage={clearMemberMediaPostImage}
                onSubmitMemberPost={submitMemberMediaPost}
                onUpdateMemberPostStatus={updateMemberMediaPostStatus}
              />
            </div>

            <section className="association-header">
              <div>
                <span className="eyebrow">Member Arena</span>
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
                vendorOptions={timelineVendorOptions}
                postedByLabel={timelinePostedByLabel}
                isSaving={isSavingTimelinePost}
                onChange={updateTimelinePostForm}
                onFileChange={updateTimelinePostFile}
                onSubmit={submitTimelinePost}
              />
            </section>
          </section>
        ) : activeSection === "Vendor Arena" ? (
          <section className="association-workspace">
            <div className="association-featured-stack member-featured-stack">
              <MemberCarouselSection
                title="Active Vendors"
                items={vendorRecords.filter(
                  (vendor) => vendor.registrationStatus === "Active",
                )}
                tone="tone-gallery"
              />
              <MemberCarouselSection
                title="Suspended Vendors"
                items={vendorRecords.filter(
                  (vendor) => vendor.registrationStatus === "Suspended",
                )}
                tone="tone-circular"
              />
              <MemberCarouselSection
                title="Lapsed Vendors"
                items={vendorRecords.filter(
                  (vendor) => vendor.registrationStatus === "Lapsed",
                )}
                tone="tone-advertisement"
              />
            </div>

            <nav className="association-tabbar" aria-label="Vendor sections">
              {vendorArenaTabs.map((tab) => (
                <button
                  key={tab}
                  type="button"
                  className={`association-tab ${tab === activeVendorTab ? "active" : ""}`}
                  onClick={() => setActiveVendorTab(tab)}
                >
                  {tab}
                </button>
              ))}
            </nav>

            <div className="association-content">
              <VendorArenaContent
                activeTab={activeVendorTab}
                items={vendorRecords}
                formData={vendorRegistrationForm}
                categories={vendorCategories}
                subCategories={vendorSubCategoryOptions}
                countryOptions={vendorCountryOptions}
                stateOptions={vendorStateOptions}
                cityOptions={vendorCityOptions}
                phoneCodeOptions={vendorPhoneCodeOptions}
                planOptions={vendorPlanOptions}
                paymentModeOptions={vendorPaymentModeOptions}
                newCategory={newVendorCategory}
                filterState={vendorFilters}
                onFormChange={updateVendorRegistrationForm}
                onFileChange={updateVendorRegistrationFile}
                onFilterChange={updateVendorFilter}
                onNewCategoryChange={setNewVendorCategory}
                onAddCategory={addVendorCategory}
                onSubmit={saveVendorRecord}
              />
            </div>

            <section className="association-header">
              <div>
                <span className="eyebrow">Vendor Arena</span>
                <h1>Vendor Registration and Access Desk</h1>
                <p>
                  Track vendor lifecycle, payment standing, and new onboarding
                  submissions in one workspace.
                </p>
              </div>

              <div className="association-header-meta">
                <div className="association-dashboard-grid">
                  {vendorSummaryStats.map((item) => (
                    <article
                      key={item.label}
                      className="association-dashboard-card"
                    >
                      <strong>{item.value}</strong>
                      <span>{item.label}</span>
                    </article>
                  ))}
                </div>
              </div>
            </section>
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
                  onSubmit={saveVendorRecord}
                />
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
                <span className="eyebrow">Vendor Arena</span>
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
                onDraftChange={setVendorCategoryDraft}
                onStartEdit={openVendorCategoryEditor}
                onCancelEdit={cancelVendorCategoryEdit}
                onSave={saveVendorCategory}
                onDelete={deleteVendorCategory}
              />
            </section>
          </section>
        ) : activeSection === "Sub Category" ? (
          <section className="association-workspace">
            <section className="association-header">
              <div>
                <span className="eyebrow">Vendor Arena</span>
                <h1>Sub Category</h1>
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
                    <span>Visible Sub Categories</span>
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
                <span className="eyebrow">Vendor Arena</span>
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
                <span className="eyebrow">Vendor Arena</span>
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
        ) : activeSection === "Events Arena" ? (
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
                eventTimelineGroups={eventTimelineData}
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
                <span className="eyebrow">Events Arena</span>
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
        ) : activeSection === "Admin arena" ? (
          <section className="association-workspace">
            <section className="association-header">
              <div>
                <span className="eyebrow">Admin Arena</span>
                <h1>{activeAdminAccessSection}</h1>
                <p>
                  Open the selected access area here and configure permissions
                  in the main workspace.
                </p>
              </div>

              <div className="association-header-meta">
                <div className="association-dashboard-grid">
                  <article className="association-dashboard-card">
                    <strong>4</strong>
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

                  <div className="profile-action-row">
                    <button
                      className="primary-link admin-action-button"
                      type="button"
                    >
                      Save App Access
                    </button>
                  </div>
                </article>
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
                  onToggleAdminRole={toggleMemberAdminRole}
                  updatingAdminUserIds={updatingAdminUserIds}
                />
              ) : activeAdminAccessSection === "Vendor Access" ? (
                <AdminVendorAccessPanel
                  items={filteredAdminVendors}
                  activeView={adminVendorAccessView}
                  searchQuery={adminVendorSearch}
                  selectedIds={selectedAdminVendors}
                  selectedVendorIds={selectedContentVendorIds}
                  vendorSearchMatches={filteredAdminVendors}
                  filteredPosts={filteredVendorContentPosts}
                  contentPostEdits={vendorContentPostEdits}
                  onSearchChange={setAdminVendorSearch}
                  onViewChange={setAdminVendorAccessView}
                  onToggleSelect={toggleSelectAdminVendor}
                  onToggleSelectAll={toggleSelectAllAdminVendors}
                  onToggleVendor={toggleContentVendor}
                  onUpdateContentPost={updateVendorContentPost}
                  onApplyAccessStatus={applyBulkVendorAccessStatus}
                  onSaveVendorAccessChanges={saveVendorAccessChanges}
                />
              ) : activeAdminAccessSection === "Timeline Access" ? (
                <AdminTimelineAccessPanel
                  items={filteredAdminTimelinePosts}
                  searchQuery={adminTimelineSearch}
                  edits={timelineAccessEdits}
                  onSearchChange={setAdminTimelineSearch}
                  onUpdatePost={updateTimelineAccessPost}
                  onSaveTimelineAccessChanges={saveTimelineAccessChanges}
                />
              ) : activeAdminAccessSection === "App Banner Access" ? (
                <AdminAppBannerAccessPanel
                  items={adminAppBannerItems}
                  searchQuery={adminAppBannerSearch}
                  edits={appBannerAccessEdits}
                  onSearchChange={setAdminAppBannerSearch}
                  onUpdateBanner={updateAppBannerAccessItem}
                  onSaveAppBannerAccessChanges={saveAppBannerAccessChanges}
                />
              ) : activeAdminAccessSection === "Add Bulk Member" ? (
                <AdminBulkMemberPanel
                  selectedFile={bulkMemberFile}
                  isUploading={isBulkMemberUploading}
                  errorMessage={bulkMemberError}
                  result={bulkMemberResult}
                  onFileChange={(file) => {
                    setBulkMemberFile(file);
                    setBulkMemberError("");
                  }}
                  onUpload={uploadBulkMembers}
                />
              ) : activeAdminAccessSection === "Event Access" ? (
                <AdminEventAccessPanel
                  items={filteredAdminEvents}
                  searchQuery={adminEventSearch}
                  formData={eventForm}
                  mediaState={eventMedia}
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
