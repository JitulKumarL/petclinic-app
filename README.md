# Petclinic App

Application source + CI (GitHub Actions). **CD is handled by cicd-platform repo** via Argo CD Image Updater.

---

## Structure

```
petclinic-app/
├── src/
├── pom.xml
├── Dockerfile
├── sonar-project.properties
├── .github/workflows/ci.yml
├── SETUP.md          # Setup and implementation guide
└── README.md
```

---

## Setup & Implementation

**→ [SETUP.md](SETUP.md)** – Prerequisites, local run, Docker build, CI configuration (secrets, OIDC), troubleshooting.

**Config:** Copy `config/app-config.example.env` → `config/app-config.env` for local use. CI uses GitHub vars/secrets.

### Quick start (local)

```bash
./mvnw spring-boot:run
# http://localhost:8080
```

---

## CI Flow

1. Build, unit tests
2. SonarQube scan (pod on EKS)
3. Push image to ECR

**No cross-repo push.** Argo CD Image Updater (in cicd-platform) watches ECR and updates the deployment.

---

## GitHub Configuration

### Secrets (required for full CI)

| Secret | Description |
|--------|-------------|
| `AWS_ROLE_ARN` | IAM role ARN for OIDC (ECR push). See cicd-platform `docs/GITHUB_OIDC_SETUP.md` |
| `SONAR_HOST_URL` | SonarQube URL |
| `SONAR_TOKEN` | SonarQube project/global token |

### Variables (optional)

| Variable | Default | Use for new apps |
|----------|---------|------------------|
| `AWS_REGION` | ap-south-1 | Override per env |
| `ECR_REPOSITORY` | petclinic | Set to your app name (e.g. myapp) |
