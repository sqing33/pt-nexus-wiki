# Dockerfile
# FROM stilleshan/docsify
FROM ghcr.io/sqing33/docsify-stilleshan

# 安装 git 和基础工具
RUN echo "http://mirrors.huaweicloud.com/alpine/v$(cat /etc/alpine-release | cut -d. -f1-2)/main" > /etc/apk/repositories && \
    echo "http://mirrors.huaweicloud.com/alpine/v$(cat /etc/alpine-release | cut -d. -f1-2)/community" >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache git

# 创建目录结构
RUN mkdir -p /tmp-docs-build

# 复制文件
COPY . /tmp-docs-build/
COPY entrypoint.sh /

# 设置文件权限
RUN chmod +x /entrypoint.sh && \
    echo "" > /tmp-docs-build/.nojekyll

# 设置默认工作目录
WORKDIR /docs

ENTRYPOINT ["/entrypoint.sh"]
