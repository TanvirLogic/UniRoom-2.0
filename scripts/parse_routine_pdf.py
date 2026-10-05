#!/usr/bin/env python3
"""
UniRoom-Live 2.0 - Deterministic PDF Timetable Parser
Extracts structured academic routine slots from multi-page PDF timetable tables.
Outputs clean JSON adhering strictly to IngestRoutineDto format.
"""

import sys
import os
import json
import re
import argparse
from typing import List, Dict, Any, Optional

try:
    import pdfplumber
except ImportError:
    import subprocess
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "pdfplumber", "--quiet"])
        import pdfplumber
    except Exception as e:
        print(json.dumps({
            "error": f"Missing dependency 'pdfplumber'. Automatic install failed: {e}. Please run: pip install pdfplumber"
        }), file=sys.stderr)
        sys.exit(1)


DAY_NAME_MAP = {
    "monday": "MON",
    "mon": "MON",
    "tuesday": "TUE",
    "tue": "TUE",
    "wednesday": "WED",
    "wed": "WED",
    "thursday": "THU",
    "thu": "THU",
    "friday": "FRI",
    "fri": "FRI",
    "saturday": "SAT",
    "sat": "SAT",
    "sunday": "SUN",
    "sun": "SUN"
}

FALLBACK_PERIODS = [
    {"period": 1, "start": "08:45", "end": "10:05"},
    {"period": 2, "start": "10:05", "end": "11:25"},
    {"period": 3, "start": "11:25", "end": "12:45"},
    {"period": 4, "start": "13:15", "end": "14:35"},
    {"period": 5, "start": "14:35", "end": "15:55"},
    {"period": 6, "start": "15:55", "end": "17:15"},
]


def normalize_time_str(t: str) -> str:
    """Format time string to HH:mm with 2-digit hour."""
    parts = t.strip().split(":")
    if len(parts) == 2:
        return f"{int(parts[0]):02d}:{parts[1]}"
    return t.strip()


def parse_cell_text(cell_text: str) -> Optional[Dict[str, str]]:
    """
    Parse a single routine cell into courseCode, facultyCode, and roomNumber.
    Format examples:
      'CSE06131 01 DNS AI Lab 5210 (514)'
      'ENG0232102 RIR Lab 5220 (515)'
      'MAT05411 01 AMU 5190 (512)'
      'PHY0533102 JHB Phy Lab 6080 (601)'
      'MIS061140 3 FAS 0020 (B106/1)'
    """
    if not cell_text or not cell_text.strip():
        return None

    raw_lines = [l.strip() for l in cell_text.split('\n') if l.strip()]
    if not raw_lines:
        return None

    # Line 1: Course code
    course_code = raw_lines[0].replace(' ', '').upper()
    idx = 1

    # Line 2 (optional): Section number if standalone digits (e.g. '01', '3')
    if idx < len(raw_lines) and re.match(r'^\d+$', raw_lines[idx]):
        idx += 1

    # Line 3 (or next): Faculty Initials (2-4 uppercase characters)
    faculty_code = "TBA"
    if idx < len(raw_lines) and re.match(r'^[A-Z]{2,4}$', raw_lines[idx].strip()):
        faculty_code = raw_lines[idx].strip().upper()
        idx += 1

    # Remaining lines: Physical Room designation
    room_number = " ".join(raw_lines[idx:]) if idx < len(raw_lines) else "TBA"
    room_number = re.sub(r'\s+', ' ', room_number).strip()

    return {
        "courseCode": course_code,
        "facultyCode": faculty_code,
        "roomNumber": room_number
    }


def parse_pdf_timetable(
    pdf_path: str,
    university: str = "UU",
    department: str = "CSE",
    semester: str = "Fall 2026"
) -> Dict[str, Any]:
    """Extract all schedule slots from the PDF timetable across all pages."""
    slots: List[Dict[str, Any]] = []

    with pdfplumber.open(pdf_path) as pdf:
        for page_idx, page in enumerate(pdf.pages):
            tables = page.find_tables()
            if not tables:
                continue

            for table in tables:
                raw_table = table.extract()
                if len(raw_table) < 4:
                    continue

                # 1. Identify weekday columns from Row 1
                row_days = raw_table[1]
                day_ranges = []  # [(day_code, start_col, end_col)]

                current_day = None
                start_c = None
                for c_idx, c_val in enumerate(row_days):
                    if c_val and c_val.strip().lower() in DAY_NAME_MAP:
                        if current_day is not None and start_c is not None:
                            day_ranges.append((current_day, start_c, c_idx))
                        current_day = DAY_NAME_MAP[c_val.strip().lower()]
                        start_c = c_idx

                if current_day is not None and start_c is not None:
                    day_ranges.append((current_day, start_c, len(row_days)))

                # Fallback if days row was empty/unparsed
                if not day_ranges:
                    day_ranges = [
                        ("MON", 1, 7),
                        ("TUE", 7, 13),
                        ("WED", 13, 19),
                        ("THU", 19, 25),
                    ]

                # 2. Extract Period times from Row 2
                row_times = raw_table[2]
                col_periods: Dict[int, Dict[str, str]] = {}

                for c_idx in range(1, len(row_times)):
                    cell_val = row_times[c_idx] or ""
                    times = re.findall(r'(\d{1,2}:\d{2})', cell_val)
                    if len(times) >= 2:
                        col_periods[c_idx] = {
                            "start": normalize_time_str(times[0]),
                            "end": normalize_time_str(times[1])
                        }
                    else:
                        # Fallback calculation based on column index modulo 6
                        p_idx = (c_idx - 1) % 6
                        fallback = FALLBACK_PERIODS[p_idx]
                        col_periods[c_idx] = {
                            "start": fallback["start"],
                            "end": fallback["end"]
                        }

                # 3. Parse Data Rows (Row 3 onwards)
                for r_idx in range(3, len(raw_table)):
                    row = raw_table[r_idx]
                    batch_sec_raw = row[0]
                    if not batch_sec_raw or not batch_sec_raw.strip():
                        continue

                    parts = batch_sec_raw.strip().split()
                    batch = parts[0] if len(parts) > 0 else "Unknown"
                    section = parts[1] if len(parts) > 1 else "A"

                    # Iterate through each scheduled day section
                    for day_code, col_start, col_end in day_ranges:
                        c = col_start
                        while c < col_end and c < len(row):
                            cell = row[c]
                            if cell and cell.strip():
                                parsed = parse_cell_text(cell)
                                if parsed and parsed["courseCode"]:
                                    start_time = col_periods.get(c, {}).get("start", "08:45")

                                    # Check if the next period column in the same day block is None (merged cell)
                                    if c + 1 < col_end and c + 1 < len(row) and row[c + 1] is None:
                                        end_time = col_periods.get(c + 1, {}).get("end", "11:25")
                                        c += 2  # skip merged cell
                                    else:
                                        end_time = col_periods.get(c, {}).get("end", "10:05")
                                        c += 1

                                    slots.append({
                                        "dayOfWeek": day_code,
                                        "startTime": start_time,
                                        "endTime": end_time,
                                        "roomNumber": parsed["roomNumber"],
                                        "courseCode": parsed["courseCode"],
                                        "courseName": parsed["courseCode"],
                                        "batch": batch,
                                        "section": section,
                                        "facultyCode": parsed["facultyCode"]
                                    })
                                else:
                                    c += 1
                            else:
                                c += 1

    return {
        "university": university,
        "department": department,
        "semester": semester,
        "slots": slots
    }


def main():
    parser = argparse.ArgumentParser(description="Deterministic Routine PDF Parser for UniRoom")
    parser.add_argument("pdf_path", help="Path to timetable PDF file")
    parser.add_argument("--university", default="UU", help="University Code/ID (default: UU)")
    parser.add_argument("--department", default="CSE", help="Department Code/ID (default: CSE)")
    parser.add_argument("--semester", default="Fall 2026", help="Semester title (default: Fall 2026)")
    parser.add_argument("--output", help="Optional output JSON file path")

    args = parser.parse_args()

    if not os.path.exists(args.pdf_path):
        print(f"Error: File not found: {args.pdf_path}", file=sys.stderr)
        sys.exit(1)

    result = parse_pdf_timetable(
        pdf_path=args.pdf_path,
        university=args.university,
        department=args.department,
        semester=args.semester
    )

    output_json = json.dumps(result, indent=2)

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output_json)
        print(f"Successfully extracted {len(result['slots'])} slots to {args.output}")
    else:
        # Standard stdout output for CLI or pipe
        print(output_json)


if __name__ == "__main__":
    main()
