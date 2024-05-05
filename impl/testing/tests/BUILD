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

"""Starlark tests for //impl/testing/*.bzl."""

load(":analysis_test.bzl", "analysis_suite")
load(":failure_test.bzl", "failure_suite")
load(":unit_test.bzl", "unit_suite")

analysis_suite(name = "analysis_test")

failure_suite(name = "failure_test")

unit_suite(name = "unit_test")

filegroup(
    name = "fake_target",
    srcs = [],
)
