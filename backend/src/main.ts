import { NestFactory } from '@nestjs/core';
import { Logger, ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // Enable Cross-Origin Resource Sharing (CORS)
  app.enableCors({
    origin: true,
    credentials: true,
  });

  // Global API Version Prefix
  app.setGlobalPrefix('api/v1');

  // Global Validation Pipe with strict DTO stripping
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Global Exception Filter for standard error responses
  app.useGlobalFilters(new AllExceptionsFilter());

  // Global Response Envelope Interceptor
  app.useGlobalInterceptors(new TransformInterceptor());

  // OpenAPI / Swagger Documentation Setup
  const config = new DocumentBuilder()
    .setTitle('UniRoom-Live 2.0 API')
    .setDescription(
      'Enterprise Multi-Tenant Real-Time Timetable & Classroom Allocation Orchestration Engine',
    )
    .setVersion('2.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'Authorization',
        description: 'Enter JWT Access Token',
        in: 'header',
      },
      'JWT-auth',
    )
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document, {
    customSiteTitle: 'UniRoom-Live 2.0 API Documentation',
  });

  const port = process.env.PORT || 3000;
  await app.listen(port, '0.0.0.0');

  logger.log(`🚀 API Server running on port ${port} (0.0.0.0)`);
  logger.log(`📚 Swagger Documentation: http://localhost:${port}/api/docs`);
}

bootstrap();
