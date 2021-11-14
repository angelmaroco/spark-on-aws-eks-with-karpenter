## Introducción


## Diagrama de Arquitectura


## Requisitos

- Terraform >= 0.15


## Despliegue infraestructura

```bash
export AWS_ACCESS_KEY_ID=XXXX
export AWS_SECRET_ACCESS_KEY=XXXX
export AWS_DEFAULT_REGION=eu-west-1
export BACKEND_S3="euw1-bluetab-general-tfstate-pro"

# Despliegue entorno producción
terraform init -backend-config="bucket=${BACKEND_S3}"
terraform apply -var-file=vars/${AWS_DEFAULT_REGION}.dev.tfvars
```