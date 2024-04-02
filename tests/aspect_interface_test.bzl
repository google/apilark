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

"""Tests for `//apilark:aspect_interface.bzl`."""

load("@rules_testing//lib:truth.bzl", "matching")
load("//apilark:access_token.bzl", "apilark_access_token")
load("//apilark:api.bzl", "apilark_api_struct")
load("//apilark:aspect_definition.bzl", "apilark_aspect_definition")
load("//apilark:aspect_interface.bzl", "apilark_aspect_interface")
load("//impl/testing:analysis.bzl", "analysis")
load("//impl/testing:failure.bzl", "failure")
load("//impl/testing:suite.bzl", "suite")

visibility("private")

_FakeInfo = provider(
    doc = "Fake provider for testing",
    fields = ["arg", "silly"],
)

_TOKEN = apilark_access_token.declare("Fake Token")
_WRONG_TOKEN = apilark_access_token.declare("Fake Token")

def _aspect_wrapper_rule(wrapped_aspect):
    return rule(
        attrs = {
            "aspect_dep": attr.label(aspects = [wrapped_aspect]),
            # The aspects pick up these values from the calling rule.
            "arg": attr.string(),
            "sameattr": attr.int(),
        },
        implementation = lambda ctx: (
            ([ctx.attr.aspect_dep[_FakeInfo]] if _FakeInfo in ctx.attr.aspect_dep else []) +
            ([ctx.attr.aspect_dep[_SameAttrInfo]] if _SameAttrInfo in ctx.attr.aspect_dep else [])
        ),
    )

_example_api = apilark_api_struct(silly = 42)
_example_aspect_definition = apilark_aspect_definition(
    apis = {"demo": "//tests:aspect_interface_test_deps__example_api"},
    implementation = lambda implctx, target, ctx: [_FakeInfo(
        arg = ctx.attr.arg,
        silly = implctx.api.demo.silly,
    )],
    token = _TOKEN,
)
_example_aspect = apilark_aspect_interface(
    attrs = {"arg": attr.string(values = ["Got some stuff", "Other value"])},
    implementation = "//tests:aspect_interface_test_deps__example_aspect",
    provides = [_FakeInfo],
    token = _TOKEN,
)
_example_aspect_rule = _aspect_wrapper_rule(_example_aspect)
_example_aspect_with_wrong_token = apilark_aspect_interface(
    attrs = {"arg": attr.string(values = ["Got some stuff", "Other value"])},
    implementation = "//tests:aspect_interface_test_deps__example_aspect",
    provides = [_FakeInfo],
    token = _WRONG_TOKEN,
)
_example_aspect_with_wrong_token_rule = _aspect_wrapper_rule(_example_aspect_with_wrong_token)

_SameAttrInfo = provider(
    doc = "Fake provider for testing",
    fields = ["from_implctx", "from_ctx"],
)

_sameattr_aspect_definition = apilark_aspect_definition(
    attrs = {"sameattr": attr.string_list()},
    implementation = lambda implctx, target, ctx: [_SameAttrInfo(
        from_implctx = implctx.attr.sameattr,
        from_ctx = ctx.attr.sameattr,
    )],
    token = _TOKEN,
)
_sameattr_aspect = apilark_aspect_interface(
    attrs = {"sameattr": attr.int(values = [42, 99, 10203040, 99999999])},
    implementation = "//tests:aspect_interface_test_deps__sameattr_aspect",
    token = _TOKEN,
)
_sameattr_aspect_rule = _aspect_wrapper_rule(_sameattr_aspect)

def _test_apilark_aspect_interface_success(*, name):
    native.filegroup(name = name + "_aspect_dep")
    _example_aspect_rule(
        name = name + "_target",
        aspect_dep = name + "_aspect_dep",
        arg = "Got some stuff",
    )

    def _impl(env, target):
        env.expect.that_target(target).has_provider(_FakeInfo)
        env.expect.that_str(target[_FakeInfo].arg).equals("Got some stuff")
        env.expect.that_int(target[_FakeInfo].silly).equals(42)

    analysis.test(
        name = name,
        target = name + "_target",
        impl = _impl,
    )

def _test_apilark_aspect_interface_with_wrong_token(*, name):
    native.filegroup(name = name + "_aspect_dep")
    _example_aspect_with_wrong_token_rule(
        name = name + "_target",
        aspect_dep = name + "_aspect_dep",
        arg = "Got some stuff",
        tags = ["manual"],
    )

    def _impl(env, target):
        env.expect.that_target(target).failures().contains_predicate(
            matching.str_endswith('Aspect interface and definition have different `token`s: "Fake Token" vs "Fake Token"'),
        )

    analysis.test(
        name = name,
        expect_failure = True,
        target = name + "_target",
        impl = _impl,
    )

def _test_apilark_aspect_interface_same_attr_name(*, name):
    native.filegroup(name = name + "_aspect_dep")
    _sameattr_aspect_rule(
        name = name + "_target",
        aspect_dep = name + "_aspect_dep",
        sameattr = 10203040,
    )

    def _impl(env, target):
        env.expect.that_target(target).has_provider(_SameAttrInfo)
        env.expect.that_collection(target[_SameAttrInfo].from_implctx).contains_exactly([
            "This",
            "comes",
            "from",
            "aspect",
            "definition",
        ]).in_order()
        env.expect.that_int(target[_SameAttrInfo].from_ctx).equals(10203040)

    analysis.test(
        name = name,
        target = name + "_target",
        impl = _impl,
    )

_test_apilark_aspect_interface_bad_implementation = failure.rule(
    error = "The `implementation` must be a label; got int: 42",
    body = lambda: apilark_aspect_interface(implementation = 42, token = _TOKEN),
)

_test_apilark_aspect_interface_bad_attrs_type = failure.rule(
    error = 'Invalid `attrs`, must be a dict: "Wrong type"',
    body = lambda: apilark_aspect_interface(
        attrs = "Wrong type",
        implementation = "//some:label",
        token = _TOKEN,
    ),
)

_test_apilark_aspect_interface_bad_attrs_reserved_prefix = failure.rule(
    error = 'User attrs cannot be named `_apilark_*`: {"_apilark_uses_reserved_prefix": None}',
    body = lambda: apilark_aspect_interface(
        attrs = {"_apilark_uses_reserved_prefix": None},
        implementation = "//some:label",
        token = _TOKEN,
    ),
)

def aspect_interface_test_deps(*, name):
    """Create common dependencies for `aspect_interface_test` cases.

    Args:
      name: The name, must be `aspect_interface_test_deps`.
    """
    if name != "aspect_interface_test_deps":
        fail("Wrong name!")
    _example_api(name = "aspect_interface_test_deps__example_api")
    _example_aspect_definition(name = "aspect_interface_test_deps__example_aspect")
    _sameattr_aspect_definition(
        name = "aspect_interface_test_deps__sameattr_aspect",
        sameattr = ["This", "comes", "from", "aspect", "definition"],
    )

aspect_interface_test = suite(
    analysis.testcase(_test_apilark_aspect_interface_success),
    analysis.testcase(_test_apilark_aspect_interface_with_wrong_token),
    analysis.testcase(_test_apilark_aspect_interface_same_attr_name),
    failure.testcase(_test_apilark_aspect_interface_bad_implementation),
    failure.testcase(_test_apilark_aspect_interface_bad_attrs_type),
    failure.testcase(_test_apilark_aspect_interface_bad_attrs_reserved_prefix),
)
