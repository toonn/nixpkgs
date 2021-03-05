#! /bin/sh

# This script generates the symbols lists found in
# `pkgs/os-specific/apple-source-releases/LibSystem/system_{c,kernel}_symbols`.

nm -j /usr/lib/system/libsystem_c.dylib >system_c_symbols
nm -j /usr/lib/system/libsystem_kernel.dylib >system_kernel_symbols
