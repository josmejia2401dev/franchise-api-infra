# Despliegue en AWS — Paso a Paso

Orden de ejecución para desplegar la Franchise API en AWS (entorno `dev`, estado local).

Todos los comandos de Terraform se ejecutan desde `terraform/`.

## Requisitos previos

- AWS CLI configurado (`aws configure`, credenciales en `~/.aws/credentials`).
- Cuenta de MongoDB Atlas con usuario/password.
- Token de acceso de Docker Hub (Account Settings -> Personal Access Tokens).
- En Atlas -> Network Access, permitir la IP saliente (NAT Gateway) o `0.0.0.0/0` para la prueba.

## Variables sensibles (variables de entorno)

Antes de cualquier `terraform apply`, exportar:

```powershell
$env:TF_VAR_mongodb_username  = "<usuario-mongo>"
$env:TF_VAR_mongodb_password  = "<password-mongo>"
$env:TF_VAR_dockerhub_username = "<usuario-dockerhub>"
$env:TF_VAR_dockerhub_token    = "<token-dockerhub>"
```

## Paso 0 — Solo en re-despliegues: liberar el secreto de Mongo

Si ya se hizo un `destroy` antes, Secrets Manager deja el secreto "scheduled for
deletion" (retencion 7-30 dias) y el `apply` falla con:
`You can't create this secret because a secret with this name is already scheduled for deletion`.

Borrarlo a la fuerza antes del apply:

```powershell
aws secretsmanager delete-secret --secret-id franchise-api/dev/mongodb-credentials --force-delete-without-recovery --region us-east-1
```

Esperar ~20 segundos. (En un primer despliegue limpio este paso no aplica.)

## Paso 1 — Lanzar la infraestructura (Terraform)

Crea VPC, subredes, NAT, ECR, CodeBuild, ALB, ECS (cluster/servicio/task), IAM,
Secrets Manager y SSM. El servicio ECS queda creado pero sin imagen todavía.

```powershell
terraform init
terraform plan
terraform apply
```

Confirmar con `yes`. Al final anota los outputs:
- `api_base_url` — URL pública del ALB.
- `codebuild_project_name` — proyecto que construye la imagen.

## Paso 2 — Construir y publicar la imagen (CodeBuild)

Terraform solo crea el proyecto de CodeBuild; no lo ejecuta. Hay que dispararlo.
CodeBuild clona el repo publico, compila el jar, construye la imagen Docker y la
sube a ECR (se autentica en Docker Hub para evitar el rate limit de descargas).

```powershell
aws codebuild start-build --project-name franchise-api-dev-image-build --region us-east-1
```

Seguir el progreso:

```powershell
aws logs tail /codebuild/franchise-api-dev --follow --region us-east-1
```

Verificar que la imagen quedo en ECR:

```powershell
aws ecr list-images --repository-name franchise-api --region us-east-1
```

## Paso 3 — Relanzar la task de ECS

Cuando ya existe la imagen `latest` en ECR, forzar un nuevo despliegue para que
ECS baje la imagen y arranque la task.

```powershell
aws ecs update-service --cluster franchise-api-dev-cluster --service franchise-api-dev-service --force-new-deployment --region us-east-1
```

## Paso 4 — Verificar

Ver logs de arranque de la aplicacion:

```powershell
aws logs tail /ecs/franchise-api-dev --follow --region us-east-1
```

Ver estado del target en el balanceador (debe pasar a `healthy`):

```powershell
$tg = aws elbv2 describe-target-groups --names franchise-api-dev-tg --region us-east-1 --query "TargetGroups[0].TargetGroupArn" --output text
aws elbv2 describe-target-health --target-group-arn $tg --region us-east-1 --query "TargetHealthDescriptions[].TargetHealth.State"
```

Probar el endpoint (usar la URL del output `api_base_url`):

```powershell
curl http://<api_base_url>/actuator/health/liveness
```

## Notas

- El health check del ALB apunta a `/actuator/health/liveness` para comprobar que
  el proceso vive, sin acoplarse a dependencias externas como Mongo.
- Cada vez que cambie el codigo de la aplicacion: repetir Paso 2 (nuevo build) y
  Paso 3 (force-new-deployment). No hace falta re-aplicar Terraform.
- Cada vez que cambie la infraestructura (modulos/variables): repetir Paso 1.
- Al terminar las pruebas, destruir todo para no seguir pagando:

```powershell
terraform destroy
```

Si `destroy` falla por el secreto de Secrets Manager que queda "scheduled for
deletion", forzar su borrado:

```powershell
aws secretsmanager delete-secret --secret-id franchise-api/dev/mongodb-credentials --force-delete-without-recovery --region us-east-1
```
