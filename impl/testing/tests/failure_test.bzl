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

"""Tests for //impl/testing:failure.bzl."""

load("@rules_testing//lib:analysis_test.bzl", "analysis_test", "test_suite")
load("//impl/testing:failure.bzl", "failure")
load("//impl/testing:suite.bzl", "suite")

_test_example_failure_matches = failure.rule(
    error = "This is the song that never ends...",
    body = lambda: fail("This is the song that never ends..."),
)

_test_example_failure_mismatch = failure.rule(
    error = "This is the song that never ends...",
    body = lambda: fail("Whoops, wrong error!"),
)

_test_example_unexpected_success = failure.rule(
    error = "This error never occurs!",
    body = lambda: None,
)

_example_suite = suite(
    failure.testcase(_test_example_failure_matches),
    failure.testcase(_test_example_failure_mismatch),
    failure.testcase(_test_example_unexpected_success),
)

def _expecting_test_result(want):
    def _impl(env, target):
        env.expect.that_target(target).has_provider(AnalysisTestResultInfo)
        if AnalysisTestResultInfo in target:
            got = target[AnalysisTestResultInfo]
            if (got.success, got.message) != (want.success, want.message):
                env.fail(
                    "Wrong AnalysisTestResultInfo:\nWANT: (success=%r, message=%r)\nGOT: (success=%r, message=%r)\n" %
                    (want.success, want.message, got.success, got.message),
                )

    return _impl

def _test_failure_matches(name):
    analysis_test(
        name = name,
        target = "failure_test_demo__example_failure_matches",
        impl = _expecting_test_result(AnalysisTestResultInfo(
            success = True,
            message = "",
        )),
    )

def _test_failure_mismatch(name):
    analysis_test(
        name = name,
        target = "failure_test_demo__example_failure_mismatch",
        impl = _expecting_test_result(AnalysisTestResultInfo(
            success = False,
            message = "Failed with wrong error:\nWANT: \"This is the song that never ends...\"\nGOT: \"Whoops, wrong error!\"\n",
        )),
    )

def _test_unexpected_success(name):
    analysis_test(
        name = name,
        target = "failure_test_demo__example_unexpected_success",
        impl = _expecting_test_result(AnalysisTestResultInfo(
            success = False,
            message = "Unexpected success! Should have failed with:\nThis error never occurs!",
        )),
    )

def failure_suite(name):
    test_suite(
        name = name,
        tests = [
            _test_failure_matches,
            _test_failure_mismatch,
            _test_unexpected_success,
        ],
    )
    _example_suite(
        name = name + "_demo",
        tags = ["manual"],
    )
