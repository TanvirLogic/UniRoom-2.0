import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter | null = null;
  private readonly emailFrom: string;

  constructor(private readonly configService: ConfigService) {
    const host = this.configService.get<string>('SMTP_HOST', 'smtp.gmail.com');
    const port = Number(this.configService.get<number>('SMTP_PORT', 465));
    const secure = this.configService.get<string>('SMTP_SECURE', 'true') === 'true' || port === 465;
    const rawUser = this.configService.get<string>('SMTP_USER', '');
    const rawPass = this.configService.get<string>('SMTP_PASS', '');
    const user = rawUser.replace(/["']/g, '').trim();
    const pass = rawPass.replace(/["'\s]/g, '').trim();
    this.emailFrom = this.configService.get<string>('EMAIL_FROM', 'UniRoom-Live <no-reply@uniroom.live>');

    if (user && pass) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure,
        auth: {
          user,
          pass,
        },
      });
      this.logger.log(`[EmailService] Configured SMTP transporter with host ${host}:${port} (User: ${user})`);
    } else {
      this.logger.warn(
        '[EmailService] SMTP credentials (SMTP_USER / SMTP_PASS) not fully set in .env. Verification PINs will be printed to server console.',
      );
    }
  }

  async sendVerificationEmail(to: string, fullName: string, pin: string): Promise<boolean> {
    const subject = 'Your UniRoom-Live 2.0 Email Verification PIN';
    const html = this.buildVerificationTemplate(fullName, pin);

    // If SMTP is not yet configured, log clearly for local development/testing
    if (!this.transporter) {
      this.logger.warn(
        `\n=======================================================\n[DEVELOPMENT EMAIL VERIFICATION PIN]\nTo: ${to} (${fullName})\nVerification PIN: [ ${pin} ]\nExpires in: 10 minutes\n=======================================================`,
      );
      return true;
    }

    try {
      const info = await this.transporter.sendMail({
        from: this.emailFrom,
        to,
        subject,
        html,
      });

      this.logger.log(`[EmailService] Verification PIN sent to ${to} (MessageId: ${info.messageId})`);
      return true;
    } catch (error: any) {
      this.logger.error(`[EmailService] Failed to send verification email to ${to}: ${error.message}`, error.stack);
      this.logger.warn(`[FALLBACK PIN] Email: ${to} | PIN: ${pin}`);
      return false;
    }
  }

  async sendPasswordResetEmail(to: string, fullName: string, pin: string): Promise<boolean> {
    const subject = 'Your UniRoom-Live 2.0 Password Reset PIN';
    const html = this.buildPasswordResetTemplate(fullName, pin);

    // If SMTP is not yet configured, log clearly for local development/testing
    if (!this.transporter) {
      this.logger.warn(
        `\n=======================================================\n[DEVELOPMENT PASSWORD RESET PIN]\nTo: ${to} (${fullName})\nReset PIN: [ ${pin} ]\nExpires in: 10 minutes\n=======================================================`,
      );
      return true;
    }

    try {
      const info = await this.transporter.sendMail({
        from: this.emailFrom,
        to,
        subject,
        html,
      });

      this.logger.log(`[EmailService] Password reset PIN sent to ${to} (MessageId: ${info.messageId})`);
      return true;
    } catch (error: any) {
      this.logger.error(`[EmailService] Failed to send password reset email to ${to}: ${error.message}`, error.stack);
      this.logger.warn(`[FALLBACK RESET PIN] Email: ${to} | PIN: ${pin}`);
      return false;
    }
  }

  private buildVerificationTemplate(fullName: string, pin: string): string {
    const currentYear = new Date().getFullYear();
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 24px; color: #333; }
          .container { max-width: 540px; margin: 0 auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,0,0.08); }
          .header { background: #0f172a; padding: 28px; text-align: center; color: #ffffff; }
          .header h1 { margin: 0; font-size: 24px; font-weight: 700; letter-spacing: 0.5px; }
          .header p { margin: 6px 0 0; color: #94a3b8; font-size: 13px; }
          .content { padding: 32px; }
          .greeting { font-size: 16px; font-weight: 600; margin-bottom: 12px; color: #1e293b; }
          .message { font-size: 14px; line-height: 1.6; color: #475569; margin-bottom: 24px; }
          .pin-container { text-align: center; margin: 28px 0; }
          .pin-box { display: inline-block; background: #f8fafc; border: 2px dashed #0284c7; border-radius: 8px; padding: 14px 32px; font-size: 32px; font-weight: 800; letter-spacing: 8px; color: #0284c7; }
          .expiry-note { font-size: 12px; color: #64748b; text-align: center; margin-top: 10px; }
          .footer { background: #f8fafc; padding: 20px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #e2e8f0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>UniRoom-Live 2.0</h1>
            <p>Enterprise Classroom & Schedule Orchestration Platform</p>
          </div>
          <div class="content">
            <div class="greeting">Hello, ${fullName}! 👋</div>
            <div class="message">
              Thank you for registering. To complete your account registration and verify your institutional email address, please use the 6-digit PIN below:
            </div>
            <div class="pin-container">
              <div class="pin-box">${pin}</div>
              <div class="expiry-note">&#9201; This PIN is valid for <strong>10 minutes</strong>. Do not share it with anyone.</div>
            </div>
            <div class="message">
              If you did not initiate this registration, please disregard this email.
            </div>
          </div>
          <div class="footer">
            &copy; ${currentYear} UniRoom-Live 2.0. All rights reserved.
          </div>
        </div>
      </body>
      </html>
    `;
  }

  private buildPasswordResetTemplate(fullName: string, pin: string): string {
    const currentYear = new Date().getFullYear();
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f7f6; margin: 0; padding: 24px; color: #333; }
          .container { max-width: 540px; margin: 0 auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 16px rgba(0,0,0,0.08); }
          .header { background: #0f172a; padding: 28px; text-align: center; color: #ffffff; }
          .header h1 { margin: 0; font-size: 24px; font-weight: 700; letter-spacing: 0.5px; }
          .header p { margin: 6px 0 0; color: #94a3b8; font-size: 13px; }
          .content { padding: 32px; }
          .greeting { font-size: 16px; font-weight: 600; margin-bottom: 12px; color: #1e293b; }
          .message { font-size: 14px; line-height: 1.6; color: #475569; margin-bottom: 24px; }
          .pin-container { text-align: center; margin: 28px 0; }
          .pin-box { display: inline-block; background: #fff1f2; border: 2px dashed #e11d48; border-radius: 8px; padding: 14px 32px; font-size: 32px; font-weight: 800; letter-spacing: 8px; color: #e11d48; }
          .expiry-note { font-size: 12px; color: #64748b; text-align: center; margin-top: 10px; }
          .warning-box { background: #fef2f2; border-left: 4px solid #ef4444; padding: 12px 16px; border-radius: 4px; font-size: 13px; color: #991b1b; margin-top: 20px; line-height: 1.5; }
          .footer { background: #f8fafc; padding: 20px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #e2e8f0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>UniRoom-Live 2.0</h1>
            <p>Enterprise Classroom & Schedule Orchestration Platform</p>
          </div>
          <div class="content">
            <div class="greeting">Hello, ${fullName}! 🔒</div>
            <div class="message">
              We received a request to reset the password for your UniRoom-Live account. Please use the 6-digit security PIN below to set a new password:
            </div>
            <div class="pin-container">
              <div class="pin-box">${pin}</div>
              <div class="expiry-note">&#9201; This PIN is valid for <strong>10 minutes</strong>. Do not share it with anyone.</div>
            </div>
            <div class="warning-box">
              <strong>Security Warning:</strong> If you did not request a password reset, please ignore this email or review your account immediately. Your password remains unchanged until verified with this PIN.
            </div>
          </div>
          <div class="footer">
            &copy; ${currentYear} UniRoom-Live 2.0. All rights reserved.
          </div>
        </div>
      </body>
      </html>
    `;
  }
}
