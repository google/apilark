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

"""Helper function for copying and validating user-supplied `attrs` dicts."""

load("//impl:visibility.bzl", "APILARK_VISIBILITY")

visibility(APILARK_VISIBILITY)

def copy_and_validate_user_attrs(user_attrs):
    """Return a validated copy of a user-supplied `attrs` dict.

    This ensures the the user-supplied `attrs` dict is valid and does not
    contain any attributes with the reserved prefix `_apilark_*`.

    Args:
      user_attrs: The attributes to validate; may be `None`.

    Returns:
      A copy of `user_attrs` (or an empty dict if `user_attrs` is `None`).
    """
    if user_attrs == None:
        return {}
    elif type(user_attrs) != type({}):
        fail("Invalid `attrs`, must be a dict: %r" % (user_attrs,))

    result = dict(user_attrs)
    for attr in result:
        if attr.startswith("_apilark_"):
            fail("User attrs cannot be named `_apilark_*`: %r" % (user_attrs,))
    return result
