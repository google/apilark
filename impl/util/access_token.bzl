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

"""Declare global constants that can be used to restrict Starlark visibility.

In certain circumstances, Starlark files may not be able to directly use the
standard Bazel `visibility` primitives, so this file provides a way to create
global constants with restricted bzl-visibility that can be used to control
access to other Starlark behaviors.

Typically, this works as follows:

1.  The callee defines an access token in a separate, restricted `.bzl` file:

    ```bzl
    # restricted.bzl
    load("//impl:access_token.bzl", "access_token")

    visibility("//some/private/package/..")

    TOKEN = access_token.declare("//path/to/restricted.bzl%TOKEN")
    ```

2.  The callee checks the token is provided by the client:

    ```bzl
    # stuff.bzl
    load(":restricted.bzl", "TOKEN")

    def do_stuff(*, token, ...):
        if token != TOKEN:
            fail("...")
        ...
    ```

3.  Optional: An intermediate caller can check if a token is a valid access
    token without checking for a specific token:

    ```bzl
    # proxy.bzl
    load("//impl:access_token.bzl", "access_token")

    def proxy(*, token, ...):
        if not access_token.is_valid(token):
            fail("...")
    ```
"""

load("//impl:visibility.bzl", "APILARK_VISIBILITY")

visibility(APILARK_VISIBILITY)

# Intentionally not exposed outside this file; callers should only use the
# function `access_token.declare()` to define their own access tokens.
_AccessTokenInfo = provider(
    doc = "Unique access token value returned by `access_token.declare()`",
    fields = {
        "_apilark_key": "Globally-unique Starlark object identifying this token",
        "debug_name": "Human-readable name supplied when creating this token.",
    },
)

def _access_token_declare(debug_name):
    """Define a new globally-unique access token.

    Returns:
      A new token that is distinct from all other access tokens ever created.

    Args:
      debug_name: Human-readable name for debugging purposes; has no effect on
        the equality of this access token.
    """
    # Lambdas with bound variables *cannot* have value equality because the
    # bound variables could change underneath them.
    #
    # Therefore, this is a globally-unique object to distinguish this token
    # from others.
    key = lambda: debug_name
    return _AccessTokenInfo(_apilark_key = key, debug_name = debug_name)

def _access_token_is_valid(token):
    """Returns `True` if `token` is an access token, `False` otherwise."""
    return (
        type(token) == type(_AccessTokenInfo()) and
        hasattr(token, "_apilark_key") and
        hasattr(token, "debug_name") and
        token == _AccessTokenInfo(
            _apilark_key = token._apilark_key,
            debug_name = token.debug_name,
        )
    )

def _access_token_gated(token, func):
    """Wrap a function to require that `token` be passed as the first argument.

    Args:
      token: The `_AccessTokenInfo` to require.
      func: The function to be wrapped.

    Returns:
      The wrapper around `func`

    Example:
      def _do_thing(arg1, arg2, *, kwarg): ...
      do_thing = access_token.gated(MY_TOKEN, _do_thing)
      do_thing(MY_TOKEN, arg1, arg2, kwarg=kwarg)  # Fails without `MY_TOKEN`
    """
    if not _access_token_is_valid(token):
        fail("Invalid access token, got `%s`: %r" % (type(token), token))
    if type(func) != "function":
        fail("Invalid function, got `%s`: %r" % (type(func), func))

    def wrapper(__token, *args, **kwargs):
        if __token == token:
            return func(*args, **kwargs)
        elif _access_token_is_valid(__token):
            fail("Wrong access token; want: %r, got: %r" % (token.debug_name, __token.debug_name))
        else:
            fail("First argument must be an access token, got `%s`: %r" % (type(__token), __token))

    return wrapper

access_token = struct(
    declare = _access_token_declare,
    gated = _access_token_gated,
    is_valid = _access_token_is_valid,
)
