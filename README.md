HW 3

## Описание

В третьей лабораторной работе в локальном кластере Kubernetes (minikube) развернуты два связанных сервиса:

* PostgreSQL - база данных.
* Nextcloud - веб-приложение, использующее PostgreSQL как бекенд.

Конфигурация выполнена в соответсвии с заданием:

* параметры вынесены в ConfigMap;
* чувствительные данные (пароли / логины) вынесены в Secret;
* для Nextcloud добавлены liveness и readiness-пробы;
* доступ к Nextcloud обеспечивается через Service типа NodePort.

Все манифесты находятся в корне проекта:

* pg_configmap.yml
* pg_secret.yml
* pg_service.yml
* pg_deployment.yml
* nextcloud_configmap.yml
* nextcloud.yml

## Соответствие требованиям

Выполнены следующие пункты задания:

* Подняты два сервиса в Kubernetes-кластере:

  * PostgreSQL,
  * Nextcloud.

* Для PostgreSQL:

  * создана ConfigMap postgres-configmap c параметром POSTGRES_DB;
  * создан Secret postgres-secret c POSTGRES_USER и POSTGRES_PASSWORD
    (перенесены из ConfigMap в Secret в соответствии с заданием);
  * создан Service postgres-service (тип NodePort) для доступа к БД внутри кластера;
  * создан Deployment postgres с:

    * ресурсными лимитами/requests по CPU и памяти,
    * переменными окружения:

      * POSTGRES_DB из postgres-configmap,
      * POSTGRES_USER и POSTGRES_PASSWORD из postgres-secret через secretKeyRef.

* Для Nextcloud:

  * создан Secret nextcloud-secret c  NEXTCLOUD_ADMIN_PASSWORD;
  * создана ConfigMap nextcloud-configmap с параметрами:

    *  NEXTCLOUD_UPDATE,
    *  ALLOW_EMPTY_PASSWORD,
    *  POSTGRES_HOST,
    *  NEXTCLOUD_TRUSTED_DOMAINS,
    *  NEXTCLOUD_ADMIN_USER;
  * создан Deployment nextcloud c:

    * ресурсными лимитами и requests;
    * подключением переменных из ConfigMap через:

      ```yaml
      envFrom:
        - configMapRef:
            name: nextcloud-configmap
      ```
    * подключением параметров БД (POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD) через configMapKeyRef и secretKeyRef;
    * подключением пароля администратора Nextcloud из nextcloud-secret.

* Для Nextcloud добавлены livenessProbe и readinessProbe:

  * тип проверки: httpGet на порт 80, путь /;
  * заданы initialDelaySeconds и periodSeconds для корректной проверки готовности приложения

* Для Nextcloud создаётся Service типа NodePort:

  * либо отдельным манифестом,
  * либо командой:

    ```bash
    kubectl expose deployment nextcloud --type=NodePort --port=80
    ```

* Для всех сущностей (ConfigMap, Secret, Deployment, Service) корректность работы проверена командами:

  * kubectl get ...
  * kubectl describe pod ...
  * kubectl logs ...

## Запуск и остановка

### Запуск

1. Запустить кластер minikube:

   ```bash
   minikube start --driver=docker
   ```

2. Применить манифесты PostgreSQL:

   ```bash
   kubectl apply -f pg_configmap.yml
   kubectl apply -f pg_secret.yml
   kubectl apply -f pg_service.yml
   kubectl apply -f pg_deployment.yml
   ```

3. Применить манифесты Nextcloud:

   ```bash
   kubectl apply -f nextcloud_configmap.yml
   kubectl apply -f nextcloud.yml
   ```

4. Создать сервис для Nextcloud (если не описан в YAML):

   ```bash
   kubectl expose deployment nextcloud --type=NodePort --port=80
   ```

5. Проверить, что все поды запущены:

   ```bash
   kubectl get pods
   ```

6. Открыть Nextcloud в браузере через minikube:

   ```bash
   minikube service nextcloud
   ```

   Войти под администратором (NEXTCLOUD_ADMIN_USER из ConfigMap и NEXTCLOUD_ADMIN_PASSWORD из Secret).

### Остановка

Остановить развернутые ресурсы:

```bash
kubectl delete -f nextcloud.yml
kubectl delete -f nextcloud_configmap.yml
kubectl delete -f pg_deployment.yml
kubectl delete -f pg_service.yml
kubectl delete -f pg_secret.yml
kubectl delete -f pg_configmap.yml
```

Остановить кластер minikube:

```bash
minikube stop
```
