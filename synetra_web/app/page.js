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
  "Management Committee",
  "Circulars",
  "Gallery",
  "Master",
];

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
  },
];

const memberSummaryStats = [
  { value: "1,284", label: "Total Members" },
  { value: "864", label: "Primary" },
  { value: "312", label: "Associate" },
  { value: "108", label: "Visitors" },
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

function AssociationTabContent({
  activeTab,
  isAdmin,
  tabItems,
  selectedIds,
  onToggleSelect,
  onToggleSelectAll,
  onDeleteSelected,
  onDeleteOne,
  onAddNew,
}) {
  const toneMap = {
    Profile: "tone-circular",
    "About Us": "tone-advertisement",
    "Management Committee": "tone-gallery",
    Circulars: "tone-circular",
    Gallery: "tone-gallery",
    Master: "tone-advertisement",
  };

  return (
    <section className="association-tab-section">
      <AssociationCrudHeader
        activeTab={activeTab}
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

export default function HomePage() {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [activeSection, setActiveSection] = useState("Association arena");
  const [activeAssociationTab, setActiveAssociationTab] = useState("Profile");
  const [activeMemberTab, setActiveMemberTab] = useState("All Members");
  const [associationTabData, setAssociationTabData] = useState(initialAssociationTabData);
  const [memberTabData, setMemberTabData] = useState(initialMemberTabData);
  const [selectedRecords, setSelectedRecords] = useState(
    Object.fromEntries(associationTabs.map((tab) => [tab, []])),
  );
  const [selectedMemberRecords, setSelectedMemberRecords] = useState(
    Object.fromEntries(memberArenaTabs.map((tab) => [tab, []])),
  );
  const [isReminderPanelOpen, setIsReminderPanelOpen] = useState(false);
  const isAssociationAdmin = true;
  const isMemberAdmin = true;

  const activeTabItems = associationTabData[activeAssociationTab] ?? [];
  const activeSelectedIds = selectedRecords[activeAssociationTab] ?? [];
  const activeMemberItems = memberTabData[activeMemberTab] ?? [];
  const activeMemberSelectedIds = selectedMemberRecords[activeMemberTab] ?? [];
  const expiringMembersCount = (memberTabData["All Members"] ?? []).filter(
    (member) => member.expiryStatus === "expiring-soon",
  ).length;

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
            <button
              key={item.label}
              type="button"
              className={`nav-item ${item.label === activeSection ? "active" : ""} ${
                isSidebarOpen ? "" : "is-icon-mode"
              }`}
              onClick={() => setActiveSection(item.label)}
            >
              <span className="nav-icon" aria-hidden="true">
                {item.icon}
              </span>
              <span className={`nav-label ${isSidebarOpen ? "" : "is-hidden"}`}>
                {item.label}
              </span>
            </button>
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

            <div className="association-content">
              <AssociationTabContent
                activeTab={activeAssociationTab}
                isAdmin={isAssociationAdmin}
                tabItems={activeTabItems}
                selectedIds={activeSelectedIds}
                onToggleSelect={(recordId) => toggleSelectRecord(activeAssociationTab, recordId)}
                onToggleSelectAll={() => toggleSelectAllRecords(activeAssociationTab)}
                onDeleteSelected={() => deleteSelectedRecords(activeAssociationTab)}
                onDeleteOne={(recordId) => deleteSingleRecord(activeAssociationTab, recordId)}
                onAddNew={() => addNewRecord(activeAssociationTab)}
              />
            </div>
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
