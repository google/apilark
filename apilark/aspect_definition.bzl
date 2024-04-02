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

"""Function to define a Starlark aspect's implementation using APIlark."""

load("//impl:aspect_info.bzl", "AspectDefinitionInfo")
load("//impl:impl_context.bzl", "impl_context")
load("//impl/util:access_token.bzl", "access_token")

visibility("public")

def apilark_aspect_definition(
        *,
        apis = None,
        attrs = None,
        implementation,
        token):
    """Define the Starlark implementation for an aspect with APILark.

    In APILark, an "API" is a Starlark `struct()` with a set of symbols (which
    can be functions, constants, other structs, etc) defined on it.

    In order to use APIs in the implementation of a Starlark aspect, the aspect must
    be defined as an "APILark Aspect", which requires it to be constructed in two
    separate parts:

    1.  `apilark_aspect_interface()`
    2.  `apilark_aspect_definition()` - This function

    This "definition" supplies the Starlark code, as well as any implicit deps
    that don't depend on the user-supplied values for the aspect.

    WARNING: The `token` *MUST* always be declared in a separate `.bzl` file
    from this definition, and *SHOULD* have restricted visibility; anyone with
    access to that "access token" can use `apilark_aspect_interface()` to bind
    their own interface to this aspect.

    IMPORTANT: The `implementation` function passed to this aspect isn't exactly
    like a normal Starlark aspect impl; it must take *THREE* arguments:

    1.  `implctx` - Like `ctx`, but comes from the `apilark_aspect_definition()`
        attributes (e.g. the ones passed to this function).
    2.  `target` - The normal `target` to be processed by this aspect instance.
    3.  `ctx` - The normal `ctx` for the user-created aspect.

    Args:
      apis: (dict) Used APIs, keyed by symbol name, e.g. `{"foo": "//my:api"}`.
      attrs: Internal attributes, only visible to the aspect implementation.
      implementation: Implementation function for this aspect (see above).
      token: Magic token created by `apilark_access_token.declare()`

    Returns:
      A `rule()` that wraps the implementation function and must be instantiated
      and referenced to by the corresponding `apilark_aspect_interface()` call.
    """
    if type(implementation) != "function":
        fail("The `implementation` must be a function; got a %s: %r" % (type(implementation), implementation))
    if not access_token.is_valid(token):
        fail("Invalid access token: %r" % (token,))

    merged_attrs, ImplContextInfo = impl_context.builder(attrs, apis)
    return rule(
        attrs = merged_attrs,
        provides = [AspectDefinitionInfo],
        implementation = lambda ctx: [AspectDefinitionInfo(
            implctx = ImplContextInfo(ctx),
            implfunc = implementation,
            token = token,
        )],
    )
