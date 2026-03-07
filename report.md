# 代码审查报告（tsparser）

## 审查范围
- 代码阅读：`parser.mbt`、`lexer.mbt`、`error.mbt`、测试与基线相关文件
- 自动化验证：`moon check`、`moon test`、`moon coverage analyze`
- 结果概览：`moon test` 全部通过（`6506/6506`），但存在若干实现级问题与维护风险

## 主要发现（按严重级别排序）

### 2. 高：不可达代码诊断开关未实现（当前被硬编码禁用）
- 位置：
  - `parser.mbt:21570`（`detect_report_unreachable_code`）
  - `parser.mbt:10336`（不可达代码诊断触发点）
- 现象：
  - `detect_report_unreachable_code` 直接 `ignore(source); false`，导致 `report_unreachable_code` 永远为 `false`；
  - 解析器内部虽然有 `TS7027` 诊断逻辑，但永远不会触发。
- 风险：
  - 与 TypeScript harness 指令（如 `@allowUnreachableCode`）语义偏离；
  - 死代码路径长期不被覆盖，后续改动容易引入隐藏 bug。
- 建议：
  - 完整实现 `@allowUnreachableCode` / 相关配置解析；
  - 增加最小回归用例验证 `TS7027` 的 on/off 行为。

### 3. 中：JSX 自动检测存在误判，普通文本包含 `@jsx` 即开启 JSX 模式
- 位置：
  - `parser.mbt:21978`
  - `parser.mbt:21987`
- 现象：
  - `detect_jsx_mode` 对每行执行 `line.contains("@jsx")`；
  - 该匹配不限定为指令注释，字符串字面量/普通注释中出现 `@jsx` 也会误触发。
- 风险：
  - 非 JSX 代码被按 JSX 规则解析，产生非预期分支与诊断偏差。
- 建议：
  - 仅识别 harness 指令（例如 `// @jsx:`、`// @jsxFactory:`）或 `@Filename` 的后缀推断；
  - 避免对任意文本做子串触发。

### 4. 中：`parse_program` 与 `parse_program_with_jsx` 大段重复，维护成本高且易漂移
- 位置：
  - `parser.mbt:22637`
  - `parser.mbt:22785`
- 现象：
  - 两个入口函数主体几乎完全重复，仅 JSX 模式来源不同。
- 风险：
  - 修复一个分支后容易漏改另一个分支，形成行为不一致；
  - 提高回归概率与审查成本。
- 建议：
  - 抽取统一内部入口（例如 `parse_program_internal(source, jsx_mode_override?)`）；
  - 共享错误归一化、指令检测、tokenize 与 parser 初始化流程。

### 5. 低：多处“整文件重复扫描”放在解析流程中，存在性能与可读性负担
- 位置：
  - `parser.mbt:21444`（`detect_no_emit` 每次都 `split("\n")` 扫描）
  - `parser.mbt:7802`（解析过程中调用 `detect_no_emit(self.source_text)`）
  - `parser.mbt:21837` + `parser.mbt:6654`（模块指令多值检测同类问题）
- 现象：
  - 指令检测函数多次把 `source` 转字符串并按行扫描；
  - 个别检测在解析中途重复触发，不是仅在入口做一次。
- 风险：
  - 大文件下会放大常数开销；
  - 逻辑分散，增加定位复杂度。
- 建议：
  - 在入口阶段统一解析并缓存 directive 配置，Parser 持有结构化配置并复用。

### 6. 低：测试覆盖有盲区，关键分支未被触发
- 证据：
  - `moon coverage analyze` 报告：`Total: 921 uncovered line(s) in 3 file(s)`
  - 未覆盖示例：`error.mbt:32/34/36/38`，`lexer.mbt:117/171/174/...`，以及不可达代码分支 `parser.mbt:10340`
- 风险：
  - 关键错误分支（尤其恢复路径、边界词法路径）未来更易回归。
- 建议：
  - 为未覆盖分支补最小黑盒用例，优先覆盖诊断开关、lexer 边界路径与错误字符串渲染路径。

## 假设与待确认
- 本报告默认：项目目标是尽量贴近 TypeScript harness 指令语义。
- 若 `@pretty` 清空诊断是“刻意兼容某特定基线流程”，建议在 README 或注释中明确声明，否则对 API 使用者是高风险隐式行为。
