import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { IngestRoutineDto } from '../dto/ingest-routine.dto';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';
import { spawn } from 'child_process';

@Injectable()
export class RoutineParserService {
  private readonly logger = new Logger(RoutineParserService.name);

  /**
   * Determine available python executable on system
   */
  private resolvePythonExecutable(): string {
    if (process.env.PYTHON_PATH && fs.existsSync(process.env.PYTHON_PATH)) {
      return process.env.PYTHON_PATH;
    }

    // Windows common locations
    const windowsPaths = [
      'C:\\Python313\\python.exe',
      'C:\\Python312\\python.exe',
      'C:\\Python311\\python.exe',
      'C:\\Program Files\\Python313\\python.exe',
      'C:\\Program Files\\Python312\\python.exe',
    ];

    for (const p of windowsPaths) {
      if (fs.existsSync(p)) {
        return p;
      }
    }

    // Default to 'python' in PATH
    return 'python';
  }

  /**
   * Resolve location of parse_routine_pdf.py script
   */
  private resolveScriptPath(): string | null {
    const candidates = [
      path.resolve(process.cwd(), 'scripts', 'parse_routine_pdf.py'),
      path.resolve(process.cwd(), 'backend', 'scripts', 'parse_routine_pdf.py'),
      path.resolve(process.cwd(), '..', 'scripts', 'parse_routine_pdf.py'),
      path.resolve(__dirname, '../../../../scripts/parse_routine_pdf.py'),
      path.resolve(__dirname, '../../../../../scripts/parse_routine_pdf.py'),
      path.resolve(__dirname, '../../scripts/parse_routine_pdf.py'),
    ];

    for (const c of candidates) {
      if (fs.existsSync(c)) {
        return c;
      }
    }

    return null;
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
    const scriptPath = this.resolveScriptPath();
    if (!scriptPath) {
      this.logger.error('Python parser script parse_routine_pdf.py not found in any candidate path.');
      throw new BadRequestException(
        'Python routine parser script (parse_routine_pdf.py) was not found on server. Please verify scripts directory.',
      );
    }

    const pythonBin = this.resolvePythonExecutable();
    const tempFile = path.join(
      os.tmpdir(),
      `routine-${Date.now()}-${Math.random().toString(36).substring(7)}.pdf`,
    );

    try {
      await fs.promises.writeFile(tempFile, fileBuffer);

      this.logger.log(
        `Executing Python parser script (${pythonBin}) with script ${scriptPath} for ${department} (${university})...`,
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
                      'Python script completed but found 0 schedule slots in this PDF table. Please verify timetable format.',
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
          this.logger.error(`Failed to launch Python runtime: ${err.message}`);
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
