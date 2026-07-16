/// <reference path="a.ts" preserve="true" />
/// <reference types="node" resolution-mode="import" />
/// <reference types="bad" resolution-mode="invalid" />
/// <reference lib="es2025" />
/// <reference no-default-lib="true" />
/// <reference />
/// <amd-dependency path="dep-a" name="named" />
/// <amd-dependency path="dep-b" />
/// <amd-module name="first" />
/// <amd-module name="second" />
// @ts-check
// @ts-nocheck
/* @jsx h
 * @jsxfrag Fragment
 * @jsximportsource pkg
 * @jsxruntime automatic
 */
export const value = 1;
