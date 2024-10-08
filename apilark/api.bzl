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

"""Functions to define APIlark API rules.

Example:

*   ```bzl
    # my_api/BUILD
    load(":my_api.bzl", "my_api")

    my_api(name = "my_api")
    ```

*   ```bzl
    # my_api/my_api.bzl
    load("@apilark//apilark:api.bzl", "apilark_api_struct")

    visibility("private")

    def _do_thing(...): ...

    my_api = apilark_api_struct(
        do_thing = do_thing,
    )
    ```
"""

load("//impl:api_info.bzl", "APIInfo")
load("//impl:impl_context.bzl", "impl_context")

visibility("public")

def apilark_api_struct(**fields):
    """Define an APIlark API rule consisting of a set of static struct fields.

    Args:
      **fields: The fields of the API struct to be returned by the API rule

    Returns:
      A `rule()` that can be invoked to define this API.
    """
    api_struct = struct(**fields)
    return rule(implementation = lambda ctx: [APIInfo(api_struct = api_struct)])

def apilark_api(*, implementation, attrs = None, deps = None):
    """Define an APIlark API whose struct is created by a function.

    Args:
      implementation: The rule implementation function, with one `implctx` arg.
      attrs: (dict) Attributes to pass to the `rule()`.
      deps: (dict) APIs depended on by this API, as `{'key': '//some:label'}`.

    Returns:
      A `rule()` that can be invoked to define this API.
    """
    if type(implementation) != "function":
        fail("The `implementation` must be a function; got a %s: %r" % (type(implementation), implementation))

    # Expand the list of `attrs` and create a custom `implctx_factory` function:
    merged_attrs, implctx_factory = impl_context.builder(attrs, deps)
    return rule(
        attrs = merged_attrs,
        implementation = lambda ctx: [
            # The `implementation` should be a function; call it!
            APIInfo(api_struct = implementation(implctx_factory(ctx))),
        ],
    )
