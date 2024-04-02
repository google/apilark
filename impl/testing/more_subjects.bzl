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

"""Custom Truth subjects for use within the APIlark codebase."""

load("//impl:visibility.bzl", "APILARK_VISIBILITY")

visibility(APILARK_VISIBILITY)

def _more_subjects_callable(ret_factory):
    """Truth subject for asserting on a function.

    Example usage:

    ```bzl
    return_str_subject = more_subjects.callable(subjects.str)
    c = env.expect.that_value(some_func, factory=return_str_subject)
    c.called_with("foo", "bar", baz=42, quux=1234).equals("result")
    ```

    Args:
      ret_factory: The subject factory to use for the return value.

    Returns:
      Truth subject factory for asserting about a callable.
    """

    def _subject(func_value, *, meta):
        def _called_with(*args, **kwargs):
            inner_meta = meta.derive("(%s)" % (_fmt_args(args, kwargs),))
            retval = func_value(*args, **kwargs)
            return ret_factory(retval, meta = inner_meta)

        return struct(called_with = _called_with)

    return _subject

def _fmt_args(args, kwargs):
    parts = ["%r" % (arg,) for arg in args]
    for key, value in kwargs.items():
        parts.append("%s = %r" % (key, value))
    return ", ".join(parts)

more_subjects = struct(
    callable = _more_subjects_callable,
)
