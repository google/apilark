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

"""Tests for `//apilark:api.bzl`."""

load("@rules_testing//lib:truth.bzl", "subjects")
load("//apilark:api.bzl", "apilark_api", "apilark_api_struct")
load("//impl:api_info.bzl", "APIInfo")
load("//impl/testing:analysis.bzl", "analysis")
load("//impl/testing:failure.bzl", "failure")
load("//impl/testing:suite.bzl", "suite")

visibility("private")

_example_api_struct_1 = apilark_api_struct(foo = "foo", stuff = lambda x: "Stuff: %r" % (x,))
_example_api_struct_2 = apilark_api_struct(different = "things")
_example_api_transitive = apilark_api(
    deps = {
        "mydep": "//tests:api_test__apilark_api_transitive_dep1",
        "other": "//tests:api_test__apilark_api_transitive_dep2",
    },
    implementation = lambda implctx: struct(my_implctx = implctx),
)
_example_api_user_attrs = apilark_api(
    attrs = {
        "some_strings": attr.string_list(default = ["default"]),
        "_internal": attr.label(default = "//tests/api_testdata:internal_label"),
        "some_file_thing": attr.label(allow_single_file = True),
        "some_tool": attr.label(allow_single_file = True, executable = True, cfg = "exec"),
        "others": attr.label_list(allow_files = True),
    },
    implementation = lambda implctx: struct(my_implctx = implctx),
)

def _fmt_args(args, kwargs):
    parts = ["%r" % (arg,) for arg in args]
    for key, value in kwargs.items():
        parts.append("%s = %r" % (key, value))
    return ", ".join(parts)

def _callable_subject(ret_factory):
    def _subject(func_value, *, meta):
        def _called_with(*args, **kwargs):
            inner_meta = meta.derive("(%r)" % (_fmt_args(args, kwargs),))
            retval = func_value(*args, **kwargs)
            return ret_factory(retval, meta = inner_meta)

        return struct(called_with = _called_with)

    return _subject

def _test_apilark_api_struct_provider_1(*, name):
    _example_api_struct_1(name = name + "_api")

    def _impl(env, target):
        env.expect.that_target(target).has_provider(APIInfo)
        expect_api = env.expect.that_struct(
            target[APIInfo].api_struct,
            expr = "target[APIInfo].api_struct",
            attrs = {
                "foo": subjects.str,
                "stuff": _callable_subject(subjects.str),
            },
        )
        expect_api.foo().equals("foo")
        expect_api.stuff().called_with("some value!").equals('Stuff: "some value!"')

    analysis.test(
        name = name,
        target = name + "_api",
        impl = _impl,
    )

def _test_apilark_api_struct_provider_2(*, name):
    _example_api_struct_2(name = name + "_api")

    def _impl(env, target):
        env.expect.that_target(target).has_provider(APIInfo)
        expect_api = env.expect.that_struct(
            target[APIInfo].api_struct,
            expr = "target[APIInfo].api_struct",
            attrs = {"different": subjects.str},
        )
        expect_api.different().equals("things")

    analysis.test(
        name = name,
        target = name + "_api",
        impl = _impl,
    )

def _test_apilark_api_transitive(*, name):
    _example_api_struct_1(name = name + "_dep1")
    _example_api_struct_2(name = name + "_dep2")
    _example_api_transitive(name = name + "_api")

    def _impl(env, target):
        env.expect.that_target(target).has_provider(APIInfo)
        implctx = target[APIInfo].api_struct.my_implctx
        env.expect.that_bool(hasattr(implctx.api, "mydep")).equals(True)
        env.expect.that_bool(hasattr(implctx.api, "other")).equals(True)
        env.expect.that_str(implctx.api.mydep.foo).equals("foo")
        env.expect.that_str(implctx.api.other.different).equals("things")

    analysis.test(
        name = name,
        target = name + "_api",
        impl = _impl,
    )

def _test_apilark_api_user_attrs(*, name):
    _example_api_user_attrs(
        name = name + "_api",
        some_file_thing = "//tests/api_testdata:some_file.txt",
        some_tool = "//tests/api_testdata:some_tool",
        others = [
            "//tests/api_testdata:other_file.txt",
            "//tests/api_testdata:some_tool",
        ],
    )

    def _impl(env, target):
        env.expect.that_target(target).has_provider(APIInfo)
        implctx = target[APIInfo].api_struct.my_implctx

        env.expect.that_collection(implctx.attr.some_strings).contains_exactly(["default"])
        env.expect.that_target(implctx.attr._internal).label().equals(Label("//tests/api_testdata:internal_label"))
        env.expect.that_target(implctx.attr.some_file_thing).label().equals(Label("//tests/api_testdata:some_file.txt"))
        env.expect.that_target(implctx.attr.some_tool).label().equals(Label("//tests/api_testdata:some_tool"))
        expect_others = env.expect.that_collection(implctx.attr.others)
        expect_others.has_size(2)
        expect_others.offset(0, subjects.target).label().equals(Label("//tests/api_testdata:other_file.txt"))
        expect_others.offset(1, subjects.target).label().equals(Label("//tests/api_testdata:some_tool"))

        env.expect.that_file(implctx.file.some_file_thing).short_path_equals("tests/api_testdata/some_file.txt")
        env.expect.that_file(implctx.file.some_tool).short_path_equals("tests/api_testdata/toolthing.sh")

        env.expect.that_str(type(implctx.executable.some_tool)).equals("FilesToRunProvider")
        env.expect.that_file(implctx.executable.some_tool.executable).equals(implctx.file.some_tool)

    analysis.test(
        name = name,
        target = name + "_api",
        impl = _impl,
    )

_test_apilark_api_bad_implementation = failure.rule(
    error = "The `implementation` must be a function; got a int: 42",
    body = lambda: apilark_api(implementation = 42),
)

_test_apilark_api_bad_attrs_type = failure.rule(
    error = 'Invalid `attrs`, must be a dict: "Wrong type"',
    body = lambda: apilark_api(
        implementation = lambda _: None,
        attrs = "Wrong type",
    ),
)

_test_apilark_api_bad_attrs_reserved_prefix = failure.rule(
    error = 'User attrs cannot be named `_apilark_*`: {"_apilark_uses_reserved_prefix": None}',
    body = lambda: apilark_api(
        implementation = lambda _: None,
        attrs = {"_apilark_uses_reserved_prefix": None},
    ),
)

_test_apilark_api_bad_deps_conflict = failure.rule(
    error = "Multiple symbols for API `//fake:api`: `bar` vs `foo`",
    body = lambda: apilark_api(
        deps = {"foo": "//fake:api", "bar": "//fake:api"},
        implementation = lambda _: None,
    ),
)

api_test = suite(
    analysis.testcase(_test_apilark_api_struct_provider_1),
    analysis.testcase(_test_apilark_api_struct_provider_2),
    analysis.testcase(_test_apilark_api_transitive),
    analysis.testcase(_test_apilark_api_user_attrs),
    failure.testcase(_test_apilark_api_bad_implementation),
    failure.testcase(_test_apilark_api_bad_attrs_type),
    failure.testcase(_test_apilark_api_bad_attrs_reserved_prefix),
    failure.testcase(_test_apilark_api_bad_deps_conflict),
)
