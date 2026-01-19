#!/usr/bin/env python3
"""
Generate Weekly Report PowerPoint with clean formatting.

Usage:
    python generate_pptx.py <week_number> <markdown_file> <output_pptx>

Requirements:
    pip install python-pptx
"""

import sys
import re
from pptx import Presentation
from pptx.util import Pt, Inches
from pptx.enum.text import PP_ALIGN
from pptx.dml.color import RGBColor

# Font specifications
FONT_CHINESE = "微軟正黑體"
FONT_ENGLISH = "Calibri"
SECTION_HEADER_SIZE = Pt(18)  # 目標、進度、困難、解決方案
CONTENT_SIZE = Pt(14)         # 內容

def has_chinese(text):
    """Check if text contains Chinese characters."""
    return bool(re.search(r'[\u4e00-\u9fff]', text))

def parse_markdown(md_file):
    """Parse markdown file and extract tasks with their sections."""
    with open(md_file, 'r', encoding='utf-8') as f:
        content = f.read()

    tasks = []
    current_task = None
    current_section = None
    current_content = []
    in_format_spec = False

    for line in content.split('\n'):
        # Handle horizontal rule separators between tasks
        if line.strip() == '---':
            if in_format_spec:
                in_format_spec = False
                continue
            elif current_task:
                if current_section:
                    current_task['sections'][current_section] = current_content
                tasks.append(current_task)
                current_task = None
                current_section = None
                current_content = []
            continue

        if in_format_spec or line.startswith('**格式規範'):
            in_format_spec = True
            continue

        # Task headers (## Task N: Name)
        if line.startswith('## ') and ('Task' in line or '任務' in line or ':' in line):
            if current_task and current_section:
                current_task['sections'][current_section] = current_content
            if current_task:
                tasks.append(current_task)

            task_name = line[3:].strip()
            current_task = {'name': task_name, 'sections': {}}
            current_section = None
            current_content = []

        # Subsection headers (### Header)
        elif line.startswith('### '):
            if current_section and current_task:
                current_task['sections'][current_section] = current_content
            current_section = line[4:].strip()
            current_content = []

        # Indented content items (2+ spaces)
        elif line.startswith('  ') and line.strip() and current_section:
            current_content.append(line.strip())

    # Save last section and task
    if current_task and current_section:
        current_task['sections'][current_section] = current_content
    if current_task:
        tasks.append(current_task)

    return tasks

def create_task_slide(prs, task_name, sections):
    """Create a clean slide for a task."""
    # Use blank layout
    slide = prs.slides.add_slide(prs.slide_layouts[6])

    # Add task title
    title_box = slide.shapes.add_textbox(Inches(0.5), Inches(0.3), Inches(9), Inches(0.6))
    title_frame = title_box.text_frame
    title_frame.text = task_name
    title_para = title_frame.paragraphs[0]
    title_para.font.size = Pt(24)
    title_para.font.bold = True
    title_para.font.name = FONT_CHINESE if has_chinese(task_name) else FONT_ENGLISH
    title_para.font.color.rgb = RGBColor(0, 0, 0)

    # Add content box
    content_box = slide.shapes.add_textbox(Inches(0.5), Inches(1.0), Inches(9), Inches(6))
    text_frame = content_box.text_frame
    text_frame.word_wrap = True

    # Section mapping
    section_mapping = {
        'Objective': '目標',
        '本週進度': '進度',
        '困難': '困難',
        '解決方案': '解決方案/方向'
    }

    first_section = True
    for section_key, section_display in section_mapping.items():
        if section_key not in sections:
            continue

        # Add spacing before section (except first)
        if not first_section:
            p = text_frame.add_paragraph()
            p.text = ""
        first_section = False

        # Add section header (目標, 進度, etc.) - Size 18
        p = text_frame.add_paragraph()
        p.text = section_display
        p.font.size = SECTION_HEADER_SIZE
        p.font.bold = True
        p.font.name = FONT_CHINESE
        p.font.color.rgb = RGBColor(0, 0, 0)
        p.space_after = Pt(6)

        # Add content items - Size 14 (no icon, let user add native bullets)
        for content in sections[section_key]:
            p = text_frame.add_paragraph()
            p.text = content
            p.font.size = CONTENT_SIZE
            p.font.name = FONT_CHINESE if has_chinese(content) else FONT_ENGLISH
            p.font.color.rgb = RGBColor(0, 0, 0)
            p.level = 1  # Indent to show hierarchy
            p.space_after = Pt(3)

    return slide

def main():
    if len(sys.argv) < 4:
        print("Usage: python generate_pptx.py <week_number> <markdown_file> <output_pptx>")
        sys.exit(1)

    week_num = sys.argv[1]
    md_file = sys.argv[2]
    output_file = sys.argv[3]

    # Parse markdown
    tasks = parse_markdown(md_file)

    # Create presentation
    prs = Presentation()
    prs.slide_width = Inches(10)
    prs.slide_height = Inches(7.5)

    # Create title slide
    title_slide = prs.slides.add_slide(prs.slide_layouts[6])
    title_box = title_slide.shapes.add_textbox(Inches(1), Inches(3), Inches(8), Inches(1.5))
    title_frame = title_box.text_frame
    title_frame.text = f"Week {week_num} 週報"
    title_para = title_frame.paragraphs[0]
    title_para.alignment = PP_ALIGN.CENTER
    title_para.font.size = Pt(32)
    title_para.font.bold = True
    title_para.font.name = FONT_CHINESE
    title_para.font.color.rgb = RGBColor(0, 0, 0)

    # Create one slide per task
    for task in tasks:
        create_task_slide(prs, task['name'], task['sections'])

    # Save
    prs.save(output_file)
    print(f"✓ Generated: {output_file}")
    print(f"✓ Total slides: {len(prs.slides)} (1 title + {len(tasks)} task slides)")
    print(f"✓ Section headers: 18pt, Content: 14pt (no icons, add bullets in PowerPoint)")

if __name__ == "__main__":
    main()
