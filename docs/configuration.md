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
