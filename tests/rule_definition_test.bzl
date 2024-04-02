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

"""Tests for `//apilark:rule_definition.bzl`."""

load("@rules_testing//lib:truth.bzl", "subjects")
load("//apilark:access_token.bzl", "apilark_access_token")
load("//apilark:api.bzl", "apilark_api_struct")
load("//apilark:rule_definition.bzl", "apilark_rule_definition")
load("//impl:rule_info.bzl", "RuleDefinitionInfo")
load("//impl/testing:analysis.bzl", "analysis")
load("//impl/testing:failure.bzl", "failure")
load("//impl/testing:more_subjects.bzl", "more_subjects")
load("//impl/testing:suite.bzl", "suite")

visibility("private")

_FakeInfo = provider(doc = "Fake provider for testing", fields = {})

_TOKEN = apilark_access_token.declare("Fake Token")

_example_api = apilark_api_struct(silly = 42)
_example_rule_simple = apilark_rule_definition(
    apis = {"demo": "//tests:rule_definition_test__apilark_rule_definition_simple_api"},
    implementation = lambda implctx, ctx: [_FakeInfo()],
    token = _TOKEN,
)
_example_rule_user_attrs = apilark_rule_definition(
    attrs = {
        "some_strings": attr.string_list(default = ["default"]),
        "_internal": attr.label(default = "//tests/rule_definition_testdata:internal_label"),
        "some_file_thing": attr.label(allow_single_file = True),
        "some_tool": attr.label(allow_single_file = True, executable = True, cfg = "exec"),
        "others": attr.label_list(allow_files = True),
    },
    implementation = lambda implctx, ctx: [_FakeInfo()],
    token = _TOKEN,
)

def _test_apilark_rule_definition_simple(*, name):
    _example_api(name = name + "_api")
    _example_rule_simple(name = name + "_rule")

    def _impl(env, target):
        env.expect.that_target(target).has_provider(RuleDefinitionInfo)
        env.expect.that_int(target[RuleDefinitionInfo].implctx.api.demo.silly).equals(42)
        env.expect.that_value(
            target[RuleDefinitionInfo].implfunc,
            factory = more_subjects.callable(subjects.collection),
        ).called_with(None, None).contains_exactly([_FakeInfo()])
        env.expect.that_bool(target[RuleDefinitionInfo].token == _TOKEN).equals(True)

    analysis.test(
        name = name,
        target = name + "_rule",
        impl = _impl,
    )

def _test_apilark_rule_definition_user_attrs(*, name):
    _example_rule_user_attrs(
        name = name + "_rule",
        some_file_thing = "//tests/rule_definition_testdata:some_file.txt",
        some_tool = "//tests/rule_definition_testdata:some_tool",
        others = [
            "//tests/rule_definition_testdata:other_file.txt",
            "//tests/rule_definition_testdata:some_tool",
        ],
    )

    def _impl(env, target):
        env.expect.that_target(target).has_provider(RuleDefinitionInfo)
        implctx = target[RuleDefinitionInfo].implctx

        env.expect.that_collection(implctx.attr.some_strings).contains_exactly(["default"])
        env.expect.that_target(implctx.attr._internal).label().equals(Label("//tests/rule_definition_testdata:internal_label"))
        env.expect.that_target(implctx.attr.some_file_thing).label().equals(Label("//tests/rule_definition_testdata:some_file.txt"))
        env.expect.that_target(implctx.attr.some_tool).label().equals(Label("//tests/rule_definition_testdata:some_tool"))
        expect_others = env.expect.that_collection(implctx.attr.others)
        expect_others.has_size(2)
        expect_others.offset(0, subjects.target).label().equals(Label("//tests/rule_definition_testdata:other_file.txt"))
        expect_others.offset(1, subjects.target).label().equals(Label("//tests/rule_definition_testdata:some_tool"))

        env.expect.that_file(implctx.file.some_file_thing).short_path_equals("tests/rule_definition_testdata/some_file.txt")
        env.expect.that_file(implctx.file.some_tool).short_path_equals("tests/rule_definition_testdata/toolthing.sh")

        env.expect.that_str(type(implctx.executable.some_tool)).equals("FilesToRunProvider")
        env.expect.that_file(implctx.executable.some_tool.executable).equals(implctx.file.some_tool)

        env.expect.that_value(
            target[RuleDefinitionInfo].implfunc,
            factory = more_subjects.callable(subjects.collection),
        ).called_with(None, None).contains_exactly([_FakeInfo()])

    analysis.test(
        name = name,
        target = name + "_rule",
        impl = _impl,
    )

_test_apilark_rule_definition_bad_implementation = failure.rule(
    error = "The `implementation` must be a function; got a int: 42",
    body = lambda: apilark_rule_definition(implementation = 42, token = _TOKEN),
)

_test_apilark_rule_definition_bad_apis_conflict = failure.rule(
    error = "Multiple symbols for API `//fake:api`: `bar` vs `foo`",
    body = lambda: apilark_rule_definition(
        apis = {"foo": "//fake:api", "bar": "//fake:api"},
        implementation = lambda implctx, ctx: None,
        token = _TOKEN,
    ),
)

_test_apilark_rule_definition_bad_attrs_type = failure.rule(
    error = 'Invalid `attrs`, must be a dict: "Wrong type"',
    body = lambda: apilark_rule_definition(
        attrs = "Wrong type",
        implementation = lambda implctx, ctx: None,
        token = _TOKEN,
    ),
)

_test_apilark_rule_definition_bad_attrs_reserved_prefix = failure.rule(
    error = 'User attrs cannot be named `_apilark_*`: {"_apilark_uses_reserved_prefix": None}',
    body = lambda: apilark_rule_definition(
        attrs = {"_apilark_uses_reserved_prefix": None},
        implementation = lambda implctx, ctx: None,
        token = _TOKEN,
    ),
)

rule_definition_test = suite(
    analysis.testcase(_test_apilark_rule_definition_simple),
    analysis.testcase(_test_apilark_rule_definition_user_attrs),
    failure.testcase(_test_apilark_rule_definition_bad_implementation),
    failure.testcase(_test_apilark_rule_definition_bad_apis_conflict),
    failure.testcase(_test_apilark_rule_definition_bad_attrs_type),
    failure.testcase(_test_apilark_rule_definition_bad_attrs_reserved_prefix),
)
