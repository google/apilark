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

"""Library for creating test-suites.

This is a replacement for the standard `test_suite()` rule in `@rules_testing`
that allows tests to supply a custom name for each created test.

Also, the names of each test-case are automatically prefixed by the name of the
test-suite as a whole, reducing the odds of conflicts.

Example:

```bzl
# In `my_test.bzl`:
load("//impl/testing:suite.bzl", "suite")
load("//impl/testing:unit.bzl", "unit")

my_test = suite(
    unit.test(_some_test),
    unit.test(_other_test),
)

# In `BUILD`:
load(":my_test.bzl", "my_test")
my_test(name = "my_test")
```
"""

load("//impl:visibility.bzl", "APILARK_VISIBILITY")
load(":testcase.bzl", "testcase")

visibility(APILARK_VISIBILITY)

# NOTE: This `unnamed-macro` is a false positive; `suite()` is not a macro
# itself but instead creates and *returns* a macro function.
#
def suite(*testcases):  # buildifier: disable=unnamed-macro
    """Creates a BUILD macro that instantiates a list of Starlark tests.

    Args:
      *testcases: Each argument must be a `TestCaseInfo` struct such as those
        returned by `unit.testcase()`, `analysis.testcase()`, etc.

    Returns:
      A BUILD macro that can be called with `name = ..` and other args to
      instantiate the test-suite.
    """
    for tc in testcases:
        if not testcase.is_valid(tc):
            fail("Invalid test-case: %r" % (tc,))

    def _suite(*, name, **test_kwargs):
        """Macro to instantiate this test-suite.

        Args:
          name: The name used as a prefix for all generated rules.
          **test_kwargs: Other arguments to pass to every test-case.
        """
        tests = []
        is_manual = "manual" in (test_kwargs.get("tags") or ())
        for tc in testcases:
            stripped_name = tc.name.lstrip("_").removeprefix("test_")
            test_name = "%s__%s" % (name, stripped_name)
            tests.append(test_name)
            tc.create_fn(
                name = test_name,
                **test_kwargs
            )
        native.test_suite(
            name = name,
            tests = tests,
            tags = ["manual"] if is_manual else [],
        )

    return _suite
