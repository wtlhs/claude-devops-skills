# 配置说明

`.claude-devops.yml` 是本项目的核心配置文件。

## 关键配置块

- `project`：需求文档目录、模板目录
- `repository`：GitHub URL、默认分支、项目路径
- `stack`：技术栈、包管理器、质量门禁
- `scopes`：模块与标签映射
- `domain`：领域原则（可选）
- `labels`：GitHub 标签体系
- `review`：PR 审查维度
- `release`：版本与 changelog 配置
- `deploy`：部署模块（可选）

完整字段示例见：`templates/config-example.yml`

## 项目特化覆盖（Project Override）

通用安装器会同时考虑两类配置：

| 文件 | 是否提交到目标项目 | 用途 |
|------|---------------------|------|
| `.claude-devops.yml` | 推荐提交 | 合并后的最终配置，开发者拉代码后可直接用 |
| `.claude/claude-devops.project.yml` | 推荐提交 | 项目特化覆盖层，给安装器/升级流程合并用 |

工作流程：

1. 安装器先生成（或读取）项目根目录下的 `.claude-devops.yml`
2. 如果 `.claude/claude-devops.project.yml` 存在
3. 则按顶层字段（如 `domain`、`stack`、`scopes`、`review`、`deploy`）整段覆盖合并到 `.claude-devops.yml`

这样做的好处：

- 通用仓库不需要内置任何具体项目的业务信息
- 项目侧只需要维护一份 `claude-devops.project.yml`
- 后续升级或重装通用 skills 时不会丢失项目定制

### 推荐放置位置

- 通用合并行为：通用仓库提供
- 项目特化覆盖文件：放在目标项目自己的仓库中（如 `scm-bi-system/.claude/claude-devops.project.yml`）

### 注意

- 当前合并机制按顶层字段做整段替换，并不做深度合并
- 如果你需要更细粒度的覆盖，请在项目侧把完整字段块写入 override 文件
