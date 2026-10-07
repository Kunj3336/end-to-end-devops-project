# Base Image: Lightweight Java 17/11 runtime environment
FROM eclipse-temurin:17-jre-alpine

# Set working directory inside container
WORKDIR /app

# Copy the packaged jar from local target to container
COPY target/database_service_project-0.0.7-SNAPSHOT.jar app.jar

# Expose the standard Spring Boot application port
EXPOSE 8080

# Command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]