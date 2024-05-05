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

"""Internal dependency injection library for use by Starlark macros.

This makes it easy to test the APIlark macros by injecting a custom `fail()`
function and other dependencies, while ensuring that clients always use the
normal implementations.

Example usage:

```bzl
# File `impl/helpers.bzl`
load("//impl/util:inject.bzl", "inject")

MY_DEPS = inject.DeclaredDeps(
    debug_name = "//impl/helpers.bzl%MY_DEPS",
    params = ["fail", "warn"],
)

_DEFAULT_DEPS = inject.InjectedDeps(
    MY_DEPS,
    fail = fail,
    warn = lambda *x: print("WARNING: ", x),
)

def my_macro(*, name, arg1, arg2, injected_deps=_DEFAULT_DEPS):
    deps = MY_DEPS.get(injected_deps)
    if ...:
        deps.fail(...)
    else:
        deps.warn(...)
```
"""

load("//impl:visibility.bzl", "APILARK_VISIBILITY")
load(":access_token.bzl", "access_token")

visibility(APILARK_VISIBILITY)

_I_AM_THE_IMPL = access_token.declare("@apilark//impl:access_token.bzl%_I_AM_THE_IMPL")

def _declared_deps_info_init(*, debug_name, params):
    """Constructor for `inject.DeclaredDeps`.

    Args:
      debug_name: Human-readable string describing this set of declared dependencies.
      params: List of injected parameter names (as strings).

    Returns:
      Keys used internally to construct a `_DeclaredDepsInfo` struct.
    """
    if type(debug_name) != type(""):
        fail("Expected `str` for `debug_name`, got `%s`: %r" % (type(debug_name), debug_name))
    if type(params) != type([]) or any([type(p) != type("") for p in params]):
        fail("Expected `list[str]` for `params`, got `%s`: %r" % (type(params), params))
    identity = access_token.declare(debug_name)
    impl = _DepsImplInfo(
        identity = identity,
        params = {p: True for p in params},
    )
    return {
        "_impl": access_token.gated(_I_AM_THE_IMPL, lambda: impl),
        "get": lambda injected: _declared_deps_info_get(impl, injected),
    }

def _declared_deps_info_is_valid(arg):
    """Return True if `arg` is a valid instance of `_DeclaredDepsInfo`."""
    return (
        hasattr(arg, "_impl") and
        hasattr(arg, "get") and
        arg == _declared_deps_info_new(
            _impl = arg._impl,
            get = arg.get,
        )
    )

def _declared_deps_info_get(decl, injected):
    if not _injected_deps_info_is_valid(injected):
        fail("Invalid InjectedDepsInfo: %r" % (injected,))
    impl = injected._impl(_I_AM_THE_IMPL)
    if impl.decl.identity != decl.identity:
        fail("Supplied `InjectedDepsInfo` is for wrong `DeclaredDepsInfo`: %s vs %s" % (
            impl.decl.identity.debug_name,
            decl.identity.debug_name,
        ))
    return struct(**impl.args)

_DeclaredDepsInfo, _declared_deps_info_new = provider(
    doc = """Identifies a particular set of injectable deps.

    This provider is created with `inject.DeclaredDeps()` and describes a set of
    declared dependencies consumed by one or more APIs.

    From this provider, a caller can use `inject.InjectedDeps(...)` to create a
    specific instance of the declared deps, and `.get(injected_deps)` returns a
    struct with the deps named by this object (checking for errors).

    IMPORTANT: A caller cannot create a value that will be accepted by `.get()`
    unless they have visibility to this specific `DeclaredDepsInfo()` value.

    Args:
      debug_name: Human-readable string describing this set of declared dependencies.
      params: List of injected parameter names (as strings).
    """,
    init = _declared_deps_info_init,
    fields = {
        "_impl": "[PRIVATE] Return the `_DepsImplInfo` struct",
        "get": "Return a struct of arguments from a given `InjectedDepsInfo`",
    },
)

def _injected_deps_info_init(__deps, **kwargs):
    """Constructor for `inject.DeclaredDeps`.

    Args:
      __deps: The `inject.DeclaredDeps` object declaring the deps to inject.
      **kwargs: Set of dependencies to be injected, must match `params` from the
        supplied `__deps` object.

    Returns:
      Keys used internally to construct a `_DeclaredDepsInfo` struct.
    """
    if not _declared_deps_info_is_valid(__deps):
        fail("Invalid DeclaredDepsInfo: %r" % (__deps,))
    decl = __deps._impl(_I_AM_THE_IMPL)

    # First, validate the arguments:
    args = {}
    missing = {}
    for param_name in decl.params:
        if param_name not in kwargs:
            missing[param_name] = True
        else:
            args[param_name] = kwargs.pop(param_name)
    if missing or kwargs:
        fail(
            "Invalid injected deps!\nMissing: %r\nExtraneous: %r\n" %
            (missing.keys(), kwargs),
        )

    impl = _InjectedImplInfo(
        decl = decl,
        args = args,
    )
    return {"_impl": access_token.gated(_I_AM_THE_IMPL, lambda: impl)}

def _injected_deps_info_is_valid(arg):
    return (
        hasattr(arg, "_impl") and
        arg == _injected_deps_info_new(_impl = arg._impl)
    )

_InjectedDepsInfo, _injected_deps_info_new = provider(
    doc = """Concrete collection of injected dep values.

    Args:
      __deps: The `inject.DeclaredDeps` object declaring the deps to inject.
      **kwargs: Set of dependencies to be injected, must match `params` from the
        supplied `__deps` object.
    """,
    init = _injected_deps_info_init,
    fields = {
        "_impl": "[PRIVATE] Return the `_InjectedImplInfo` struct",
    },
)

inject = struct(
    DeclaredDeps = _DeclaredDepsInfo,
    InjectedDeps = _InjectedDepsInfo,
)

_DepsImplInfo = provider(
    doc = "Implementation data backing the `DeclaredDepsInfo` struct above.",
    fields = {
        "identity": "An `access_token` value uniquely identifying this object.",
        "params": "Set of required parameter names, as `{'param1': True, ...}`",
    },
)

_InjectedImplInfo = provider(
    doc = "Implementation data backing the `InjectedDepsInfo` struct above.",
    fields = {
        "decl": "Linked `_DepsImplInfo` identifying the parameters.",
        "args": "Dictionary of injected dependency values, by name.",
    },
)
