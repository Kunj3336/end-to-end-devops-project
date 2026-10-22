# Copied from the application repository (github.com/Kunj3336/Board_game_DBproject).
# Used by the Jenkins "Build Docker image" stage, after `mvn package` has produced target/*.jar.
FROM eclipse-temurin:17-jdk

EXPOSE 8080

ENV APP_HOME /usr/src/app

COPY target/*.jar $APP_HOME/app.jar

WORKDIR $APP_HOME

CMD ["java", "-jar", "app.jar"]
