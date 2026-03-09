# petclinic-app Setup Guide

This guide covers local development, Docker build, and CI configuration.

---

## Prerequisites

- **JDK 17** (Eclipse Temurin recommended)
- **Maven** (or use included `./mvnw`)
- **Docker** (optional, for local image build)
- **Git**

### Quick verify

```bash
./mvnw -v
java -version
```

---

## Local Development

### 1. Clone

```bash
git clone <your-petclinic-app-repo-url>
cd petclinic-app
```

### 2. Build

```bash
./mvnw clean package
```

### 3. Run

```bash
./mvnw spring-boot:run
```

Or run the JAR:

```bash
java -jar target/*.jar
```

Application: http://localhost:8080

### 4. Run tests

```bash
./mvnw test
```

---

## Docker Build (Local)

### Build image

```bash
./mvnw clean package -DskipTests
docker build -t petclinic:local --build-arg VERSION=local .
```

### Run container

```bash
docker run -p 8080:8080 petclinic:local
```

Open http://localhost:8080

---

## CI Configuration (GitHub Actions)

CI runs on push/PR to `main`, `master`, or `develop`. To enable full pipeline:

### 1. Create ECR repository (one-time)

```bash
aws ecr create-repository --repository-name petclinic --region ap-south-1
```

**IAM (your AWS user/role):** `ecr:CreateRepository`, `ecr:DescribeRepositories` – covered by `AmazonECRFullAccess`.

### 2. Configure GitHub OIDC for ECR

See `cicd-platform/docs/GITHUB_OIDC_SETUP.md` (in the cicd-platform repo) for:

- Creating GitHub OIDC identity provider in AWS
- Creating IAM role with ECR push permissions and trust policy for `sts:AssumeRoleWithWebIdentity`
- **IAM permissions for OIDC role:** `ecr:GetAuthorizationToken`, `ecr:BatchCheckLayerAvailability`, `ecr:GetDownloadUrlForLayer`, `ecr:BatchGetImage`, `ecr:PutImage`, `ecr:InitiateLayerUpload`, `ecr:UploadLayerPart`, `ecr:CompleteLayerUpload` on the ECR repository

### 3. GitHub repository secrets

| Secret | Description |
|--------|-------------|
| `AWS_ROLE_ARN` | IAM role ARN for OIDC (e.g. `arn:aws:iam::ACCOUNT:role/github-actions-ecr`) |
| `SONAR_HOST_URL` | SonarQube URL – must be reachable from GitHub (e.g. LoadBalancer: `http://<elb-dns>:9000`) |
| `SONAR_TOKEN` | SonarQube user token with Execute Analysis + Create Projects |

**Note:** `SONAR_HOST_URL` must be publicly reachable if using GitHub-hosted runners. Internal URLs (e.g. `http://sonarqube.sonarqube:9000`) only work with self-hosted runners.

### 4. GitHub repository variables (optional)

| Variable | Default | Description |
|----------|---------|-------------|
| `AWS_REGION` | ap-south-1 | ECR region |
| `ECR_REPOSITORY` | petclinic | ECR repository name |

### 5. Verify CI

1. Push to `main`, `master`, or `develop`
2. Check **Actions** tab for workflow run
3. Jobs: `build-test` → `sonar` → `build-push-ecr`

---

## SonarQube Project (required before first CI run)

1. **Create project manually:** SonarQube UI → Projects → Create project manually → Project key: `petclinic_sonar_key` (must match `pom.xml` sonar profile), Display name: `Spring Petclinic`.
2. **Generate token:** My Account → Security → Generate Tokens → name `github-actions` → Generate. Copy token.
3. **Add token as** `SONAR_TOKEN` **secret** in GitHub.
4. **Permissions:** Admin → Security → Global Permissions. Ensure `sonar-users` has **Execute Analysis** and **Create Projects**.

**Project key configuration:** The Maven plugin defaults to `groupId:artifactId` and ignores `sonar-project.properties`. The project key is set in `pom.xml` under the `sonar` profile's `<properties>`:
- `sonar.projectKey=petclinic_sonar_key`
- `sonar.projectName=Spring Petclinic`

---

## Troubleshooting

### Build fails with "No compiler"

Install JDK 17 and set `JAVA_HOME`:

```bash
export JAVA_HOME=/path/to/jdk17
```

### Docker build fails

Ensure JAR exists:

```bash
./mvnw clean package -DskipTests
ls target/*.jar
```

### CI: ECR push fails

- Verify `AWS_ROLE_ARN` is correct
- Ensure OIDC trust policy allows your repo/org
- Check ECR repo exists and name matches `ECR_REPOSITORY`

### CI: SonarQube fails ("not authorized to analyze this project or the project doesn't exist")

- **Project key mismatch:** The sonar-maven-plugin uses `groupId:artifactId` by default, so SonarQube receives `org.springframework.samples:spring-petclinic` instead of `petclinic_sonar_key`. **Fix:** Add in `pom.xml` under the sonar profile's `<properties>`:
  ```xml
  <sonar.projectKey>petclinic_sonar_key</sonar.projectKey>
  <sonar.projectName>Spring Petclinic</sonar.projectName>
  ```
  The CI workflow also passes `-Dsonar.projectKey=petclinic_sonar_key` for redundancy.
- **SonarQube project:** Ensure project key `petclinic_sonar_key` exists in SonarQube UI.
- **Token:** Regenerate token (My Account → Security) and update `SONAR_TOKEN` secret.
- **Permissions:** Admin → Security → Global Permissions. `sonar-users` needs **Execute Analysis** and **Create Projects**.
- **URL:** `SONAR_HOST_URL` must be reachable from GitHub (public LoadBalancer DNS; internal URLs require self-hosted runners).
