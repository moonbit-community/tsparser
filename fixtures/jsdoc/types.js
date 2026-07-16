/** @type {*} */
const allType = 0;

/** @type {?} */
const unknownType = 0;

/** @type {?Foo} */
const nullableType = 0;

/** @type {!Foo} */
const nonNullableType = 0;

/** @type {Foo?} */
const postfixNullableType = 0;

/** @type {Foo!} */
const postfixNonNullableType = 0;

/** @type {...string=} */
const variadicOptionalType = 0;

/** @type {function(string, this:Foo): number} */
const functionType = 0;

/** @type {module:foo/bar} */
const namepathType = 0;

/** @type {Array.<string>} */
const genericType = 0;
