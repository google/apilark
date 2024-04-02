# Copyright 2024 Google LLC
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

"""Declare global constants that can be used to restrict Starlark visibility.

APIlark rule defintions should typically only be bound to a single interface,
but both load-time and rule visibility are unusable for that purpose.

Therefore, this module provides a mechanism to define global "access token"
constants in `.bzl` files and pass them into `apilark_rule_definition()`s.

In order for an `apilark_rule_interface()` to successfully bind to a given rule
definition, it *must* pass exactly the same "access token".

Those access tokens should always be defined in a separate `.bzl` file whose
own load-time `visibility()` is restricted appropriately.

For example:

*   ```bzl
    # my_token.bzl
    load("@apilark//apilark:access_token.bzl", "apilark_access_token")
    visibility("private")
    MY_TOKEN = apilark_access_token.declare()
    ```

*   ```bzl
    # myrule_defn.bzl
    load("@apilark//apilark:rule_definition.bzl", "apilark_rule_definition")
    load(":my_token.bzl", "MY_TOKEN")
    apilark_rule_definition(
        access_token = MY_TOKEN,
        ...,
    )
    ```

*   ```bzl
    # myrule.bzl
    load("@apilark//apilark:rule_interface.bzl", "apilark_rule_interface")
    load(":my_token.bzl", "MY_TOKEN")
    apilark_rule_interface(
        access_token = MY_TOKEN,
        ...,
    )
    ```
"""

load("//impl/util:access_token.bzl", "access_token")

# This is public, usable from external libraries.
visibility("public")

def _apilark_access_token_declare(debug_name):
    """Define a new globally-unique access token.

    This token is distinct from all other access tokens ever created.

    IMPORTANT: The `debug_name` is for debugging purposes only and has no effect
    on the equality of this object.
    """
    return access_token.declare(debug_name)

apilark_access_token = struct(
    declare = _apilark_access_token_declare,
)
