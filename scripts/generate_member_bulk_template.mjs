import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { SpreadsheetFile, Workbook } from "@oai/artifact-tool";

const currentFilePath = fileURLToPath(import.meta.url);
const currentDirPath = path.dirname(currentFilePath);
const rootDirPath = path.resolve(currentDirPath, "..");
const outputPath = path.join(
  rootDirPath,
  "synetra_web",
  "public",
  "templates",
  "member-bulk-import-template.xlsx",
);

const workbook = Workbook.create();
const sheet = workbook.worksheets.add("Member Import Template");
sheet.showGridLines = false;
sheet.freezePanes.freezeRows(3);

sheet.getRange("A1:L1").merge();
sheet.getRange("A1").values = [[
  "Member Bulk Import Template",
]];
sheet.getRange("A2:L2").merge();
sheet.getRange("A2").values = [[
  "Fill one row per member. Keep the header names exactly as provided below.",
]];

sheet.getRange("A4:L5").values = [[
  "membership_no",
  "company_name",
  "midc_area",
  "representative_name",
  "cell_no",
  "email",
  "website",
  "date_of_birth",
  "gender",
  "blood_group",
  "business_type",
  "address",
], [
  "M-001",
  "Acme Industrial Works Pvt Ltd",
  "Satpur",
  "Rohan Mehta",
  "9876543210",
  "rohan.mehta@example.com",
  "https://example.com",
  "1990-05-14",
  "Male",
  "B+",
  "Manufacturing",
  "Plot 12, Satpur MIDC, Nashik",
]];

sheet.getRange("A1:L1").format = {
  fill: "#312E81",
  font: { bold: true, color: "#FFFFFF", size: 16 },
  horizontalAlignment: "center",
  verticalAlignment: "center",
};
sheet.getRange("A2:L2").format = {
  fill: "#E0E7FF",
  font: { color: "#312E81", italic: true },
  horizontalAlignment: "left",
  verticalAlignment: "center",
  wrapText: true,
};
sheet.getRange("A4:L4").format = {
  fill: "#4338CA",
  font: { bold: true, color: "#FFFFFF" },
  horizontalAlignment: "center",
  verticalAlignment: "center",
};
sheet.getRange("A5:L5").format = {
  fill: "#F8FAFC",
  font: { color: "#0F172A" },
  verticalAlignment: "center",
};
sheet.getRange("A4:L5").format.borders = {
  preset: "all",
  style: "thin",
  color: "#C7D2FE",
};

sheet.getRange("A1:L5").format.rowHeight = 26;
sheet.getRange("A2").format.rowHeight = 38;

const widths = [16, 28, 18, 24, 16, 28, 24, 16, 14, 14, 18, 34];
widths.forEach((width, index) => {
  sheet.getRangeByIndexes(0, index, 1, 1).format.columnWidth = width;
});

sheet.getRange("E5:E200").format.numberFormat = "@";
sheet.getRange("H5:H200").format.numberFormat = "yyyy-mm-dd";

sheet.getRange("I5:I200").dataValidation = {
  rule: { type: "list", values: ["Male", "Female", "Other"] },
};
sheet.getRange("J5:J200").dataValidation = {
  rule: {
    type: "list",
    values: ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"],
  },
};

const notesSheet = workbook.worksheets.add("Instructions");
notesSheet.showGridLines = false;
notesSheet.getRange("A1:B8").values = [
  ["Field", "Notes"],
  ["membership_no", "Optional membership number or internal code."],
  ["company_name", "Required company name."],
  ["representative_name", "Required full name of the member representative."],
  ["cell_no", "Phone number to store for the member profile."],
  ["email", "Required. Used as the member login ID for bulk-imported accounts."],
  ["date_of_birth", "Use YYYY-MM-DD format when available."],
  ["address", "Full postal address of the member company or representative."],
];
notesSheet.getRange("A1:B1").format = {
  fill: "#0F766E",
  font: { bold: true, color: "#FFFFFF" },
};
notesSheet.getRange("A1:B8").format.borders = {
  preset: "all",
  style: "thin",
  color: "#99F6E4",
};
notesSheet.getRange("A:A").format.columnWidth = 22;
notesSheet.getRange("B:B").format.columnWidth = 64;
notesSheet.getRange("A1:B8").format.wrapText = true;

const inspection = await workbook.inspect({
  kind: "table",
  sheetId: "Member Import Template",
  range: "A1:L5",
  include: "values",
  tableMaxRows: 5,
  tableMaxCols: 12,
});
console.log(inspection.ndjson);

const formulaErrors = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A",
  options: { useRegex: true, maxResults: 50 },
  summary: "template formula scan",
});
console.log(formulaErrors.ndjson);

await workbook.render({
  sheetName: "Member Import Template",
  range: "A1:L8",
  scale: 1,
});
await workbook.render({
  sheetName: "Instructions",
  range: "A1:B8",
  scale: 1,
});

await fs.mkdir(path.dirname(outputPath), { recursive: true });
const output = await SpreadsheetFile.exportXlsx(workbook);
await output.save(outputPath);
