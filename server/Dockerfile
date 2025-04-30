FROM python:3.13-slim

WORKDIR /server

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080

# RUN apk add --no-cache shadow && \
#     useradd -U -u 1000 appuser && \
#     chown -R 1000:1000 /server
# USER 1000

# CMD [ "python", "server.py"]

CMD ["gunicorn", "server:app", "--bind", "0.0.0.0:8080", "--workers", "2"]

# ENV WEB_CONCURRENCY=3
# ENV THREADS_PER_WORKER=4
#
# CMD ["sh", "-c", \
#   "exec gunicorn server:app \
#     --bind 0.0.0.0:${PORT:-8080} \
#     --workers ${WEB_CONCURRENCY} \
#     --threads ${THREADS_PER_WORKER} \
#     --worker-class gthread"]