# XFENetworkMonitor 执行约束

> 作用域：`Modules/XFENetworkMonitor/`。遵循上层 `Modules/AGENTS.md` 与根级 `AGENTS.md`。

## 必读文档
- 开始任务前先阅读：`Modules/XFENetworkMonitor/CLAUDE.md`。

## 模块边界（强制）
- 本模块只输出网络信号，不承载业务门禁/降级/重试策略。
- 业务策略在业务模块实现：`NetworkSnapshot` + `NetworkGatingPolicy` + `NetworkGatingProvider`。

## 依赖与生命周期（强制）
- 保持纯系统框架属性，不引入第三方依赖。
- 订阅生命周期与监控生命周期一致：`start()`/`stop()` 配对，释放订阅避免泄漏。

## 接口稳定性
- 对外保持连接类型、质量评估、变化事件三类基础能力，避免夹带业务字段。
