"""XML template strings for weekly report PPTX generation.

These match the formatting in the company .potx template:
- Sub-items: Wingdings hollow bullet (&#xF06E;), sz=1400, font 微軟正黑體
- Blank separators between sections
"""


def xml_escape(text):
    """Escape special characters for XML content."""
    text = text.replace("&", "&amp;")
    text = text.replace("<", "&lt;")
    text = text.replace(">", "&gt;")
    text = text.replace('"', "&quot;")
    return text


def sub_item_xml(text):
    """Return XML for one sub-item paragraph (sz=1400, Wingdings hollow bullet)."""
    escaped = xml_escape(text)
    return f'''          <a:p>
            <a:pPr marL="571500" indent="-285840">
              <a:lnSpc>
                <a:spcPct val="150000"/>
              </a:lnSpc>
              <a:buClr>
                <a:srgbClr val="000000"/>
              </a:buClr>
              <a:buFont typeface="Wingdings" charset="2"/>
              <a:buChar char="&#xF06E;"/>
            </a:pPr>
            <a:r>
              <a:rPr b="0" lang="zh-TW" sz="1400" spc="-1" strike="noStrike">
                <a:solidFill>
                  <a:srgbClr val="000000"/>
                </a:solidFill>
                <a:latin typeface="\u5fae\u8edf\u6b63\u9ed1\u9ad4"/>
                <a:ea typeface="\u5fae\u8edf\u6b63\u9ed1\u9ad4"/>
              </a:rPr>
              <a:t>{escaped}</a:t>
            </a:r>
            <a:endParaRPr b="0" lang="en-US" sz="1400" spc="-1" strike="noStrike">
              <a:solidFill>
                <a:srgbClr val="000000"/>
              </a:solidFill>
              <a:latin typeface="Arial"/>
            </a:endParaRPr>
          </a:p>'''


BLANK_XML = '''          <a:p>
            <a:pPr>
              <a:lnSpc>
                <a:spcPct val="150000"/>
              </a:lnSpc>
            </a:pPr>
            <a:endParaRPr b="0" lang="en-US" sz="1400" spc="-1" strike="noStrike">
              <a:solidFill>
                <a:srgbClr val="000000"/>
              </a:solidFill>
              <a:latin typeface="Arial"/>
            </a:endParaRPr>
          </a:p>'''


# Section anchors in slide XML — used to locate where to insert sub-items
SECTION_ANCHORS = {
    "objective": "<a:t>目標</a:t>",
    "progress_status": "<a:t>(Close/In progress/Pending)</a:t>",
    "difficulty": "<a:t>困難</a:t>",
    "solution": "<a:t>方向 </a:t>",
}
