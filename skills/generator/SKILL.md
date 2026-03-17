---
name: generator
description: This skill should be used when the user asks to "generate 5G note", "create O-RAN note", "生成技術筆記", "生成 2026 W2", mentions "5G technical note", "O-RAN learning material", or discusses 5G/O-RAN topics and wants to create learning documentation.
version: 2.1.0
---

# 5G/O-RAN Technical Note Generator

Generate 5G/O-RAN technical learning notes as 研究紀錄 (research records), outputting both Markdown and Word (.docx) files.

## When This Skill Applies

- User asks to generate 5G or O-RAN technical notes
- User says "生成 2026 WN" (weekly note generation)
- User wants to create learning notes for 5G Core, RIC, xApp, or related topics

## Parameter Handling

The user may provide arguments after `/generator`:
- `--category <value>`: One of: oran, xapp, ric, 5g-core, smart-factory, ai-ml, mec, slicing, oss
- `--tags <comma-separated>`: E.g., "E2 介面,KPM,SDL"
- `--title <value>`: Optional custom title
- `--description <text>`: Additional context
- `--week <YYYY-WNN>`: Target week (e.g., "2026-W02"). Auto-calculates date and filename.

### If the user provides parameters:
Use them directly without asking. Skip to generation.

### If the user says "生成 YYYY WN" (e.g., "生成 2026 W2"):
Extract year and week number. Ask only for Category and Tags, then generate immediately.

### If the user provides NO parameters (interactive mode):
Ask using AskUserQuestion with these questions:

1. **Topic Category** (header: "Category"):
   - Label: "O-RAN Architecture", Description: "Open RAN architecture, interfaces, and protocols"
   - Label: "xApp Development", Description: "Developing xApps for Near-RT RIC"
   - Label: "RIC Platform", Description: "RIC platform architecture and deployment"
   - Label: "5G Core Network", Description: "5G Core network functions and procedures"
   - Label: "Smart Factory", Description: "5G applications in smart manufacturing"
   - Label: "AI/ML Applications", Description: "AI/ML for network optimization"
   - Label: "MEC (Edge Computing)", Description: "Multi-access Edge Computing"
   - Label: "Network Slicing", Description: "5G network slicing technologies"
   - Label: "OSS (Operations Support System)", Description: "OSS/BSS systems, service management, and orchestration"

2. **Related Tags** (header: "Tags", multiSelect: true):
   - Label: "E2 介面", Description: "E2 interface between RIC and RAN"
   - Label: "A1 Policy", Description: "A1 interface for policy management"
   - Label: "Near-RT RIC", Description: "Near real-time RAN Intelligent Controller"
   - Label: "Non-RT RIC", Description: "Non real-time RIC"
   - Label: "KPM", Description: "Key Performance Measurement"
   - Label: "SDL", Description: "Shared Data Layer"
   - Label: "O1 Interface", Description: "O1 interface for O&M operations"
   - Label: "SMO", Description: "Service Management and Orchestration"

## Writing Style: 研究紀錄

**CRITICAL**: Notes must read like a human researcher's study records, NOT like an AI-generated textbook.

### DO:
- Write in the style of existing notes in the project (202548~202552 as reference)
- Use `**一、 Section Name**` format for section headings
- Write flowing paragraphs that synthesize information
- Include practical code examples and summary tables naturally
- Keep each note 200~400 lines, 4 sections per note

### DO NOT:
- Add table of contents or section index
- Add any AI-generated metadata footer (no `*產生時間*`, `*檔案編號*`)
- Write in a textbook/tutorial tone
- Add emojis in generated content

## Generation Requirements

### Content structure
- **Title**: `## {Topic Name}技術筆記 - {Main Tag or Concept}`
- **Sections**: 4 sections per note, format: `**一、 Section Name**`
- **Each section**: 3-5 paragraphs with tables and code examples where appropriate
- **Section separator**: `---` between sections
- **Total length**: 200~400 lines per note file

### Must include:
- Practical code examples (Python/YAML preferred) with syntax highlighting and inline comments
- Tables summarizing key concepts
- Realistic, standards-based examples
- **Diagrams**: Use ` ```mermaid ` blocks for architecture/flow diagrams (NOT ASCII art). The docx generator renders them as PNG images automatically.

## File Naming

Filename format: `YYYYMMDD.md` where YYYYMMDD = **Monday of the target ISO week**.

Calculation:
1. Determine the ISO week number from user input or current date
2. Find the Monday of that week
3. Format as YYYYMMDD

Examples:
- 2026 W02 → Monday is 2026-01-05 → `20260105.md`
- 2026 W12 → Monday is 2026-03-16 → `20260316.md`

## Output Workflow

### Step 1: Generate Markdown
1. Generate note content following the style rules above
2. Write to `YYYYMMDD.md` in the current working directory
3. Confirm: "Generated `YYYYMMDD.md` (N lines)"

### Step 2: Generate Word (.docx)
After Markdown is generated, **automatically** generate the Word file:

1. Run the generator script:
```bash
python3 generator/generate_docx.py <YYYYMMDD> <input.md>
```

2. The script auto-discovers the template docx (matching `*_研究記錄簿_W*_*.docx`) and derives the output filename from it. It:
   - Updates cover page: 記錄日期 → YYYY/MM/DD, 年份週別 → YYYYWNN
   - Replaces content from paragraph 12 onward
   - Renders ` ```mermaid ` blocks as PNG images (via mmdc/mermaid-cli)
   - Applies Pygments syntax highlighting to code blocks (Consolas 10pt, gray background)
   - Body text: 新細明體 12pt

### Step 3: Present results
```
完成。生成的檔案：
- Markdown: ./YYYYMMDD.md (N lines)
- Word: ./<output docx filename>

請檢視內容，如需修改再告訴我。
```

## Important Notes

- Write in Traditional Chinese (繁體中文)
- Focus on technical accuracy and practical utility
- Content must look like authentic research records, not AI output
- Include realistic examples based on actual 5G/O-RAN standards
- Dense and information-rich content

## Category Mappings

- oran → "O-RAN 架構"
- xapp → "xApp 開發"
- ric → "RIC 平台"
- 5g-core → "5G 核心網路"
- smart-factory → "智慧工廠"
- ai-ml → "AI/ML 應用"
- mec → "邊緣運算 MEC"
- slicing → "網路切片"
- oss → "OSS 營運支撐系統"
