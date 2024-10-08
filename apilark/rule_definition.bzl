# Copyright 2024 The APIlark Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Function to define a Starlark rule's implementation using APIlark."""

load("//impl:impl_context.bzl", "impl_context")
load("//impl:rule_info.bzl", "RuleDefinitionInfo")
load("//impl/util:access_token.bzl", "access_token")

visibility("public")

def apilark_rule_definition(
        *,
        apis = None,
        attrs = None,
        implementation,
        token):
    """Define the Starlark implementation for a rule with APILark.

    In APILark, an "API" is a Starlark `struct()` with a set of symbols (which
    can be functions, constants, other structs, etc) defined on it.

    In order to use APIs in the implementation of a Starlark rule, the rule must
    be defined as an "APILark Rule", which requires it to be constructed in two
    separate parts:

    1.  `apilark_rule_interface()`
    2.  `apilark_rule_definition()` - This rule

    This "definition" supplies the Starlark code, as well as any implicit deps
    that don't depend on the user-supplied values for the rule.

    WARNING: The `token` *MUST* always be declared in a separate `.bzl` file
    from this definition, and *SHOULD* have restricted visibility; anyone with
    access to that "access token" can use `apilark_rule_interface()` to bind
    their own interface to this rule.

    IMPORTANT: The `implementation` function passed to this rule isn't exactly
    like a normal Starlark rule impl; it must take *TWO* arguments:

    1.  `implctx` - Like `ctx`, but comes from the `apilark_rule_definition()`
        attributes (e.g. the ones passed to this function).
    2.  `ctx` - The normal `ctx` for the user-created rule.

    Args:
      apis: (dict) Used APIs, keyed by symbol name, e.g. `{"foo": "//my:api"}`.
      attrs: Internal attributes, only visible to the rule implementation.
      implementation: Implementation function for this rule (see above).
      token: Magic token created by `apilark_access_token.declare()`

    Returns:
      A `rule()` that wraps the implementation function and must be instantiated
      and referenced to by the corresponding `apilark_rule_interface()` call.
    """
    if type(implementation) != "function":
        fail("The `implementation` must be a function; got a %s: %r" % (type(implementation), implementation))
    if not access_token.is_valid(token):
        fail("Invalid access token: %r" % (token,))

    merged_attrs, implctx_factory = impl_context.builder(attrs, apis)
    return rule(
        attrs = merged_attrs,
        provides = [RuleDefinitionInfo],
        implementation = lambda ctx: [RuleDefinitionInfo(
            implctx = implctx_factory(ctx),
            implfunc = implementation,
            token = token,
        )],
    )
