

`Parser::parse_program` silently catches and then drops errors raised by `Parser::parse_stmt`. Thus users can only see tokenization errors.

_______

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