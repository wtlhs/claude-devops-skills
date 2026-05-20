# claude-devops-skills

可复用的 Claude Code GitHub Flow 开发全流程自动化技能包。

## 目标

安装后自动获得以下能力：

- `/requirement`：需求分析并生成结构化需求文档
- `/task-split`：从需求文档拆分 GitHub Feature / Task Issues
- `/dev-pick`：认领 Issue 并创建开发分支
- `/dev-submit`：执行质量门禁并创建 PR
- `/pr-review`：按多维度审查 PR
- `/merge`：合并 PR 并清理分支
- `/release`：生成版本、CHANGELOG、Tag、GitHub Release
- `/rollback`：回滚版本
- `/lifecycle`：全流程编排
- `/deploy`：可选的多环境部署能力

## 设计原则

1. 默认零配置：优先自动检测项目结构和技术栈。
2. 配置可覆盖：通过 `.claude-devops.yml` 做精细化定制。
3. 项目优先：默认安装到目标项目的 `.claude/commands/`。
4. 保守覆盖：不强制覆盖已有模板、规则和命令。
5. 可迁移：可无缝迁移 `scm-bi-system` 现有命令体系。

## 目录结构

```text
claude-devops-skills/
├── commands/
├── templates/
├── rules/
├── lib/
├── docs/
├── install.sh
└── README.md
```

## 安装方式

### 方式 1：clone 后安装（当前推荐）

```bash
git clone https://github.com/wtlhs/claude-devops-skills.git
cd /path/to/project
/path/to/claude-devops-skills/install.sh
```

### 方式 3：全局安装命令模板

```bash
/path/to/claude-devops-skills/install.sh --global
```

- 该模式只安装通用命令到 `~/.claude/commands/`
- 不会为当前目录自动生成 `.claude-devops.yml`、GitHub 模板或规则文件
- 如果你还需要为某个项目做完整脚手架，请额外执行：

```bash
/path/to/claude-devops-skills/install.sh --target /path/to/project
```

> 说明：当前 `install.sh` 依赖同目录下的 `commands/`、`templates/`、`rules/`、`lib/` 资源文件，因此首版发布前暂不建议直接 `curl | bash`。如需支持该模式，后续会增加 bootstrap installer。

## 当前状态

首版将包含：

- 通用命令模板
- 安装脚本
- 自动检测脚本
- GitHub 模板脚手架
- 自动触发规则
- `scm-bi-system` 迁移方案文档
