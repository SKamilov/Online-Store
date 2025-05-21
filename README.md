**Momo Store aka Пельменная №2  https://158-160-185-251.nip.io**

<img width="900" alt="image" src="https://user-images.githubusercontent.com/9394918/167876466-2c530828-d658-4efe-9064-825626cc6db5.png">


Momo-Store/
├── backend/                # Исходники backend-сервиса
├── frontend/               # Исходники frontend-сервиса
├── infra/
│   └── helm/
│       └── momo-store/     # Helm-чарт для деплоя всего приложения
│           ├── templates/  # Манифесты
│           └── values.yaml # Параметры для Helm-чарта
├── .gitlab-ci.yml          # CI/CD pipeline для сборки и деплоя
└── README.md


Инструкция по развёртыванию приложения

1. Требования

	•	Kubernetes-кластер Yandex.Cloud
	•	Helm
	•	Развёрнутый Nexus
	•	Доступ к gitlab-runner, настроенному на работу с Kubernetes

2. Сборка и публикация контейнеров

Сборка и пуш происходит автоматически через GitLab CI/CD

# Backend
docker build -t <registry>/std-033-40/momo-store/backend:<tag> ./backend
docker push <registry>/std-033-40/momo-store/backend:<tag>

# Frontend
docker build -t <registry>/std-033-40/momo-store/frontend:<tag> ./frontend
docker push <registry>/std-033-40/momo-store/frontend:<tag>

Registry указываются в values.yaml

3. Деплой в Kubernetes

# Добавь Helm репозиторий
helm repo add momo-nexus <url>
helm repo update

# Установи ingress-nginx
kubectl create namespace ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.publishService.enabled=true

# Создай namespace для приложения
kubectl create namespace gitlab-runner

# Деплой приложения:
helm upgrade --install momo-store infra/helm/momo-store \
  --namespace gitlab-runner \
  --set image.registry=<registry> \
  --set backend.repository=std-033-40/momo-store/backend \
  --set backend.tag=<tag> \
  --set frontend.repository=std-033-40/momo-store/frontend \
  --set frontend.tag=<tag> \
  --set ingress.host=<hostname>

После деплоя приложение доступно по адресу:
https://<ingress-host>
(например, https://158-160-185-251.nip.io)




Инструкция по развёртыванию инфраструктуры

	•	Инфраструктурные манифесты лежат в infra/helm/momo-store/templates/
	•	Все параметры — в infra/helm/momo-store/values.yaml
	•	Ингресс и сервисы создаются автоматически при деплое Helm-чарта
	•	Обновлять только через pull request (см. правила изменений)

Важно:
Если в кластере еще нет ingress-nginx, обязательно развернуть по инструкции выше.

⸻

Правила внесения изменений в инфраструктуру
	1.	Все изменения инфраструктуры (Helm-чарт, values.yaml, манифесты) только через Pull Request
	2.	Название PR должно начинаться с infra: (например, infra: вынес ingress в отдельный шаблон)
	3.	Обяхательно должен быть аппрув изменений перед слиянием
	4.	В master пушить напрямую нельзя
	5.	После мержа деплой запускается автоматически через GitLab CI/CD

⸻

Релизный цикл и версионирование

	•	Версии контейнеров и Helm-чарта совпадают с номером CI/CD pipeline ($CI_PIPELINE_ID)
	•	Все релизы публикуются в Nexus (https://nexus.praktikum-services.tech/#browse/browse:sausage-store-helm-shamil-kamilov-033-40 в папке momo-store)
	•	Для каждого коммита/pipeline создаётся отдельный релиз (semver не используется, используется номер пайплайна)
	•	История изменений ведётся в merge requests

⸻
