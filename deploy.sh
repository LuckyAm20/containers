#!/bin/bash

# Скрипт для развертывания ЛР 4 в Kubernetes
# Автор: Мария Казакова

set -e  # Прервать выполнение при ошибке

echo "========================================="
echo "  Развертывание ЛР 4 в Kubernetes"
echo "========================================="
echo

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Функция для вывода успешного сообщения
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Функция для вывода предупреждения
warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Функция для вывода ошибки
error() {
    echo -e "${RED}✗ $1${NC}"
}

# Проверка наличия kubectl
if ! command -v kubectl &> /dev/null; then
    error "kubectl не установлен. Установите kubectl и попробуйте снова."
    exit 1
fi
success "kubectl найден"

# Проверка наличия minikube
if ! command -v minikube &> /dev/null; then
    error "minikube не установлен. Установите minikube и попробуйте снова."
    exit 1
fi
success "minikube найден"

# Проверка, что minikube запущен
if ! minikube status &> /dev/null; then
    warning "minikube не запущен. Запускаю..."
    minikube start --driver=docker
    success "minikube запущен"
else
    success "minikube уже запущен"
fi

echo
echo "--- Шаг 1: Сборка кастомного образа nginx ---"
echo

# Настройка Docker для использования Minikube
eval $(minikube docker-env)
success "Docker настроен для работы с Minikube"

# Сборка образа
if docker build -t custom-nginx:1.0 . ; then
    success "Образ custom-nginx:1.0 успешно собран"
else
    error "Ошибка сборки образа"
    exit 1
fi

echo
echo "--- Шаг 2: Развертывание PostgreSQL ---"
echo

kubectl apply -f pg_configmap.yml
success "ConfigMap для PostgreSQL применен"

kubectl apply -f pg_secret.yml
success "Secret для PostgreSQL применен"

kubectl apply -f pg_deployment.yml
success "Deployment для PostgreSQL применен"

kubectl apply -f pg_service.yml
success "Service для PostgreSQL применен"

echo "Ожидание запуска PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s
success "PostgreSQL запущен и готов"

echo
echo "--- Шаг 3: Развертывание Nextcloud ---"
echo

kubectl apply -f nextcloud_pvc.yml
success "PersistentVolumeClaim для Nextcloud применен"

kubectl apply -f nextcloud_configmap.yml
success "ConfigMap для Nextcloud применен"

kubectl apply -f nextcloud.yml
success "Deployment для Nextcloud применен"

kubectl apply -f nextcloud_service.yml
success "Service для Nextcloud применен"

echo "Ожидание запуска Nextcloud (может занять до 2 минут)..."
kubectl wait --for=condition=ready pod -l app=nextcloud --timeout=180s
success "Nextcloud запущен и готов"

echo
echo "--- Шаг 4: Развертывание Nginx Proxy ---"
echo

kubectl apply -f nginx_deployment.yml
success "Deployment для Nginx применен"

kubectl apply -f nginx_service.yml
success "Service для Nginx применен"

echo "Ожидание запуска Nginx..."
kubectl wait --for=condition=ready pod -l app=nginx --timeout=60s
success "Nginx запущен и готов"

echo
echo "========================================="
echo "  Развертывание завершено успешно!"
echo "========================================="
echo

# Вывод информации о развернутых ресурсах
echo "--- Статус подов ---"
kubectl get pods -l lab=lab4

echo
echo "--- Сервисы ---"
kubectl get svc -l lab=lab4

echo
echo "--- PersistentVolumeClaims ---"
kubectl get pvc

echo
echo "========================================="
echo "  Доступ к приложению"
echo "========================================="
echo

NGINX_URL=$(minikube service nginx-proxy-service --url 2>/dev/null || echo "")
if [ -n "$NGINX_URL" ]; then
    echo "Nginx Proxy (рекомендуется): $NGINX_URL"
else
    warning "Не удалось получить URL. Используйте: minikube service nginx-proxy-service"
fi

NEXTCLOUD_URL=$(minikube service nextcloud-service --url 2>/dev/null || echo "")
if [ -n "$NEXTCLOUD_URL" ]; then
    echo "Nextcloud (напрямую):        $NEXTCLOUD_URL"
fi

echo
echo "Учетные данные для входа:"
echo "  Логин:  masha25"
echo "  Пароль: masha25"
echo

echo "Для открытия в браузере выполните:"
echo "  minikube service nginx-proxy-service"
echo

echo "Для просмотра логов:"
echo "  kubectl logs -l lab=lab4 --all-containers=true"
echo

success "Готово! Приложение развернуто и доступно."

