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

"""Tests for `//apilark:rule_interface.bzl`."""

load("@rules_testing//lib:truth.bzl", "matching")
load("//apilark:access_token.bzl", "apilark_access_token")
load("//apilark:api.bzl", "apilark_api_struct")
load("//apilark:rule_definition.bzl", "apilark_rule_definition")
load("//apilark:rule_interface.bzl", "apilark_rule_interface")
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

_example_api = apilark_api_struct(silly = 42)
_example_rule_definition = apilark_rule_definition(
    apis = {"demo": "//tests:rule_interface_test_deps__example_api"},
    implementation = lambda implctx, ctx: [_FakeInfo(
        arg = ctx.attr.arg,
        silly = implctx.api.demo.silly,
    )],
    token = _TOKEN,
)
_example_rule = apilark_rule_interface(
    attrs = {"arg": attr.string()},
    implementation = "//tests:rule_interface_test_deps__example_rule",
    token = _TOKEN,
)
_example_rule_with_wrong_token = apilark_rule_interface(
    attrs = {"arg": attr.string()},
    implementation = "//tests:rule_interface_test_deps__example_rule",
    token = _WRONG_TOKEN,
)

_SameAttrInfo = provider(
    doc = "Fake provider for testing",
    fields = ["from_implctx", "from_ctx"],
)

_sameattr_rule_definition = apilark_rule_definition(
    attrs = {"sameattr": attr.string_list()},
    implementation = lambda implctx, ctx: [_SameAttrInfo(
        from_implctx = implctx.attr.sameattr,
        from_ctx = ctx.attr.sameattr,
    )],
    token = _TOKEN,
)
_sameattr_rule = apilark_rule_interface(
    attrs = {"sameattr": attr.int()},
    implementation = "//tests:rule_interface_test_deps__sameattr_rule",
    token = _TOKEN,
)

def _test_apilark_rule_interface_success(*, name):
    _example_rule(
        name = name + "_target",
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

def _test_apilark_rule_interface_with_wrong_token(*, name):
    _example_rule_with_wrong_token(
        name = name + "_target",
        arg = "Got some stuff",
        tags = ["manual"],
    )

    def _impl(env, target):
        env.expect.that_target(target).failures().contains_predicate(
            matching.str_endswith('Rule interface and definition have different `token`s: "Fake Token" vs "Fake Token"'),
        )

    analysis.test(
        name = name,
        expect_failure = True,
        target = name + "_target",
        impl = _impl,
    )

def _test_apilark_rule_interface_same_attr_name(*, name):
    _sameattr_rule(
        name = name + "_target",
        sameattr = 10203040,
    )

    def _impl(env, target):
        env.expect.that_target(target).has_provider(_SameAttrInfo)
        env.expect.that_collection(target[_SameAttrInfo].from_implctx).contains_exactly([
            "This",
            "comes",
            "from",
            "rule",
            "definition",
        ]).in_order()
        env.expect.that_int(target[_SameAttrInfo].from_ctx).equals(10203040)

    analysis.test(
        name = name,
        target = name + "_target",
        impl = _impl,
    )

_test_apilark_rule_interface_bad_implementation = failure.rule(
    error = "The `implementation` must be a label; got int: 42",
    body = lambda: apilark_rule_interface(implementation = 42, token = _TOKEN),
)

_test_apilark_rule_interface_bad_attrs_type = failure.rule(
    error = 'Invalid `attrs`, must be a dict: "Wrong type"',
    body = lambda: apilark_rule_interface(
        attrs = "Wrong type",
        implementation = "//some:label",
        token = _TOKEN,
    ),
)

_test_apilark_rule_interface_bad_attrs_reserved_prefix = failure.rule(
    error = 'User attrs cannot be named `_apilark_*`: {"_apilark_uses_reserved_prefix": None}',
    body = lambda: apilark_rule_interface(
        attrs = {"_apilark_uses_reserved_prefix": None},
        implementation = "//some:label",
        token = _TOKEN,
    ),
)

def rule_interface_test_deps(*, name):
    """Create common dependencies for `rule_interface_test` cases.

    Args:
      name: The name, must be `rule_interface_test_deps`.
    """
    if name != "rule_interface_test_deps":
        fail("Wrong name!")
    _example_api(name = "rule_interface_test_deps__example_api")
    _example_rule_definition(name = "rule_interface_test_deps__example_rule")
    _sameattr_rule_definition(
        name = "rule_interface_test_deps__sameattr_rule",
        sameattr = ["This", "comes", "from", "rule", "definition"],
    )

rule_interface_test = suite(
    analysis.testcase(_test_apilark_rule_interface_success),
    analysis.testcase(_test_apilark_rule_interface_with_wrong_token),
    analysis.testcase(_test_apilark_rule_interface_same_attr_name),
    failure.testcase(_test_apilark_rule_interface_bad_implementation),
    failure.testcase(_test_apilark_rule_interface_bad_attrs_type),
    failure.testcase(_test_apilark_rule_interface_bad_attrs_reserved_prefix),
)
