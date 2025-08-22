# ===== Stage 1: build web UI =====
FROM node:20-bullseye AS web
WORKDIR /tmp/src

# 启用 Corepack，确保使用 Yarn 4
RUN corepack enable
RUN corepack prepare yarn@4.4.0 --activate

# 下载 upstream 指定 tag 的源码包，仅用于构建前端
ADD https://codeload.github.com/OpenMaxIO/openmaxio-object-browser/tar.gz/refs/tags/v1.7.6 /tmp/src.tar.gz
RUN mkdir /tmp/up && tar -xzf /tmp/src.tar.gz -C /tmp/up --strip-components=1

WORKDIR /tmp/up/web-app
# 用 Yarn 4 安装依赖
RUN yarn install
# 构建前端
RUN yarn build

# ===== Stage 2: build Go console (后端) =====
FROM golang:1.24-bullseye AS build
WORKDIR /app
COPY . .

# 用刚才构建好的前端覆盖
RUN rm -rf web-app/build && mkdir -p web-app/build
COPY --from=web /tmp/up/web-app/build/ web-app/build/

# 编译 console
RUN go build -o console ./cmd/console

# ===== Stage 3: 运行镜像 =====
FROM debian:bookworm-slim
WORKDIR /opt/console
COPY --from=build /app/console /opt/console/console

# 默认监听端口
EXPOSE 9090 9443

# 环境变量由 Coolify 注入
ENV CONSOLE_MINIO_SERVER=http://minio:9000
ENV CONSOLE_PBKDF_PASSPHRASE=CHANGE_ME
ENV CONSOLE_PBKDF_SALT=CHANGE_ME

ENTRYPOINT ["./console","server","--port","9090"]
