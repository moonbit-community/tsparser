# Parser 对齐官方 TypeScript Parser 计划

## 当前修复批次：2026-03-21

### 范围

修复这轮代码审查里已经确认、且可以最小复现的 4 个问题：

1. `.js/.mjs/.cjs` 输入里的 JSX 被误解析成 TS 类型断言。
2. 块注释里的 `import` / `export` 会把文件误判成 external module。
3. 模板字符串 `${...}` 内部的注释和 `@ts-*` 指令会在 `SourceFile.comments` / `comment_directives` 中丢失。
4. 正则字面量中的 `/*...*/` 会被误收集成真实块注释。

### 执行顺序

1. 先补定向回归测试，锁定上述 4 个 case。
2. 修 JSX 模式判定：
   - 让 JS-like 文件在兼容入口下按官方 parser 行为启用 JSX 解析。
   - 保持 `.ts` 输入仍优先按 TS 语法处理类型断言。
3. 修 external module 检测：
   - 不能再用按行字符串匹配的方式判断 `import` / `export`。
   - 必须跳过注释、字符串、模板字符串和正则字面量中的伪命中。
4. 修注释收集：
   - 模板字符串中要进入 `${...}` 扫描真实注释。
   - 正则字面量中不能把 `/*...*/` / `//...` 当作注释。
5. 完成后统一验证并检查导出接口是否有意外变化。

### 验证标准

- `moon check`
- 定向 `moon test ts59_alignment_test.mbt`
- 全量 `moon test`
- `moon info`
- `moon fmt`
- `pkg.generated.mbti` 只出现预期变化；若无 API 变化则应保持稳定

## 目标

把当前仓库从“诊断导向的简化 parser”推进到“更接近 `tsc` 官方 parser 的结构化 parser”。

重点不是一次性做完所有语法，而是先解决已经确认的高价值信息丢失问题：

1. JSX 被降级成字符串节点。
2. `as` / `satisfies` 不保留 AST。
3. 类型语法存在大量节点压扁。
4. decorator / class static block 不进 AST。
5. private identifier 没有独立词法和语法类别。
6. 注释 / JSDoc 完全丢失。

## 原则

- 先补 AST 表达能力，再补 parser 细节。
- 每一类语法先补最小可用表示，再补错误恢复和边角诊断。
- 每一步都配增量测试，避免只靠大批量 `tsfiles` 回归。
- 不强行一次性复刻 TS 全部内部结构，但要避免“语法接受了、信息丢了”。

## 阶段 0：建立基线

### 任务

- 增加一组定向回归测试，覆盖：
  - JSX element / fragment / attribute / child
  - `as`、`satisfies`、`as const`
  - template literal type
  - import type / import attributes
  - mapped type / infer type
  - decorator
  - class static block
  - private field / `#x in obj`
  - JSDoc comment
- 为这些 case 增加 AST 快照测试，而不只校验 errors。
- 记录当前行为，作为后续每阶段的 diff 基线。

### 验收标准

- 新增测试能稳定暴露当前的 AST 丢失点。
- 失败信息足够精确，能指导单项修复。

## 阶段 1：扩展 AST 表达能力

### 任务

- 扩展 `ExprKind`：
  - `As`
  - `Satisfies`
  - JSX 相关节点
- 扩展 `ClassMemberKind`：
  - `StaticBlock`
- 给类声明、类成员、顶层声明增加 decorator 存储位。
- 把“成员名”从裸 `String` 改成更明确的名字类型，至少区分：
  - 普通标识符
  - 字符串/数字名
  - computed name
  - private identifier
- 扩展 `TypeKind`，至少补齐：
  - `ImportType`
  - `MappedType`
  - `TemplateLiteralType`
  - `InferType`
  - `ConstructorType`
  - `ParenthesizedType`
- 为注释 / JSDoc 设计最小存储方案：
  - 先支持节点关联的原始 comment range
  - 再决定是否建独立 JSDoc AST

### 验收标准

- AST 类型定义已经能无损承载上述语法。
- 不再需要用 `String("<jsx>")`、`Ident("import(...)")`、`TypeOperator("infer", ...)` 这类占位表示真实语法。

## 阶段 2：词法层修复

### 任务

- 给 `#name` 引入独立 token，而不是 `Ident("#name")`。
- 评估 JSX 模式下 token 化策略，避免 JSX 依赖后续“整体吞掉”恢复。
- 为 comment / JSDoc 保留最小必要词法信息，而不是在 lexer 阶段完全跳过。

### 验收标准

- private identifier 在 parser 中可被正常区分。
- comment / JSDoc 信息在进入 parser 前未丢失。

## 阶段 3：表达式 parser 保真修复

### 任务

- 让 `as` / `satisfies` 构造真实 AST 节点。
- 保留 `as const` 的结构，而不是仅保留诊断。
- 把 JSX parser 改成真正构造树：
  - opening/self-closing
  - closing
  - fragment
  - text
  - expression child
  - attribute / spread attribute
- 校正 JSX 与泛型尖括号歧义路径，确保 AST 不被占位节点替代。

### 验收标准

- 表达式相关 AST 快照与预期结构一致。
- TSX case 不再只返回单个字符串节点。

## 阶段 4：类型 parser 保真修复

### 任务

- 补齐 template literal type 的结构节点。
- 把 import type 解析成独立类型节点，保留：
  - `typeof`
  - qualifier
  - type arguments
  - import attributes
- 把 `infer` 解析成独立节点，而不是字符串化或 type operator 化。
- 给 mapped type 建正式结构，保留：
  - readonly 修饰
  - `as` name remap
  - optional 修饰
  - member body
- 补 constructor type / parenthesized type。

### 验收标准

- 类型系统相关快照不再出现占位字符串或语义压扁。
- 关键用例能映射到接近官方 parser 的结构。

## 阶段 5：类与声明语法修复

### 任务

- decorator 挂到正确节点上，而不是只做诊断。
- class static block 进入 `members`。
- computed name / private name 在类成员和对象类型成员中保留结构。
- 检查 interface / type member 当前是否还存在额外压扁，继续拆分为更明确节点。

### 验收标准

- 类声明相关 AST 能完整表达现代 TS 类语法。

## 阶段 6：JSDoc 与注释

### 任务

- 先把 comment range 挂到节点。
- 再决定 JSDoc 的实现深度：
  - 最小方案：保留原始块注释文本
  - 完整方案：单独 JSDoc parser
- 至少支持后续工具能判断：
  - 节点上是否有 JSDoc
  - 原始文本范围在哪里

### 验收标准

- 注释和 JSDoc 不再在 lexer 阶段永久丢失。

## 阶段 7：API 与配置模型

### 任务

- 把当前依赖源码内 `detect_*` pragma 的模式判断，逐步改成显式 parse options。
- API 至少允许调用方传入：
  - `scriptKind`
  - `jsxMode`
  - `languageTarget`
  - `experimentalDecorators`
  - 是否解析 JSDoc
- 保留现有基于 pragma 的兼容入口，但降为包装层。

### 验收标准

- parser 行为主要由调用参数决定，而不是由源码注释隐式决定。

## 执行顺序建议

1. 阶段 0
2. 阶段 1
3. 阶段 2
4. 阶段 3
5. 阶段 4
6. 阶段 5
7. 阶段 6
8. 阶段 7

## 每阶段结束时的固定检查

- `moon check`
- 定向 `moon test`
- 必要时 `moon test --update`
- `moon info`
- `moon fmt`

## 第一批建议先做的最小里程碑

如果只做一轮高收益修复，建议范围控制在：

1. 建立 AST 快照测试。
2. 给 `as` / `satisfies` 建真实表达式节点。
3. 给 class static block 和 decorator 建 AST 表达。
4. 给 private identifier 建独立 token 和名字节点。
5. 停止把 JSX 降级成字符串。

这批完成后，当前 parser 的“可消费性”会先上一个台阶；再去补 import type / mapped type / template literal type，投入产出会更高。
