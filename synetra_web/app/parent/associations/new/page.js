import Link from "next/link";

const associationFields = [
  "Association name",
  "Slug / unique code",
  "Sector or vertical",
  "Primary color",
  "Logo",
  "Admin name and email",
  "Preferred web domain",
  "Flutter app name",
  "Membership rules",
  "Vendor access model",
];

export default function NewAssociationPage() {
  return (
    <main className="page-shell">
      <section className="panel parent-shell">
        <div className="parent-header">
          <div>
            <span className="eyebrow">Parent Flow</span>
            <h1 className="page-title">Create A New Association</h1>
            <p className="parent-copy">
              This page represents the higher-level flow used to provision a new association
              tenant with its branding, admin owner, and app-specific setup.
            </p>
          </div>

          <Link className="secondary-link" href="/">
            Back To Association 1 Admin
          </Link>
        </div>

        <div className="parent-grid">
          <article className="subpanel">
            <h2>Parameters To Capture</h2>
            <ul className="data-list">
              {associationFields.map((field) => (
                <li key={field}>
                  <div>
                    <strong>{field}</strong>
                    <p>Required during tenant provisioning or onboarding configuration.</p>
                  </div>
                </li>
              ))}
            </ul>
          </article>

          <article className="subpanel subpanel-accent">
            <h2>Why This Page Exists</h2>
            <p>
              Association admins stay inside one tenant. This page is a separate parent-level
              workflow for adding another association with its own branding, admin panel, and
              future Flutter app.
            </p>
            <p>
              Next we can turn this into a real form and persist these parameters into the
              `Association` table.
            </p>
          </article>
        </div>
      </section>
    </main>
  );
}
