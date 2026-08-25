import Link from "next/link";

export const metadata = {
  title: "Page Not Found | Synetra",
};

export default function NotFound() {
  return (
    <main
      style={{
        minHeight: "100vh",
        display: "grid",
        placeItems: "center",
        padding: "32px 20px",
        background:
          "linear-gradient(180deg, rgba(248,250,252,1) 0%, rgba(255,255,255,1) 100%)",
      }}
    >
      <section
        style={{
          width: "100%",
          maxWidth: "540px",
          padding: "32px",
          borderRadius: "28px",
          background: "#ffffff",
          boxShadow: "0 24px 60px rgba(15, 23, 42, 0.08)",
          border: "1px solid #E5E7EB",
        }}
      >
        <span
          style={{
            display: "inline-flex",
            padding: "6px 12px",
            borderRadius: "999px",
            background: "#FFF7ED",
            color: "#C2410C",
            fontSize: "12px",
            fontWeight: 700,
            letterSpacing: "0.04em",
            textTransform: "uppercase",
          }}
        >
          404
        </span>
        <h1
          style={{
            marginTop: "18px",
            marginBottom: "10px",
            color: "#111827",
            fontSize: "32px",
            lineHeight: 1.1,
          }}
        >
          This page isn&apos;t available.
        </h1>
        <p
          style={{
            margin: 0,
            color: "#6B7280",
            fontSize: "16px",
            lineHeight: 1.6,
          }}
        >
          The page may have moved, or the link may not be active in this admin
          build yet.
        </p>
        <div style={{ marginTop: "24px" }}>
          <Link
            href="/"
            style={{
              display: "inline-flex",
              alignItems: "center",
              justifyContent: "center",
              minHeight: "46px",
              padding: "0 18px",
              borderRadius: "999px",
              background: "#F97316",
              color: "#ffffff",
              textDecoration: "none",
              fontWeight: 700,
            }}
          >
            Return Home
          </Link>
        </div>
      </section>
    </main>
  );
}
