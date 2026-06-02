export const metadata = {
  title: "Privacy Policy | NIMA NASHIK",
  description:
    "Privacy policy for the NIMA NASHIK mobile application published by Operisaverick.",
};

const sections = [
  {
    title: "Information We Collect",
    body: [
      "Depending on your role and how you use the app, we may collect your name, email address, phone number, address, company information, vendor profile details, member profile details, uploaded files, and account session information.",
      "Submitted content may include timeline posts, app banners, brochures, images, and related metadata needed to run association workflows.",
    ],
  },
  {
    title: "How We Use Information",
    body: [
      "We use information to authenticate users, manage role-based access, display directories, process moderated submissions, manage events, committee and association operations, and improve communication inside the association ecosystem.",
    ],
  },
  {
    title: "Data Sharing",
    body: [
      "We do not sell personal information. Information may be visible inside the app according to user role, administrative approvals, and association workflows.",
    ],
  },
  {
    title: "Data Storage and Security",
    body: [
      "We use reasonable administrative and technical measures to protect stored data, including authenticated access controls and session-based account management.",
    ],
  },
  {
    title: "User Content and Moderation",
    body: [
      "Members, vendors, and administrators may submit content such as posts, banners, brochures, profile details, and supporting files. Submitted content may be reviewed, approved, rejected, held, or removed according to association moderation rules.",
    ],
  },
  {
    title: "Account Updates and Removal Requests",
    body: [
      "If you need to update your information, correct data, or request account-related assistance, please contact the support details listed below.",
    ],
  },
];

export default function PrivacyPolicyPage() {
  return (
    <main className="policy-page">
      <div className="policy-shell">
        <div className="policy-hero">
          <span className="policy-eyebrow">NIMA NASHIK</span>
          <h1>Privacy Policy</h1>
          <p>
            This privacy policy explains how the NIMA NASHIK app handles account
            information, association data, and moderated user content.
          </p>
          <div className="policy-meta">
            <span>Last updated: June 2, 2026</span>
            <span>Publisher: Operisaverick</span>
          </div>
        </div>

        <div className="policy-card">
          <p>
            NIMA NASHIK (&quot;we&quot;, &quot;our&quot;, or &quot;us&quot;)
            provides a mobile application for association members, vendors, and
            administrators to access directories, events, circulars, banners,
            and moderated content workflows.
          </p>

          {sections.map((section) => (
            <section key={section.title} className="policy-section">
              <h2>{section.title}</h2>
              {section.body.map((paragraph) => (
                <p key={paragraph}>{paragraph}</p>
              ))}
            </section>
          ))}

          <section className="policy-section">
            <h2>Contact</h2>
            <p>
              For privacy-related questions, contact the publisher or support
              contact below:
            </p>
            <ul className="policy-list">
              <li>Association: NIMA NASHIK</li>
              <li>
                Website:{" "}
                <a href="https://www.operisaverick.com">
                  https://www.operisaverick.com
                </a>
              </li>
              <li>
                Email: <a href="mailto:ritsman@gmail.com">ritsman@gmail.com</a>
              </li>
              <li>
                Phone: <a href="tel:+919820083733">+91 9820083733</a>
              </li>
            </ul>
          </section>
        </div>
      </div>
    </main>
  );
}
