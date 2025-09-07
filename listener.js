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
