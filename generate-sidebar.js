// dockerfile/generate-sidebar.js
const fs = require('fs');
const path = require('path');

// 脚本假设在项目根目录下运行，文档在 docs 目录中
const docsDir = './docs'; // 指向 docs 目录
const sidebarFile = './docs/_sidebar.md'; // 生成的侧边栏文件放在 docs 目录中
let sidebarContent = '';

// 排除列表
const excludeList = [
    '_sidebar.md',       // 排除侧边栏文件本身
    '.git',              // 排除 .git 目录
    '.gitignore',        // 排除 .gitignore 目录
];

// 提取文件名中的数字前缀
function extractNumberPrefix(filename) {
    const match = filename.match(/^(\d+)\./);
    return match ? parseInt(match[1], 10) : Infinity; // 如果没有数字前缀，返回无穷大，使其排在后面
}

function buildSidebar(currentDir, level) {
  const items = fs.readdirSync(currentDir);

  // 修改排序算法，先按数字前缀排序，再按字母顺序排序
  items.sort((a, b) => {
    const numA = extractNumberPrefix(a);
    const numB = extractNumberPrefix(b);
    
    if (numA !== numB) {
      return numA - numB; // 按数字排序
    }
    
    // 如果数字相同或都没有数字，按字母顺序排序
    return a.localeCompare(b, undefined, { sensitivity: 'base' });
  });

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
	  const displayFileName = fileNameWithoutExt.replace(/^(\d+\.)/, '$1 '); // 在数字前缀后添加空格
      sidebarContent += `${indent}* [${displayFileName}](${linkPath})\n`; // 使用原始文件名作为链接文本
    }
  });
}

// 从根目录（/docs，因为脚本会在那里运行）开始构建
buildSidebar(docsDir, 0);

// 在顶部添加一个指向根目录（README.md 或 index.html）的链接
// 这通常是 Docsify 侧边栏的第一项
sidebarContent = `* [首页](/docs/)\n` + sidebarContent;

// 写入 _sidebar.md 文件
fs.writeFileSync(sidebarFile, sidebarContent);

console.log(`${sidebarFile} generated successfully.`);
