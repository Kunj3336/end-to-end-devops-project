## Project Progress

### === Phase 0 Complete ===
- **Application**: Spring Boot 2.5.6 compiled with Maven and running on Java 17 JRE Alpine runtime.
- **Local Validation**: Maven clean, unit tests, and packaging verified (`mvn clean test`, `mvn package`).
- **Containerization**: Built lightweight Docker image (`boardgame-app:v1`) and verified local container startup on host port `8085` (`http://localhost:8085`).
- **Build Command**: `docker build -t boardgame-app:v1 .`
- **Run Command**: `docker run -d --name boardgame-container -p 8085:8080 boardgame-app:v1`

---

### === Phase 1: In Progress ===
- Configured Terraform foundation files (`providers.tf`, `variables.tf`, `main.tf`, `outputs.tf`) targeting `ap-south-1` region.