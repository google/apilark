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

"""Simple struct for storing metadata about each test-case."""

visibility("private")  # Not for use outside of `//impl/testing/...`

_TestCaseInfo = provider(
    doc = "Metadata about an individual test-case.",
    fields = {
        "name": "(str) Name of this individual test-case",
        "create_fn": "(callable) Test creation function to invoke",
    },
)

def _testcase_is_valid(tc):
    return (
        hasattr(tc, "name") and
        hasattr(tc, "create_fn") and
        tc == _TestCaseInfo(
            name = tc.name,
            create_fn = tc.create_fn,
        )
    )

testcase = struct(
    Info = _TestCaseInfo,
    is_valid = _testcase_is_valid,
)
