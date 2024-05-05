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

"""Test helpers for expecting code to `fail()`."""

load("//impl:visibility.bzl", "APILARK_VISIBILITY")
load(":misc.bzl", "rule_name")
load(":testcase.bzl", "testcase")

visibility(APILARK_VISIBILITY)

def _failure_rule(*, body, error):
    if type(body) != "function":
        fail("Invalid test body function, got %s: %r" % (type(body), body))
    if type(error) != type(""):
        fail("Invalid expected error, got %s: %r" % (type(error), error))
    return rule(
        implementation = lambda ctx: [_ExpectedErrorInfo(body = body, error = error)],
    )

def _failure_testcase(testcase_rule):
    def _create(*, name, tags = None):
        info_name = "_%s_info" % (name,)
        runner_name = "_%s_runner" % (name,)
        testcase_rule(
            name = info_name,
            tags = ["manual"],
            visibility = ["//visibility:private"],
        )
        _runner(
            name = runner_name,
            info = info_name,
            tags = ["manual"],
            visibility = ["//visibility:private"],
        )
        testing.analysis_test(
            name = name,
            implementation = _testcase_impl,
            attrs = _EXPECTED_ERROR_TESTCASE_ATTRS,
            attr_values = {
                "info": info_name,
                "runner": runner_name,
                "tags": tags,
            },
        )

    return testcase.Info(
        name = rule_name(testcase_rule),
        create_fn = _create,
    )

failure = struct(
    rule = _failure_rule,
    testcase = _failure_testcase,
)

_ExpectedErrorInfo = provider(
    doc = "Internal metadata passed from `failure.rule()` to `_runner`.",
    fields = {
        "error": "The expected error string (from `fail`)",
        "body": "The function to invoke that is expected to raise an error",
    },
)

def _runner_impl(ctx):
    ctx.attr.info[_ExpectedErrorInfo].body()
    return []

_runner = rule(
    implementation = _runner_impl,
    attrs = {"info": attr.label(mandatory = True, providers = [[_ExpectedErrorInfo]])},
)

def _testcase_impl(ctx):
    expected = ctx.attr.info[_ExpectedErrorInfo].error

    # Make sure it didn't unexpectedly complete without an error.
    runner = ctx.attr.runner[0]  # TODO: Why is this a list?
    if AnalysisFailureInfo not in runner:
        return [AnalysisTestResultInfo(
            success = False,
            message = "Unexpected success! Should have failed with:\n" + expected,
        )]

    failures = runner[AnalysisFailureInfo].causes.to_list()
    if len(failures) != 1 or failures[0].label != runner.label:
        # NOTE: This should Never Happen(TM); it would require a transitive dep
        # of the `_runner` rule to fail analysis, but `_runner` has no deps that
        # the user of the test can control.
        return [AnalysisTestResultInfo(
            success = False,
            message = "Expected only failure of target `%s`; got:\n%s" % (
                runner.label,
                "\n".join(["*   " + str(cause.label) for cause in failures]),
            ),
        )]

    # Split into lines and remove the traceback (if any)
    lines = failures[0].message.strip("\n").split("\n")
    if lines[0].startswith("Traceback "):
        for i, line in enumerate(lines[1:]):
            if not line.startswith("\t"):
                lines = lines[i + 1:]
                break
    message = "\n".join(lines).removeprefix("Error in fail: ")

    if message != expected:
        return [AnalysisTestResultInfo(
            success = False,
            message = "Failed with wrong error:\nWANT: %r\nGOT: %r\n" % (expected, message),
        )]

    return [AnalysisTestResultInfo(success = True, message = "")]

_ALLOW_ANALYSIS_FAILURES = analysis_test_transition(settings = {
    "//command_line_option:allow_analysis_failures": "True",
})

_EXPECTED_ERROR_TESTCASE_ATTRS = {
    "info": attr.label(mandatory = True, providers = [[_ExpectedErrorInfo]]),
    "runner": attr.label(mandatory = True, cfg = _ALLOW_ANALYSIS_FAILURES),
}
