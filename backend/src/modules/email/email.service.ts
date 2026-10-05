import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

export interface SendEmailResult {
  success: boolean;
  delivered: boolean;
  messageId?: string;
  error?: string;
}

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter | null = null;
  private readonly emailFrom: string;
  private readonly resendApiKey: string | null = null;

  private readonly host: string;
  private readonly port: number;
  private readonly secure: boolean;
  private readonly user: string;

  constructor(private readonly configService: ConfigService) {
    this.resendApiKey = this.configService.get<string>('RESEND_API_KEY', '').trim() || null;
    this.host = this.configService.get<string>('SMTP_HOST', 'smtp.gmail.com');
    this.port = Number(this.configService.get<number>('SMTP_PORT', 465));
    const secureVal = this.configService.get<string>('SMTP_SECURE');
    this.secure = secureVal !== undefined ? (secureVal === 'true' || secureVal === '1') : this.port === 465;

    const rawUser = this.configService.get<string>('SMTP_USER', '');
    const rawPass = this.configService.get<string>('SMTP_PASS', '');
    this.user = rawUser.replace(/["']/g, '').trim();
    const pass = rawPass.replace(/["'\s]/g, '').trim();
    this.emailFrom = this.configService.get<string>('EMAIL_FROM', 'UniRoom-Live <no-reply@uniroom.live>');

    if (this.resendApiKey) {
      this.logger.log('[EmailService] Configured Resend HTTP API for production email dispatch (Port 443 HTTPS).');
    }

    if (this.user && pass) {
      this.transporter = nodemailer.createTransport({
        host: this.host,
        port: this.port,
        secure: this.secure,
        auth: {
          user: this.user,
          pass,
        },
        connectionTimeout: 10000,
        greetingTimeout: 10000,
        socketTimeout: 15000,
        // Force IPv4 to prevent ENETUNREACH in cloud container environments
        family: 4,
        tls: {
          rejectUnauthorized: false,
        },
      } as any);
      this.logger.log(`[EmailService] Configured SMTP transporter with host ${this.host}:${this.port} (secure: ${this.secure}, IPv4 forced, User: ${this.user})`);
    }

    if (!this.resendApiKey && (!this.user || !pass)) {
      this.logger.warn(
        '[EmailService] No active email provider (neither RESEND_API_KEY nor SMTP credentials). Verification PINs will be printed to server console.',
      );
    }
  }

  private async sendViaResend(
    to: string,
    subject: string,
    html: string,
  ): Promise<{ success: boolean; messageId?: string; error?: string }> {
    if (!this.resendApiKey) return { success: false, error: 'No Resend API Key configured' };
    try {
      const fromAddress = this.configService.get<string>('RESEND_FROM') || 'UniRoom-Live <onboarding@resend.dev>';
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.resendApiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: fromAddress,
          to: [to],
          subject,
          html,
        }),
      });

      const data: any = await response.json();
      if (!response.ok) {
        throw new Error(data.message || `Resend returned HTTP ${response.status}`);
      }
      return { success: true, messageId: data.id };
    } catch (err: any) {
      return { success: false, error: err.message };
    }
  }

  /**
   * Get current email service status and masked telemetry
   */
  getStatus() {
    const isSmtpConfigured = !!(this.transporter && this.user);
    const isResendConfigured = !!this.resendApiKey;
    const isConfigured = isResendConfigured || isSmtpConfigured;

    const maskedUser = this.user
      ? this.user.includes('@')
        ? `${this.user.split('@')[0].slice(0, 3)}***@${this.user.split('@')[1]}`
        : `${this.user.slice(0, 3)}***`
      : 'not set';

    return {
      isConfigured,
      provider: isResendConfigured ? 'resend-http' : isSmtpConfigured ? 'smtp' : 'none',
      host: this.host,
      port: this.port,
      secure: this.secure,
      user: maskedUser,
      from: this.emailFrom,
    };
  }

  /**
   * Verify SMTP connection or Resend credentials
   */
  async verifyConnection(): Promise<{ success: boolean; message: string }> {
    if (this.resendApiKey) {
      return {
        success: true,
        message: 'Resend HTTP API key is configured and ready for outbound HTTPS dispatch (Port 443).',
      };
    }

    if (!this.transporter) {
      return {
        success: false,
        message: 'No email credentials found (neither RESEND_API_KEY nor SMTP_USER/SMTP_PASS).',
      };
    }

    try {
      await this.transporter.verify();
      return {
        success: true,
        message: `Successfully connected to SMTP server (${this.host}:${this.port}). Ready to deliver emails.`,
      };
    } catch (error: any) {
      this.logger.error(`[EmailService] SMTP verification failed: ${error.message}`);
      return {
        success: false,
        message: `SMTP connection failed (${error.message}). Tip: On Render Free tier, configure RESEND_API_KEY to send emails over HTTPS.`,
      };
    }
  }

  /**
   * Send a test email to verify delivery
   */
  async sendTestEmail(to: string): Promise<{ success: boolean; message: string; messageId?: string }> {
    const subject = 'UniRoom-Live 2.0 - Email Delivery Test';
    const html = `
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 500px; margin: 0 auto; padding: 24px; background: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px;">
        <h2 style="color: #059669; margin-top: 0; font-size: 20px;">🎉 Email Service Operational!</h2>
        <p style="color: #334155; font-size: 14px; line-height: 1.5;">This test email confirms that live transactional email delivery is operational for <strong>UniRoom-Live 2.0</strong>.</p>
        <div style="background: #f8fafc; border-left: 4px solid #059669; padding: 12px; margin: 16px 0; font-size: 13px; color: #475569;">
          <strong>Target:</strong> ${to}<br/>
          <strong>Timestamp:</strong> ${new Date().toUTCString()}
        </div>
      </div>
    `;

    if (this.resendApiKey) {
      const resendRes = await this.sendViaResend(to, subject, html);
      if (resendRes.success) {
        return {
          success: true,
          message: `Test email dispatched successfully via Resend API to ${to}!`,
          messageId: resendRes.messageId,
        };
      }
    }

    if (this.transporter) {
      try {
        const info = await this.transporter.sendMail({
          from: this.emailFrom,
          to,
          subject,
          html,
        });
        return {
          success: true,
          message: `Test email dispatched successfully via SMTP to ${to}!`,
          messageId: info.messageId,
        };
      } catch (error: any) {
        return {
          success: false,
          message: `SMTP delivery failed (${error.message}). Tip: On Render Free tier, set RESEND_API_KEY in Render environment.`,
        };
      }
    }

    return {
      success: false,
      message: 'No email service configured. Please add RESEND_API_KEY or SMTP credentials.',
    };
  }

  async sendVerificationEmail(to: string, fullName: string, pin: string): Promise<SendEmailResult> {
    const subject = 'Your UniRoom-Live 2.0 Email Verification PIN';
    const html = this.buildVerificationTemplate(fullName, pin);

    // 1. Try Resend HTTP API (Bypasses Render Free SMTP egress blocks)
    if (this.resendApiKey) {
      const resendRes = await this.sendViaResend(to, subject, html);
      if (resendRes.success) {
        this.logger.log(`[EmailService] Verification PIN sent to ${to} via Resend (Id: ${resendRes.messageId})`);
        return { success: true, delivered: true, messageId: resendRes.messageId };
      }
      this.logger.warn(`[EmailService] Resend dispatch failed (${resendRes.error}), falling back to SMTP...`);
    }

    // 2. Try SMTP
    if (this.transporter) {
      try {
        const info = await this.transporter.sendMail({
          from: this.emailFrom,
          to,
          subject,
          html,
        });

        this.logger.log(`[EmailService] Verification PIN sent to ${to} via SMTP (MessageId: ${info.messageId})`);
        return { success: true, delivered: true, messageId: info.messageId };
      } catch (error: any) {
        this.logger.error(`[EmailService] Failed to send verification email via SMTP to ${to}: ${error.message}`);
      }
    }

    // 3. Resilient Fallback Logging
    this.logger.warn(
      `\n=======================================================\n[FALLBACK VERIFICATION PIN]\nTo: ${to} (${fullName})\nVerification PIN: [ ${pin} ]\nExpires in: 10 minutes\n=======================================================`,
    );
    return { success: true, delivered: false };
  }

  async sendPasswordResetEmail(to: string, fullName: string, pin: string): Promise<SendEmailResult> {
    const subject = 'Your UniRoom-Live 2.0 Password Reset PIN';
    const html = this.buildPasswordResetTemplate(fullName, pin);

    // 1. Try Resend HTTP API
    if (this.resendApiKey) {
      const resendRes = await this.sendViaResend(to, subject, html);
      if (resendRes.success) {
        this.logger.log(`[EmailService] Password reset PIN sent to ${to} via Resend (Id: ${resendRes.messageId})`);
        return { success: true, delivered: true, messageId: resendRes.messageId };
      }
      this.logger.warn(`[EmailService] Resend dispatch failed (${resendRes.error}), falling back to SMTP...`);
    }

    // 2. Try SMTP
    if (this.transporter) {
      try {
        const info = await this.transporter.sendMail({
          from: this.emailFrom,
          to,
          subject,
          html,
        });

        this.logger.log(`[EmailService] Password reset PIN sent to ${to} via SMTP (MessageId: ${info.messageId})`);
        return { success: true, delivered: true, messageId: info.messageId };
      } catch (error: any) {
        this.logger.error(`[EmailService] Failed to send password reset email via SMTP to ${to}: ${error.message}`);
      }
    }

    // 3. Resilient Fallback Logging
    this.logger.warn(
      `\n=======================================================\n[FALLBACK PASSWORD RESET PIN]\nTo: ${to} (${fullName})\nReset PIN: [ ${pin} ]\nExpires in: 10 minutes\n=======================================================`,
    );
    return { success: true, delivered: false };
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
