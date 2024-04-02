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

"""Function to declare a Starlark rule's public attributes using APIlark."""

load("//impl:rule_info.bzl", "RuleDefinitionInfo")
load("//impl:user_attrs.bzl", "copy_and_validate_user_attrs")
load("//impl/util:access_token.bzl", "access_token")

visibility("public")

def apilark_rule_interface(
        *,
        attrs = None,
        implementation,
        token,
        **kwargs):
    """Declare the public Starlark interface for a rule defined with APILark.

    In APILark, an "API" is a Starlark `struct()` with a set of symbols (which
    can be functions, constants, other structs, etc) defined on it.

    In order to use APIs in the implementation of a Starlark rule, the rule must
    be defined as an "APILark Rule", which requires it to be constructed in two
    separate parts:

    1.  `apilark_rule_interface()` - This rule
    2.  `apilark_rule_definition()`

    This "interface" defines the parameters and refers to the implementation
    indirectly, via a label.

    WARNING: The `token` *MUST* always be declared in a separate `.bzl` file
    from this interface, and *SHOULD* have restricted visibility; anyone with
    access to that "access token" can use `apilark_rule_interface()` to bind
    their own interface to the same implementation.

    Args:
      attrs: User-visible attributes to define on the rule's interface.
      implementation: BUILD label of the `apilark_rule_definition()`, or maybe
          of an `alias()` that `select()`s the right definition to use.
      token: Magic token created by `apilark_access_token.declare()`
      **kwargs: Other arguments to pass to the `rule()` function.

    Returns:
      A usable `rule()` with the given attributes and implementation.
    """
    if type(implementation) not in ("string", "Label"):
        fail("The `implementation` must be a label; got %s: %r" % (type(implementation), implementation))
    if not access_token.is_valid(token):
        fail("Invalid access token: %r" % (token,))
    attrs = copy_and_validate_user_attrs(attrs)
    attrs["_apilark_impl"] = attr.label(
        default = implementation,
        providers = [[RuleDefinitionInfo]],
    )

    def _impl(ctx):
        defn = ctx.attr._apilark_impl[RuleDefinitionInfo]
        if token != defn.token:
            fail("Rule interface and definition have different `token`s: %r vs %r" %
                 (token.debug_name, defn.token.debug_name))
        return defn.implfunc(defn.implctx, ctx)

    return rule(attrs = attrs, implementation = _impl, **kwargs)
