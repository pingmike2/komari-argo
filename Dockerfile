FROM debian:bookworm-slim

# 安装依赖（包含 cron）
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        curl \
        bash \
        git \
        tar \
        jq \
        unzip \
        sqlite3 \
        ca-certificates \
        python3 \
        supervisor \
        procps \
        tzdata \
        cron && \
    rm -rf /var/lib/apt/lists/*

# 环境变量
ENV TZ=UTC

WORKDIR /app

# 安装 Komari
RUN wget -q https://github.com/komari-monitor/komari/releases/latest/download/komari-linux-amd64 \
    -O /app/komari && \
    chmod +x /app/komari

# 安装 Caddy
ARG CADDY_VERSION=2.9.1
RUN ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
        amd64) arch="amd64" ;; \
        arm64) arch="arm64" ;; \
        *) echo "Unsupported arch: $ARCH"; exit 1 ;; \
    esac && \
    wget -q "https://github.com/caddyserver/caddy/releases/download/v${CADDY_VERSION}/caddy_${CADDY_VERSION}_linux_${arch}.tar.gz" -O /tmp/caddy.tar.gz && \
    tar xzf /tmp/caddy.tar.gz -C /usr/local/bin caddy && \
    chmod +x /usr/local/bin/caddy && \
    rm -f /tmp/caddy.tar.gz

# 删除可能存在的 cloudflared
RUN rm -f /usr/local/bin/cloudflared /usr/bin/cloudflared

# 复制脚本
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY start_cloudflared.py /app/start_cloudflared.py
RUN chmod +x /app/start_cloudflared.py

COPY repo.conf /app/repo.conf

COPY backup.sh /app/backup.sh
RUN chmod +x /app/backup.sh

COPY restore.sh /app/restore.sh
RUN chmod +x /app/restore.sh

COPY renew.sh /app/renew.sh
RUN chmod +x /app/renew.sh

COPY sub_link.sh /app/sub_link.sh
RUN chmod +x /app/sub_link.sh

# 创建目录
RUN mkdir -p /app/data /tmp

# HuggingFace 端口
EXPOSE 7860

# 启动
CMD ["/usr/local/bin/entrypoint.sh"]