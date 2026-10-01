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

  onModuleInit() {
    this.initializeFirebase();
  }

  private initializeFirebase() {
    try {
      const existingApps = getApps();
      if (existingApps.length > 0) {
        this.firebaseApp = existingApps[0]!;
        this.isInitialized = true;
        this.logger.log('[PushNotificationService] Reusing existing Firebase Admin instance.');
        return;
      }

      let serviceAccount: any = null;

      if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
        try {
          serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
          this.logger.log('[PushNotificationService] Loaded service account from FIREBASE_SERVICE_ACCOUNT_JSON env.');
        } catch (e: any) {
          this.logger.error('[PushNotificationService] Failed parsing FIREBASE_SERVICE_ACCOUNT_JSON env var: ' + e.message);
        }
      } else if (process.env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
        try {
          const decoded = Buffer.from(process.env.FIREBASE_SERVICE_ACCOUNT_BASE64, 'base64').toString('utf8');
          serviceAccount = JSON.parse(decoded);
          this.logger.log('[PushNotificationService] Loaded service account from FIREBASE_SERVICE_ACCOUNT_BASE64 env.');
        } catch (e: any) {
          this.logger.error('[PushNotificationService] Failed parsing FIREBASE_SERVICE_ACCOUNT_BASE64 env var: ' + e.message);
        }
      }

      if (!serviceAccount) {
        const keyPath = path.resolve(process.cwd(), 'firebase-service-account.json');
        if (fs.existsSync(keyPath)) {
          const rawKey = fs.readFileSync(keyPath, 'utf8');
          serviceAccount = JSON.parse(rawKey);
        }
      }

      if (!serviceAccount) {
        this.logger.warn(
          '[PushNotificationService] Service account key not found (neither in env nor firebase-service-account.json). Push notifications disabled.',
        );
        return;
      }

      this.firebaseApp = initializeApp({
        credential: cert(serviceAccount),
        projectId: serviceAccount.project_id || 'uniroom-live',
      });

      this.isInitialized = true;
      this.logger.log(
        `[PushNotificationService] Firebase Admin SDK successfully initialized for project '${serviceAccount.project_id}'.`,
      );
    } catch (error: any) {
      this.logger.error(
        `[PushNotificationService] Failed to initialize Firebase Admin: ${error.message}`,
        error.stack,
      );
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
