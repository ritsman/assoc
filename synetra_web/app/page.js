"use client";

import Link from "next/link";
import { useState } from "react";

const navSections = [
  {
    label: "Dashboard",
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
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
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
        <circle cx="9" cy="8" r="3" />
        <path d="M4.5 18c.9-2.8 3-4.2 6-4.2s5.1 1.4 6 4.2" />
        <path d="M16.5 9.5c.7-.8 1.6-1.2 2.8-1.2 1.7 0 3.1 1 3.7 2.7" />
      </svg>
    ),
  },
  {
    label: "Association arena",
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
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
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
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
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
        <path d="M4 7.5 12 4l8 3.5-8 3.5L4 7.5Z" />
        <path d="M4 12l8 3.5 8-3.5" />
        <path d="M4 16.5 12 20l8-3.5" />
      </svg>
    ),
  },
  {
    label: "Events Arena",
    icon: (
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
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

const adminAccessSections = ["App Access", "Member Access", "Vendor Access"];
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
const eventTimelineGroups = [
  {
    title: "Past Events",
    tone: "tone-gallery",
    items: [
      {
        id: "event-past-1",
        title: "Annual Manufacturing Meet 2025",
        meta: "Hosted in Ahmedabad with 420 attendees and 18 vendor showcases.",
        badge: "Past",
      },
      {
        id: "event-past-2",
        title: "Safety Workshop Series",
        meta: "Three-city workshop completed for plant supervisors and line managers.",
        badge: "Past",
      },
    ],
  },
  {
    title: "Current Events",
    tone: "tone-circular",
    items: [
      {
        id: "event-current-1",
        title: "Quarterly Technical Training",
        meta: "Live multi-session program for members on automation and process controls.",
        badge: "Current",
      },
      {
        id: "event-current-2",
        title: "Vendor Discovery Week",
        meta: "Running spotlight series featuring preferred vendors and demos.",
        badge: "Current",
      },
    ],
  },
  {
    title: "Coming Events",
    tone: "tone-advertisement",
    items: [
      {
        id: "event-upcoming-1",
        title: "Association Leadership Summit",
        meta: "Scheduled for June 2026 with cross-city committee representation.",
        badge: "Coming",
      },
      {
        id: "event-upcoming-2",
        title: "Industrial Innovation Expo",
        meta: "Upcoming member and vendor networking day with demo booths and talks.",
        badge: "Coming",
      },
    ],
  },
];
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
const initialEventTypeRecords = [
  {
    id: "event-type-1",
    title: "Conference",
    meta: "Large-scale annual and strategic gatherings for members and partners.",
    badge: "Type",
  },
  {
    id: "event-type-2",
    title: "Workshop",
    meta: "Skill-focused sessions for operations, safety, and technical training.",
    badge: "Type",
  },
  {
    id: "event-type-3",
    title: "Expo",
    meta: "Showcase events for vendors, products, member discovery, and networking.",
    badge: "Type",
  },
  {
    id: "event-type-4",
    title: "Seminar",
    meta: "Focused knowledge-sharing sessions with speakers, panels, and discussion rounds.",
    badge: "Type",
  },
  {
    id: "event-type-5",
    title: "Trade Show",
    meta: "Business-facing networking and product visibility events for industry partners.",
    badge: "Type",
  },
  {
    id: "event-type-6",
    title: "Exhibition",
    meta: "Display-led event format for products, member showcases, and association initiatives.",
    badge: "Type",
  },
  {
    id: "event-type-7",
    title: "Online Seminar",
    meta: "Virtual seminar format for remote participation, live sessions, and digital Q and A.",
    badge: "Type",
  },
];

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
  "All Members",
  "Primary Members",
  "Associate Members",
  "Temporary Visitors",
  "Committee Members",
];
const vendorArenaTabs = ["Registration", "Membership & Payment", "Master"];
const eventsArenaTabs = ["Master", "Create New Event", "Type of Event", "Event"];
const initialCreatedEvents = [
  {
    id: "created-event-1",
    name: "Quarterly Technical Training",
    type: "Workshop",
    audience: "Primary Members",
    entryType: "Paid",
    entryCharges: "Rs. 1,500",
    participationCharges: "Rs. 2,500",
    date: "2026-05-14",
    venue: "Association Hall, Ahmedabad",
    startTime: "10:00",
    endTime: "16:00",
    summary: "Hands-on training program covering automation, process checks, and plant safety.",
    imageName: "technical-training-banner.jpg",
    videoName: "technical-training-intro.mp4",
    liveStatus: "Scheduled",
    scheduledGoLive: "2026-05-01",
  },
  {
    id: "created-event-2",
    name: "Industrial Innovation Expo",
    type: "Exhibition",
    audience: "Open for All",
    entryType: "Free",
    entryCharges: "Rs. 0",
    participationCharges: "Rs. 5,000",
    date: "2026-06-22",
    venue: "Expo Grounds, Pune",
    startTime: "09:30",
    endTime: "18:00",
    summary: "Member and vendor expo with product showcases, networking zones, and technical sessions.",
    imageName: "innovation-expo-banner.jpg",
    videoName: "",
    liveStatus: "Live",
    scheduledGoLive: "",
  },
];

const memberRecords = [
  {
    id: "member-1",
    name: "Aarav Mehta",
    company: "Mehta Industrial Systems",
    address: "14 Ashram Road, Ahmedabad",
    phone: "+91 98765 10001",
    whatsapp: "919876510001",
    email: "aarav@mehtaindustrial.com",
    membershipType: "Committee",
    membershipPeriod: "Apr 2023 - Mar 2027",
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
    phone: "+91 98765 10002",
    whatsapp: "919876510002",
    email: "nisha@raoengineers.com",
    membershipType: "Committee",
    membershipPeriod: "Apr 2024 - Mar 2027",
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
    phone: "+91 98765 10003",
    whatsapp: "919876510003",
    email: "kunal@sethifab.com",
    membershipType: "Primary",
    membershipPeriod: "Jan 2022 - Dec 2026",
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
    phone: "+91 98765 10004",
    whatsapp: "919876510004",
    email: "rhea@patelprecision.com",
    membershipType: "Primary",
    membershipPeriod: "Jul 2021 - Jun 2026",
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
    phone: "+91 98765 10005",
    whatsapp: "919876510005",
    email: "dev@khannaauto.in",
    membershipType: "Associate",
    membershipPeriod: "Apr 2025 - Mar 2026",
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
    phone: "+91 98765 10006",
    whatsapp: "919876510006",
    email: "ira@joshitoolcraft.com",
    membershipType: "Associate",
    membershipPeriod: "Apr 2024 - Mar 2026",
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
    phone: "+91 98765 10007",
    whatsapp: "919876510007",
    email: "vikram.visitor@example.com",
    membershipType: "Temporary Visit",
    membershipPeriod: "Valid until 30 Apr 2026",
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
    phone: "+91 98765 10008",
    whatsapp: "919876510008",
    email: "maya.visitor@example.com",
    membershipType: "Temporary Visit",
    membershipPeriod: "Valid until 12 May 2026",
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
const vendorSummaryStats = [
  { value: "126", label: "Registered Vendors" },
  { value: "84", label: "Active" },
  { value: "21", label: "Suspended" },
  { value: "21", label: "Lapsed" },
];
const memberContentPosts = [
  {
    id: "post-1",
    memberId: "member-3",
    title: "Automation Upgrade Showcase",
    summary: "A short banner update on the shop-floor automation rollout and performance gains.",
    status: "Approved",
    postedBy: "Kunal Sethi",
    postedOn: "20 Apr 2026",
    displayPeriod: "20 Apr 2026 - 10 May 2026",
    displayStart: "2026-04-20",
    displayEnd: "2026-05-10",
    badge: "Banner",
  },
  {
    id: "post-2",
    memberId: "member-4",
    title: "Precision Casting Process Note",
    summary: "Article snippet about process controls, sampling, and traceability improvements.",
    status: "Rejected",
    postedBy: "Rhea Patel",
    postedOn: "19 Apr 2026",
    displayPeriod: "Rejected",
    displayStart: "2026-04-19",
    displayEnd: "2026-04-25",
    badge: "Article",
  },
  {
    id: "post-3",
    memberId: "member-5",
    title: "Associate Partner Training Invite",
    summary: "Promotional banner for the upcoming technical workshop open to associate members.",
    status: "Approved",
    postedBy: "Dev Khanna",
    postedOn: "18 Apr 2026",
    displayPeriod: "18 Apr 2026 - 28 Apr 2026",
    displayStart: "2026-04-18",
    displayEnd: "2026-04-28",
    badge: "Banner",
  },
  {
    id: "post-4",
    memberId: "member-1",
    title: "Chairman Message For Members",
    summary: "Short article introducing the next quarter priorities for the community and vendors.",
    status: "Approved",
    postedBy: "Aarav Mehta",
    postedOn: "17 Apr 2026",
    displayPeriod: "17 Apr 2026 - 30 Apr 2026",
    displayStart: "2026-04-17",
    displayEnd: "2026-04-30",
    badge: "Article",
  },
];
const vendorRecords = [
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
const vendorContentPosts = [
  {
    id: "vendor-post-1",
    vendorId: "vendor-1",
    title: "High Precision CNC Package",
    summary: "Short-form ad banner promoting a new CNC bundle for association members.",
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
    summary: "Short article-style ad for digital transformation onboarding and implementation support.",
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
    summary: "Guest-facing ad campaign offering early registration for the next fabrication expo.",
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
    "Primary Members": allMembers.filter((member) => member.group === "Primary Members"),
    "Associate Members": allMembers.filter((member) => member.group === "Associate Members"),
    "Temporary Visitors": allMembers.filter((member) => member.group === "Temporary Visitors"),
    "Committee Members": allMembers.filter((member) => member.group === "Committee Members"),
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

const initialMemberTabData = buildMemberTabData(memberRecords);

function CarouselSection({ title, items, tone, compact = false }) {
  const carouselItems = compact ? [...items, ...items] : items;

  return (
    <section className={`welcome-panel ${compact ? "welcome-panel-compact" : ""}`}>
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
                <span>{String((index % items.length) + 1).padStart(2, "0")}</span>
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
                <span>{member.initials}</span>
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
            <input type="checkbox" checked={allSelected} onChange={onToggleSelectAll} />
            <span>Select multiple</span>
          </label>
          <button className="secondary-link secondary-button" type="button" onClick={onDeleteSelected}>
            Delete Selected
          </button>
          <button className="primary-link admin-action-button" type="button" onClick={onAddNew}>
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
            <input type="date" value={dateFrom} onChange={(event) => onDateFromChange(event.target.value)} />
          </label>
          <label className="content-control-field">
            <span>To Date</span>
            <input type="date" value={dateTo} onChange={(event) => onDateToChange(event.target.value)} />
          </label>
          <label className="content-control-field">
            <span>Entry Type</span>
            <select value={filterType} onChange={(event) => onFilterTypeChange(event.target.value)}>
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
                    <span className="access-status-chip">{entry.direction}</span>
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
            activeTab={activeTab === "Finance" ? `Finance · ${activeFinanceTab}` : activeTab}
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
        <p>CRUD and communication controls are kept behind an admin flag for future auth roles.</p>
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
                <button type="button" onClick={() => onApplyReminderFilter("expiring-soon")}>
                  Expiring Soon
                </button>
                <button type="button" onClick={() => onApplyReminderFilter("Temporary Visitors")}>
                  Temporary Visitors
                </button>
                <button type="button" onClick={() => onApplyReminderFilter("Primary Members")}>
                  Primary Members
                </button>
                <button type="button" onClick={() => onApplyReminderFilter("Associate Members")}>
                  Associate Members
                </button>
                <button type="button" onClick={() => onApplyReminderFilter("Committee Members")}>
                  Committee Members
                </button>
              </div>
            ) : null}
          </div>
          <label className="selection-chip">
            <input type="checkbox" checked={allSelected} onChange={onToggleSelectAll} />
            <span>Select multiple</span>
          </label>
          <button className="secondary-link secondary-button" type="button" onClick={onContactSelected}>
            Contact
          </button>
          <button className="secondary-link secondary-button" type="button" onClick={onSendNotice}>
            Send Notice
          </button>
          <button className="secondary-link secondary-button" type="button" onClick={onDeleteSelected}>
            Delete Selected
          </button>
          <button className="primary-link admin-action-button" type="button" onClick={onAddNew}>
            Add Member
          </button>
        </div>
      ) : null}
    </div>
  );
}

function MemberCardGrid({ items, selectedIds, isAdmin, onToggleSelect, onDeleteOne }) {
  return (
    <div className="member-record-grid">
      {items.map((member) => (
        <article key={member.id} className="member-record-card">
          <div className="member-record-head">
            <div className="member-record-photo">
              <span>{member.initials}</span>
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
            <a className="secondary-link" href={`https://wa.me/${member.whatsapp}`} target="_blank" rel="noreferrer">
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
                  member.expiryStatus === "expiring-soon" ? "member-row-expiring" : "member-row-active"
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
                      <span className="expiry-chip expiry-chip-active">Active</span>
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
                  <a className="table-action-link" href={`https://wa.me/${member.whatsapp}`} target="_blank" rel="noreferrer">
                    Open Chat
                  </a>
                </td>
                <td>
                  {member.expiryStatus === "expiring-soon" ? (
                    <button className="secondary-link secondary-button table-button reminder-button" type="button">
                      Send Reminder
                    </button>
                  ) : (
                    <button className="secondary-link secondary-button table-button" type="button">
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
  selectedIds,
  isReminderPanelOpen,
  onToggleReminderPanel,
  onApplyReminderFilter,
  onToggleSelect,
  onToggleSelectAll,
  onDeleteSelected,
  onDeleteOne,
  onAddNew,
}) {
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
        onAddNew={onAddNew}
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
            <span className="access-status-chip">{vendor.registrationStatus}</span>
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
            <a className="secondary-link" href={`https://wa.me/${vendor.whatsapp}`} target="_blank" rel="noreferrer">
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
                  <span className="access-status-chip">{vendor.registrationStatus}</span>
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
        <article key={vendor.id} className="association-record-card tone-advertisement">
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
                  <span className="access-status-chip">{vendor.paymentStatus}</span>
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

function VendorRegistrationForm({ formData, onChange, categories, newCategory, onNewCategoryChange, onAddCategory }) {
  return (
    <section className="member-table-panel">
      <div className="panel-topline">
        <h2>Vendor Registration Form</h2>
        <span className="mini-label">Master</span>
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
        <button className="secondary-link secondary-button" type="button" onClick={onAddCategory}>
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
          <span>Vendor Name</span>
          <input
            type="text"
            value={formData.name}
            onChange={(event) => onChange("name", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Company Name</span>
          <input
            type="text"
            value={formData.company}
            onChange={(event) => onChange("company", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Vendor Type</span>
          <input
            type="text"
            value={formData.vendorType}
            onChange={(event) => onChange("vendorType", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Category</span>
          <select value={formData.category} onChange={(event) => onChange("category", event.target.value)}>
            <option value="">Select category</option>
            {categories.map((category) => (
              <option key={category} value={category}>
                {category}
              </option>
            ))}
          </select>
        </label>
        <label className="profile-field">
          <span>Contact Person</span>
          <input
            type="text"
            value={formData.contactPerson}
            onChange={(event) => onChange("contactPerson", event.target.value)}
          />
        </label>
        <label className="profile-field profile-field-wide">
          <span>Address</span>
          <textarea
            rows="3"
            value={formData.address}
            onChange={(event) => onChange("address", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>City</span>
          <input
            type="text"
            value={formData.city}
            onChange={(event) => onChange("city", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Phone</span>
          <input
            type="text"
            value={formData.phone}
            onChange={(event) => onChange("phone", event.target.value)}
          />
        </label>
        <label className="profile-field">
          <span>Email</span>
          <input
            type="email"
            value={formData.email}
            onChange={(event) => onChange("email", event.target.value)}
          />
        </label>
      </div>

      <div className="profile-action-row">
        <button className="primary-link admin-action-button" type="button">
          Submit Vendor Registration
        </button>
      </div>
    </section>
  );
}

function VendorArenaContent({
  activeTab,
  items,
  formData,
  categories,
  newCategory,
  filterState,
  onFormChange,
  onFilterChange,
  onNewCategoryChange,
  onAddCategory,
}) {
  const filteredItems = items.filter((vendor) => {
    const matchesName =
      !filterState.name || `${vendor.name} ${vendor.company}`.toLowerCase().includes(filterState.name.toLowerCase());
    const matchesCategory = !filterState.category || vendor.category === filterState.category;
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
                onChange={(event) => onFilterChange("category", event.target.value)}
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
              <select value={filterState.city} onChange={(event) => onFilterChange("city", event.target.value)}>
                <option value="">All Cities</option>
                {[...new Set(items.map((vendor) => vendor.city))].map((city) => (
                  <option key={city} value={city}>
                    {city}
                  </option>
                ))}
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
        newCategory={newCategory}
        onNewCategoryChange={onNewCategoryChange}
        onAddCategory={onAddCategory}
      />
    </section>
  );
}

function EventTimelineCards() {
  return (
    <div className="association-record-grid">
      {eventTimelineGroups.map((group) => (
        <article key={group.title} className={`association-record-card ${group.tone}`}>
          <div className="association-record-visual">
            <span>{group.title.split(" ")[0]}</span>
          </div>
          <div className="association-record-copy">
            <div className="association-record-topline">
              <em className="carousel-badge">{group.title}</em>
            </div>
            {group.items.map((item) => (
              <div key={item.id} className="event-card-entry">
                <strong>{item.title}</strong>
                <p>{item.meta}</p>
              </div>
            ))}
          </div>
        </article>
      ))}
    </div>
  );
}

function EventCreateForm({ formData, mediaState, onChange, onMediaChange }) {
  return (
    <section className="member-table-panel">
      <div className="panel-topline">
        <h2>Create New Event</h2>
        <span className="mini-label">Event Setup</span>
      </div>

      <div className="profile-form-grid">
        <label className="profile-field">
          <span>Event Name</span>
          <input type="text" value={formData.name} onChange={(event) => onChange("name", event.target.value)} />
        </label>
        <label className="profile-field">
          <span>Type of Event</span>
          <input type="text" value={formData.type} onChange={(event) => onChange("type", event.target.value)} />
        </label>
        <label className="profile-field">
          <span>Audience</span>
          <select value={formData.audience} onChange={(event) => onChange("audience", event.target.value)}>
            <option value="">Select audience</option>
            <option value="Primary Members">Primary Members</option>
            <option value="Associate Members">Associate Members</option>
            <option value="Guest">Guest</option>
            <option value="Open for All">Open for All</option>
          </select>
        </label>
        <label className="profile-field">
          <span>Entry Type</span>
          <select value={formData.entryType} onChange={(event) => onChange("entryType", event.target.value)}>
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
            onChange={(event) => onChange("participationCharges", event.target.value)}
            placeholder="Rs. 0 or participation fee"
          />
        </label>
        <label className="profile-field">
          <span>Event Date</span>
          <input type="date" value={formData.date} onChange={(event) => onChange("date", event.target.value)} />
        </label>
        <label className="profile-field">
          <span>Venue</span>
          <input type="text" value={formData.venue} onChange={(event) => onChange("venue", event.target.value)} />
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
            onChange={(event) => onMediaChange("imageName", event.target.files?.[0]?.name ?? "")}
          />
        </label>
        <label className="profile-field profile-field-wide">
          <span>Event Promo Video</span>
          <input
            type="file"
            accept="video/*"
            onChange={(event) => onMediaChange("videoName", event.target.files?.[0]?.name ?? "")}
          />
        </label>
      </div>

      <div className="content-member-selector">
        {mediaState.imageName ? <span className="content-member-chip active">Image: {mediaState.imageName}</span> : null}
        {mediaState.videoName ? <span className="content-member-chip active">Video: {mediaState.videoName}</span> : null}
      </div>

      <div className="profile-action-row">
        <button className="primary-link admin-action-button" type="button">
          Save Event Draft
        </button>
      </div>
    </section>
  );
}

function EventTypeManager({ items, draftType, onDraftChange, onAddType, onUpdateType }) {
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
          <button className="secondary-link secondary-button" type="button" onClick={onAddType}>
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
                    onChange={(event) => onUpdateType(item.id, "title", event.target.value)}
                  />
                </label>
                <label className="content-control-field">
                  <span>Description</span>
                  <input
                    type="text"
                    value={item.meta}
                    onChange={(event) => onUpdateType(item.id, "meta", event.target.value)}
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
  onFormChange,
  onMediaChange,
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

  return (
    <section className="association-tab-section">
      <EventCreateForm
        formData={formData}
        mediaState={mediaState}
        onChange={onFormChange}
        onMediaChange={onMediaChange}
      />
    </section>
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
  onUpdateContentPost,
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
              <input type="checkbox" checked={allSelected} onChange={onToggleSelectAll} />
              <span>Select filtered</span>
            </label>
            <button className="secondary-link secondary-button" type="button">
              Restrict App Usage
            </button>
            <button className="secondary-link secondary-button" type="button">
              Suspend Access
            </button>
            <button className="secondary-link secondary-button danger-button" type="button">
              Remove App Usage
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
                      <span className="access-status-chip">{member.appAccessStatus}</span>
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
                    <span>Status: {contentPostEdits[post.id]?.status ?? post.status}</span>
                    <span>
                      Display:{" "}
                      {(contentPostEdits[post.id]?.displayStart ?? post.displayStart) &&
                      (contentPostEdits[post.id]?.displayEnd ?? post.displayEnd)
                        ? `${contentPostEdits[post.id]?.displayStart ?? post.displayStart} to ${
                            contentPostEdits[post.id]?.displayEnd ?? post.displayEnd
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
                          onUpdateContentPost(post.id, "status", event.target.value)
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
                        value={contentPostEdits[post.id]?.displayStart ?? post.displayStart}
                        onChange={(event) =>
                          onUpdateContentPost(post.id, "displayStart", event.target.value)
                        }
                      />
                    </label>
                    <label className="content-control-field">
                      <span>Display End</span>
                      <input
                        type="date"
                        value={contentPostEdits[post.id]?.displayEnd ?? post.displayEnd}
                        onChange={(event) =>
                          onUpdateContentPost(post.id, "displayEnd", event.target.value)
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
                <p>Select one or more members above to review content intended for the Flutter app.</p>
              </article>
            ) : null}
          </div>
        </>
      )}

      <div className="profile-action-row">
        <button className="primary-link admin-action-button" type="button">
          {activeView === "app" ? "Save Member Access Changes" : "Save Content Access Changes"}
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
              <input type="checkbox" checked={allSelected} onChange={onToggleSelectAll} />
              <span>Select filtered</span>
            </label>
            <button className="secondary-link secondary-button" type="button">
              Restrict App Usage
            </button>
            <button className="secondary-link secondary-button" type="button">
              Suspend Access
            </button>
            <button className="secondary-link secondary-button danger-button" type="button">
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
                      <span className="access-status-chip">{vendor.appAccessStatus}</span>
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
                    <span>Status: {contentPostEdits[post.id]?.status ?? post.status}</span>
                    <span>
                      Display:{" "}
                      {(contentPostEdits[post.id]?.displayStart ?? post.displayStart) &&
                      (contentPostEdits[post.id]?.displayEnd ?? post.displayEnd)
                        ? `${contentPostEdits[post.id]?.displayStart ?? post.displayStart} to ${
                            contentPostEdits[post.id]?.displayEnd ?? post.displayEnd
                          }`
                        : post.displayPeriod}
                    </span>
                  </div>
                  <div className="member-content-controls">
                    <label className="content-control-field">
                      <span>Status</span>
                      <select
                        value={contentPostEdits[post.id]?.status ?? post.status}
                        onChange={(event) => onUpdateContentPost(post.id, "status", event.target.value)}
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
                        value={contentPostEdits[post.id]?.displayStart ?? post.displayStart}
                        onChange={(event) =>
                          onUpdateContentPost(post.id, "displayStart", event.target.value)
                        }
                      />
                    </label>
                    <label className="content-control-field">
                      <span>Display End</span>
                      <input
                        type="date"
                        value={contentPostEdits[post.id]?.displayEnd ?? post.displayEnd}
                        onChange={(event) =>
                          onUpdateContentPost(post.id, "displayEnd", event.target.value)
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
                <p>Select one or more vendors above to review ad content intended for the Flutter app.</p>
              </article>
            ) : null}
          </div>
        </>
      )}

      <div className="profile-action-row">
        <button className="primary-link admin-action-button" type="button">
          {activeView === "app" ? "Save Vendor Access Changes" : "Save Vendor Content Changes"}
        </button>
      </div>
    </article>
  );
}

export default function HomePage() {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [activeSection, setActiveSection] = useState("Association arena");
  const [activeAssociationTab, setActiveAssociationTab] = useState("Profile");
  const [activeFinanceTab, setActiveFinanceTab] = useState("Income");
  const [activeEventsTab, setActiveEventsTab] = useState("Master");
  const [financeStatementFilterType, setFinanceStatementFilterType] = useState("");
  const [financeStatementDateFrom, setFinanceStatementDateFrom] = useState("");
  const [financeStatementDateTo, setFinanceStatementDateTo] = useState("");
  const [activeMemberTab, setActiveMemberTab] = useState("All Members");
  const [activeVendorTab, setActiveVendorTab] = useState("Registration");
  const [isAdminAccessOpen, setIsAdminAccessOpen] = useState(true);
  const [activeAdminAccessSection, setActiveAdminAccessSection] = useState("App Access");
  const [appPermissions, setAppPermissions] = useState({
    approveMembersLogin: true,
    disableScreenshots: false,
    approveMembership: true,
    approveRegistrationRequest: true,
    disableAdminFunctionsFromApp: false,
  });
  const [associationTabData, setAssociationTabData] = useState(initialAssociationTabData);
  const [memberTabData, setMemberTabData] = useState(initialMemberTabData);
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
  const [selectedContentMemberIds, setSelectedContentMemberIds] = useState([]);
  const [adminVendorSearch, setAdminVendorSearch] = useState("");
  const [adminVendorAccessView, setAdminVendorAccessView] = useState("app");
  const [selectedAdminVendors, setSelectedAdminVendors] = useState([]);
  const [selectedContentVendorIds, setSelectedContentVendorIds] = useState([]);
  const [contentPostEdits, setContentPostEdits] = useState(
    Object.fromEntries(
      memberContentPosts.map((post) => [
        post.id,
        {
          status: post.status,
          displayStart: post.displayStart,
          displayEnd: post.displayEnd,
        },
      ]),
    ),
  );
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
    name: "",
    company: "",
    vendorType: "",
    category: "",
    contactPerson: "",
    address: "",
    city: "",
    phone: "",
    email: "",
  });
  const [vendorCategories, setVendorCategories] = useState(initialVendorCategories);
  const [newVendorCategory, setNewVendorCategory] = useState("");
  const [vendorFilters, setVendorFilters] = useState({
    name: "",
    category: "",
    city: "",
  });
  const [eventForm, setEventForm] = useState({
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
  });
  const [eventMedia, setEventMedia] = useState({
    imageName: "",
    videoName: "",
  });
  const [eventTypes, setEventTypes] = useState(initialEventTypeRecords);
  const [eventTypeDraft, setEventTypeDraft] = useState({
    title: "",
    meta: "",
  });
  const isAssociationAdmin = true;
  const isMemberAdmin = true;

  const filteredFinanceStatementEntries = financeStatementEntries.filter((entry) => {
    const matchesType = !financeStatementFilterType || entry.entryType === financeStatementFilterType || entry.direction === financeStatementFilterType;
    const matchesFrom = !financeStatementDateFrom || entry.date >= financeStatementDateFrom;
    const matchesTo = !financeStatementDateTo || entry.date <= financeStatementDateTo;
    return matchesType && matchesFrom && matchesTo;
  });
  const activeTabItems =
    activeAssociationTab === "Finance"
      ? financeRecords[activeFinanceTab] ?? []
      : associationTabData[activeAssociationTab] ?? [];
  const activeSelectedIds =
    activeAssociationTab === "Finance" ? [] : selectedRecords[activeAssociationTab] ?? [];
  const activeMemberItems = memberTabData[activeMemberTab] ?? [];
  const activeMemberSelectedIds = selectedMemberRecords[activeMemberTab] ?? [];
  const expiringMembersCount = (memberTabData["All Members"] ?? []).filter(
    (member) => member.expiryStatus === "expiring-soon",
  ).length;
  const filteredAdminMembers = (memberTabData["All Members"] ?? []).filter((member) => {
    const query = adminMemberSearch.trim().toLowerCase();
    const matchesFilter =
      activeAdminMemberFilter === "All"
        ? ["Primary", "Associate", "Temporary Visit", "Committee"].includes(member.membershipType)
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

    return (
      `${member.name} ${member.company} ${member.membershipType}`.toLowerCase().includes(query)
    );
  });
  const contentMemberMatches = (memberTabData["All Members"] ?? []).filter((member) => {
    const query = adminContentMemberSearch.trim().toLowerCase();
    if (!query) {
      return true;
    }

    return `${member.name} ${member.company}`.toLowerCase().includes(query);
  });
  const filteredMemberContentPosts = memberContentPosts.filter((post) => {
    const query = adminContentMemberSearch.trim().toLowerCase();
    const postStatus = (contentPostEdits[post.id]?.status ?? post.status).toLowerCase();
    const matchesQuery =
      !query ||
      `${post.title} ${post.summary} ${post.postedBy} ${postStatus}`.toLowerCase().includes(query);

    if (!matchesQuery) {
      return false;
    }

    if (selectedContentMemberIds.length === 0) {
      return true;
    }

    return selectedContentMemberIds.includes(post.memberId);
  });
  const filteredAdminVendors = vendorRecords.filter((vendor) => {
    const query = adminVendorSearch.trim().toLowerCase();
    if (!query) {
      return true;
    }

    return `${vendor.name} ${vendor.company} ${vendor.vendorType}`.toLowerCase().includes(query);
  });
  const filteredVendorContentPosts = vendorContentPosts.filter((post) => {
    const query = adminVendorSearch.trim().toLowerCase();
    const postStatus = (vendorContentPostEdits[post.id]?.status ?? post.status).toLowerCase();
    const matchesQuery =
      !query ||
      `${post.title} ${post.summary} ${post.postedBy} ${postStatus}`.toLowerCase().includes(query);

    if (!matchesQuery) {
      return false;
    }

    if (selectedContentVendorIds.length === 0) {
      return true;
    }

    return selectedContentVendorIds.includes(post.vendorId);
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
      [tab]: (current[tab] ?? []).filter((item) => !selectedIds.includes(item.id)),
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
      buildMemberTabData((current["All Members"] ?? []).filter((item) => !selectedIds.includes(item.id))),
    );

    setSelectedMemberRecords(Object.fromEntries(memberArenaTabs.map((memberTab) => [memberTab, []])));
  };

  const deleteSingleMemberRecord = (tab, recordId) => {
    setMemberTabData((current) =>
      buildMemberTabData((current["All Members"] ?? []).filter((item) => item.id !== recordId)),
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

  const addNewMemberRecord = (tab) => {
    const count = (memberTabData[tab] ?? []).length + 1;
    const draftMember = {
      id: `member-draft-${Date.now()}`,
      name: `Draft Member ${count}`,
      company: "New Company Name",
      address: "Draft address",
      phone: "+91 90000 00000",
      whatsapp: "919000000000",
      email: "draft.member@example.com",
      membershipType: tab === "All Members" ? "Primary" : tab.replace(" Members", ""),
      membershipPeriod: "Draft period",
      badge: "Draft",
      initials: "DM",
      group: tab === "All Members" ? "Primary Members" : tab,
    };

    setMemberTabData((current) => buildMemberTabData([draftMember, ...(current["All Members"] ?? [])]));
  };

  const toggleAdminMemberSelect = (memberId) => {
    setSelectedAdminMembers((current) =>
      current.includes(memberId) ? current.filter((id) => id !== memberId) : [...current, memberId],
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
      current.includes(memberId) ? current.filter((id) => id !== memberId) : [...current, memberId],
    );
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
  const toggleSelectAdminVendor = (vendorId) => {
    setSelectedAdminVendors((current) =>
      current.includes(vendorId) ? current.filter((id) => id !== vendorId) : [...current, vendorId],
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
      current.includes(vendorId) ? current.filter((id) => id !== vendorId) : [...current, vendorId],
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
    setVendorRegistrationForm((current) => ({
      ...current,
      [field]: value,
    }));
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
    setNewVendorCategory("");
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
      [field]: value,
    }));
  };
  const updateEventTypeDraft = (field, value) => {
    setEventTypeDraft((current) => ({
      ...current,
      [field]: value,
    }));
  };
  const addEventType = () => {
    const title = eventTypeDraft.title.trim();
    const meta = eventTypeDraft.meta.trim();
    if (!title || !meta) {
      return;
    }

    setEventTypes((current) => [
      ...current,
      {
        id: `event-type-${Date.now()}`,
        title,
        meta,
        badge: "Type",
      },
    ]);
    setEventTypeDraft({ title: "", meta: "" });
  };
  const updateEventType = (eventTypeId, field, value) => {
    setEventTypes((current) =>
      current.map((item) => (item.id === eventTypeId ? { ...item, [field]: value } : item)),
    );
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

  return (
    <main className={`admin-shell ${isSidebarOpen ? "sidebar-open" : "sidebar-collapsed"}`}>
      <aside className={`sidebar ${isSidebarOpen ? "" : "is-collapsed"}`}>
        <div className="sidebar-brand">
          <span className="brand-mark">S</span>
          <div className={`sidebar-brand-copy ${isSidebarOpen ? "" : "is-hidden"}`}>
            <strong>Synetra</strong>
            <p>Association 1</p>
          </div>
        </div>

        <nav className="sidebar-nav" aria-label="Sidebar">
          {navSections.map((item) => (
            <div key={item.label} className="sidebar-nav-group">
              <button
                type="button"
                className={`nav-item ${item.label === activeSection ? "active" : ""} ${
                  isSidebarOpen ? "" : "is-icon-mode"
                }`}
                onClick={() => {
                  setActiveSection(item.label);
                  if (item.label === "Admin arena") {
                    setIsAdminAccessOpen((current) => !current);
                  }
                }}
              >
                <span className="nav-icon" aria-hidden="true">
                  {item.icon}
                </span>
                <span className={`nav-label ${isSidebarOpen ? "" : "is-hidden"}`}>
                  {item.label}
                </span>
                {item.label === "Admin arena" && isSidebarOpen ? (
                  <span className="nav-accordion-indicator" aria-hidden="true">
                    {isAdminAccessOpen ? "−" : "+"}
                  </span>
                ) : null}
              </button>

              {item.label === "Admin arena" && isSidebarOpen && isAdminAccessOpen ? (
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
                          <span className="sidebar-subnav-active-dot" aria-hidden="true" />
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
          <p>One logged-in admin inside one association only.</p>
        </div>
      </aside>

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
            <button className="icon-chip" type="button" aria-label="Unread notifications">
              <span className="icon-chip-symbol">!</span>
              <span className="icon-chip-count">3</span>
            </button>

            <Link className="text-link top-link" href="#">
              Logout
            </Link>

            <Link className="avatar-link" href="/profile" aria-label="Open profile settings">
              <span className="avatar-circle">AU</span>
              <span className="avatar-edit-badge">Edit</span>
            </Link>
          </div>
        </header>

        {activeSection === "Association arena" ? (
          <section className="association-workspace">
            <div className="association-featured-stack">
              <CarouselSection title="Latest Gallery" items={galleryItems} tone="tone-gallery" compact />
              <CarouselSection
                title="Latest Circulars"
                items={associationTabData.Circulars}
                tone="tone-circular"
                compact
              />
            </div>

            <nav className="association-tabbar" aria-label="Association sections">
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
                isAdmin={activeAssociationTab === "Finance" ? false : isAssociationAdmin}
                tabItems={activeTabItems}
                selectedIds={activeSelectedIds}
                onToggleSelect={(recordId) => toggleSelectRecord(activeAssociationTab, recordId)}
                onToggleSelectAll={() => toggleSelectAllRecords(activeAssociationTab)}
                onDeleteSelected={() => deleteSelectedRecords(activeAssociationTab)}
                onDeleteOne={(recordId) => deleteSingleRecord(activeAssociationTab, recordId)}
                onAddNew={() => addNewRecord(activeAssociationTab)}
                onFinanceTabChange={setActiveFinanceTab}
                onFinanceStatementFilterTypeChange={setFinanceStatementFilterType}
                onFinanceStatementDateFromChange={setFinanceStatementDateFrom}
                onFinanceStatementDateToChange={setFinanceStatementDateTo}
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
                    <article key={item.label} className="association-dashboard-card">
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
                    <div key={member.name} className="committee-avatar-chip" title={member.name}>
                      <span className="committee-avatar">{member.initials}</span>
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
                <p>28 new images added from the manufacturing excellence tour this week.</p>
                <div className="latest-gallery-strip" aria-hidden="true">
                  <span />
                  <span />
                  <span />
                </div>
              </article>
            </section>
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
                    <span className="tab-notification-chip">{expiringMembersCount} expiring</span>
                  ) : null}
                </button>
              ))}
            </nav>

            <div className="association-content">
              <MemberArenaContent
                activeTab={activeMemberTab}
                isAdmin={isMemberAdmin}
                tabItems={activeMemberItems}
                selectedIds={activeMemberSelectedIds}
                isReminderPanelOpen={isReminderPanelOpen}
                onToggleReminderPanel={() => setIsReminderPanelOpen((current) => !current)}
                onApplyReminderFilter={applyReminderFilter}
                onToggleSelect={(recordId) => toggleSelectMemberRecord(activeMemberTab, recordId)}
                onToggleSelectAll={() => toggleSelectAllMemberRecords(activeMemberTab)}
                onDeleteSelected={() => deleteSelectedMemberRecords(activeMemberTab)}
                onDeleteOne={(recordId) => deleteSingleMemberRecord(activeMemberTab, recordId)}
                onAddNew={() => addNewMemberRecord(activeMemberTab)}
              />
            </div>

            <section className="association-header">
              <div>
                <span className="eyebrow">Member Arena</span>
                <h1>Association Member Directory</h1>
                <p>Member cards, bulk actions, and communication controls in one workspace.</p>
              </div>

              <div className="association-header-meta">
                <div className="association-dashboard-grid">
                  {memberSummaryStats.map((item) => (
                    <article key={item.label} className="association-dashboard-card">
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
        ) : activeSection === "Vendor Arena" ? (
          <section className="association-workspace">
            <div className="association-featured-stack member-featured-stack">
              <MemberCarouselSection
                title="Active Vendors"
                items={vendorRecords.filter((vendor) => vendor.registrationStatus === "Active")}
                tone="tone-gallery"
              />
              <MemberCarouselSection
                title="Suspended Vendors"
                items={vendorRecords.filter((vendor) => vendor.registrationStatus === "Suspended")}
                tone="tone-circular"
              />
              <MemberCarouselSection
                title="Lapsed Vendors"
                items={vendorRecords.filter((vendor) => vendor.registrationStatus === "Lapsed")}
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
                newCategory={newVendorCategory}
                filterState={vendorFilters}
                onFormChange={updateVendorRegistrationForm}
                onFilterChange={updateVendorFilter}
                onNewCategoryChange={setNewVendorCategory}
                onAddCategory={addVendorCategory}
              />
            </div>

            <section className="association-header">
              <div>
                <span className="eyebrow">Vendor Arena</span>
                <h1>Vendor Registration and Access Desk</h1>
                <p>Track vendor lifecycle, payment standing, and new onboarding submissions in one workspace.</p>
              </div>

              <div className="association-header-meta">
                <div className="association-dashboard-grid">
                  {vendorSummaryStats.map((item) => (
                    <article key={item.label} className="association-dashboard-card">
                      <strong>{item.value}</strong>
                      <span>{item.label}</span>
                    </article>
                  ))}
                </div>
              </div>
            </section>
            </section>
        ) : activeSection === "Events Arena" ? (
          <section className="association-workspace">
            <EventTimelineCards />

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
                onFormChange={updateEventForm}
                onMediaChange={updateEventMedia}
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
                <p>Track past, current, and coming events while preparing new programs and event masters.</p>
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
                <p>Open the selected access area here and configure permissions in the main workspace.</p>
              </div>

              <div className="association-header-meta">
                <div className="association-dashboard-grid">
                  <article className="association-dashboard-card">
                    <strong>3</strong>
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
                          <p>Enable or disable this permission for the Flutter app experience.</p>
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
                    <button className="primary-link admin-action-button" type="button">
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
                  onUpdateContentPost={updateContentPost}
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
                />
              ) : (
                <article className="association-empty-state">
                  <span className="mini-label">{activeAdminAccessSection}</span>
                  <h2>{activeAdminAccessSection} configuration will open here.</h2>
                  <p>This keeps the sidebar focused on navigation while the real controls open in the main area.</p>
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
                  This is the post-login home for an admin user. From here we can grow the
                  member, association, vendor, and communication flows without mixing multiple
                  associations.
                </p>
              </div>

              <div className="hero-spotlight">
                <span className="spotlight-label">Today&apos;s focus</span>
                <strong>Onboarding, circular publishing, and vendor visibility.</strong>
                <p>All activity here stays inside the Association 1 tenant scope.</p>
              </div>

              <div className="hero-inline-actions">
                <Link className="secondary-link" href="/parent/associations/new">
                  Add New Association
                </Link>
                <Link className="secondary-link" href="#">
                  Open Profile
                </Link>
              </div>
            </section>

            <div className="welcome-stack">
              <CarouselSection title="Gallery Pictures" items={galleryItems} tone="tone-gallery" />
              <CarouselSection title="Circulars" items={circularItems} tone="tone-circular" />
              <CarouselSection
                title="Advertisements"
                items={advertisementItems}
                tone="tone-advertisement"
              />
            </div>
          </>
        )}
      </section>
    </main>
  );
}
