---
name: generator
description: This skill should be used when the user asks to "generate 5G note", "create O-RAN note", "生成技術筆記", mentions "5G technical note", "O-RAN learning material", or discusses 5G/O-RAN topics and wants to create learning documentation.
version: 1.0.0
---

# 5G/O-RAN Technical Note Generator

This skill generates comprehensive 5G/O-RAN technical learning notes in Traditional Chinese (繁體中文).

## When This Skill Applies

Use this skill when the user wants to:
- Generate 5G or O-RAN technical documentation
- Create learning notes for 5G Core, RIC, xApp, or related topics
- Document 5G technologies like network slicing, MEC, AI/ML applications
- Produce reference material for 5G/O-RAN standards

## Parameter Handling

The user may provide command line arguments after `/generator`:
- `--category <value>`: One of: oran, xapp, ric, 5g-core, smart-factory, ai-ml, mec, slicing, oss
- `--tags <comma-separated>`: E.g., "E2 介面,KPM,SDL"
- `--title <value>`: Optional custom title
- `--description <text>`: Additional context or specific requirements
- `--sections <number>`: 8, 12 (default), or 16
- `--filename <name>`: Custom filename (without .md extension)

### If the user provides parameters:
Use them directly without asking for confirmation. Skip to the generation step.

### If the user provides NO parameters (interactive mode):
Ask the user to select options using the AskUserQuestion tool with these questions:

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

3. **Section Count** (header: "Sections"):
   - Label: "8 sections (Brief)", Description: "Quick overview with 8 main sections"
   - Label: "12 sections (Standard) (Recommended)", Description: "Standard depth with 12 sections"
   - Label: "16 sections (Detailed)", Description: "In-depth coverage with 16 sections"

4. **File Name** (header: "Filename"):
   - Label: "Auto (YYYYWW.md) (Recommended)", Description: "Use week-based naming, e.g., 202603.md"
   - Label: "Custom", Description: "Enter a custom filename"

If user selects "Custom", ask them to provide the filename (without .md extension).

After collecting parameters, acknowledge them and proceed to generation.

## Generation Requirements

Generate the note with the following structure:

1. **Title format**: `## {Topic Name}技術筆記 - {Main Tag or Concept}`

2. **Content structure**:
   - Use numbered sections in format: `**一、 Section Name**` followed by content
   - Include {sections} sections total (from --sections parameter or user choice)
   - Each section should be substantive (3-5 paragraphs or equivalent)

3. **Must include**:
   - Practical code examples (Python/YAML preferred)
   - Tables summarizing key concepts
   - Bullet-point lists for clarity
   - Notes on best practices and pitfalls

4. **Code block requirements**:
   - Use proper syntax highlighting
   - Include brief inline comments
   - Show realistic, runnable examples

5. **Footer format**:
```
---
*產生時間: {current_datetime}*
*檔案編號: {YYYYWW}.md*
```

Where YYYYWW is calculated as: current year + ISO week number (e.g., 202602)

## File Naming

Use the filename from `--filename` parameter or user's choice. If "Auto" was selected or no filename specified, calculate as `YYYYWW.md` where:
- YYYY = current year (2026)
- WW = ISO week number (01-53), zero-padded

For example: 202602.md for week 2 of 2026

If user provided a custom filename, append `.md` extension if not already present.

## Output Behavior

After generating the note:

1. **Display the full markdown content** to the user
2. **Write the file** to `{filename}.md` in the current working directory
3. Confirm to the user: "✅ Generated `{filename}.md` ({file_size} bytes)"

## Important Notes

- Write in Traditional Chinese (繁體中文)
- Use Markdown format throughout
- Focus on technical accuracy and practical utility
- Include realistic examples based on actual 5G/O-RAN standards
- The note should be reference material suitable for learning and quick review
- Do NOT use emojis in the generated content (only in confirmation messages)
- Make the content dense and information-rich

## Category Mappings

Use these full names when generating content:
- oran → "O-RAN 架構"
- xapp → "xApp 開發"
- ric → "RIC 平台"
- 5g-core → "5G 核心網路"
- smart-factory → "智慧工廠"
- ai-ml → "AI/ML 應用"
- mec → "邊緣運算 MEC"
- slicing → "網路切片"
- oss → "OSS 營運支撐系統"
