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

"""Rule implementation function provider struct for APIlark.

This provider is emitted by each `apilark_rule_definition()` rule to contain the
provided rule implementation function and context.
"""

load("//impl:visibility.bzl", "APILARK_VISIBILITY")

visibility(APILARK_VISIBILITY)

RuleDefinitionInfo = provider(
    doc = "Rule implementation using the APIlark framework",
    fields = {
        "implctx": "Context from the rule definition.",
        "implfunc": "Rule implementation function.",
        "token": "Access token that must be passed to use this impl.",
    },
)
