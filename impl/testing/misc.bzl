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

"""Helpers for getting function and rule names."""

visibility("private")  # Not for use outside of `//impl/testing/...`

def function_name(func):
    """Returns the name of the given function; for better test feedback.

    Args:
      func: The function whose name should be returned.

    Returns:
      The name of the given function.
    """
    if type(func) != "function":
        fail("Expected a `function`, got `%s`: %r" % (type(func), func))

    # Starlark currently stringifies a function as "<function NAME from PATH>",
    # so we use that knowledge to parse the "NAME" portion out. If this behavior
    # ever changes, we'll need to update this.
    #
    # TODO(bazel-team): Expose a `.__name__` field on functions to avoid this.
    s = str(func)
    if not s.startswith("<function ") or not s.endswith(">") or not " from " in s:
        fail("Expected function `%r` to be stringified like `<function NAME from PATH>`" % (func,))
    return s.removeprefix("<function ").removesuffix(">").split(" from ", 1)[0]

def rule_name(rule_class):
    """Returns the name of the given rule class; for better test feedback.

    Args:
      rule_class: The `rule()` class whose name should be returned.

    Returns:
      The name of the given rule class.
    """
    if type(rule_class) != "rule":
        fail("Expected a `rule`, got `%s`: %r" % (type(rule_class), rule_class))

    # Starlark currently stringifies a rule as "<rule NAME>", so we use that
    # knowledge to parse the "NAME" portion out. If this behavior ever changes,
    # we'll need to update this.
    #
    # TODO(bazel-team): Expose a `rule().__name__` so we can avoid this.
    s = str(rule_class)
    if not s.startswith("<rule ") or not s.endswith(">"):
        fail("Expected rule `%r` to be stringified like `<rule NAME>`" % (rule_class,))
    return s.removeprefix("<rule ").removesuffix(">")
