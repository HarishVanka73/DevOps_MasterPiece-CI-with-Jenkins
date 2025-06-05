FROM openjdk:17-alpine3.18
COPY target/*.jar app.jar
CMD ["java", "-jar","app.jar"]
