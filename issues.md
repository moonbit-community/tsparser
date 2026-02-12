

Consider the expression below:

```typescript
(...) => {}
```

This should result in a `TS1003`, but tsparser parses it as a valid arrow function with a single parameter `undefined`.

_________

Consider the expression below:

```typescript
(public foo) => {}
```

This should result in a `TS2369`, but tsparser just ignores the invalid `public` modifer. The same applies to `private`, `protected`, `readonly` and `export`. Also, similar neglection happens for parameter lists of function types:


```typescript
declare const foo: (public bar) => baz
```

_______

`Parser::parse_expression` returns a dummy result with `Parser::recover_expression` when an error is encountered, but the catched error is not collected.

_______

`undefined` is a valid type literal in typescript:

```typescript
declare const foo: undefined
```

However, tsparser would parse it as an `Ident("undefined")`.

_________

TypeScript distinguishes `yield*` from`yield`, the former used to "flatten" another iterator. However, tsparser silently ignores the asterisk and treats the two expressions the same.


_________

TypeScript element access expression should have exactly one argument, so the following is a `TS1011` error:

```typescript
foo[]
```

However, tsparser parses it as if it were `foo[undefined]`

_________

tsparser parses `` `${}` `` as `` `${undefined}` ``, but empty template interpolation should be rejected

_________

Consider the following function:

```typescript
function foo(...bar, baz) {}
```

The misplaced rest parameter causes a `TS1014`. However, tsparser does not check this case.

_________

In TypeScript, `new` or `abstract new` type specification must take the following form:

```typescript
[abstract] new (params...) => returns
```

in which the parameter list is parenthesized. However, in tsparser these two keywords are simply ignored

```typescript
type foo = abstract new bar // same as type foo = bar
```

_________

In TypeScript function types can have generic parameters:

```typescript
type foo = <T>(_: T) => T
```

However, tsparser just ignores them.

__________

Each entry in parameter lists of TypeScript function types consists of four parts: binding pattern, type annotation and (maybe) optional and rest annotations. However, in tsparser only type annotations are preserved. That is, from caller's perspective, the following function type

```typescript
type foo = (bar?: baz, ...daz: fred[]) => quux
```

has no difference from

```typescript
type foo = (_: baz, _: fred[]) => quux
```

_________

The type annotations in TypeScript function types are optional. When type annotation is omitted, tsparser implicitly inserts an `any`:

```typescript
type foo = (...baz) => daz // same as type foo = (...baz[]) => daz
```

Doing so fails in this case where the parameter is annotated with `...`. Its type should infers to be `any[]`.

_________

Consider the following expressions:

```typescript
1 1 4 5 1 4
```

This is invalid and causes a `TS1005` as TypeScript requires expression statements to be `;`-separated. tsparser does not reject this case.

____________

Consider the following expression:

```typescript
0.foo
```

This causes a `TS1351`, but tsparser parses it as a member access on number literal `0`.

__________

Consider the following type alias:

```typescript
type foo = typeof import("bar" baz)
```

The token `baz` is invalid here as an immediate `)` is expected. However, tsparser ignores this tokens and treat the type query as if it were `typeof import("bar")`.

___________

Consider the following declarations:

```typescript
const foo: number = 42
type bar = typeof foo[]
```

The `[]` here indicates an array type and `bar` evaluates to `number[]`. In other words, the type expressons is equivalent to `(typeof foo)[]`. However, tsparser neglects the `[]` as if it were mere `typeof foo`.

In addition, if the bracket pair contains a string, number, identifier or keyword, the content is appended to the argument of type query. For example, 

```typescript
const foo: number = 42
type bar = typeof foo[baz]
```

is not invalid TypeScript code. But tsparser returns something like `TypeQuery("foo[baz]")`.

___________

TypeScript type parameter modifers `in` and `out` are not allowed to appear in a function's type parameter list, so

```typescript
declare function foo<in T>(): T;
```

causes a `TS1274`, but tsparser does not signal any error here. Also, even if a modifier appears in a right place:

```typescript
class Bar<in T> {}
```

tsparser ignores this part of information and users cannot inspect if a modifer is present.

___________

```typescript
declare function foo<function, "bar", 114514>();
```

All these three type parameters here are invalid.

___________

Hard keywords (in contrast to soft or contextual keywords such as `abstract`) are those which can never be treated as identifiers. But tsparser parses the following code

```typescript
let let = let
``` 

without any error.