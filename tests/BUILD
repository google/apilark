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

"""Tests for `//apilark:*.bzl`."""

load(":api_test.bzl", "api_test")
load(":aspect_definition_test.bzl", "aspect_definition_test")
load(":aspect_interface_test.bzl", "aspect_interface_test", "aspect_interface_test_deps")
load(":rule_definition_test.bzl", "rule_definition_test")
load(":rule_interface_test.bzl", "rule_interface_test", "rule_interface_test_deps")

api_test(name = "api_test")

aspect_definition_test(name = "aspect_definition_test")

aspect_interface_test(name = "aspect_interface_test")

aspect_interface_test_deps(name = "aspect_interface_test_deps")

rule_definition_test(name = "rule_definition_test")

rule_interface_test(name = "rule_interface_test")

rule_interface_test_deps(name = "rule_interface_test_deps")
