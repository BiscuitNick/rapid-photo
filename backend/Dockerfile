FROM amazoncorretto:17-alpine3.20

WORKDIR /app

# Copy only the bootable JAR (not the -plain.jar)
COPY build/libs/*-SNAPSHOT.jar app.jar

# Expose port
EXPOSE 8080

# Run the application
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
