#!/bin/sh
set -e # 如果任何命令失败，立即退出脚本

# --- 变量定义 ---
DOCS_DIR="/docs"
LISTENER_DIR="/docs/git_listen" # 监听脚本所在的目录
TMP_DOCS_BUILD="/tmp-docs-build" # Dockerfile 构建时复制文件到的临时目录

# 从环境变量读取是否启用 Git
# 如果 ENABLE_GIT 未设置，默认为 true
ENABLE_GIT=${ENABLE_GIT:-true}

# --- 确保目录存在并进入工作目录 ---
echo "确保目录存在: ${DOCS_DIR} 和 ${LISTENER_DIR}"
mkdir -p "$DOCS_DIR"
mkdir -p "$LISTENER_DIR"
mkdir -p "${DOCS_DIR}/_media" # 确保 _media 目录存在

echo "从 ${TMP_DOCS_BUILD} 复制 listener.js 到 ${LISTENER_DIR}"

# 检查目标目录是否存在
if [ ! -d "${LISTENER_DIR}" ]; then
  echo "目录 ${LISTENER_DIR} 不存在，创建它..."
  mkdir -p "${LISTENER_DIR}"
fi

# 检查目标文件是否存在
if [ ! -f "${LISTENER_DIR}/listener.js" ]; then
  cp "${TMP_DOCS_BUILD}/listener.js" "${LISTENER_DIR}/listener.js"
  chmod +x "${LISTENER_DIR}/listener.js"
  echo "已复制 listener.js 到 ${LISTENER_DIR}"
else
  echo "文件 ${LISTENER_DIR}/listener.js 已存在，跳过复制。"
fi

echo "从 ${TMP_DOCS_BUILD} 复制 icon.svg 到 ${DOCS_DIR}/_media/"

# 检查目标目录是否存在
if [ ! -d "${DOCS_DIR}/_media" ]; then
  echo "目录 ${DOCS_DIR}/_media 不存在，创建它..."
  mkdir -p "${DOCS_DIR}/_media"
fi

# 检查目标文件是否存在
if [ ! -f "${DOCS_DIR}/_media/icon.svg" ]; then
  cp "${TMP_DOCS_BUILD}/icon.svg" "${DOCS_DIR}/_media/icon.svg"
  echo "已复制 icon.svg 到 ${DOCS_DIR}/_media/"
else
  echo "文件 ${DOCS_DIR}/_media/icon.svg 已存在，跳过复制。"
fi

echo "进入 ${LISTENER_DIR} 并安装 npm 依赖..."
cd "$LISTENER_DIR"
npm install --registry=https://repo.huaweicloud.com/repository/npm/ express body-parser crypto
echo "npm 依赖安装完成。"

cd "$DOCS_DIR"
echo "当前工作目录: $(pwd)"

# --- 默认文件填充逻辑 ---
# 从构建时复制进来的 /tmp-docs-build 目录移动文件到 /docs，
# 只有当 /docs 中对应文件不存在时才移动。
echo "检查并填充默认 Docsify 文件从 ${TMP_DOCS_BUILD} 到 ${DOCS_DIR}..."

# 需要检查和移动的文件列表
# 包含你复制的以及可能的 .nojekyll
DEFAULT_FILES="_sidebar.md index.html README.md generate-sidebar.js .nojekyll"

for FILE in $DEFAULT_FILES; do
  # 构建源文件路径 (在临时目录中)
  SOURCE_PATH="$TMP_DOCS_BUILD/$FILE"
  # 构建目标文件路径 (在 /docs 目录中)
  TARGET_PATH="$DOCS_DIR/$FILE"

  # 检查源文件是否存在 (确保 Dockerfile 构建时复制了它)
  if [ -f "$SOURCE_PATH" ]; then
    # 检查目标文件是否不存在 (在卷中)
    if [ ! -f "$TARGET_PATH" ]; then
      echo "复制默认文件: ${FILE}"
      # 使用 cp 替代 mv，保留临时目录中的文件
      cp "$SOURCE_PATH" "$TARGET_PATH"
    else
      echo "文件已存在，跳过: ${FILE}"
    fi
  fi
done
echo "默认文件填充检查完成。"

# --- 定制逻辑: Git 初始化和拉取 (根据 ENABLE_GIT 控制) ---
# 检查 ENABLE_GIT 环境变量是否不是 'false' (忽略大小写)
# 使用 case 语句进行 ash 兼容的 case-insensitive 检查
case "$ENABLE_GIT" in
  [fF][aA][lL][sS][eE])
    # ENABLE_GIT is "false" (case-insensitive)
    echo "ENABLE_GIT 设置为 'false'，跳过 Git 相关操作（初始化、拉取、safe.directory）。"
    SKIP_GIT=true
    ;;
  *)
    # ENABLE_GIT is anything else (true, empty, or other values)
    echo "ENABLE_GIT 已启用或未设置为 'false'，执行 Git 相关操作。"
    SKIP_GIT=false
    ;;
esac

if [ "$SKIP_GIT" != "true" ]; then
  # 如果 .git 目录不存在，则初始化 Git 仓库
  if [ ! -d .git ]; then
    echo "正在 ${DOCS_DIR} 中初始化 Git 仓库..."
    git init
    # 从环境变量中添加远程仓库地址 (GIT_REMOTE_URL 来自 docker-compose.yml)
    if [ -z "$GIT_REMOTE_URL" ]; then
      echo "错误: 未设置 GIT_REMOTE_URL 环境变量。无法添加远程源。Git 初始化不完整。"
      # 这里不立即退出，允许容器启动，但 Git 拉取将失败
    else
      git remote add origin "$GIT_REMOTE_URL"
      echo "已添加远程源: $GIT_REMOTE_URL"

      # 首次拉取内容填充仓库
      echo "尝试进行首次 git 拉取..."
      # 使用 GIT_REMOTE 和 GIT_BRANCH 环境变量
      if git pull origin "$GIT_BRANCH"; then
        echo "首次 git pull 成功。"
        # 在首次拉取成功后运行 generate-sidebar.js
        echo "首次拉取成功，正在运行 generate-sidebar.js..."
        # 确保在正确的目录执行脚本 (当前工作目录已经是 /docs)
        node generate-sidebar.js || echo "运行 generate-sidebar.js 失败！" # 即使 generate 失败也不中断 entrypoint
        echo "generate-sidebar.js 执行完成。"
      else
        echo "首次 git pull 失败。"
      fi

      echo "Git 仓库初始化和首次拉取完成。"
    fi
  else
      echo "Git 仓库已存在，跳过初始化。"
      # 如果 Git 仓库已存在，我们通常不自动运行 generate-sidebar.js
      # 因为它应该由 webhook 触发
  fi

  # 将 /docs 添加到 Git 的全局安全目录中
  echo "将 ${DOCS_DIR} 添加到 Git 全局 safe.directory..."
  git config --global --add safe.directory "$DOCS_DIR"
  echo "/docs 已添加到全局 safe.directory。"

# else 块对应 case 语句中的 SKIP_GIT=true 分支，其 echo 消息已在 case 中处理
fi


# --- 定制逻辑: 启动 webhook 监听器 (根据 ENABLE_GIT 控制) ---
# 仅在未跳过 Git 操作时启动监听器
if [ "$SKIP_GIT" != "true" ]; then
  echo "正在启动 webhook 监听器脚本位于: ${LISTENER_DIR}/listener.js ..."
  # 使用环境变量传递配置给 listener.js
  WEBHOOK_PORT="$WEBHOOK_PORT" \
  WEBHOOK_SECRET="$WEBHOOK_SECRET" \
  GIT_REMOTE="$GIT_REMOTE" \
  GIT_BRANCH="$GIT_BRANCH" \
  DOCS_DIR="$DOCS_DIR" \
  node "$LISTENER_DIR/listener.js" & # '&' 使其在后台运行

  LISTENER_PID=$!
  echo "Webhook 监听器启动命令已执行，PID 可能为 $LISTENER_PID。"
else
  echo "ENABLE_GIT 设置为 'false'，跳过启动 webhook 监听器。"
fi


# --- 最后一步: 启动主要的 docsify 服务器 ---
echo "正在启动 docsify 服务器..."
exec docsify start "$DOCS_DIR" --port "$DOCSIFY_PORT"

echo "Docsify 服务器启动失败！"
exit 1
