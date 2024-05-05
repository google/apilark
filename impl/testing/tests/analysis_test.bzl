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

"""Tests for //impl/testing:analysis.bzl."""

load("@rules_testing//lib:analysis_test.bzl", "analysis_test", "test_suite")
load("//impl/testing:analysis.bzl", "analysis")
load("//impl/testing:suite.bzl", "suite")

def _test_example_analysis_success(*, name, blarg, tags):
    def _impl(env, target):
        env.expect.that_target(target).label().equals(Label(":fake_target"))
        env.expect.that_str(env.ctx.attr.blarg).equals("expected value")

    analysis.test(
        name = name,
        target = ":fake_target",
        impl = _impl,
        attrs = {"blarg": attr.string()},
        attr_values = {"blarg": blarg, "tags": tags},
    )

def _test_example_analysis_failure(*, name, blarg, tags):
    _ = blarg  # @unused

    def _impl(env, target):
        _ = target  # @unused
        env.fail("This test intentionally fails")

    analysis.test(
        name = name,
        target = ":fake_target",
        impl = _impl,
        attr_values = {"tags": tags},
    )

_example_suite = suite(
    analysis.testcase(_test_example_analysis_success),
    analysis.testcase(_test_example_analysis_failure),
)

def _expecting_test_result(want_success):
    def _impl(env, target):
        env.expect.that_target(target).has_provider(AnalysisTestResultInfo)
        if AnalysisTestResultInfo in target:
            env.expect.that_bool(target[AnalysisTestResultInfo].success).equals(want_success)

    return _impl

def _test_analysis_success(name):
    analysis_test(
        name = name,
        target = "analysis_test_demo__example_analysis_success",
        impl = _expecting_test_result(True),
    )

def _test_analysis_failure(name):
    analysis_test(
        name = name,
        target = "analysis_test_demo__example_analysis_failure",
        impl = _expecting_test_result(False),
    )

def analysis_suite(name):
    test_suite(
        name = name,
        tests = [
            _test_analysis_success,
            _test_analysis_failure,
        ],
    )
    _example_suite(
        name = name + "_demo",
        blarg = "expected value",
        tags = ["manual"],
    )
