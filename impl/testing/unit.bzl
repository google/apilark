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

"""Trivial test-case wrapper for creating Starlark unit-tests.

This allows `unit_test()` to be used with `suite.bzl`.
"""

load("@rules_testing//lib:analysis_test.bzl", "analysis_test")
load("//impl:visibility.bzl", "APILARK_VISIBILITY")
load(":misc.bzl", "function_name")
load(":testcase.bzl", "testcase")

visibility(APILARK_VISIBILITY)

def _unit_testcase(test_body_fn):
    return testcase.Info(
        name = function_name(test_body_fn),
        create_fn = lambda *, name, tags = None: analysis_test(
            name = name,
            target = "//impl/testing:_stub_target_for_unit_tests",
            impl = lambda env, _: test_body_fn(env),
            attr_values = {"tags": tags},
        ),
    )

unit = struct(
    testcase = _unit_testcase,
)
