# Кастомный образ nginx для ЛР 4
# Используется как reverse proxy перед Nextcloud

FROM nginx:1.25-alpine

# Метаданные
LABEL maintainer="Maria Kazakova"
LABEL description="Custom nginx reverse proxy for Nextcloud"
LABEL version="1.0"

# Копируем кастомную конфигурацию nginx
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# Создаем директорию для логов
RUN mkdir -p /var/log/nginx && \
    chown -R nginx:nginx /var/log/nginx

# Добавляем кастомную страницу здоровья
RUN echo '<html><body><h1>Nginx Proxy OK</h1></body></html>' > /usr/share/nginx/html/health.html

# Открываем порт
EXPOSE 80

# Запускаем nginx
CMD ["nginx", "-g", "daemon off;"]

