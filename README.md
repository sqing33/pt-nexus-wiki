# Docsify Docker 项目

本项目提供了一个基于 Docker 的 Docsify 环境，基于 `stilleshan/docsify` 镜像修改而成，新增了右侧标题栏插件，使用左边文件名+右边标题的布局，支持通过 Git Webhook 自动更新文档内容并重新生成侧边栏。

## 功能特性

- **Docker化环境**: 使用 Docker 容器运行 Docsify，方便部署和管理。
- **Git Webhook 集成**:
    - 通过 `listener.js` 脚本监听来自 Gitea (或其他兼容 Git 服务) 的 Webhook `push` 事件。
    - 验证 Webhook 签名以确保安全性。
    - 仅处理指定分支的 `push` 事件。
    - 自动从指定的 Git 远程仓库拉取最新更改。
- **自动侧边栏生成**:
    - `generate-sidebar.js` 脚本在 Git 拉取成功后自动运行，根据 `/docs` 目录下的 Markdown 文件结构生成 `_sidebar.md`。
    - 支持排除特定文件和目录。
- **灵活的 Git 配置**:
    - 可以通过环境变量 `ENABLE_GIT` (默认为 `true`) 控制是否启用 Git 相关功能（初始化、拉取、Webhook 监听）。
    - 首次启动时，如果启用了 Git 且 `/docs` 目录为空，会自动初始化 Git 仓库，添加远程源 (由 `GIT_REMOTE_URL` 指定)，并拉取指定分支 (由 `GIT_BRANCH` 指定) 的内容。
- **Docsify 插件**:
    - `docsify-plugin-toc`: 右侧目录导航。
    - `docsify-count`: 字数统计。
    - `emoji.min.js`: Emoji 支持。
    - `zoom-image.min.js`: 图片缩放。
    - `docsify-copy-code`: 代码块复制按钮。
- **自定义 Logo 和标题**: `index.html` 中的自定义脚本会美化侧边栏顶部的 Logo 和站点名称显示。
- **默认文件填充**: 容器启动时，如果 `/docs` 目录中缺少核心 Docsify 文件（如 `index.html`, `_sidebar.md`, `README.md`, `generate-sidebar.js`, `.nojekyll`），会从镜像中复制默认版本。

## Dockerfile 项目结构

```plaintext
.
├── Dockerfile              # Docker 镜像构建文件
├── entrypoint.sh           # 容器入口脚本，处理初始化和启动服务
├── generate-sidebar.js     # Node.js 脚本，用于生成 _sidebar.md
├── listener.js             # Node.js 脚本，Webhook 监听服务
├── index.html              # Docsify 主 HTML 文件和配置
├── _sidebar.md             # Docsify 侧边栏文件 (由 generate-sidebar.js 生成)
├── README.md               # 本 README 文件
└── icon.svg                # 站点图标
```

## 构建与运行

### 1. 构建 Docker 镜像

> 因为本地网络问题无法获取到源镜像`stilleshan/docsify`的元数据，所以将dockerhub同步到github的ghcr仓库以继续进行(`ghcr.io/sqing33/docsify-stilleshan`)

> 同步过程：https://github.com/sqing33/docker-image-sync

> 构建项目：https://github.com/sqing33/docker-docsify

> DockerHub：https://hub.docker.com/r/sqing33/docsify

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t sqing33/docsify:latest \
  -t ghcr.io/sqing33/docsify:latest \
  --push .
```

### 2. 运行 Docker 容器
你需要根据你的需求配置以下环境变量：

- `DOCSIFY_PORT`: Docsify 服务监听的端口 (默认为 `6158`)。
- `ENABLE_GIT`: 是否启用 Git 功能 (默认为 `true`)。
- `WEBHOOK_PORT`: Webhook 监听器监听的端口 (默认为 `6159`)。
- `WEBHOOK_SECRET`: 用于验证 Webhook 签名的密钥。
- `GIT_REMOTE_URL`: 你的 Git 仓库的 URL (例如: https://gitea.example.com/user/repo.git)。
- `GIT_REMOTE`: Git 远程仓库的名称 (默认为 `origin`)。
- `GIT_BRANCH`: 你希望拉取和监听的分支 (默认为 `main`)。

挂载容器内的 `/docs` 目录，以便于持久化存储文档内容。

示例 docker run 命令:

```bash
docker run -d \
  --name docsify \
  -p 6158:6158 \
  -p 6159:6159 \
  -e DOCSIFY_PORT=6158 \
  -e ENABLE_GIT="true" \
  -e WEBHOOK_PORT=6159 \
  -e WEBHOOK_SECRET=YOUR_WEBHOOK_SECRET \
  -e GIT_REMOTE_URL=YOUR_GIT_REPO_URL \
  -e GIT_REMOTE=origin \
  -e GIT_BRANCH=main \
  -e DOCS_DIR=/docs \
  -v /vol1/1000/Docker/docsify/docs:/docs \
  --restart unless-stopped \
  ghcr.io/sqing33/docsify:latest
```

示例 docker-compose.yml 文件:

```yml
services:
  docsify:
    image: ghcr.io/sqing33/docsify:latest
    container_name: docsify
    ports:
      # Docsify 服务器端口映射
      - "6158:6158"
      # Webhook 监听器端口映射，listener.js 在容器内部监听 6159 端口
      - "6159:6159"

    environment:
      # Docsify 服务端口
      - DOCSIFY_PORT=6158
      # 是否启用 Git 更新
      - ENABLE_GIT="true"
      # WEBHOOK_PORT 监听端口
      - WEBHOOK_PORT=6159
      # Webhook 验证密钥
      - WEBHOOK_SECRET=YOUR_WEBHOOK_SECRET
      # Git 远程仓库的 URL，用于 entrypoint 中的 git remote add origin
      - GIT_REMOTE_URL=YOUR_GIT_REPO_URL
      # Git 远程源的名称，用于 listener.js 中的 git pull
      - GIT_REMOTE=origin # 通常是 origin，如果你的仓库不是则修改
      # Git 分支名称，用于 listener.js 中的 git pull 和事件判断
      - GIT_BRANCH=main
      - DOCS_DIR=/docs # 默认 /docs ，这应与卷挂载点匹配

    volumes:
      # 将宿主机目录挂载到容器内的 /docs
      - '/vol1/1000/Docker/docsify/docs:/docs'

    # 可选：重启策略
    restart: unless-stopped

```

# 具体修改内容

## index.html 示例

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title>Docsify</title>
    <link rel="icon" href="/_media/icon.svg" sizes="any">
    <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1" />
    <meta name="description" content="Description" />
    <meta
      name="viewport"
      content="width=device-width, initial-scale=1.0, minimum-scale=1.0"
    />
    <link
      rel="stylesheet"
      href="//cdn.jsdelivr.net/npm/docsify@4/lib/themes/vue.css"
    />
    <!-- 右侧标题栏 -->
    <link
      rel="stylesheet"
      href="https://unpkg.com/docsify-plugin-toc@1.3.1/dist/light.css"
    />
    <style>
      .sidebar {
        padding: 20px 0 0;
      }
      .content {
        padding-top: 0;
      }
    </style>
    <link rel="icon" href="/_media/icon.jpg" type="image/png" />
  </head>
  <body>
    <div id="app"></div>
    <script>
      window.$docsify = {
        name: "Docsify",
        logo: "/_media/icon.svg",
        repo: "",
        loadSidebar: true, // 是否加载侧边栏
        auto2top: true, // 是否自动滚动到页面顶部
        toc: {
          tocMaxLevel: 6,
          target: "h1, h2, h3, h4, h5, h6",
          ignoreHeaders: [
            "<!-- {docsify-ignore} -->",
            "<!-- {docsify-ignore-all} -->",
          ],
        },
        count: {
          countable: true,
          fontsize: "0.9em",
          color: "rgb(90,90,90)",
          language: "chinese",
        },
        copyCode: {
          buttonText: "复制",
          errorText: "复制错误",
          successText: "复制成功",
        },
      };
      function wrapLogoAndTitle() {
        return function (hook, vm) {
          hook.doneEach(function () {
            const appName = document.querySelector(".sidebar .app-name");
            if (appName) {
              const logoImg = appName.querySelector("img");
              const titleLink = appName.querySelector("a");
              const titleText = vm.config.name;

              if (logoImg && titleLink) {
                // 创建包含logo和标题的新链接
                const newLink = document.createElement("a");
                newLink.href = titleLink.href;
                newLink.className = "app-name-link";

                // 复制原始链接的事件监听器
                newLink.onclick = titleLink.onclick;

                // 添加logo到新链接，并设置尺寸
                const logoClone = logoImg.cloneNode(true);
                logoClone.style.width = "35px";
                logoClone.style.height = "35px";
                logoClone.style.objectFit = "contain"; // 保持图片比例
                logoClone.style.verticalAlign = "middle";

                // 添加标题到新链接
                const titleSpan = document.createElement("span");
                titleSpan.textContent = titleText;
                titleSpan.style.display = "inline-block";
                titleSpan.style.verticalAlign = "middle";
                titleSpan.style.marginLeft = "10px";
                titleSpan.style.fontWeight = "bold";
                titleSpan.style.fontSize = "1.2em";
                titleSpan.style.lineHeight = "35px"; // 关键：使行高等于logo高度

                newLink.appendChild(logoClone);
                newLink.appendChild(titleSpan);

                // 替换原始链接
                appName.innerHTML = "";
                appName.appendChild(newLink);

                document.head.appendChild(style);
              }
            }
          });
        };
      }

      // 注册插件时可以传入自定义配置
      window.$docsify.plugins = [].concat(
        wrapLogoAndTitle(),
        window.$docsify.plugins || []
      );
    </script>
    <!-- Docsify v4 -->
    <script src="//cdn.jsdelivr.net/npm/docsify@4"></script>
    <!-- 右侧标题栏 -->
    <script src="https://unpkg.com/docsify-plugin-toc@1.3.1/dist/docsify-plugin-toc.min.js"></script>
    <!-- 字数统计 -->
    <script src="//unpkg.com/docsify-count/dist/countable.js"></script>
    <!-- emoji 解析 -->
    <script src="//cdn.jsdelivr.net/npm/docsify/lib/plugins/emoji.min.js"></script>
    <!-- 图片缩放 -->
    <script src="//cdn.jsdelivr.net/npm/docsify/lib/plugins/zoom-image.min.js"></script>
    <!-- 复制 -->
    <script src="//cdn.jsdelivr.net/npm/docsify-copy-code/dist/docsify-copy-code.min.js"></script>
  </body>
</html>

```

插件包含：右侧标题栏、字数统计、emoji 解析、图片缩放、代码复制、自定义左上角 logo + 标题

![image](https://github.com/user-attachments/assets/081fb389-cca2-498a-a079-02f5ce1c262e)


## 同步远程 Git 仓库实现远程修改

### 1. 同步 Git 仓库

- 在映射的数据目录/vol1/1000/Docker/docsify/docs:/docs'新建 git 仓库：

```bash
git init
git remote add origin http://192.168.1.100:3111/sqing/wiki.js.git
git config --global --add safe.directory /docs
```

- 添加`.gitignore`文件设置忽略项

```ini
index.html
generate-sidebar.js
_sidebar.md
_media
```

- 同步远程 Git 仓库到本地

```bash
git pull origin main
```


### 2. 根据目录自动生成 _sidebar.md 文件

```js
// dockerfile/generate-sidebar.js
const fs = require('fs');
const path = require('path');

// 脚本假设在 /docs 目录下运行
const docsDir = '.'; // 你的文档根目录，通常是当前目录
const sidebarFile = '_sidebar.md';
let sidebarContent = '';

// 排除列表
const excludeList = [
    '_sidebar.md',       // 排除侧边栏文件本身
    '_media',            // 排除媒体文件
    'index.html',        // 排除主页 HTML 文件
    '.git',              // 排除 .git 目录
    '.gitignore',        // 排除 .gitignore 目录
    'readme.md',         // 排除 readme.md 文件
    'git_listen',      // 排除 git_listen 文件夹
];

function buildSidebar(currentDir, level) {
  const items = fs.readdirSync(currentDir);

  // 对items进行排序，让侧边栏顺序更可控，例如按字母排序
  // 确保排序时不区分大小写，并处理中文等非英文字符（如果需要更复杂的排序）
  items.sort((a, b) => a.localeCompare(b, undefined, { sensitivity: 'base' }));


  items.forEach(item => {
    // 在处理前检查是否在排除列表中
    // 使用 path.basename 确保只比较文件名/目录名本身
    if (excludeList.includes(item) || item.startsWith('.')) {
        console.log(`Excluding: ${item}`); // 可选：打印排除项
        return; // 跳过当前循环迭代
    }

    const itemPath = path.join(currentDir, item);
    const stat = fs.statSync(itemPath);
    // 使用两个空格作为基本缩进，因为 docsify 对缩进要求可能不同
    const indent = '  '.repeat(level);

    if (stat.isDirectory()) {
      // 在目录名后添加斜杠以便清晰地表示目录
      sidebarContent += `${indent}* **${item}**\n`; // 可以加粗目录名

      // 递归处理子目录，层级加1
      buildSidebar(itemPath, level + 1);
    } else if (stat.isFile() && item.endsWith('.md')) {
      const fileNameWithoutExt = path.parse(item).name;
      // 排除 README.md 文件本身，如果需要链接它，应该在父级目录处特殊处理
       if (fileNameWithoutExt.toLowerCase() === 'readme') {
           console.log(`Excluding README.md file entry: ${item}`);
           return; // 跳过 README.md 的文件条目
       }

      const linkPath = path.relative(docsDir, itemPath).replace(/\\/g, '/'); // 确保路径使用正斜杠

      sidebarContent += `${indent}* [${fileNameWithoutExt}](${linkPath})\n`; // 使用原始文件名作为链接文本
    }
  });
}

// 从根目录（/docs，因为脚本会在那里运行）开始构建
buildSidebar(docsDir, 0);

// 在顶部添加一个指向根目录（README.md 或 index.html）的链接
// 这通常是 Docsify 侧边栏的第一项
sidebarContent = `* [首页](/)\n` + sidebarContent;


// 写入 _sidebar.md 文件
fs.writeFileSync(sidebarFile, sidebarContent);

console.log(`${sidebarFile} generated successfully.`);

```

### 3. 刷新 Docsify 页面

## 根据远程 Git 仓库提交自动更新本地 Docsify 项目（以 Gitea 为例)

1. 在挂载的项目路径下新建一个`git_listen`目录，在其中新建一个`listener.js`文件，内容如下：

```js
// dockerfile/listener.js (只包含监听和命令执行逻辑)
const express = require('express');
const bodyParser = require('body-parser');
const crypto = require('crypto');
const { exec } = require('child_process');

const app = express();

// --- 配置 ---
// 从环境变量读取配置，如果未设置则使用默认值
const PORT = process.env.WEBHOOK_PORT || 6159;
// !! IMPORTANT !!: 从环境变量读取密钥
const WEBHOOK_SECRET = process.env.WEBHOOK_SECRET;
// 当前容器内的文档目录，从环境变量读取或使用默认值
const DOCS_DIR_IN_CONTAINER = process.env.DOCS_DIR || '/docs';

// 从环境变量读取 Git 配置
const GIT_REMOTE = process.env.GIT_REMOTE || 'origin'; // 用于 git pull 命令
const GIT_BRANCH = process.env.GIT_BRANCH || 'main'; // 用于 git pull 和事件类型判断

// 检查是否设置了必需的环境变量
if (!WEBHOOK_SECRET) {
    console.error("错误: 必须设置 WEBHOOK_SECRET 环境变量。");
    // 在实际生产环境中，可能需要更优雅地处理或延迟启动
    // 为了脚本能立即运行，这里只警告，但 webhook 将无法验证
    // process.exit(1); // 如果密钥未设置就退出，但这样容器会停止
}
// GIT_REMOTE 和 GIT_BRANCH 如果未设置有默认值，GIT_REMOTE_URL 用于 entrypoint 中的 git remote add

// --- 中间件 ---
// 使用原始 body 以便进行签名验证
app.use(bodyParser.raw({ type: 'application/json' }));

// --- Webhook 处理路由 ---
app.post('/webhook', (req, res) => {
    console.log('接收到 Webhook 请求。');

    // 1. 验证签名 (Gitea 使用 x-gitea-signature)
    const signature = req.headers['x-gitea-signature'];
    if (!signature) {
        console.warn('接收到没有 x-gitea-signature 签名的 Webhook 请求。');
        return res.status(401).send('Signature required');
    }

    const payload = req.body;
    const hmac = crypto.createHmac('sha256', WEBHOOK_SECRET);
    hmac.update(payload);
    const digest = hmac.digest('hex');

    if (digest !== signature) {
        console.warn('无效的 Webhook 签名。');
        return res.status(401).send('Invalid signature');
    }

    console.log('Webhook 签名验证成功。');

    let payloadJson;
    try {
        payloadJson = JSON.parse(payload.toString());
    } catch (e) {
        console.error('解析 Webhook Payload JSON 失败：', e);
        return res.status(400).send('Invalid JSON payload');
    }

    // 2. 判断事件类型 (Gitea 使用 x-gitea-event)
    const eventType = req.headers['x-gitea-event'];
    console.log(`Webhook 事件类型: ${eventType}`);

    // 只处理 push 事件
    if (eventType === 'push') {
        // 判断是否是指定的分支
        // ref 的格式是 'refs/heads/分支名' 或 'refs/tags/标签名'
        const pushBranch = payloadJson.ref.split('/').pop(); // 从 'refs/heads/main' 中提取 'main'

        if (pushBranch !== GIT_BRANCH) {
            console.log(`Push 事件发生在分支 ${pushBranch}，但只监听分支 ${GIT_BRANCH}。忽略。`);
            return res.status(200).send(`Ignored event for branch '${pushBranch}'`);
        }

        console.log(`接收到分支 ${GIT_BRANCH} 的 Push 事件。`);

        // 3. 执行容器内部的命令：进入 docs 目录，拉取最新更改，然后运行 generate-sidebar.js
        console.log(`正在容器内部执行更新命令: cd ${DOCS_DIR_IN_CONTAINER} && git pull ${GIT_REMOTE} ${GIT_BRANCH} && node generate-sidebar.js`);

        // 构建在容器内部执行的命令序列
        // 注意：如果 generate-sidebar.js 不在 DOCS_DIR_IN_CONTAINER 根目录，需要调整路径
        const containerCommands = `cd ${DOCS_DIR_IN_CONTAINER} && git pull ${GIT_REMOTE} ${GIT_BRANCH} && node generate-sidebar.js`;

        exec(containerCommands, (error, stdout, stderr) => {
            if (error) {
                console.error(`执行命令失败： ${error.message}`);
                // 即使失败，也回复 500 以外的状态码，避免 Gitea 重试过多，但通常 500 是可以的
                return res.status(500).send('Failed to update docs');
            }
            if (stderr) {
                console.error(`命令的标准错误输出: ${stderr}`);
            }
            console.log(`命令的标准输出: ${stdout}`);

            const now = new Date();
            const timestamp = now.toLocaleString();
            console.log(`文档更新并侧边栏生成成功。完成时间: ${timestamp}`);

            res.status(200).send('Docs updated');
        });

    } else {
        // 忽略其他类型的事件
        console.log(`事件类型 '${eventType}' 已忽略。`);
        res.status(200).send(`事件类型 '${eventType}' 已忽略`);
    }
});

// --- 启动服务 ---
app.listen(PORT, () => {
    console.log(`Webhook 监听服务正在容器内部运行，端口号: ${PORT}`);
    console.log(`监听分支: ${GIT_BRANCH} 的 push 事件`);
    console.log(`Git 远程源名称: ${GIT_REMOTE}`); // 注意这里是远程源名称，不是 URL
    console.log(`文档目录: ${DOCS_DIR_IN_CONTAINER}`);
    // 注意：WEBHOOK_SECRET 不应该打印到日志，因为它是一个密钥
});
```

2. 设置`listener.js`的端口`PORT`、为 Gitea Webhook 设置的 Secret Token`WEBHOOK_SECRET`，`GIT_REMOTE`和`GIT_BRANCH`根据创建的 git 仓库填写

3. 进入 Gitea 仓库的设置 -> 点击`Web 钩子(Webhooks)` -> 添加 Web 钩子 -> 选择 `Gitea`

4. `目标 URL`设置为`http://192.168.1.100:6159/webhook`，`HTTP 方法`为`POST`，`密钥文本`填`WEBHOOK_SECRET`，`触发条件：`选择`所有事件`，点击`添加 Web 钩子`

5. 进入 Docsify 容器的终端 -> 进入目录`/docs/Gitea listen` -> 安装依赖`npm install express body-parser crypto` -> 运行监听服务`node listener.js`
