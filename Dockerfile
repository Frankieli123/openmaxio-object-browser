# ===== Stage 1: build web UI =====
FROM node:18-bullseye AS web
WORKDIR /tmp/src
# 拉取 upstream 指定 tag 的源码包，仅为拿到 web-app 前端
ADD https://codeload.github.com/OpenMaxIO/openmaxio-object-browser/tar.gz/refs/tags/v1.7.6 /tmp/src.tar.gz
RUN mkdir /tmp/up && tar -xzf /tmp/src.tar.gz -C /tmp/up --strip-components=1 \
 && cd /tmp/up/web-app \
 && yarn install --frozen-lockfile || yarn install \
 && yarn build

# ===== Stage 2: build Go console (后端) =====
FROM golang:1.22-bullseye AS build
WORKDIR /app
# 把你 fork 的源码拷进来（Coolify 会把仓库作为 build context 传进来）
COPY . .
# 用我们刚刚编好的前端覆盖到仓库的 web-app/build 里（go:embed 会打进二进制）
RUN rm -rf web-app/build && mkdir -p web-app/build
COPY --from=web /tmp/up/web-app/build/ web-app/build/
# 编译 console（等价于 README 里的 make console）
RUN go build -o console ./cmd/console

# ===== Stage 3: 运行镜像 =====
FROM debian:bookworm-slim
WORKDIR /opt/console
COPY --from=build /app/console /opt/console/console
# 缺省监听 9090（HTTP）和 9443（HTTPS）
EXPOSE 9090 9443
# 这三个环境变量在运行时由 Coolify 注入
ENV CONSOLE_MINIO_SERVER=http://minio:9000
ENV CONSOLE_PBKDF_PASSPHRASE=CHANGE_ME
ENV CONSOLE_PBKDF_SALT=CHANGE_ME
ENTRYPOINT ["./console","server","--port","9090"]
