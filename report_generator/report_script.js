const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, HeadingLevel, BorderStyle, WidthType,
  ShadingType, VerticalAlign, PageNumber, PageBreak, LevelFormat,
  TableOfContents, UnderlineType
} = require('docx');
const fs = require('fs');

// ─── Colors ───────────────────────────────────────────────────────────────────
const COLOR_BLACK = "000000";
const COLOR_HEADER_BG = "1F3864";
const COLOR_LIGHT_BLUE = "BDD7EE";
const COLOR_ALT_ROW = "DEEAF1";
const COLOR_WHITE = "FFFFFF";

// ─── DXA helpers (A4 page) ────────────────────────────────────────────────────
// A4: 11906 x 16838
// Left: 1.25" = 1800, Right: 1.0" = 1440, Top: 1.0" = 1440, Bottom: 1.0" = 1440
// Content width = 11906 - 1800 - 1440 = 8666 DXA
const CONTENT_WIDTH = 8666;

// ─── Borders helper ───────────────────────────────────────────────────────────
const thinBorder = { style: BorderStyle.SINGLE, size: 6, color: "2E4D7B" };
const cellBorders = { top: thinBorder, bottom: thinBorder, left: thinBorder, right: thinBorder };
const noBorder = { style: BorderStyle.NONE, size: 0, color: "FFFFFF" };
const noBorders = { top: noBorder, bottom: noBorder, left: noBorder, right: noBorder };

// ─── Spacing helper ───────────────────────────────────────────────────────────
const LINE_SPACING_15 = { line: 360, lineRule: "auto" };  // 1.5 line spacing
const LINE_SPACING_DOUBLE = { line: 480, lineRule: "auto" };
const PARA_SPACING = { before: 240, after: 240 };

// ─── Font ─────────────────────────────────────────────────────────────────────
const FONT = "Times New Roman";

// ─── Helper: Regular paragraph ────────────────────────────────────────────────
function para(text, opts = {}) {
  return new Paragraph({
    alignment: AlignmentType.JUSTIFIED,
    spacing: { ...LINE_SPACING_15, before: 120, after: 120 },
    children: [new TextRun({ text, font: FONT, size: 24, ...opts })],
  });
}

function paraCenter(text, opts = {}) {
  return new Paragraph({
    alignment: AlignmentType.CENTER,
    spacing: LINE_SPACING_15,
    children: [new TextRun({ text, font: FONT, size: 24, ...opts })],
  });
}

function chapterHeading(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_1,
    alignment: AlignmentType.CENTER,
    spacing: { before: 480, after: 360 },
    children: [new TextRun({ text: text.toUpperCase(), font: FONT, size: 32, bold: true })],
  });
}

function sectionHeading(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_2,
    spacing: { before: 360, after: 240 },
    children: [new TextRun({ text: text.toUpperCase(), font: FONT, size: 28, bold: true })],
  });
}

function subSectionHeading(text) {
  return new Paragraph({
    heading: HeadingLevel.HEADING_3,
    spacing: { before: 240, after: 180 },
    children: [new TextRun({ text, font: FONT, size: 24, bold: true })],
  });
}

function bullet(text, opts = {}) {
  return new Paragraph({
    numbering: { reference: "bullets", level: 0 },
    spacing: { line: 320, lineRule: "auto", before: 60, after: 60 },
    children: [new TextRun({ text, font: FONT, size: 24, ...opts })],
  });
}

function pageBreak() {
  return new Paragraph({ children: [new PageBreak()] });
}

function emptyPara() {
  return new Paragraph({ children: [new TextRun({ text: "", font: FONT, size: 24 })] });
}

// ─── Header/Footer ────────────────────────────────────────────────────────────
function makeHeader(chapterTitle, enrollNo) {
  return new Header({
    children: [
      new Paragraph({
        children: [
          new TextRun({ text: enrollNo, font: FONT, size: 18 }),
          new TextRun({ text: "\t" + chapterTitle.toUpperCase(), font: FONT, size: 18, bold: true }),
        ],
        tabStops: [{ type: "right", position: 8666 }],
        border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: "2E4D7B", space: 1 } },
      }),
    ],
  });
}

function makeFooter(collegeName) {
  return new Footer({
    children: [
      new Paragraph({
        children: [
          new TextRun({ text: "CVM University", font: FONT, size: 18 }),
          new TextRun({ text: "\t", font: FONT, size: 18 }),
          new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 18 }),
          new TextRun({ text: "\t" + collegeName, font: FONT, size: 18 }),
        ],
        tabStops: [
          { type: "center", position: 4333 },
          { type: "right", position: 8666 },
        ],
        alignment: AlignmentType.LEFT,
        border: { top: { style: BorderStyle.SINGLE, size: 6, color: "2E4D7B", space: 1 } },
      }),
    ],
  });
}

// ─── Table helpers ────────────────────────────────────────────────────────────
function headerCell(text, widthDxa) {
  return new TableCell({
    borders: cellBorders,
    width: { size: widthDxa, type: WidthType.DXA },
    shading: { fill: COLOR_HEADER_BG, type: ShadingType.CLEAR },
    margins: { top: 100, bottom: 100, left: 150, right: 150 },
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [new TextRun({ text, font: FONT, size: 22, bold: true, color: COLOR_WHITE })],
    })],
  });
}

function dataCell(text, widthDxa, shade = false, center = false) {
  return new TableCell({
    borders: cellBorders,
    width: { size: widthDxa, type: WidthType.DXA },
    shading: shade
      ? { fill: COLOR_ALT_ROW, type: ShadingType.CLEAR }
      : { fill: COLOR_WHITE, type: ShadingType.CLEAR },
    margins: { top: 80, bottom: 80, left: 150, right: 150 },
    verticalAlign: VerticalAlign.CENTER,
    children: [new Paragraph({
      alignment: center ? AlignmentType.CENTER : AlignmentType.LEFT,
      children: [new TextRun({ text, font: FONT, size: 22 })],
    })],
  });
}

// ─── COVER PAGE ───────────────────────────────────────────────────────────────
function buildCoverPage() {
  return [
    emptyPara(), emptyPara(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 200, after: 200 },
      children: [
        new TextRun({ text: "INDUSTRIAL INTERNSHIP REPORT", font: FONT, size: 40, bold: true }),
      ],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 100, after: 100 },
      children: [new TextRun({ text: "Subject Code: 202000801", font: FONT, size: 28, bold: true })],
    }),
    emptyPara(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 200, after: 200 },
      children: [new TextRun({ text: "Submitted by", font: FONT, size: 26, italics: true })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 100, after: 100 },
      children: [new TextRun({ text: "[YOUR FULL NAME]", font: FONT, size: 32, bold: true })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 100, after: 100 },
      children: [new TextRun({ text: "[CVMU Enrollment Number]", font: FONT, size: 26, bold: true })],
    }),
    emptyPara(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [new TextRun({ text: "In partial fulfillment for the award of the degree of", font: FONT, size: 26, italics: true })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 200, after: 100 },
      children: [new TextRun({ text: "BACHELOR OF ENGINEERING / TECHNOLOGY", font: FONT, size: 28, bold: true })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      children: [new TextRun({ text: "in", font: FONT, size: 24, italics: true })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 100, after: 200 },
      children: [new TextRun({ text: "Computer Engineering", font: FONT, size: 28, bold: true })],
    }),
    emptyPara(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 200, after: 100 },
      children: [new TextRun({ text: "[College Name]", font: FONT, size: 28, bold: true })],
    }),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 100, after: 200 },
      children: [new TextRun({ text: "The Charutar Vidya Mandal (CVM) University, Vallabh Vidyanagar – 388120", font: FONT, size: 24 })],
    }),
    emptyPara(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 200 },
      children: [new TextRun({ text: "[Month], 2025", font: FONT, size: 26, bold: true })],
    }),
  ];
}

// ─── CERTIFICATE ──────────────────────────────────────────────────────────────
function buildCertificate() {
  return [
    pageBreak(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 480, after: 480 },
      children: [new TextRun({ text: "CERTIFICATE", font: FONT, size: 36, bold: true })],
    }),
    new Paragraph({
      alignment: AlignmentType.JUSTIFIED,
      spacing: LINE_SPACING_DOUBLE,
      children: [
        new TextRun({ text: "This is to certify that ", font: FONT, size: 28 }),
        new TextRun({ text: "[Name of Student] ([Enrollment No.])", font: FONT, size: 28, bold: true }),
        new TextRun({ text: " has submitted the Industrial Internship report based on internship undergone at ", font: FONT, size: 28 }),
        new TextRun({ text: "[Name of Industry]", font: FONT, size: 28, bold: true }),
        new TextRun({ text: " for a period of ", font: FONT, size: 28 }),
        new TextRun({ text: "26 weeks", font: FONT, size: 28, bold: true }),
        new TextRun({ text: " from ", font: FONT, size: 28 }),
        new TextRun({ text: "[Start Date]", font: FONT, size: 28, bold: true }),
        new TextRun({ text: " to ", font: FONT, size: 28 }),
        new TextRun({ text: "[End Date]", font: FONT, size: 28, bold: true }),
        new TextRun({ text: " in partial fulfillment for the degree of Bachelor of Engineering in Computer Engineering, [College Name] at The Charutar Vidya Mandal (CVM) University, Vallabh Vidyanagar during the academic year 2024 – 25.", font: FONT, size: 28 }),
      ],
    }),
    emptyPara(), emptyPara(), emptyPara(),
    new Paragraph({
      children: [
        new TextRun({ text: "___________________________\t\t___________________________", font: FONT, size: 28 }),
      ],
      tabStops: [{ type: "left", position: 4680 }],
    }),
    new Paragraph({
      children: [
        new TextRun({ text: "[Internal Guide Name]\t\t[Head of Department Name]", font: FONT, size: 28 }),
      ],
      tabStops: [{ type: "left", position: 4680 }],
    }),
    new Paragraph({
      children: [
        new TextRun({ text: "Internal Guide\t\tHead of the Department", font: FONT, size: 28 }),
      ],
      tabStops: [{ type: "left", position: 4680 }],
    }),
  ];
}

// ─── DECLARATION ──────────────────────────────────────────────────────────────
function buildDeclaration() {
  return [
    pageBreak(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 480, after: 480 },
      children: [new TextRun({ text: "CANDIDATE'S DECLARATION", font: FONT, size: 36, bold: true })],
    }),
    new Paragraph({
      alignment: AlignmentType.JUSTIFIED,
      spacing: LINE_SPACING_DOUBLE,
      children: [
        new TextRun({ text: "I hereby declare that the work which is being presented in this Industrial Internship Report entitled ", font: FONT, size: 28 }),
        new TextRun({ text: "\"Development of Flutter-based Mobile Applications using Firebase\"", font: FONT, size: 28, bold: true }),
        new TextRun({ text: " in partial fulfillment of the requirements for the award of the degree of Bachelor of Engineering in Computer Engineering at The Charutar Vidya Mandal (CVM) University, Vallabh Vidyanagar is an authentic record of my own work carried out during the period from [Start Date] to [End Date] under the supervision of [Industry Mentor Name].", font: FONT, size: 28 }),
      ],
    }),
    emptyPara(),
    new Paragraph({
      alignment: AlignmentType.JUSTIFIED,
      spacing: LINE_SPACING_DOUBLE,
      children: [
        new TextRun({ text: "The matter embodied in this report has not been submitted by me for the award of any other degree.", font: FONT, size: 28 }),
      ],
    }),
    emptyPara(), emptyPara(), emptyPara(),
    new Paragraph({
      children: [new TextRun({ text: "Date: _______________", font: FONT, size: 28 })],
    }),
    emptyPara(),
    new Paragraph({
      children: [new TextRun({ text: "___________________________", font: FONT, size: 28 })],
    }),
    new Paragraph({
      children: [new TextRun({ text: "[YOUR FULL NAME]", font: FONT, size: 28, bold: true })],
    }),
    new Paragraph({
      children: [new TextRun({ text: "[Enrollment Number]", font: FONT, size: 28 })],
    }),
  ];
}

// ─── ACKNOWLEDGEMENT ─────────────────────────────────────────────────────────
function buildAcknowledgement() {
  return [
    pageBreak(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 480, after: 480 },
      children: [new TextRun({ text: "ACKNOWLEDGEMENT", font: FONT, size: 36, bold: true })],
    }),
    new Paragraph({
      alignment: AlignmentType.JUSTIFIED,
      spacing: LINE_SPACING_DOUBLE,
      children: [new TextRun({ text: "I express my sincere gratitude to [Industry Mentor Name], [Designation], [Company Name], for their invaluable guidance, constant encouragement, and support throughout my internship period. Their technical expertise and practical insights have been instrumental in shaping my understanding of real-world application development.", font: FONT, size: 24 })],
    }),
    emptyPara(),
    new Paragraph({
      alignment: AlignmentType.JUSTIFIED,
      spacing: LINE_SPACING_DOUBLE,
      children: [new TextRun({ text: "I am equally thankful to [Internal Guide Name], my Internal Guide at [College Name], for providing academic direction and evaluating my progress at every stage of the internship.", font: FONT, size: 24 })],
    }),
    emptyPara(),
    new Paragraph({
      alignment: AlignmentType.JUSTIFIED,
      spacing: LINE_SPACING_DOUBLE,
      children: [new TextRun({ text: "I extend my heartfelt thanks to [HOD Name], Head of the Department of Computer Engineering, for facilitating the internship program and creating opportunities for industry exposure.", font: FONT, size: 24 })],
    }),
    emptyPara(),
    new Paragraph({
      alignment: AlignmentType.JUSTIFIED,
      spacing: LINE_SPACING_DOUBLE,
      children: [new TextRun({ text: "I also wish to acknowledge the entire team at [Company Name] for welcoming me warmly, providing a conducive work environment, and mentoring me on industry best practices. This experience has been a significant milestone in my academic and professional journey.", font: FONT, size: 24 })],
    }),
    emptyPara(), emptyPara(),
    new Paragraph({
      children: [new TextRun({ text: "[YOUR FULL NAME]", font: FONT, size: 24, bold: true })],
    }),
    new Paragraph({
      children: [new TextRun({ text: "[Enrollment Number]", font: FONT, size: 24 })],
    }),
  ];
}

// ─── ABSTRACT ─────────────────────────────────────────────────────────────────
function buildAbstract() {
  return [
    pageBreak(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 480, after: 480 },
      children: [new TextRun({ text: "ABSTRACT", font: FONT, size: 36, bold: true })],
    }),
    new Paragraph({
      alignment: AlignmentType.JUSTIFIED,
      spacing: { line: 360, lineRule: "auto", before: 120, after: 120 },
      children: [new TextRun({ text: "This report documents the industrial internship experience undertaken for a period of six months at [Company Name], focusing on the design, development, and deployment of Flutter-based mobile applications integrated with Firebase as the backend infrastructure. The internship provided extensive hands-on exposure to cross-platform mobile application development, version control using Git, real-time database management, role-based authentication systems, and Agile software development practices.", font: FONT, size: 28, italics: true })],
    }),
    emptyPara(),
    new Paragraph({
      alignment: AlignmentType.JUSTIFIED,
      spacing: { line: 360, lineRule: "auto", before: 120, after: 120 },
      children: [new TextRun({ text: "Two major projects were undertaken during the internship period. The first project, College Connect (CMS), is a comprehensive College Management System designed to digitize and streamline academic operations for an educational institution. It encompasses role-based dashboards for students, teachers, coordinators, administrators, librarians, and retailers, along with features such as attendance tracking, examination management, canteen ordering, and UFM (Unfair Means) monitoring.", font: FONT, size: 28, italics: true })],
    }),
    emptyPara(),
    new Paragraph({
      alignment: AlignmentType.JUSTIFIED,
      spacing: { line: 360, lineRule: "auto", before: 120, after: 120 },
      children: [new TextRun({ text: "The second project, Gokuldiyugam, is a spiritual content management application developed for BAPS Badlapur Mandal. It offers features such as daily darshan, kirtan playback with smart transliteration-based lyrics search, Sabha timetable management, admin content control, biometric authentication, and AI integration using Google's Gemini 1.5 Flash model.", font: FONT, size: 28, italics: true })],
    }),
    emptyPara(),
    new Paragraph({
      alignment: AlignmentType.JUSTIFIED,
      spacing: { line: 360, lineRule: "auto", before: 120, after: 120 },
      children: [new TextRun({ text: "The internship commenced with a structured study of Git version control commands, which served as the foundation for collaborative and systematic software development. Technologies mastered include Flutter, Firebase (Firestore, Storage, Authentication, App Check), Google AI APIs, and modern UI/UX design principles.", font: FONT, size: 28, italics: true })],
    }),
  ];
}

// ─── LIST OF ABBREVIATIONS ────────────────────────────────────────────────────
function buildAbbreviations() {
  return [
    pageBreak(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 480, after: 480 },
      children: [new TextRun({ text: "LIST OF SYMBOLS, ABBREVIATIONS AND NOMENCLATURE", font: FONT, size: 32, bold: true })],
    }),
    new Table({
      width: { size: CONTENT_WIDTH, type: WidthType.DXA },
      columnWidths: [2000, 6666],
      rows: [
        new TableRow({ children: [headerCell("Abbreviation", 2000), headerCell("Full Form", 6666)] }),
        ...([
          ["API", "Application Programming Interface"],
          ["BaaS", "Backend as a Service"],
          ["BAPS", "Bochasanwasi Akshar Purushottam Sanstha"],
          ["CMS", "College Management System"],
          ["CRUD", "Create, Read, Update, Delete"],
          ["CVM", "Charutar Vidya Mandal"],
          ["FCM", "Firebase Cloud Messaging"],
          ["IDE", "Integrated Development Environment"],
          ["JSON", "JavaScript Object Notation"],
          ["NoSQL", "Non-relational Structured Query Language"],
          ["SDK", "Software Development Kit"],
          ["UI", "User Interface"],
          ["UFM", "Unfair Means"],
          ["UX", "User Experience"],
          ["UUID", "Universally Unique Identifier"],
        ].map((row, i) =>
          new TableRow({ children: [dataCell(row[0], 2000, i % 2 !== 0, true), dataCell(row[1], 6666, i % 2 !== 0)] })
        )),
      ],
    }),
  ];
}

// ─── LIST OF FIGURES ─────────────────────────────────────────────────────────
function buildListOfFigures() {
  return [
    pageBreak(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 480, after: 480 },
      children: [new TextRun({ text: "LIST OF FIGURES", font: FONT, size: 32, bold: true })],
    }),
    new Table({
      width: { size: CONTENT_WIDTH, type: WidthType.DXA },
      columnWidths: [1500, 5666, 1500],
      rows: [
        new TableRow({ children: [headerCell("Figure No.", 1500), headerCell("Title", 5666), headerCell("Page No.", 1500)] }),
        ...([
          ["Fig 1.1", "Git Version Control Workflow", "10"],
          ["Fig 1.2", "Flutter Architecture Overview", "13"],
          ["Fig 2.1", "College Connect – System Architecture", "18"],
          ["Fig 2.2", "College Connect – Login Screen Flow", "20"],
          ["Fig 2.3", "College Connect – Role-Based Dashboard Structure", "22"],
          ["Fig 2.4", "College Connect – Student Dashboard", "24"],
          ["Fig 2.5", "College Connect – Admin Panel Overview", "28"],
          ["Fig 2.6", "College Connect – Firebase Firestore Data Model", "32"],
          ["Fig 3.1", "Gokuldiyugam – Application Architecture", "38"],
          ["Fig 3.2", "Gokuldiyugam – Home Screen with Dynamic Slider", "40"],
          ["Fig 3.3", "Gokuldiyugam – Kirtan Player Screen", "44"],
          ["Fig 3.4", "Gokuldiyugam – Admin Panel Workflow", "48"],
          ["Fig 3.5", "Gokuldiyugam – Authentication Flow", "50"],
        ].map((row, i) =>
          new TableRow({ children: [dataCell(row[0], 1500, i % 2 !== 0, true), dataCell(row[1], 5666, i % 2 !== 0), dataCell(row[2], 1500, i % 2 !== 0, true)] })
        )),
      ],
    }),
  ];
}

// ─── LIST OF TABLES ───────────────────────────────────────────────────────────
function buildListOfTables() {
  return [
    pageBreak(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 480, after: 480 },
      children: [new TextRun({ text: "LIST OF TABLES", font: FONT, size: 32, bold: true })],
    }),
    new Table({
      width: { size: CONTENT_WIDTH, type: WidthType.DXA },
      columnWidths: [1500, 5666, 1500],
      rows: [
        new TableRow({ children: [headerCell("Table No.", 1500), headerCell("Title", 5666), headerCell("Page No.", 1500)] }),
        ...([
          ["Table 1.1", "Commonly Used Git Commands and Their Functions", "11"],
          ["Table 2.1", "College Connect – User Roles and Permissions", "19"],
          ["Table 2.2", "College Connect – Module-wise Feature Summary", "21"],
          ["Table 2.3", "Firebase Collections Used in College Connect", "33"],
          ["Table 3.1", "Gokuldiyugam – Feature Module Summary", "39"],
          ["Table 3.2", "Firebase Services Used in Gokuldiyugam", "49"],
        ].map((row, i) =>
          new TableRow({ children: [dataCell(row[0], 1500, i % 2 !== 0, true), dataCell(row[1], 5666, i % 2 !== 0), dataCell(row[2], 1500, i % 2 !== 0, true)] })
        )),
      ],
    }),
  ];
}

// ─── TABLE OF CONTENTS ────────────────────────────────────────────────────────
function buildTOC() {
  return [
    pageBreak(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 480, after: 480 },
      children: [new TextRun({ text: "TABLE OF CONTENTS", font: FONT, size: 32, bold: true })],
    }),
    new TableOfContents("Table of Contents", { hyperlink: true, headingStyleRange: "1-3" }),
  ];
}

// ─── CHAPTER 1 ────────────────────────────────────────────────────────────────
function buildChapter1() {
  const gitTable = new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2500, 4000, 2166],
    rows: [
      new TableRow({ children: [headerCell("Git Command", 2500), headerCell("Description", 4000), headerCell("Usage Stage", 2166)] }),
      ...([
        ["git init", "Initializes a new local Git repository", "Project Setup"],
        ["git clone <url>", "Clones a remote repository to local machine", "Project Setup"],
        ["git status", "Displays working directory and staging area status", "Daily Use"],
        ["git add .", "Stages all modified files for the next commit", "Daily Use"],
        ["git commit -m \"msg\"", "Records staged changes with a descriptive message", "Daily Use"],
        ["git push origin <branch>", "Pushes committed changes to the remote branch", "Collaboration"],
        ["git pull origin <branch>", "Fetches and merges changes from the remote branch", "Collaboration"],
        ["git branch <name>", "Creates a new branch for feature development", "Branching"],
        ["git checkout <branch>", "Switches to the specified branch", "Branching"],
        ["git merge <branch>", "Merges specified branch into the current branch", "Integration"],
        ["git log --oneline", "Displays a compact commit history", "Review"],
        ["git stash", "Temporarily saves uncommitted changes", "Context Switch"],
        ["git reset HEAD~1", "Undoes the last commit while keeping changes", "Correction"],
        ["git diff", "Shows differences between commits or files", "Review"],
      ].map((row, i) =>
        new TableRow({ children: [dataCell(row[0], 2500, i % 2 !== 0), dataCell(row[1], 4000, i % 2 !== 0), dataCell(row[2], 2166, i % 2 !== 0, true)] })
      )),
    ],
  });

  return [
    pageBreak(),
    chapterHeading("Chapter 1: Introduction and Technology Overview"),
    sectionHeading("1.1   Introduction to the Internship"),
    para("The industrial internship is an integral part of the Bachelor of Engineering curriculum at The Charutar Vidya Mandal (CVM) University. It provides students with a valuable opportunity to bridge the gap between theoretical academic learning and practical industry experience. This internship was undertaken at [Company Name] for a duration of six months, from [Start Date] to [End Date]."),
    emptyPara(),
    para("During this period, the intern was actively involved in the complete software development lifecycle of two major mobile applications using Flutter and Firebase. The internship commenced with a thorough orientation to industry workflows, development environment setup, and version control practices using Git."),
    emptyPara(),

    sectionHeading("1.2   Company Profile"),
    para("[Company Name] is a technology-driven software development firm specializing in mobile and web application development. The company delivers innovative digital solutions to clients across various sectors including education, retail, and spiritual organizations. Their development philosophy is rooted in agile methodologies, clean code practices, and user-centric design."),
    emptyPara(),
    para("The development team employs modern technology stacks including Flutter for cross-platform mobile development, Firebase for backend services, and various cloud platforms for deployment. The collaborative work environment and exposure to live project development made this internship an exceptionally enriching experience."),
    emptyPara(),

    sectionHeading("1.3   Objectives of the Internship"),
    para("The primary objectives set at the commencement of this internship were as follows:"),
    bullet("To gain practical exposure to cross-platform mobile application development using Flutter."),
    bullet("To understand and implement Firebase services including Firestore, Authentication, Storage, and Cloud Messaging."),
    bullet("To master Git version control for collaborative software development."),
    bullet("To develop and deliver two fully functional mobile applications from conceptualization to deployment."),
    bullet("To understand software project management, documentation practices, and team collaboration in an industry setting."),
    bullet("To integrate modern technologies such as AI APIs into mobile applications."),
    emptyPara(),

    sectionHeading("1.4   Git – Foundation of the Internship"),
    para("The internship commenced with a comprehensive study and practice of Git, the industry-standard distributed version control system. Mastering Git was identified as the foundational prerequisite before contributing to any live project codebase. Git enables multiple developers to collaborate on the same codebase efficiently, maintain a complete history of all changes, and revert to any previous state if issues arise."),
    emptyPara(),
    para("Every command was studied in context – understanding not just what it does, but when and why it is used in a professional setting. The following table summarizes all Git commands studied and practiced during the initial phase of the internship:"),
    emptyPara(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 120, after: 240 },
      children: [new TextRun({ text: "Table 1.1   Commonly Used Git Commands and Their Functions", font: FONT, size: 22, bold: true })],
    }),
    gitTable,
    emptyPara(),

    subSectionHeading("1.4.1 Git Branching Strategy"),
    para("The team followed a feature-branch workflow, wherein each new feature or bug fix was developed in an isolated branch created from the main development branch. This ensured that the main codebase remained stable at all times. Upon completion of a feature, a pull request was raised, reviewed by a senior developer, and then merged into the development branch."),
    emptyPara(),

    sectionHeading("1.5   Flutter – The Development Framework"),
    para("Flutter is an open-source UI toolkit developed by Google for building natively compiled applications for mobile (Android and iOS), web, and desktop from a single codebase using the Dart programming language. Flutter's widget-based architecture, hot reload feature, and extensive widget library make it an ideal choice for rapid application development."),
    emptyPara(),
    para("Key Flutter concepts learned and applied during the internship include:"),
    bullet("Stateless and Stateful Widgets and their lifecycle management."),
    bullet("Navigator and routing for multi-screen applications."),
    bullet("State management using Provider and setState patterns."),
    bullet("Custom widget development for reusable UI components."),
    bullet("Responsive layout design using MediaQuery and LayoutBuilder."),
    bullet("Integration with third-party packages from pub.dev."),
    emptyPara(),

    sectionHeading("1.6   Firebase – The Backend Infrastructure"),
    para("Firebase is a Backend-as-a-Service (BaaS) platform by Google that provides a comprehensive suite of cloud-based tools for mobile and web application development. It eliminates the need to build and manage server infrastructure, allowing developers to focus entirely on the client-side application logic."),
    emptyPara(),
    para("The following Firebase services were utilized extensively across both projects:"),
    bullet("Firebase Authentication: For secure user login using email/password and Google Sign-In."),
    bullet("Cloud Firestore: A flexible, scalable NoSQL cloud database for real-time data synchronization."),
    bullet("Firebase Storage: For storing and serving user-generated content such as images and audio files."),
    bullet("Firebase Cloud Messaging (FCM): For sending push notifications to users."),
    bullet("Firebase App Check: For protecting backend resources from abuse by verifying that requests originate from authentic app instances."),
  ];
}

// ─── CHAPTER 2 ────────────────────────────────────────────────────────────────
function buildChapter2() {
  const rolesTable = new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [1800, 2000, 4866],
    rows: [
      new TableRow({ children: [headerCell("Role", 1800), headerCell("Dashboard", 2000), headerCell("Key Permissions", 4866)] }),
      ...([
        ["Admin", "Admin Panel", "Full system access: manage students, teachers, results, library, UFM"],
        ["Teacher / Coordinator", "Teacher Panel", "View students, manage leave requests, assign homework, view timetable"],
        ["Student", "Student Dashboard", "Attendance, exam forms, results, elective selection, canteen ordering"],
        ["Librarian", "Library Module", "Book issuance, return tracking, stock management"],
        ["Retailer", "Canteen Panel", "Order management, order fulfillment, inventory overview"],
      ].map((row, i) =>
        new TableRow({ children: [dataCell(row[0], 1800, i % 2 !== 0, true), dataCell(row[1], 2000, i % 2 !== 0), dataCell(row[2], 4866, i % 2 !== 0)] })
      )),
    ],
  });

  const featuresTable = new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2200, 3000, 3466],
    rows: [
      new TableRow({ children: [headerCell("Module", 2200), headerCell("Screens", 3000), headerCell("Description", 3466)] }),
      ...([
        ["Authentication", "Login, Change Password", "Role-based login with auto-redirect to appropriate dashboard"],
        ["Student – Attendance", "Attendance Screen", "Displays subject-wise attendance percentage with date-wise details"],
        ["Student – Examination", "Exam Form, Timetable, Result, Fee", "Complete exam management from form submission to result download"],
        ["Student – Electives", "Elective Selection Screen", "Students select optional subjects from available choices"],
        ["Student – Leave", "Leave Application Screen", "Submit leave requests with reason and dates for coordinator approval"],
        ["Student – Canteen", "Canteen, Order History", "Order food items from the college canteen and track order history"],
        ["Teacher Panel", "Students List, Assignments, Timetable", "Manage classroom operations, assignments, and personal schedule"],
        ["Coordinator", "Leave Approval Screen", "Approve or reject student leave applications"],
        ["Admin – Setup", "College Setup, Semester Mgmt.", "Configure college branches, semesters, and academic structure"],
        ["Admin – Results", "Result Management Screen", "Upload and publish student examination results"],
        ["Admin – UFM", "UFM Dashboard", "Impose academic suspension on students caught in malpractice"],
        ["Library", "Library Management Screen", "Manage book issuance, return, and stock for the library"],
        ["Retailer", "Order Management Screen", "Accept and fulfill canteen orders placed by students"],
      ].map((row, i) =>
        new TableRow({ children: [dataCell(row[0], 2200, i % 2 !== 0), dataCell(row[1], 3000, i % 2 !== 0), dataCell(row[2], 3466, i % 2 !== 0)] })
      )),
    ],
  });

  return [
    pageBreak(),
    chapterHeading("Chapter 2: Project 1 – College Connect (CMS)"),
    sectionHeading("2.1   Project Overview"),
    para("College Connect (CMS) is a comprehensive College Management System developed as a Flutter-based mobile application with Firebase as its backend. The application was designed to digitize and centralize all academic and administrative operations of an educational institution, providing a unified platform for all stakeholders – students, teachers, administrators, librarians, and canteen retailers."),
    emptyPara(),
    para("The system was architected around a role-based access control (RBAC) model, ensuring that each user sees only the features and data relevant to their role. This not only enhances security but also provides a clean and intuitive user experience tailored to each user type."),
    emptyPara(),

    sectionHeading("2.2   User Roles and Access Control"),
    para("The application supports five distinct user roles, each with a dedicated dashboard and a specific set of permissions. The role of a user is determined at the time of account creation by the administrator and is stored in Firestore. Upon login, the application reads the user's role from Firebase and redirects them to the appropriate dashboard."),
    emptyPara(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 120, after: 240 },
      children: [new TextRun({ text: "Table 2.1   College Connect – User Roles and Permissions", font: FONT, size: 22, bold: true })],
    }),
    rolesTable,
    emptyPara(),

    sectionHeading("2.3   Common Screens"),
    para("Several screens are shared across multiple user roles to maintain design consistency and reduce code duplication:"),
    emptyPara(),
    subSectionHeading("2.3.1 Login Screen"),
    para("The Login Screen serves as the single entry point to the application. Users authenticate using their institutional email address and a password. Upon successful authentication, Firebase identifies the user's role from their Firestore document and navigates them to the corresponding dashboard. The screen also handles error states such as invalid credentials and account suspension (in the case of UFM-flagged students)."),
    emptyPara(),
    subSectionHeading("2.3.2 Change Password Screen"),
    para("For security purposes, users logging in for the first time are automatically redirected to the Change Password screen before accessing their dashboard. This ensures that the default system-assigned password is replaced immediately. Subsequent password changes can be initiated from the Profile screen at any time."),
    emptyPara(),
    subSectionHeading("2.3.3 Profile Screen"),
    para("Each user has a dedicated profile page where they can view and edit personal information such as name, profile photograph, and contact details. Profile images are stored in Firebase Storage, and the URL is saved in Firestore for retrieval."),
    emptyPara(),
    subSectionHeading("2.3.4 Coming Soon and Maintenance Screen"),
    para("A placeholder screen is displayed when a feature is under development or when the application is in maintenance mode. This is controlled remotely via a Firestore configuration document, allowing administrators to toggle the maintenance mode without requiring an app update."),
    emptyPara(),

    sectionHeading("2.4   Student Dashboard Modules"),
    para("The Student Dashboard is the most feature-rich section of the application, providing students with a consolidated view of all their academic activities:"),
    emptyPara(),
    subSectionHeading("2.4.1 Attendance Module"),
    para("The Attendance Screen presents a subject-wise breakdown of the student's attendance record, displaying the total number of lectures held, lectures attended, and the resulting percentage. Color-coded indicators (green for satisfactory, red for below threshold) provide instant visual feedback. The data is fetched in real-time from Firestore, ensuring that students always see the most current records."),
    emptyPara(),
    subSectionHeading("2.4.2 Examination Module"),
    para("The examination module comprises four interconnected screens:"),
    bullet("Exam Form Screen: Allows students to fill and submit their examination enrollment forms within the specified deadline. The form captures subject selections and verifies fee payment status before submission."),
    bullet("Exam Timetable Screen: Displays the examination schedule including dates, times, and venue details for each subject."),
    bullet("Result Screen: Enables students to view their published results, including subject-wise marks and CGPA. Results can also be downloaded as PDF documents for official record-keeping."),
    bullet("Exam Fee Screen: Integrates with the payment gateway to allow students to pay their examination fees directly through the application."),
    emptyPara(),
    subSectionHeading("2.4.3 Elective Subject Selection"),
    para("The Elective Selection Screen presents available optional subjects for the current semester, allowing students to choose their preferred elective from the available options. The selection is saved to Firestore and is visible to the administrator for seat allocation purposes. Once the selection deadline passes, the screen becomes read-only."),
    emptyPara(),
    subSectionHeading("2.4.4 Leave Management"),
    para("Students can submit leave applications through the Leave Screen by specifying the dates, reason for absence, and any supporting documentation. The application is forwarded to the student's coordinator for review. Students can track the status of their applications (Pending, Approved, Rejected) in real-time."),
    emptyPara(),
    subSectionHeading("2.4.5 Canteen Ordering System"),
    para("The Canteen Screen displays the current menu with item descriptions, prices, and availability status. Students can add items to a cart and place orders directly from the application. The Order History screen maintains a complete log of all past orders with their status and payment details."),
    emptyPara(),

    sectionHeading("2.5   Teacher and Coordinator Modules"),
    para("The Teacher Panel provides educators with tools to manage their classroom responsibilities efficiently:"),
    bullet("Students List: Displays a list of all students enrolled in the teacher's assigned class, with individual profile access."),
    bullet("Coordinator Leave Approval: Coordinators can review pending leave requests from students, view the stated reason, and either approve or reject the application. Approved leaves are reflected in the student's attendance records."),
    bullet("Assignment Management: Teachers can create and publish assignment tasks with deadlines, attach reference materials, and track submission status."),
    bullet("Timetable Screen: Displays the teacher's weekly lecture schedule, including class, subject, and room details."),
    emptyPara(),

    sectionHeading("2.6   Admin Panel"),
    para("The Administrator has the highest level of access in the system, with the ability to configure the entire application and manage all users and academic data:"),
    bullet("Admin Dashboard: Provides a high-level overview of the institution including total student count, teacher count, and active semester details."),
    bullet("College Setup: Allows the admin to configure branches, semesters, and their associated subjects and credits."),
    bullet("Result Management: Admins can upload semester results in bulk or individually for students, which are then published to the Result Screen upon confirmation."),
    bullet("Library Management: Manages the complete book inventory including additions, issuances, returns, and overdue tracking."),
    bullet("UFM Dashboard: Provides a dedicated interface for managing academic malpractice cases. Flagged students can be placed under suspension, temporarily restricting their access to examination features."),
    emptyPara(),

    sectionHeading("2.7   Module Feature Summary"),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 120, after: 240 },
      children: [new TextRun({ text: "Table 2.2   College Connect – Module-wise Feature Summary", font: FONT, size: 22, bold: true })],
    }),
    featuresTable,
    emptyPara(),

    sectionHeading("2.8   Technical Architecture"),
    para("The application follows a clean architecture pattern with a clear separation between the UI layer, the business logic layer, and the data layer. Firebase Firestore serves as the primary database, with collections organized by user roles, academic years, and modules."),
    emptyPara(),
    para("Real-time listeners are established for frequently changing data such as attendance, leave status, and order tracking. For static or infrequently changing data such as timetables and exam schedules, one-time fetch calls are used to optimize performance and minimize Firestore read costs."),
    emptyPara(),
    para("The UI is built using Google Fonts (Poppins family) combined with a carefully designed color palette to deliver a modern, professional aesthetic. Custom reusable widgets were developed for cards, form inputs, and data tables to maintain visual consistency across all screens."),
  ];
}

// ─── CHAPTER 3 ────────────────────────────────────────────────────────────────
function buildChapter3() {
  const techTable = new Table({
    width: { size: CONTENT_WIDTH, type: WidthType.DXA },
    columnWidths: [2500, 2500, 3666],
    rows: [
      new TableRow({ children: [headerCell("Firebase Service", 2500), headerCell("Purpose", 2500), headerCell("Usage in Gokuldiyugam", 3666)] }),
      ...([
        ["Firebase Authentication", "User Identity", "Email/Password, Google Sign-In, Guest Mode"],
        ["Cloud Firestore", "Real-time Database", "User profiles, kirtan metadata, Sabha schedules, admin config"],
        ["Firebase Storage", "Media Storage", "Darshan photos, audio files, Sabha Saar documents"],
        ["Firebase App Check", "Security", "Prevents unauthorized API access and data scraping"],
        ["Firebase Cloud Messaging", "Push Notifications", "Sabha reminders, news updates, admin announcements"],
      ].map((row, i) =>
        new TableRow({ children: [dataCell(row[0], 2500, i % 2 !== 0), dataCell(row[1], 2500, i % 2 !== 0), dataCell(row[2], 3666, i % 2 !== 0)] })
      )),
    ],
  });

  return [
    pageBreak(),
    chapterHeading("Chapter 3: Project 2 – Gokuldiyugam Application"),
    sectionHeading("3.1   Project Overview"),
    para("Gokuldiyugam is a feature-rich spiritual content management and community application developed for BAPS Badlapur Mandal. The application aims to bring the devotional experience of the Mandal to the fingertips of its members by digitizing daily religious content, organizational schedules, and administrative functions."),
    emptyPara(),
    para("The application was built using Flutter with Firebase as the backend, following the same architectural principles as College Connect. However, Gokuldiyugam introduced several additional complexities, including AI-powered content processing using Google's Gemini 1.5 Flash API, biometric authentication, custom music playback, and smart transliteration-based search."),
    emptyPara(),

    sectionHeading("3.2   Home Screen"),
    para("The Home Screen is designed as the central hub of the application, providing quick access to all major features through visually appealing feature cards. It incorporates the following key elements:"),
    emptyPara(),
    subSectionHeading("3.2.1 Dynamic Image Slider"),
    para("A prominent image carousel occupies the top portion of the Home Screen, displaying announcements, event photographs, and spiritual imagery curated by the admin. The slider images are stored in Firebase Storage and their URLs are managed through a Firestore document, enabling the admin to update the content without requiring an application update."),
    emptyPara(),
    subSectionHeading("3.2.2 Birthday Wish Feature"),
    para("A distinctive personalization feature greets users on their birthday with an animated dialog box displaying a customized spiritual message. The application checks the user's date of birth (stored in their Firestore profile) against the current date on each app launch, triggering the birthday greeting exactly once per year."),
    emptyPara(),
    subSectionHeading("3.2.3 Navigation Drawer"),
    para("A side navigation drawer provides quick access to Profile, Settings, and Logout functionality. The drawer also displays the logged-in user's name and profile photograph for immediate personalization."),
    emptyPara(),

    sectionHeading("3.3   Daily Darshan Module"),
    para("The Daily Darshan screen presents high-resolution photographs of the daily worship and rituals performed at the Badlapur temple. Photographs are uploaded by authorized administrators and are instantly visible to all users through real-time Firestore listeners. The Coil image loading library is used to ensure fast, progressive, and high-quality image rendering with proper caching to minimize repeated data downloads."),
    emptyPara(),

    sectionHeading("3.4   Kirtan and Media Section"),
    para("The Kirtan module is among the most technically sophisticated components of the application, offering a complete digital library of devotional songs:"),
    emptyPara(),
    subSectionHeading("3.4.1 Kirtan Listing and Categories"),
    para("Kirtans are organized into themed categories such as Shanti (peace), Bhakti (devotion), and Utsav (festival). The listing screen displays kirtan titles, duration, and category tags. Users can browse by category or search directly."),
    emptyPara(),
    subSectionHeading("3.4.2 Kirtan Player"),
    para("A fully functional music player was implemented with controls for Play, Pause, Next, Previous, and seek (forward/backward). The player maintains its state across screen navigations, allowing users to browse other sections of the app while music continues to play in the background."),
    emptyPara(),
    subSectionHeading("3.4.3 Smart Transliteration Search for Lyrics"),
    para("The lyrics search feature implements a custom Smart Transliteration algorithm. Users can type Gujarati kirtan lyrics in Roman/English script, and the system automatically maps the phonetic input to matching Gujarati text in the database. This dramatically lowers the barrier for users who are not comfortable typing in the Gujarati script on mobile keyboards."),
    emptyPara(),
    subSectionHeading("3.4.4 Personal Playlist"),
    para("Users can create and manage personal playlists by adding their favourite kirtans to a playlist stored in their Firestore user document. Playlists can be played sequentially with full player controls."),
    emptyPara(),

    sectionHeading("3.5   Sabha and Satsang Management"),
    subSectionHeading("3.5.1 Sabha Timetable"),
    para("The Sabha Timetable screen displays a structured weekly schedule of all Sabhas (congregational gatherings) organized by the Mandal, including Youth Sabha, Children's Sabha, and Women's Sabha. Each entry includes the day, time, location, and presiding facilitator."),
    emptyPara(),
    subSectionHeading("3.5.2 Sabha Saar (Summary)"),
    para("The Sabha Saar screen allows users to access the written summaries of past Sabhas, uploaded by the admin in PDF, Word, or plain text formats. The application uses the Google Docs Viewer integration to render documents directly within the app without requiring the user to download them. The AI integration using Gemini 1.5 Flash was employed to automatically generate concise summaries of uploaded Sabha content."),
    emptyPara(),
    subSectionHeading("3.5.3 Satsang News"),
    para("The Satsang News section serves as a digital newsletter for the Mandal, featuring updates, announcements, and news about upcoming events and organizational activities. News articles are managed by the admin through the Admin Panel and are displayed in a chronological feed."),
    emptyPara(),

    sectionHeading("3.6   Admin Panel"),
    para("The Admin Panel in Gokuldiyugam is accessible exclusively to users designated as Host or Sub-Host by the super administrator. It provides complete control over the application's content and user base:"),
    bullet("User Management: View all registered users, change their roles (e.g., promote a user to Sub-Host), and manage permissions."),
    bullet("Content Upload: Update Home Screen slider images, upload new kirtan lyrics, add Sabha Saar documents, and publish Satsang News articles."),
    bullet("Feedback Review: View messages and queries submitted by users through the in-app feedback form."),
    bullet("Password Request Management: Review and approve password reset requests submitted by users who have forgotten their credentials."),
    emptyPara(),

    sectionHeading("3.7   Authentication and Security"),
    para("Gokuldiyugam implements a multi-layered authentication and security framework:"),
    bullet("Standard Login: Email and password-based authentication through Firebase Authentication."),
    bullet("Google Sign-In: One-tap login using existing Google accounts for ease of access."),
    bullet("Guest Mode: Allows unauthenticated users to access a limited subset of the application's content (Daily Darshan, Sabha Timetable) without creating an account."),
    bullet("Biometric Authentication: For returning users, the application supports fingerprint and Face ID authentication as an alternative to entering the password on each launch, implemented using Flutter's local_auth package."),
    bullet("Firebase App Check: Integrates with the device's integrity verification systems to ensure that only genuine, unmodified instances of the application can access Firebase backend resources, protecting against automated abuse and unauthorized data extraction."),
    emptyPara(),

    sectionHeading("3.8   Firebase Services Summary"),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 120, after: 240 },
      children: [new TextRun({ text: "Table 3.2   Firebase Services Used in Gokuldiyugam", font: FONT, size: 22, bold: true })],
    }),
    techTable,
  ];
}

// ─── CHAPTER 4 ────────────────────────────────────────────────────────────────
function buildChapter4() {
  return [
    pageBreak(),
    chapterHeading("Chapter 4: Learning Outcomes and Experience"),
    sectionHeading("4.1   Technical Skills Acquired"),
    para("The six-month internship was a period of intensive technical skill development. The following competencies were acquired and refined through hands-on project work:"),
    emptyPara(),
    subSectionHeading("4.1.1 Flutter and Dart"),
    para("The internship provided deep practical expertise in Flutter application development, from fundamental widget composition to advanced state management patterns. The experience of building two complete, production-grade applications from scratch solidified understanding of Flutter's rendering engine, widget lifecycle, and performance optimization techniques."),
    emptyPara(),
    subSectionHeading("4.1.2 Firebase Ecosystem"),
    para("Extensive work with Firebase services across both projects provided comprehensive knowledge of cloud-based backend development without traditional server management. Real-time data synchronization with Firestore, file management with Storage, user identity management with Authentication, and application security with App Check were all mastered through practical implementation."),
    emptyPara(),
    subSectionHeading("4.1.3 AI Integration"),
    para("The integration of Google's Gemini 1.5 Flash API into the Gokuldiyugam application for automated Sabha Saar summarization provided initial exposure to applied Artificial Intelligence in mobile applications. This included working with REST API calls, handling streaming responses, and presenting AI-generated content in a user-friendly format."),
    emptyPara(),
    subSectionHeading("4.1.4 Git and Version Control"),
    para("From the very first day of the internship, Git was used as the primary tool for all code management activities. The practice of creating feature branches, writing meaningful commit messages, raising pull requests, and performing code reviews through Git became second nature over the course of six months."),
    emptyPara(),

    sectionHeading("4.2   Professional Skills Developed"),
    para("Beyond technical competencies, the internship fostered the development of several critical professional skills:"),
    bullet("Project Planning: Breaking down complex feature requirements into manageable development tasks and estimating effort."),
    bullet("Communication: Regular updates to team leads, participation in code review discussions, and documentation writing."),
    bullet("Problem Solving: Independently debugging complex issues involving asynchronous operations, Firebase security rules, and UI rendering anomalies."),
    bullet("Time Management: Delivering features within sprint deadlines while maintaining code quality standards."),
    bullet("Documentation: Writing comprehensive code comments, README files, and technical documentation for both projects."),
    emptyPara(),

    sectionHeading("4.3   Work Environment and Team Support"),
    para("The work environment at [Company Name] was collaborative, encouraging, and highly professional. The team comprised experienced Flutter developers and Firebase specialists who were always willing to provide guidance, conduct knowledge-sharing sessions, and review code constructively. The open-door policy of the management allowed interns to raise questions and suggestions without hesitation."),
    emptyPara(),
    para("The company provided all necessary hardware, software licenses, and access to development tools. Regular weekly meetings ensured that the intern's progress was tracked, feedback was provided promptly, and blockers were resolved without significant delays. The entire team's cooperative attitude made the internship experience particularly productive and enjoyable."),
    emptyPara(),

    sectionHeading("4.4   Challenges Encountered and Solutions"),
    para("The internship also presented several technical and professional challenges that contributed significantly to the learning experience:"),
    emptyPara(),
    subSectionHeading("4.4.1 Firebase Security Rules"),
    para("Configuring Firestore Security Rules to correctly enforce role-based access while still allowing the application to function correctly across all user types was a significant challenge. Extensive study of the Firebase documentation and iterative testing using the Firebase Emulator Suite were employed to arrive at a robust rule configuration."),
    emptyPara(),
    subSectionHeading("4.4.2 Background Audio Playback"),
    para("Implementing continuous background audio playback for the Kirtan Player in Gokuldiyugam while maintaining player state across screen navigations required careful implementation of Flutter's audio service and proper foreground service configuration for Android."),
    emptyPara(),
    subSectionHeading("4.4.3 Smart Transliteration Algorithm"),
    para("Developing the transliteration mapping system for the Kirtan lyrics search required research into Gujarati phonetic patterns and the creation of a custom mapping table that correctly handles consonant clusters, matras (vowel diacritics), and conjunct characters."),
  ];
}

// ─── CHAPTER 5 ────────────────────────────────────────────────────────────────
function buildChapter5() {
  return [
    pageBreak(),
    chapterHeading("Chapter 5: Conclusion and Future Scope"),
    sectionHeading("5.1   Conclusion"),
    para("This industrial internship at [Company Name] over a period of six months has been a transformative experience that significantly enhanced both technical and professional capabilities. The opportunity to work on two complete, real-world mobile applications – College Connect (CMS) and Gokuldiyugam – from initial setup to final deployment provided invaluable insights into the software development lifecycle as practiced in a professional industry environment."),
    emptyPara(),
    para("The internship commenced with a foundational study of Git version control, which proved to be an essential skill for all subsequent development activities. The mastery of Flutter and Firebase through hands-on project work goes far beyond what could be achieved in an academic setting, as it involved dealing with real user requirements, production-grade code quality standards, and the constraints of live deployment environments."),
    emptyPara(),
    para("The development of College Connect demonstrated how technology can be leveraged to solve complex organizational challenges in the education sector, while Gokuldiyugam illustrated the application of the same technology stack to create meaningful community-driven solutions. Both projects reinforced the importance of user-centric design, robust backend architecture, and clean, maintainable code."),
    emptyPara(),

    sectionHeading("5.2   Future Scope"),
    para("Both applications developed during the internship have significant potential for future enhancements:"),
    emptyPara(),
    subSectionHeading("5.2.1 College Connect – Future Enhancements"),
    bullet("Integration of a Payment Gateway: Full payment gateway integration for fee collection, exam fees, and canteen payments within the application."),
    bullet("Advanced Analytics Dashboard: An analytics module for administrators providing insights into student performance trends, attendance patterns, and canteen sales."),
    bullet("Offline Support: Implementation of local data caching using Hive or SQFlite to allow students and teachers to access key information even without an internet connection."),
    bullet("Push Notifications: Automated notifications for attendance warnings, result publication, and upcoming examination deadlines."),
    emptyPara(),
    subSectionHeading("5.2.2 Gokuldiyugam – Future Enhancements"),
    bullet("Live Streaming Integration: Embedding live streaming capabilities to broadcast Sabha sessions to members who cannot attend in person."),
    bullet("Multi-language Support: Extension of the application to support Hindi and English in addition to Gujarati, making it accessible to a wider audience."),
    bullet("Advanced AI Features: Expanding the use of Gemini API for generating personalized spiritual reading recommendations based on user preferences."),
    bullet("Event Management Module: A dedicated module for managing registrations and logistics for large-scale Mandal events and festivals."),
    emptyPara(),

    sectionHeading("5.3   Final Remarks"),
    para("This internship has been an invaluable investment in professional growth and technical expertise. The experience of contributing to real projects that serve actual users is something that cannot be replicated in a classroom environment. The skills, best practices, and professional work ethic cultivated during these six months will serve as a strong foundation for a successful career in software development."),
    emptyPara(),
    para("The intern expresses deep gratitude to [Company Name] for providing such a comprehensive and enriching internship experience, and looks forward to applying these learnings in future professional endeavors."),
  ];
}

// ─── REFERENCES ───────────────────────────────────────────────────────────────
function buildReferences() {
  const refs = [
    "Flutter Team. (2024). Flutter Documentation. Google LLC. https://docs.flutter.dev/",
    "Firebase Team. (2024). Firebase Documentation. Google LLC. https://firebase.google.com/docs",
    "Dart Team. (2024). Dart Programming Language Documentation. Google LLC. https://dart.dev/guides",
    "Chacon, S. and Straub, B. (2014). Pro Git (2nd ed.). Apress. https://git-scm.com/book/en/v2",
    "Google LLC. (2024). Gemini API Documentation. https://ai.google.dev/gemini-api/docs",
    "Firebase Team. (2024). Firebase App Check Documentation. https://firebase.google.com/docs/app-check",
    "pub.dev. (2024). Flutter and Dart Package Repository. https://pub.dev/",
    "Flutter Team. (2024). State Management in Flutter. https://docs.flutter.dev/data-and-backend/state-mgmt/intro",
    "Google LLC. (2024). Cloud Firestore Security Rules Reference. https://firebase.google.com/docs/firestore/security/get-started",
    "Flutter Community. (2024). just_audio Package Documentation. https://pub.dev/packages/just_audio",
  ];

  return [
    pageBreak(),
    new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 480, after: 480 },
      children: [new TextRun({ text: "REFERENCES", font: FONT, size: 32, bold: true })],
    }),
    ...refs.map(ref => new Paragraph({
      spacing: { line: 320, lineRule: "auto", before: 60, after: 60 },
      indent: { left: 720, hanging: 720 },
      children: [new TextRun({ text: ref, font: FONT, size: 24 })],
    })),
  ];
}

// ─── DOCUMENT ASSEMBLY ────────────────────────────────────────────────────────
const ENROLL = "[Enrollment No.]";
const COLLEGE = "[College Name]";

const doc = new Document({
  numbering: {
    config: [
      {
        reference: "bullets",
        levels: [{
          level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
          style: { paragraph: { indent: { left: 720, hanging: 360 } } }
        }]
      },
    ]
  },
  styles: {
    default: {
      document: { run: { font: FONT, size: 24 } }
    },
    paragraphStyles: [
      {
        id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 32, bold: true, font: FONT, color: COLOR_BLACK },
        paragraph: { spacing: { before: 480, after: 360 }, outlineLevel: 0, alignment: AlignmentType.CENTER }
      },
      {
        id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 28, bold: true, font: FONT, color: COLOR_BLACK },
        paragraph: { spacing: { before: 360, after: 240 }, outlineLevel: 1 }
      },
      {
        id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 24, bold: true, font: FONT, color: COLOR_BLACK },
        paragraph: { spacing: { before: 240, after: 180 }, outlineLevel: 2 }
      },
    ]
  },
  sections: [
    // ── Section 1: Front matter (no header/footer, roman page numbers) ─────
    {
      properties: {
        page: {
          size: { width: 11906, height: 16838 },
          margin: { top: 1440, right: 1440, bottom: 1440, left: 1800 },
          pageNumbers: { formatType: "lowerRoman" },
        }
      },
      children: [
        ...buildCoverPage(),
        ...buildCertificate(),
        ...buildDeclaration(),
        ...buildAcknowledgement(),
        ...buildAbstract(),
        ...buildListOfFigures(),
        ...buildListOfTables(),
        ...buildAbbreviations(),
        ...buildTOC(),
      ],
    },
    // ── Section 2: Main chapters (headers + footers, arabic numerals) ──────
    {
      properties: {
        page: {
          size: { width: 11906, height: 16838 },
          margin: { top: 1440, right: 1440, bottom: 1800, left: 1800 },
          pageNumbers: { formatType: "decimal", start: 1 },
        }
      },
      headers: { default: makeHeader("Industrial Internship Report", ENROLL) },
      footers: { default: makeFooter(COLLEGE) },
      children: [
        ...buildChapter1(),
        ...buildChapter2(),
        ...buildChapter3(),
        ...buildChapter4(),
        ...buildChapter5(),
        ...buildReferences(),
      ],
    },
  ],
});

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("/home/claude/Internship_Report.docx", buffer);
  console.log("Report created successfully!");
});