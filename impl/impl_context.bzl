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

"""Internal helpers used by the APIlark library."""

load(":api_info.bzl", "APIInfo")
load(":user_attrs.bzl", "copy_and_validate_user_attrs")
load(":visibility.bzl", "APILARK_VISIBILITY")

visibility(APILARK_VISIBILITY)

def _impl_context_init(ctx, user_attr_names):
    """Create fields for an `implctx` struct from `ctx`."""
    res_api = {
        sym: dep[APIInfo].api_struct
        for dep, sym in ctx.attr._apilark_api_deps.items()
    }

    res_attr = {}
    res_executable = {}
    res_file = {}
    for attr_name in user_attr_names:
        res_attr[attr_name] = getattr(ctx.attr, attr_name)
        if hasattr(ctx.executable, attr_name):
            res_executable[attr_name] = getattr(ctx.attr, attr_name)[DefaultInfo].files_to_run
        if hasattr(ctx.file, attr_name):
            res_file[attr_name] = getattr(ctx.file, attr_name)

    return {
        "api": struct(**res_api),
        "attr": struct(**res_attr),
        "executable": struct(**res_executable),
        "file": struct(**res_file),
    }

_ImplContextInfo, _ = provider(
    doc = "The provider used to create `implctx` for rules and aspects.",
    init = _impl_context_init,
    fields = {
        "api": "API structs, accessed like `implctx.api.some_name`.",
        "attr": "Like `ctx.attr`.",
        "executable": "Like `ctx.executable`.",
        "file": "Like `ctx.file`.",
    },
)

def _impl_context_builder(user_attrs, apis):
    """Construct a "builder" struct for APIlark implementation providers.

    Args:
      user_attrs: Additional user-supplied `attrs` for `implctx`.
      apis: Dictionary of API dependencies, e.g.: `{'foo': '//some:api'}`

    Returns:
      A tuple `(attrs, implctx_factory)`, with the fields defined as:

      *   `attrs` - Dictionary to pass to `aspect()`, `rule()`, etc containing
          both the supplied `user_attrs` and the APIlark-internal attributes
          needed to construct the `implctx` object.

      *   `implctx_factory` - Function to create `implctx` from `ctx`.
    """
    attrs = copy_and_validate_user_attrs(user_attrs)
    user_attr_names = list(attrs)

    # Validate the `apis` dictionary and invert it into a set of API deps to be
    # added to the attributes as `_apilark_api_deps`:
    api_deps = {}
    for api_symbol, api_label in (apis or {}).items():
        if api_deps.setdefault(api_label, api_symbol) != api_symbol:
            fail("Multiple symbols for API `%s`: `%s` vs `%s`" %
                 (api_label, api_symbol, api_deps[api_label]))
    attrs["_apilark_api_deps"] = attr.label_keyed_string_dict(
        default = api_deps,
        providers = [APIInfo],
    )

    return (attrs, lambda ctx: _ImplContextInfo(ctx, user_attr_names))

impl_context = struct(
    builder = _impl_context_builder,
)
