# XFENetworkMonitor 约束

> 作用域：`Modules/XFENetworkMonitor/`。遵循上层 `Modules/AGENTS.md` 与根级 `AGENTS.md`。

## 必读文档
- 开始任何任务前先阅读：`Modules/XFENetworkMonitor/CLAUDE.md`

## 依赖与资源管理（强制）
- 保持“纯系统框架模块”属性：不引入第三方依赖。
- Combine 订阅与监控生命周期要对齐（start/stop、deinit 释放），避免泄漏与后台线程常驻。

