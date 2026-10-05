import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { initializeApp, cert, getApps, App } from 'firebase-admin/app';
import { getMessaging, Message } from 'firebase-admin/messaging';
import * as path from 'path';
import * as fs from 'fs';

export interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

@Injectable()
export class PushNotificationService implements OnModuleInit {
  private readonly logger = new Logger(PushNotificationService.name);
  private firebaseApp: App | null = null;
  private isInitialized = false;
  private projectId: string | null = null;
  private clientEmail: string | null = null;
  private lastInitError: string | null = null;

  onModuleInit() {
    this.initializeFirebase();
  }

  private initializeFirebase() {
    try {
      const existingApps = getApps();
      if (existingApps.length > 0) {
        this.firebaseApp = existingApps[0]!;
        this.isInitialized = true;
        this.projectId = this.firebaseApp.options.projectId || 'uniroom-live';
        this.logger.log(`[PushNotificationService] Reusing existing Firebase Admin instance for '${this.projectId}'.`);
        return;
      }

      let serviceAccount: any = null;

      // 1. Raw JSON string from environment variable
      if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
        try {
          serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
          this.logger.log('[PushNotificationService] Loaded service account from FIREBASE_SERVICE_ACCOUNT_JSON.');
        } catch (e: any) {
          this.lastInitError = 'Failed parsing FIREBASE_SERVICE_ACCOUNT_JSON: ' + e.message;
          this.logger.error(`[PushNotificationService] ${this.lastInitError}`);
        }
      }

      // 2. Base64-encoded string from environment variable
      if (!serviceAccount && process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
        try {
          const decoded = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64, 'base64').toString('utf8');
          serviceAccount = JSON.parse(decoded);
          this.logger.log('[PushNotificationService] Loaded service account from FIREBASE_SERVICE_ACCOUNT_BASE64.');
        } catch (e: any) {
          this.lastInitError = 'Failed parsing FIREBASE_SERVICE_ACCOUNT_BASE64: ' + e.message;
          this.logger.error(`[PushNotificationService] ${this.lastInitError}`);
        }
      }

      // 3. Generic FIREBASE_SERVICE_ACCOUNT (can be JSON or Base64)
      if (!serviceAccount && process.env.FIREBASE_SERVICE_ACCOUNT) {
        const raw = process.env.FIREBASE_SERVICE_ACCOUNT.trim();
        try {
          if (raw.startsWith('{')) {
            serviceAccount = JSON.parse(raw);
          } else {
            const decoded = Buffer.from(raw, 'base64').toString('utf8');
            serviceAccount = JSON.parse(decoded);
          }
          this.logger.log('[PushNotificationService] Loaded service account from FIREBASE_SERVICE_ACCOUNT.');
        } catch (e: any) {
          this.lastInitError = 'Failed parsing FIREBASE_SERVICE_ACCOUNT: ' + e.message;
          this.logger.error(`[PushNotificationService] ${this.lastInitError}`);
        }
      }

      // 4. Discrete Environment Variables (often used in Cloud PaaS like Render)
      if (
        !serviceAccount &&
        process.env.FIREBASE_PROJECT_ID &&
        process.env.FIREBASE_CLIENT_EMAIL &&
        process.env.FIREBASE_PRIVATE_KEY
      ) {
        try {
          serviceAccount = {
            project_id: process.env.FIREBASE_PROJECT_ID.trim(),
            client_email: process.env.FIREBASE_CLIENT_EMAIL.trim(),
            private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n').trim(),
          };
          this.logger.log('[PushNotificationService] Loaded service account from discrete FIREBASE_* variables.');
        } catch (e: any) {
          this.lastInitError = 'Failed constructing credentials from discrete FIREBASE_* vars: ' + e.message;
          this.logger.error(`[PushNotificationService] ${this.lastInitError}`);
        }
      }

      // 5. File-based credentials
      if (!serviceAccount) {
        const candidatePaths = [
          process.env.GOOGLE_APPLICATION_CREDENTIALS,
          path.resolve(process.cwd(), 'firebase-service-account.json'),
          path.resolve(process.cwd(), 'backend', 'firebase-service-account.json'),
          path.resolve(__dirname, '..', '..', '..', 'firebase-service-account.json'),
        ].filter(Boolean) as string[];

        for (const candidate of candidatePaths) {
          if (fs.existsSync(candidate)) {
            try {
              const rawKey = fs.readFileSync(candidate, 'utf8');
              serviceAccount = JSON.parse(rawKey);
              this.logger.log(`[PushNotificationService] Loaded service account from file: ${candidate}`);
              break;
            } catch (err: any) {
              this.logger.warn(`[PushNotificationService] Could not parse candidate file ${candidate}: ${err.message}`);
            }
          }
        }
      }

      if (!serviceAccount) {
        this.logger.warn(
          '[PushNotificationService] Service account not found (neither in environment variables nor local JSON file). Push notifications are paused.',
        );
        return;
      }

      this.firebaseApp = initializeApp({
        credential: cert(serviceAccount),
        projectId: serviceAccount.project_id || 'uniroom-live',
      });

      this.isInitialized = true;
      this.projectId = serviceAccount.project_id || 'uniroom-live';
      this.clientEmail = serviceAccount.client_email || null;
      this.lastInitError = null;

      this.logger.log(
        `[PushNotificationService] Firebase Admin SDK successfully initialized for project '${this.projectId}'.`,
      );
    } catch (error: any) {
      this.lastInitError = error.message;
      this.logger.error(
        `[PushNotificationService] Failed to initialize Firebase Admin: ${error.message}`,
        error.stack,
      );
    }
  }

  /**
   * Diagnostic telemetry for Push Notification service
   */
  getStatus() {
    const maskedEmail = this.clientEmail
      ? this.clientEmail.includes('@')
        ? `${this.clientEmail.split('@')[0].slice(0, 3)}***@${this.clientEmail.split('@')[1]}`
        : `${this.clientEmail.slice(0, 3)}***`
      : null;

    return {
      isInitialized: this.isInitialized,
      projectId: this.projectId,
      clientEmail: maskedEmail,
      lastInitError: this.lastInitError,
    };
  }

  /**
   * Send a test push notification to verify topic broadcast or device delivery
   */
  async sendTestNotification(options: {
    topic?: string;
    token?: string;
    title?: string;
    body?: string;
  }): Promise<{ success: boolean; message: string; responseId?: string }> {
    if (!this.isInitialized || !this.firebaseApp) {
      return {
        success: false,
        message:
          'Firebase Admin SDK is not initialized. Please configure FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT_BASE64 in your Render environment variables.',
      };
    }

    const title = options.title || '🔔 UniRoom-Live 2.0 Test Push';
    const body = options.body || 'This is a test notification confirming FCM delivery is operational.';
    const targetTopic = options.topic || (!options.token ? 'test_channel' : undefined);

    try {
      if (options.token) {
        const response = await getMessaging(this.firebaseApp).send({
          token: options.token,
          notification: { title, body },
          data: { test: 'true', timestamp: Date.now().toString() },
        });
        return {
          success: true,
          message: `Test push sent to device token successfully!`,
          responseId: response,
        };
      } else {
        const sanitized = this.sanitizeTopic(targetTopic!);
        const response = await getMessaging(this.firebaseApp).send({
          topic: sanitized,
          notification: { title, body },
          data: { test: 'true', topic: sanitized, timestamp: Date.now().toString() },
        });
        return {
          success: true,
          message: `Test push broadcast to /topics/${sanitized} sent successfully!`,
          responseId: response,
        };
      }
    } catch (err: any) {
      this.logger.error(`[PushNotificationService] Test push failed: ${err.message}`);
      return {
        success: false,
        message: `FCM push delivery failed: ${err.message}`,
      };
    }
  }

  /**
   * Format safe topic string for FCM (only alphanumeric, -, _, ~, %)
   */
  private sanitizeTopic(topic: string): string {
    return topic.trim().replace(/[^a-zA-Z0-9-_.~%]+/g, '_').toLowerCase();
  }

  /**
   * Broadcast push notification to all students of a specific department, batch, and section
   * Example: dept_swe_batch_68_sec_b
   */
  async sendToSectionTopic(
    department: string,
    batch: string,
    section: string,
    notification: NotificationPayload,
  ): Promise<boolean> {
    const rawTopic = `dept_${department}_batch_${batch}_sec_${section}`;
    const topic = this.sanitizeTopic(rawTopic);
    return this.sendToTopic(topic, notification);
  }

  /**
   * Broadcast room release alert to all Class Representatives (CRs) of a department
   * Example: dept_swe_crs
   */
  async sendToCrTopic(department: string, notification: NotificationPayload): Promise<boolean> {
    const rawTopic = `dept_${department}_crs`;
    const topic = this.sanitizeTopic(rawTopic);
    return this.sendToTopic(topic, notification);
  }

  /**
   * Direct notification to faculty member by teacher initials
   * Example: faculty_dns
   */
  async sendToFacultyTopic(
    teacherInitials: string,
    notification: NotificationPayload,
  ): Promise<boolean> {
    const rawTopic = `faculty_${teacherInitials}`;
    const topic = this.sanitizeTopic(rawTopic);
    return this.sendToTopic(topic, notification);
  }

  /**
   * Send notification to an arbitrary topic
   */
  async sendToTopic(topic: string, notification: NotificationPayload): Promise<boolean> {
    if (!this.isInitialized || !this.firebaseApp) {
      this.logger.warn(
        `[PushNotificationService] Skipped push to /topics/${topic} (Firebase not initialized). Title: "${notification.title}"`,
      );
      return false;
    }

    try {
      const message: Message = {
        topic,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: {
          ...(notification.data || {}),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'uniroom_classes',
            priority: 'max',
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
      };

      const response = await getMessaging(this.firebaseApp).send(message);
      this.logger.log(`[PushNotificationService] Successfully sent push to /topics/${topic}: ${response}`);
      return true;
    } catch (error: any) {
      this.logger.error(
        `[PushNotificationService] Error sending push to /topics/${topic}: ${error.message}`,
        error.stack,
      );
      return false;
    }
  }

  /**
   * Direct push notification to a specific user device token
   */
  async sendToDevice(deviceToken: string, notification: NotificationPayload): Promise<boolean> {
    if (!this.isInitialized || !this.firebaseApp || !deviceToken) {
      return false;
    }

    try {
      const response = await getMessaging(this.firebaseApp).send({
        token: deviceToken,
        notification: {
          title: notification.title,
          body: notification.body,
        },
        data: {
          ...(notification.data || {}),
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'uniroom_classes',
            priority: 'max',
          },
        },
      });

      this.logger.log(`[PushNotificationService] Push sent to device: ${response}`);
      return true;
    } catch (error: any) {
      this.logger.error(`[PushNotificationService] Error sending push to device: ${error.message}`);
      return false;
    }
  }
}
