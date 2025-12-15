HW 4

## Описание

В четвертой лабораторной работе в локальном кластере Kubernetes (minikube) развернуты три связанных сервиса:

* PostgreSQL - база данных.
* Nextcloud - веб-приложение, использующее PostgreSQL как бекенд.
* Nginx - reverse proxy с кастомным Docker-образом для проксирования запросов к Nextcloud.

Конфигурация выполнена в соответствии с заданием:

* развернуты три Deployment (postgres, nextcloud, nginx-proxy);
* создан кастомный Docker-образ для nginx из собственного Dockerfile;
* в Nextcloud добавлен init-контейнер для проверки доступности PostgreSQL;
* используется PersistentVolumeClaim для хранения данных Nextcloud;
* параметры вынесены в ConfigMap;
* чувствительные данные (пароли / логины) вынесены в Secret;
* для Nextcloud и Nginx добавлены liveness и readiness-пробы;
* все ресурсы помечены структурированными лейблами (app, tier, component, lab).

Все манифесты находятся в корне проекта:

* Dockerfile
* nginx.conf
* default.conf
* nginx_deployment.yml
* nginx_service.yml
* nextcloud_pvc.yml
* nextcloud.yml
* nextcloud_configmap.yml
* nextcloud_service.yml
* pg_deployment.yml
* pg_service.yml
* pg_configmap.yml
* pg_secret.yml
* deploy.sh (скрипт автоматического развертывания)

## Соответствие требованиям

Выполнены следующие пункты задания:

* Развернуты минимум два Deployment (фактически три):

  * PostgreSQL (база данных),
  * Nextcloud (веб-приложение с init-контейнером),
  * Nginx Proxy (reverse proxy с кастомным образом).

* Создан кастомный Docker-образ:

  * Dockerfile на основе nginx:1.25-alpine;
  * кастомная конфигурация nginx.conf и default.conf для проксирования Nextcloud;
  * добавлен health endpoint /health;
  * образ собирается локально в Minikube: `docker build -t custom-nginx:1.0 .`;
  * в nginx_deployment.yml указан `image: custom-nginx:1.0` с `imagePullPolicy: Never`.

* Добавлен init-контейнер:

  * в Deployment nextcloud создан init-контейнер `wait-for-postgres`;
  * образ: busybox:1.36;
  * функция: проверяет доступность PostgreSQL (postgres-service:5432) перед запуском основного контейнера Nextcloud;
  * команда использует `nc -z postgres-service 5432` в цикле до успешного подключения.

* Используется volume:

  * создан PersistentVolumeClaim `nextcloud-data-pvc` с объемом 1Gi;
  * PVC примонтирован в Deployment nextcloud по пути /var/www/html;
  * дополнительно в nginx-proxy используется emptyDir volume для логов (/var/log/nginx).

* Обязательное использование ConfigMap и Secret:

  * ConfigMap:
    * postgres-configmap (POSTGRES_DB),
    * nextcloud-configmap (POSTGRES_HOST, NEXTCLOUD_TRUSTED_DOMAINS, NEXTCLOUD_ADMIN_USER и др.).
  * Secret:
    * postgres-secret (POSTGRES_USER, POSTGRES_PASSWORD),
    * nextcloud-secret (NEXTCLOUD_ADMIN_PASSWORD).

* Созданы Service для всех сервисов:

  * postgres-service (тип ClusterIP) для внутреннего доступа к БД,
  * nextcloud-service (тип NodePort:30080) для доступа к Nextcloud,
  * nginx-proxy-service (тип NodePort:30090) для доступа через reverse proxy.

* Добавлены Liveness и Readiness пробы:

  * Nextcloud:
    * livenessProbe и readinessProbe типа tcpSocket на порт 80;
    * initialDelaySeconds: 60 (liveness), 30 (readiness).
  * Nginx:
    * livenessProbe и readinessProbe типа httpGet на путь /health порт 80;
    * initialDelaySeconds: 10 (liveness), 5 (readiness).

* Использованы структурированные лейблы:

  * `app`: postgres | nextcloud | nginx - основной идентификатор приложения;
  * `tier`: database | backend | frontend - уровень архитектуры;
  * `component`: storage | application | proxy - роль компонента;
  * `lab`: lab4 - маркер лабораторной работы.
  
  Примеры использования:
  
  ```bash
  kubectl get all -l lab=lab4
  kubectl get pods -l tier=backend
  kubectl get all -l app=nginx
  ```

* Для всех сущностей корректность работы проверена командами:

  * kubectl get pods -l lab=lab4
  * kubectl get all -l lab=lab4
  * kubectl describe deployment nextcloud
  * kubectl logs deployment/nextcloud -c wait-for-postgres
  * kubectl logs deployment/nextcloud -c nextcloud
  * kubectl get pvc
  * kubectl get configmap,secret -l lab=lab4

## Запуск и остановка

### Запуск

1. Запустить кластер minikube:

   ```bash
   minikube start --driver=docker
   ```

2. Собрать кастомный Docker-образ nginx:

   ```bash
   eval $(minikube docker-env)
   docker build -t custom-nginx:1.0 .
   docker images | grep custom-nginx
   ```

3. Применить манифесты PostgreSQL:

   ```bash
   kubectl apply -f pg_configmap.yml
   kubectl apply -f pg_secret.yml
   kubectl apply -f pg_deployment.yml
   kubectl apply -f pg_service.yml
   ```

4. Дождаться запуска PostgreSQL:

   ```bash
   kubectl get pods -l app=postgres -w
   ```
   
   Нажать Ctrl+C когда под станет Ready (1/1).

5. Применить манифесты Nextcloud:

   ```bash
   kubectl apply -f nextcloud_pvc.yml
   kubectl apply -f nextcloud_configmap.yml
   kubectl apply -f nextcloud.yml
   kubectl apply -f nextcloud_service.yml
   ```

6. Дождаться запуска Nextcloud (init-контейнер должен завершиться, основной контейнер запуститься):

   ```bash
   kubectl get pods -l app=nextcloud -w
   ```

7. Применить манифесты Nginx:

   ```bash
   kubectl apply -f nginx_deployment.yml
   kubectl apply -f nginx_service.yml
   ```

8. Проверить, что все поды запущены:

   ```bash
   kubectl get pods -l lab=lab4
   ```

9. Открыть Nextcloud в браузере через nginx proxy:

   ```bash
   minikube service nginx-proxy-service
   ```
   
   Или напрямую к Nextcloud:
   
   ```bash
   minikube service nextcloud-service
   ```
   
   Войти под администратором:
   * Логин: masha25 (NEXTCLOUD_ADMIN_USER из ConfigMap)
   * Пароль: masha25 (NEXTCLOUD_ADMIN_PASSWORD из Secret)

**Автоматический запуск:**

Для автоматического развертывания всех компонентов можно использовать скрипт:

```bash
./deploy.sh
```

### Остановка

Остановить развернутые ресурсы:

```bash
kubectl delete -f nginx_service.yml
kubectl delete -f nginx_deployment.yml
kubectl delete -f nextcloud_service.yml
kubectl delete -f nextcloud.yml
kubectl delete -f nextcloud_configmap.yml
kubectl delete -f nextcloud_pvc.yml
kubectl delete -f pg_service.yml
kubectl delete -f pg_deployment.yml
kubectl delete -f pg_secret.yml
kubectl delete -f pg_configmap.yml
```

Или удалить все ресурсы по лейблу:

```bash
kubectl delete all,pvc,configmap,secret -l lab=lab4
```

Остановить кластер minikube:

```bash
minikube stop
```

## Проверка выполнения требований

Команды для проверки соответствия заданию:

```bash
# 1. Минимум два Deployment (у нас три)
kubectl get deployments -l lab=lab4

# 2. Кастомный образ
kubectl get deployment nginx-proxy -o jsonpath='{.spec.template.spec.containers[0].image}'
# Должно вывести: custom-nginx:1.0

# 3. Init-контейнер
kubectl get deployment nextcloud -o jsonpath='{.spec.template.spec.initContainers[*].name}'
# Должно вывести: wait-for-postgres

# Логи init-контейнера
kubectl logs deployment/nextcloud -c wait-for-postgres

# 4. Volume (PVC)
kubectl get pvc
# Должно быть: nextcloud-data-pvc в статусе Bound

# Проверка volumes в deployment
kubectl get deployment nextcloud -o jsonpath='{.spec.template.spec.volumes[*].name}'
# Должно вывести: nextcloud-data

# 5. ConfigMap и Secret
kubectl get configmap,secret -l lab=lab4
# Должно быть минимум 2 configmap и 2 secret

# 6. Service
kubectl get svc -l lab=lab4
# Должно быть 3 service

# 7. Liveness/Readiness пробы
kubectl get deployment nextcloud -o yaml | grep -A 3 "livenessProbe"
kubectl get deployment nextcloud -o yaml | grep -A 3 "readinessProbe"
kubectl get deployment nginx-proxy -o yaml | grep -A 3 "livenessProbe"
kubectl get deployment nginx-proxy -o yaml | grep -A 3 "readinessProbe"

# 8. Лейблы
kubectl get all -l lab=lab4 --show-labels
```
