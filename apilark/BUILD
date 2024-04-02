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

"""Public interfaces for APIlark."""

load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(default_visibility = ["//visibility:public"])

bzl_library(
    name = "access_token",
    srcs = ["access_token.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "//impl/util:access_token",
    ],
)

bzl_library(
    name = "api",
    srcs = ["api.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "//impl:api_info",
        "//impl:impl_context",
    ],
)

bzl_library(
    name = "rule_definition",
    srcs = ["rule_definition.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "//impl:impl_context",
        "//impl:rule_info",
        "//impl/util:access_token",
    ],
)

bzl_library(
    name = "rule_interface",
    srcs = ["rule_interface.bzl"],
    visibility = ["//visibility:public"],
    deps = [
        "//impl:rule_info",
        "//impl:user_attrs",
        "//impl/util:access_token",
    ],
)
