FROM eclipse-temurin:17-jre-alpine
ARG VERSION=unknown
LABEL version="${VERSION}"
WORKDIR /app
COPY target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
