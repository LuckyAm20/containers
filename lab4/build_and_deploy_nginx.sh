#!/bin/bash
set -e

echo "🔧 Настройка Docker окружения для Minikube..."
eval $(minikube docker-env)

echo "🐳 Сборка образа custom-nginx:1.0..."
docker build -t custom-nginx:1.0 .

echo "✅ Проверка образа..."
docker images | grep custom-nginx

echo "🗑️  Удаление старого deployment nginx..."
kubectl delete deployment nginx-proxy 2>/dev/null || true

echo "📦 Применение нового deployment..."
kubectl apply -f nginx_deployment.yml

echo "⏳ Ожидание запуска nginx..."
kubectl wait --for=condition=ready pod -l app=nginx --timeout=60s

echo "✅ Nginx успешно развернут!"
kubectl get pods -l app=nginx
