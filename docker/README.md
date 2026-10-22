# Docker

`Dockerfile` packages the Board Game application as a container image. It is copied from the application repository ([Board_game_DBproject](https://github.com/Kunj3336/Board_game_DBproject)).

| Instruction | Purpose |
|---|---|
| `FROM eclipse-temurin:17-jdk` | Java 17 runtime base image |
| `EXPOSE 8080` | Port the Spring Boot app listens on |
| `COPY target/*.jar ...` | Copies the jar produced by `mvn package` |
| `CMD ["java", "-jar", "app.jar"]` | Starts the application |

## Usage

The jar must exist first, so build it with Maven, then build and run the image from the application repository root:

```bash
mvn package
docker build -t kunj0701/boardgameprojectimage .
docker run -p 8080:8080 kunj0701/boardgameprojectimage
```

Then open `http://localhost:8080`.

In the pipeline, Jenkins runs `docker build` after `mvn package`, scans the image with Trivy, and pushes it to Docker Hub. Amazon EKS then pulls it from Docker Hub.
