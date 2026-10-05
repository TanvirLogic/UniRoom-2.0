import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { IngestRoutineDto } from '../dto/ingest-routine.dto';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { spawn, spawnSync } from 'child_process';

/**
 * Embedded fallback Python script code in case the repository scripts directory
 * is not bundled into the production container (e.g. Render rootDir build).
 */
const EMBEDDED_PYTHON_PARSER = `#!/usr/bin/env python3
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
            "error": f"Missing dependency 'pdfplumber'. Auto-install failed: {e}. Please run: pip install pdfplumber"
        }), file=sys.stderr)
        sys.exit(1)

DAY_NAME_MAP = {
    "monday": "MON", "mon": "MON",
    "tuesday": "TUE", "tue": "TUE",
    "wednesday": "WED", "wed": "WED",
    "thursday": "THU", "thu": "THU",
    "friday": "FRI", "fri": "FRI",
    "saturday": "SAT", "sat": "SAT",
    "sunday": "SUN", "sun": "SUN"
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
    parts = t.strip().split(":")
    if len(parts) == 2:
        return f"{int(parts[0]):02d}:{parts[1]}"
    return t.strip()

def parse_cell_text(cell_text: str) -> Optional[Dict[str, str]]:
    if not cell_text or not cell_text.strip():
        return None
    raw_lines = [l.strip() for l in cell_text.split('\\n') if l.strip()]
    if not raw_lines:
        return None
    course_code = raw_lines[0].replace(' ', '').upper()
    idx = 1
    if idx < len(raw_lines) and re.match(r'^\\d+$', raw_lines[idx]):
        idx += 1
    faculty_code = "TBA"
    if idx < len(raw_lines) and re.match(r'^[A-Z]{2,4}$', raw_lines[idx].strip()):
        faculty_code = raw_lines[idx].strip().upper()
        idx += 1
    room_number = " ".join(raw_lines[idx:]) if idx < len(raw_lines) else "TBA"
    room_number = re.sub(r'\\s+', ' ', room_number).strip()
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
    slots: List[Dict[str, Any]] = []
    with pdfplumber.open(pdf_path) as pdf:
        for page in pdf.pages:
            tables = page.find_tables()
            if not tables:
                continue
            for table in tables:
                raw_table = table.extract()
                if len(raw_table) < 4:
                    continue
                row_days = raw_table[1]
                day_ranges = []
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
                if not day_ranges:
                    day_ranges = [
                        ("MON", 1, 7), ("TUE", 7, 13), ("WED", 13, 19), ("THU", 19, 25),
                    ]
                row_times = raw_table[2]
                col_periods: Dict[int, Dict[str, str]] = {}
                for c_idx in range(1, len(row_times)):
                    cell_val = row_times[c_idx] or ""
                    times = re.findall(r'(\\d{1,2}:\\d{2})', cell_val)
                    if len(times) >= 2:
                        col_periods[c_idx] = {
                            "start": normalize_time_str(times[0]),
                            "end": normalize_time_str(times[1])
                        }
                    else:
                        p_idx = (c_idx - 1) % 6
                        fallback = FALLBACK_PERIODS[p_idx]
                        col_periods[c_idx] = {
                            "start": fallback["start"],
                            "end": fallback["end"]
                        }
                for r_idx in range(3, len(raw_table)):
                    row = raw_table[r_idx]
                    batch_sec_raw = row[0]
                    if not batch_sec_raw or not batch_sec_raw.strip():
                        continue
                    parts = batch_sec_raw.strip().split()
                    batch = parts[0] if len(parts) > 0 else "Unknown"
                    section = parts[1] if len(parts) > 1 else "A"
                    for day_code, col_start, col_end in day_ranges:
                        c = col_start
                        while c < col_end and c < len(row):
                            cell = row[c]
                            if cell and cell.strip():
                                parsed = parse_cell_text(cell)
                                if parsed and parsed["courseCode"]:
                                    start_time = col_periods.get(c, {}).get("start", "08:45")
                                    if c + 1 < col_end and c + 1 < len(row) and row[c + 1] is None:
                                        end_time = col_periods.get(c + 1, {}).get("end", "11:25")
                                        c += 2
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
    parser = argparse.ArgumentParser(description="Deterministic Routine PDF Parser")
    parser.add_argument("pdf_path", help="Path to timetable PDF file")
    parser.add_argument("--university", default="UU")
    parser.add_argument("--department", default="CSE")
    parser.add_argument("--semester", default="Fall 2026")
    args = parser.parse_args()

    if not os.path.exists(args.pdf_path):
        print(json.dumps({"error": f"File not found: {args.pdf_path}"}), file=sys.stderr)
        sys.exit(1)

    result = parse_pdf_timetable(
        pdf_path=args.pdf_path,
        university=args.university,
        department=args.department,
        semester=args.semester
    )
    print(json.dumps(result))

if __name__ == "__main__":
    main()
`;

@Injectable()
export class RoutineParserService {
  private readonly logger = new Logger(RoutineParserService.name);

  /**
   * Determine available python executable on system (cross-platform Linux/Windows/Mac)
   */
  private resolvePythonExecutable(): string {
    if (process.env.PYTHON_PATH) {
      return process.env.PYTHON_PATH;
    }

    const testCommand = (cmd: string): boolean => {
      try {
        const res = spawnSync(cmd, ['--version']);
        return res.status === 0;
      } catch {
        return false;
      }
    };

    // Candidate binaries in priority order
    // On Linux/Render: 'python3' is standard. On Windows: 'python' or 'py'
    const candidates = [
      'python3',
      'python',
      'py',
      '/usr/bin/python3',
      '/usr/local/bin/python3',
      'C:\\Python313\\python.exe',
      'C:\\Python312\\python.exe',
      'C:\\Python311\\python.exe',
    ];

    for (const c of candidates) {
      if (testCommand(c)) {
        return c;
      }
    }

    // Default to 'python3' on Unix, 'python' on Windows
    return process.platform === 'win32' ? 'python' : 'python3';
  }

  /**
   * Resolve location of parse_routine_pdf.py script.
   * If not found anywhere in filesystem, automatically writes embedded parser to temp directory.
   */
  private async resolveScriptPath(): Promise<string> {
    const candidates = [
      path.resolve(process.cwd(), 'scripts', 'parse_routine_pdf.py'),
      path.resolve(process.cwd(), 'backend', 'scripts', 'parse_routine_pdf.py'),
      path.resolve(process.cwd(), '..', 'scripts', 'parse_routine_pdf.py'),
      path.resolve(__dirname, '../../../../scripts/parse_routine_pdf.py'),
      path.resolve(__dirname, '../../../../../scripts/parse_routine_pdf.py'),
      path.resolve(__dirname, '../../scripts/parse_routine_pdf.py'),
      path.resolve(__dirname, '../scripts/parse_routine_pdf.py'),
      path.resolve(__dirname, 'parse_routine_pdf.py'),
    ];

    for (const c of candidates) {
      if (fs.existsSync(c)) {
        return c;
      }
    }

    // Fallback: Dynamically generate script file in temp directory so it can NEVER fail to find it!
    const fallbackPath = path.join(os.tmpdir(), 'parse_routine_pdf.py');
    try {
      await fs.promises.writeFile(fallbackPath, EMBEDDED_PYTHON_PARSER, 'utf-8');
      this.logger.log(`Initialized embedded Python parser at fallback location: ${fallbackPath}`);
      return fallbackPath;
    } catch (err: any) {
      this.logger.error(`Failed to write embedded python parser: ${err.message}`);
      throw new BadRequestException(`Failed to initialize routine parser script: ${err.message}`);
    }
  }

  /**
   * Deterministic Python table extraction using pdfplumber (Script-Only)
   */
  async parseDocument(
    fileBuffer: Buffer,
    mimeType: string,
    university = 'UU',
    department = 'CSE',
  ): Promise<IngestRoutineDto> {
    const scriptPath = await this.resolveScriptPath();
    const pythonBin = this.resolvePythonExecutable();
    const tempFile = path.join(
      os.tmpdir(),
      `routine-${Date.now()}-${Math.random().toString(36).substring(7)}.pdf`,
    );

    try {
      await fs.promises.writeFile(tempFile, fileBuffer);

      this.logger.log(
        `Executing Python parser (${pythonBin}) with script ${scriptPath} for ${department} (${university})...`,
      );

      const parsedResult = await new Promise<IngestRoutineDto>((resolve, reject) => {
        const pyProcess = spawn(pythonBin, [
          scriptPath,
          tempFile,
          '--university',
          university,
          '--department',
          department,
          '--semester',
          'Fall 2026',
        ]);

        let stdout = '';
        let stderr = '';

        pyProcess.stdout.on('data', (chunk) => {
          stdout += chunk.toString();
        });

        pyProcess.stderr.on('data', (chunk) => {
          stderr += chunk.toString();
        });

        pyProcess.on('close', (code) => {
          if (code === 0 && stdout.trim()) {
            try {
              const parsed: IngestRoutineDto = JSON.parse(stdout);
              if (parsed && Array.isArray(parsed.slots)) {
                if (parsed.slots.length === 0) {
                  reject(
                    new BadRequestException(
                      'Python parser completed but found 0 schedule slots in this PDF table. Please verify table structure.',
                    ),
                  );
                  return;
                }
                resolve(parsed);
                return;
              }
            } catch (jsonErr: any) {
              this.logger.error(`Failed to parse Python script output as JSON: ${jsonErr.message}`);
              reject(
                new BadRequestException(
                  `Python parser output was not valid JSON: ${jsonErr.message}. Output was: ${stdout.substring(0, 300)}`,
                ),
              );
              return;
            }
          }

          const errorDetail = stderr.trim() || stdout.trim() || `Process exited with code ${code}`;
          this.logger.error(`Python parser script failed (code ${code}): ${errorDetail}`);
          reject(
            new BadRequestException(
              `Python routine parser error: ${errorDetail}`,
            ),
          );
        });

        pyProcess.on('error', (err) => {
          this.logger.error(`Failed to launch Python runtime (${pythonBin}): ${err.message}`);
          reject(
            new BadRequestException(
              `Failed to launch Python process (${pythonBin}): ${err.message}. Ensure Python and pdfplumber are installed.`,
            ),
          );
        });
      });

      this.logger.log(
        `Python parser successfully extracted ${parsedResult.slots.length} slots from PDF!`,
      );
      return parsedResult;
    } catch (err: any) {
      if (err instanceof BadRequestException) throw err;
      throw new BadRequestException(`Routine parsing failed: ${err.message}`);
    } finally {
      fs.promises.unlink(tempFile).catch(() => {});
    }
  }
}
