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

"""Tests for //impl/testing:unit.bzl."""

load("@rules_testing//lib:analysis_test.bzl", "analysis_test", "test_suite")
load("//impl/testing:suite.bzl", "suite")
load("//impl/testing:unit.bzl", "unit")

def _test_example_unit_success(env):
    env.expect.that_str("foo").equals("foo")

def _test_example_unit_failure(env):
    env.expect.that_str("foo").equals("bar")

_example_suite = suite(
    unit.testcase(_test_example_unit_success),
    unit.testcase(_test_example_unit_failure),
)

def _expecting_test_result(want_success):
    def _impl(env, target):
        env.expect.that_target(target).has_provider(AnalysisTestResultInfo)
        if AnalysisTestResultInfo in target:
            env.expect.that_bool(target[AnalysisTestResultInfo].success).equals(want_success)

    return _impl

def _test_unit_success(name):
    analysis_test(
        name = name,
        target = "unit_test_demo__example_unit_success",
        impl = _expecting_test_result(True),
    )

def _test_unit_failure(name):
    analysis_test(
        name = name,
        target = "unit_test_demo__example_unit_failure",
        impl = _expecting_test_result(False),
    )

def unit_suite(name):
    test_suite(
        name = name,
        tests = [
            _test_unit_success,
            _test_unit_failure,
        ],
    )
    _example_suite(
        name = name + "_demo",
        tags = ["manual"],
    )
