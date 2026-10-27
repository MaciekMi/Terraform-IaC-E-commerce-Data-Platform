# E-commerce Data Platform — Terraform

Projekt zaliczeniowy z modułu Terraform w ramach kursu Data Engineering.

Celem projektu jest wdrożenie infrastruktury AWS dla prostego pipeline'u danych e-commerce przy użyciu Infrastructure as Code. Infrastruktura obejmuje warstwy S3, bazę PostgreSQL w Amazon RDS, AWS Glue oraz konfigurację IAM.

## Architektura

Projekt tworzy i zarządza następującymi elementami:

- 3 buckety Amazon S3:
  - `raw` — dane źródłowe,
  - `processed` — dane po przetworzeniu,
  - `curated` — dane przygotowane do dalszego wykorzystania,
- Amazon RDS PostgreSQL,
- Security Group dla RDS,
- DB Subnet Group,
- DB Parameter Group,
- IAM Role dla AWS Glue,
- politykę dostępu Glue do S3,
- AWS Glue Job,
- skrypt PySpark `orders_etl.py`,
- zdalny Terraform State w Amazon S3,
- blokowanie state przy użyciu DynamoDB.

## Struktura projektu


.
├── README.md
├── glue_scripts/
│   └── orders_etl.py
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── locals.tf
    ├── outputs.tf
    ├── s3.tf
    ├── rds.tf
    ├── iam.tf
    ├── glue.tf
    ├── terraform.tfvars.example
    ├── .gitignore
    └── modules/
        └── glue_job/
            ├── main.tf
            ├── variables.tf
            └── outputs.tf


## Wymagania

Do uruchomienia projektu potrzebne są:

- Terraform >= 1.7,
- AWS CLI,
- konto AWS z odpowiednimi uprawnieniami,
- skonfigurowany profil AWS,
- istniejące VPC oraz co najmniej dwa subnety,
- bucket S3 przeznaczony na Terraform Remote State,
- tabela DynamoDB do blokowania Terraform State.

Projekt był przygotowany i testowany w regionie:


eu-central-1


## Konfiguracja zmiennych

Zmienne infrastruktury znajdują się w pliku:


terraform/variables.tf


Przykładowe wartości znajdują się w:


terraform/terraform.tfvars.example


Zmienne `vpc_id` oraz `private_subnet_ids` należy ustawić zgodnie z własnym środowiskiem AWS.

Przykład:


vpc_id = "vpc-xxxxxxxxxxxxxxxxx"

private_subnet_ids = [
  "subnet-xxxxxxxxxxxxxxxxx",
  "subnet-yyyyyyyyyyyyyyyyy"
]


Dane dostępowe do RDS nie powinny być przechowywane w repozytorium.

Można je przekazać przez zmienne środowiskowe Terraform.

PowerShell:

```powershell
$env:TF_VAR_db_username="your_username"
$env:TF_VAR_db_password="your_password"
```

## Konfiguracja AWS

W przypadku korzystania z profilu AWS należy go ustawić przed uruchomieniem Terraform:

```powershell
$env:AWS_PROFILE="ecommerce-dev"
```

Poprawność konfiguracji można sprawdzić:

```powershell
aws sts get-caller-identity
```

## Remote State

Terraform State przechowywany jest w Amazon S3.

Backend wykorzystuje:

- szyfrowanie state,
- S3 jako backend,
- DynamoDB do blokowania state.

Bucket oraz tabela DynamoDB muszą istnieć przed wykonaniem:

```powershell
terraform init
```

Przykładowa konfiguracja znajduje się w `main.tf`.

> Terraform może wyświetlać ostrzeżenie, że parametr `dynamodb_table` jest przestarzały. Został on zachowany ze względu na wymagania projektu zaliczeniowego dotyczące blokowania state przy użyciu DynamoDB.

## Uruchomienie projektu

Przejdź do katalogu Terraform:

```powershell
cd terraform
```

### 1. Inicjalizacja

```powershell
terraform init
```

### 2. Formatowanie

```powershell
terraform fmt
```

### 3. Walidacja

```powershell
terraform validate
```

Oczekiwany rezultat:

```text
Success! The configuration is valid.
```

### 4. Plan

```powershell
terraform plan -var="env=dev"
```

Opcjonalnie plan można zapisać:

```powershell
terraform plan -var="env=dev" -out=tfplan
```

### 5. Wdrożenie

```powershell
terraform apply tfplan
```

lub:

```powershell
terraform apply -var="env=dev"
```

### 6. Sprawdzenie idempotencji (trudne słowo)

Po wykonaniu `terraform apply` należy ponownie uruchomić:

```powershell
terraform plan -var="env=dev"
```

Poprawnie wdrożona i zsynchronizowana infrastruktura powinna zwrócić:


No changes. Your infrastructure matches the configuration.


## Amazon S3

Tworzone są trzy warstwy Data Lake:

### RAW

- versioning włączony,
- szyfrowanie AES256,
- Block Public Access,
- usuwanie poprzednich wersji obiektów po 90 dniach,
- anulowanie nieukończonych multipart uploadów po 7 dniach.

### PROCESSED

- versioning włączony,
- szyfrowanie AES256,
- Block Public Access.

### CURATED

- szyfrowanie AES256,
- Block Public Access.

## Amazon RDS

Projekt wykorzystuje:

- PostgreSQL 15,
- `db.t3.micro` dla środowiska DEV,
- storage typu `gp3`,
- szyfrowanie storage,
- brak publicznego dostępu,
- Security Group umożliwiający PostgreSQL na porcie `5432` wyłącznie z CIDR używanego VPC,
- DB Subnet Group,
- DB Parameter Group.

### Wersja PostgreSQL

W pierwotnej specyfikacji zadania wskazana została wersja PostgreSQL `15.4`.

Podczas wdrożenia AWS RDS w regionie `eu-central-1` zwrócił:


InvalidParameterCombination: Cannot find version 15.4 for postgres


Z tego powodu konfiguracja została dostosowana do dostępnej wersji PostgreSQL `15.19`.

Pozostałe wymagania dotyczące PostgreSQL 15 oraz konfiguracji RDS pozostają bez zmian.

## AWS Glue

AWS Glue Job jest tworzony za pomocą lokalnego modułu Terraform:


terraform/modules/glue_job


Moduł obsługuje:

- tworzenie Glue Job,
- opcjonalne utworzenie własnej roli IAM,
- wykorzystanie zewnętrznej roli IAM,
- przekazywanie bucketów SOURCE i TARGET do skryptu ETL.

W tym projekcie IAM Role jest tworzona w głównym pliku:


terraform/iam.tf


i przekazywana do modułu Glue.

## PySpark ETL

Skrypt:


glue_scripts/orders_etl.py


pobiera argumenty:


JOB_NAME
SOURCE_BUCKET
TARGET_BUCKET


Dane wejściowe są odczytywane z:


s3://SOURCE_BUCKET/raw/orders/


Pipeline wykonuje m.in.:

- rzutowanie typów danych,
- konwersję `order_id` do LongType,
- konwersję `total_amount` do DecimalType(12,2),
- konwersję `ordered_at` do TimestampType,
- odrzucanie rekordów z ujemną wartością `total_amount`,
- usuwanie duplikatów według `order_id`,
- dodanie pól:
  - `order_date`,
  - `order_year`,
  - `order_month`,
  - `processed_at`,
  - `etl_run_date`.

Dane wynikowe są zapisywane w formacie Parquet do warstwy processed.

## IAM

AWS Glue korzysta z dedykowanej roli IAM.

Rola posiada:

- trust relationship dla `glue.amazonaws.com`,
- managed policy `AWSGlueServiceRole`,
- własną politykę umożliwiającą dostęp wyłącznie do wymaganych bucketów S3.

## Outputs

Terraform zwraca m.in.:

- nazwę bucketa RAW,
- nazwę bucketa PROCESSED,
- nazwę bucketa CURATED,
- endpoint RDS,
- nazwę Glue Job,
- ARN roli IAM Glue.

Wyświetlenie outputów:

```powershell
terraform output
```

## Bezpieczeństwo

Repozytorium nie powinno zawierać:

- haseł do RDS,
- kluczy AWS,
- plików `terraform.tfstate`,
- prawdziwych plików `.tfvars` zawierających dane dostępowe,
- katalogu `.terraform`.

Plik `.gitignore` zabezpiecza te elementy przed przypadkowym dodaniem do repozytorium.

## Najczęstsze problemy

### Brak uprawnień AWS

Przykład:

```text
UnauthorizedOperation
```

Należy sprawdzić polityki przypisane do użytkownika IAM oraz używany profil AWS.

### Terraform używa niewłaściwego konta AWS

Sprawdzenie:

```powershell
aws sts get-caller-identity
```

W razie potrzeby:

```powershell
$env:AWS_PROFILE="ecommerce-dev"
```

### Zasób już istnieje

Przykład:


BucketAlreadyOwnedByYou
DBSubnetGroupAlreadyExists


Jeżeli zasób istnieje już w AWS, ale nie znajduje się w aktualnym Terraform State, można go zaimportować:

```powershell
terraform import <resource_address> <resource_id>
```

### Niedostępna wersja PostgreSQL

AWS może wycofać możliwość tworzenia nowych instancji RDS na starszej wersji minor PostgreSQL.

W takim przypadku należy wybrać aktualnie dostępną wersję z tej samej głównej gałęzi PostgreSQL.

## Wynik wdrożenia

Po wykonaniu konfiguracji końcowy Terraform Plan zwrócił:


No changes. Your infrastructure matches the configuration.


Potwierdza to, że infrastruktura AWS jest zgodna z konfiguracją Terraform.

Log ostatniego wdrożenia znajduje się również w pliku:


terraform_apply_output.txt


a ostatnie 20 linii w:


terraform_apply_last20.txt


## Azure

Część Azure została pominięta zgodnie z ustaleniami bo jestem geniuszem.