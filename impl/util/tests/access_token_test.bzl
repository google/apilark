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

"""Tests for `//impl/util:access_token.bzl`."""

load("//impl/testing:failure.bzl", "failure")
load("//impl/testing:suite.bzl", "suite")
load("//impl/testing:unit.bzl", "unit")
load("//impl/util:access_token.bzl", "access_token")

visibility("private")

_TOKEN1 = access_token.declare("Arg")
_TOKEN2 = access_token.declare("Arg")
_TWO_TOKENS = [access_token.declare("Arg"), access_token.declare("Arg")]
_gated_demo = access_token.gated(_TOKEN1, lambda *args, **kwargs: 'Demo: args=%r, kwargs=%r' % (args, kwargs))

def _test_is_valid(env):
    env.expect.that_bool(access_token.is_valid(_TOKEN1)).equals(True)
    env.expect.that_bool(access_token.is_valid(_TOKEN2)).equals(True)
    env.expect.that_bool(access_token.is_valid(env)).equals(False)
    env.expect.that_bool(access_token.is_valid(env.ctx)).equals(False)
    env.expect.that_bool(access_token.is_valid(struct())).equals(False)
    env.expect.that_bool(access_token.is_valid(struct(_apilark_key = _TOKEN1._apilark_key, debug_name = "Arg"))).equals(False)
    env.expect.that_bool(access_token.is_valid(access_token.declare("Arg"))).equals(True)

def _test_equals(env):
    env.expect.that_bool(_TOKEN1 == _TOKEN1).equals(True)
    env.expect.that_bool(_TWO_TOKENS[0] == _TWO_TOKENS[0]).equals(True)
    env.expect.that_bool(_TWO_TOKENS[1] == _TWO_TOKENS[1]).equals(True)
    env.expect.that_bool(_TOKEN1 == _TOKEN2).equals(False)
    env.expect.that_bool(_TOKEN1 == access_token.declare("Arg")).equals(False)
    env.expect.that_bool(_TWO_TOKENS[0] == _TWO_TOKENS[1]).equals(False)
    env.expect.that_bool(_TWO_TOKENS[0] == access_token.declare("Arg")).equals(False)
    env.expect.that_bool(access_token.declare("Arg") == access_token.declare("Arg")).equals(False)

def _test_debug_name(env):
    env.expect.that_str(_TOKEN1.debug_name).equals("Arg")
    env.expect.that_str(access_token.declare("//foo:bar.bzl%TOKEN").debug_name).equals("//foo:bar.bzl%TOKEN")

_test_gated_invalid_token = failure.rule(
    error = "Invalid access token, got `int`: 42",
    body = lambda: access_token.gated(42, lambda: None),
)

_test_gated_invalid_func = failure.rule(
    error = "Invalid function, got `int`: 42",
    body = lambda: access_token.gated(_TOKEN1, 42),
)

_test_gated_call_invalid_token = failure.rule(
    error = 'First argument must be an access token, got `string`: "Woops!"',
    body = lambda: _gated_demo("Woops!"),
)

_test_gated_call_wrong_token_same_debug_name = failure.rule(
    error = 'Wrong access token; want: "Arg", got: "Arg"',
    body = lambda: _gated_demo(_TOKEN2),
)

_test_gated_call_wrong_token_different_debug_name = failure.rule(
    error = 'Wrong access token; want: "Arg", got: "Other name!"',
    body = lambda: _gated_demo(access_token.declare("Other name!")),
)

def _test_gated_call_works(env):
    env.expect.that_str(_gated_demo(_TOKEN1)).equals("Demo: args=(), kwargs={}")
    env.expect.that_str(_gated_demo(_TOKEN1, 1, "two", 3.0)).equals('Demo: args=(1, "two", 3.0), kwargs={}')
    env.expect.that_str(_gated_demo(_TOKEN1, foo="yo", bar=42)).equals('Demo: args=(), kwargs={"foo": "yo", "bar": 42}')
    env.expect.that_str(_gated_demo(_TOKEN1, 1, "two", 3.0, foo="yo", bar=42)).equals('Demo: args=(1, "two", 3.0), kwargs={"foo": "yo", "bar": 42}')

access_token_test = suite(
    unit.testcase(_test_is_valid),
    unit.testcase(_test_equals),
    unit.testcase(_test_debug_name),
    failure.testcase(_test_gated_invalid_token),
    failure.testcase(_test_gated_invalid_func),
    failure.testcase(_test_gated_call_invalid_token),
    failure.testcase(_test_gated_call_wrong_token_same_debug_name),
    failure.testcase(_test_gated_call_wrong_token_different_debug_name),
    unit.testcase(_test_gated_call_works),
)
