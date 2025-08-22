# ---------- Build stage ----------
FROM node:20-alpine AS builder

WORKDIR /app

# 复制源码
COPY . .

# 安装依赖
RUN yarn install --frozen-lockfile

# 构建前端（输出到 /app/dist）
RUN yarn build

# ---------- Runtime stage ----------
FROM nginx:alpine

# 拷贝构建好的静态文件到 Nginx 默认目录
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
