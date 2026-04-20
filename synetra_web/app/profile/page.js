"use client";

import Link from "next/link";
import { useState } from "react";

const defaultProfile = {
  fullName: "Association User",
  designation: "Association Admin",
  company: "Association 1",
  email: "admin@association1.org",
  phone: "+91 79 4000 2200",
  whatsapp: "+91 98765 10001",
  address: "Industrial Estate Road, Ahmedabad",
  username: "association.admin",
};

export default function ProfilePage() {
  const [profile, setProfile] = useState(defaultProfile);
  const [passwords, setPasswords] = useState({
    currentPassword: "",
    newPassword: "",
    confirmPassword: "",
  });
  const [avatarPreview, setAvatarPreview] = useState("");

  const updateProfileField = (field, value) => {
    setProfile((current) => ({
      ...current,
      [field]: value,
    }));
  };

  const updatePasswordField = (field, value) => {
    setPasswords((current) => ({
      ...current,
      [field]: value,
    }));
  };

  const handleAvatarChange = (event) => {
    const file = event.target.files?.[0];
    if (!file) {
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      setAvatarPreview(String(reader.result ?? ""));
    };
    reader.readAsDataURL(file);
  };

  return (
    <main className="profile-page-shell">
      <div className="profile-page-header">
        <div>
          <span className="eyebrow">Profile Settings</span>
          <h1 className="profile-page-title">Personal info, account access, and picture controls.</h1>
          <p className="profile-page-copy">
            This page is ready for future backend persistence. For now it gives the user a clear
            place to update profile details, reset username and password, and change the profile
            picture.
          </p>
        </div>

        <Link className="secondary-link" href="/">
          Back To Workspace
        </Link>
      </div>

      <section className="profile-grid">
        <article className="profile-panel profile-avatar-panel">
          <span className="mini-label">Profile Picture</span>
          <div className="profile-avatar-wrap">
            {avatarPreview ? (
              <img className="profile-avatar-image" src={avatarPreview} alt="Profile preview" />
            ) : (
              <div className="profile-avatar-placeholder">AU</div>
            )}
          </div>
          <strong>{profile.fullName}</strong>
          <p>{profile.designation}</p>
          <label className="primary-link profile-upload-button">
            Change Picture
            <input type="file" accept="image/*" onChange={handleAvatarChange} />
          </label>
        </article>

        <article className="profile-panel">
          <div className="panel-topline">
            <h2>Personal Information</h2>
            <span className="mini-label">Editable</span>
          </div>

          <div className="profile-form-grid">
            <label className="profile-field">
              <span>Full Name</span>
              <input
                value={profile.fullName}
                onChange={(event) => updateProfileField("fullName", event.target.value)}
              />
            </label>
            <label className="profile-field">
              <span>Designation</span>
              <input
                value={profile.designation}
                onChange={(event) => updateProfileField("designation", event.target.value)}
              />
            </label>
            <label className="profile-field">
              <span>Company</span>
              <input
                value={profile.company}
                onChange={(event) => updateProfileField("company", event.target.value)}
              />
            </label>
            <label className="profile-field">
              <span>Email</span>
              <input
                type="email"
                value={profile.email}
                onChange={(event) => updateProfileField("email", event.target.value)}
              />
            </label>
            <label className="profile-field">
              <span>Phone</span>
              <input
                value={profile.phone}
                onChange={(event) => updateProfileField("phone", event.target.value)}
              />
            </label>
            <label className="profile-field">
              <span>WhatsApp</span>
              <input
                value={profile.whatsapp}
                onChange={(event) => updateProfileField("whatsapp", event.target.value)}
              />
            </label>
            <label className="profile-field profile-field-wide">
              <span>Address</span>
              <textarea
                rows="4"
                value={profile.address}
                onChange={(event) => updateProfileField("address", event.target.value)}
              />
            </label>
          </div>
        </article>
      </section>

      <section className="profile-grid profile-grid-secondary">
        <article className="profile-panel">
          <div className="panel-topline">
            <h2>Username</h2>
            <span className="mini-label">Account Access</span>
          </div>

          <label className="profile-field">
            <span>Username</span>
            <input
              value={profile.username}
              onChange={(event) => updateProfileField("username", event.target.value)}
            />
          </label>
        </article>

        <article className="profile-panel">
          <div className="panel-topline">
            <h2>Password Reset</h2>
            <span className="mini-label">Security</span>
          </div>

          <div className="profile-form-grid profile-password-grid">
            <label className="profile-field">
              <span>Current Password</span>
              <input
                type="password"
                value={passwords.currentPassword}
                onChange={(event) => updatePasswordField("currentPassword", event.target.value)}
              />
            </label>
            <label className="profile-field">
              <span>New Password</span>
              <input
                type="password"
                value={passwords.newPassword}
                onChange={(event) => updatePasswordField("newPassword", event.target.value)}
              />
            </label>
            <label className="profile-field">
              <span>Confirm New Password</span>
              <input
                type="password"
                value={passwords.confirmPassword}
                onChange={(event) => updatePasswordField("confirmPassword", event.target.value)}
              />
            </label>
          </div>
        </article>
      </section>

      <div className="profile-action-row">
        <button className="secondary-link secondary-button" type="button">
          Cancel
        </button>
        <button className="primary-link admin-action-button" type="button">
          Save Profile
        </button>
      </div>
    </main>
  );
}
