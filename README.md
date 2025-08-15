# DevOps-pipeline  
                              +------------------------+
                              |      GitHub Repo       |
                              +-----------+------------+
                                          |
                                  Push / PR / Merge
                                          |
                              +-----------v------------+
                              |      GitHub Actions     |
                              |   - Terraform 실행      |
                              |   - Jenkins Job 트리거   |
                              +-----------+------------+
                                          |
                            ┌─────────────v──────────────┐
                            │        AWS VPC (Infra)     │
                            │                             │
          +-----------------+----------------+   +--------+-----------+
          |  Public Subnet (CI/CD)           |   | Private Subnet     |
          |                                  |   | (App Servers)       |
+---------------------+       +----------------------+    +---------------------+
| EC2: Jenkins Master | <---> | EC2: Jenkins Agent   |    | EC2: App Server     |
| - Port 8080         |       | - Docker Build       |    | - docker pull/run   |
+---------------------+       | - Unit/Integration Test|  | - app container     |
                              +----------------------+    +---------------------+
                                         |
                                         | Docker 이미지 Push
                                         v
                              +------------------------+
                              |      AWS ECR           |
                              | - 이미지 저장소        |
                              +------------------------+
                                         |
                          +--------------v------------------+
                          |   Prometheus + Node Exporter    |
                          | - Jenkins/Agent/App 상태 모니터링 |
                          +----------------------------------+
