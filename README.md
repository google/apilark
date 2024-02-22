# APILark - Starlark API Framework

The APILark framework supports the development of large Starlark rulesets for
various languages and platforms, by providing helper libraries that encourage
safe, efficient, and maintainable Starlark code.

## Quickstart

TODO: Populate this quickstart.

## Goals

1.  Strongly encourage the development of custom rules and aspects, instead of
    composing existing rules together with sprawling macros, because:

    1.  Macros must be evaluated entirely during the "loading" phase, which is
        much less parallel and often requires doing unnecessary work.
    2.  Macros cannot easily hide implementation details from their users; any
        rule created by a macro can be depended on by any user-defined rule in
        the same package.
    3.  Macros cannot take advantage of custom providers to share information
        with other rules or introspect individual outputs of a single rule.

2.  Provide tools for writing reusable Starlark APIs, so that it is simpler to
    create rulesets with various derivative rules using a single API than it is
    to create a single rule and wrap it with many different macros.

3.  Provide tools for testing Starlark APIs and custom rules, including tools to
    create API fakes and inject them into the code under test.
