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

"""Tests for `//impl/util:inject.bzl`."""

load("//impl/testing:failure.bzl", "failure")
load("//impl/testing:suite.bzl", "suite")
load("//impl/testing:unit.bzl", "unit")
load("//impl/util:inject.bzl", "inject")

visibility("private")

_DECL1 = inject.DeclaredDeps(
    debug_name = "Some stuff",
    params = ["foo", "bar", "fail"],
)
_DECL2 = inject.DeclaredDeps(
    debug_name = "Other things",
    params = ["thing1", "thing2", "thing1"],
)
_DEFAULT1 = inject.InjectedDeps(
    _DECL1,
    bar = "bar default",
    fail = fail,
    foo = "default foo",
)
_DEFAULT2 = inject.InjectedDeps(
    _DECL2,
    thing1 = "some thing1",
    thing2 = "other thing2",
)

def _test_get_default1_works(env):
    want = struct(
        foo = "default foo",
        bar = "bar default",
        fail = fail,
    )
    got = _DECL1.get(_DEFAULT1)
    if got != want:
        env.fail("Wrong dict from `.get()`. want: %r, got: %r" % (want, got))

def _test_get_default2_works(env):
    want = struct(
        thing1 = "some thing1",
        thing2 = "other thing2",
    )
    got = _DECL2.get(_DEFAULT2)
    if got != want:
        env.fail("Wrong dict from `.get()`. want: %r, got: %r" % (want, got))

def _test_get_other_works(env):
    fake_fail = lambda *x: None
    injected_deps = inject.InjectedDeps(
        _DECL1,
        foo = "different",
        bar = "stuff",
        fail = fake_fail,
    )
    got = _DECL1.get(injected_deps)
    want = struct(
        foo = "different",
        bar = "stuff",
        fail = fake_fail,
    )
    if got != want:
        env.fail("Wrong dict from `.get()`. want: %r, got: %r" % (want, got))

_test_declare_bad_debug_name = failure.rule(
    error = "Expected `str` for `debug_name`, got `int`: 42",
    body = lambda: inject.DeclaredDeps(debug_name = 42, params = ["stuff"]),
)

_test_declare_bad_params_1 = failure.rule(
    error = "Expected `list[str]` for `params`, got `int`: 42",
    body = lambda: inject.DeclaredDeps(debug_name = "Some stuff", params = 42),
)

_test_declare_bad_params_2 = failure.rule(
    error = "Expected `list[str]` for `params`, got `list`: [42, None]",
    body = lambda: inject.DeclaredDeps(debug_name = "Some stuff", params = [42, None]),
)

_test_inject_bad_decl = failure.rule(
    error = "Invalid DeclaredDepsInfo: 42",
    body = lambda: inject.InjectedDeps(42, foo = "foo"),
)

_test_inject_missing_param = failure.rule(
    error = 'Invalid injected deps!\nMissing: ["thing2"]\nExtraneous: {}',
    body = lambda: inject.InjectedDeps(_DECL2, thing1 = "present"),
)

_test_inject_extra_param = failure.rule(
    error = 'Invalid injected deps!\nMissing: []\nExtraneous: {"extra": "woops"}',
    body = lambda: inject.InjectedDeps(_DECL2, thing1 = "yes", thing2 = "yes", extra = "woops"),
)

_test_inject_wrong_param = failure.rule(
    error = 'Invalid injected deps!\nMissing: ["thing2"]\nExtraneous: {"wrong2": 42}',
    body = lambda: inject.InjectedDeps(_DECL2, thing1 = "yes", wrong2 = 42),
)

_test_get_wrong_type_1 = failure.rule(
    error = "Invalid InjectedDepsInfo: 42",
    body = lambda: _DECL1.get(42),
)

_test_get_wrong_type_2 = failure.rule(
    error = "Invalid InjectedDepsInfo: struct(_impl = <function lambda from //impl/util/tests:inject_test.bzl>)",
    body = lambda: _DECL1.get(struct(_impl = lambda x: None)),
)

_test_get_wrong_deps_1 = failure.rule(
    error = "Supplied `InjectedDepsInfo` is for wrong `DeclaredDepsInfo`: Other things vs Some stuff",
    body = lambda: _DECL1.get(_DEFAULT2),
)

_test_get_wrong_deps_2 = failure.rule(
    error = "Supplied `InjectedDepsInfo` is for wrong `DeclaredDepsInfo`: Some stuff vs Other things",
    body = lambda: _DECL2.get(_DEFAULT1),
)

_test_get_wrong_deps_3 = failure.rule(
    error = "Supplied `InjectedDepsInfo` is for wrong `DeclaredDepsInfo`: Other things vs Some stuff",
    body = lambda: _DECL1.get(inject.InjectedDeps(_DECL2, thing1 = "foo", thing2 = "Bar")),
)

inject_test = suite(
    unit.testcase(_test_get_default1_works),
    unit.testcase(_test_get_default2_works),
    unit.testcase(_test_get_other_works),
    failure.testcase(_test_declare_bad_debug_name),
    failure.testcase(_test_declare_bad_params_1),
    failure.testcase(_test_declare_bad_params_2),
    failure.testcase(_test_inject_bad_decl),
    failure.testcase(_test_inject_missing_param),
    failure.testcase(_test_inject_extra_param),
    failure.testcase(_test_inject_wrong_param),
    failure.testcase(_test_get_wrong_type_1),
    failure.testcase(_test_get_wrong_type_2),
    failure.testcase(_test_get_wrong_deps_1),
    failure.testcase(_test_get_wrong_deps_2),
    failure.testcase(_test_get_wrong_deps_3),
)
