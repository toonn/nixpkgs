{ appleDerivation', stdenvNoCC, libplatform-10_12 }:

appleDerivation' stdenvNoCC {
  installPhase = ''
    mkdir $out
    cp -r include $out/include

    # Include headers Apple removed in 10.13 from 10.12 libplatform
    cp ${libplatform-10_12}/include/_simple.h \
      $out/include/_simple.h
    cp ${libplatform-10_12}/include/os/alloc_once_impl.h \
      $out/include/os/alloc_once_impl.h
    cp ${libplatform-10_12}/include/os/base_private.h \
      $out/include/os/base_private.h
    cp -r ${libplatform-10_12}/include/os/internal \
      $out/include/os/internal
    cp ${libplatform-10_12}/include/os/lock_private.h \
      $out/include/os/lock_private.h
    cp ${libplatform-10_12}/include/os/once_private.h \
      $out/include/os/once_private.h
    cp ${libplatform-10_12}/include/os/semaphore_private.h \
      $out/include/os/semaphore_private.h
    cp -r ${libplatform-10_12}/include/platform \
      $out/include/platform
  '';

  appleHeaders = ''
    _simple.h
    libkern/OSAtomic.h
    libkern/OSAtomicDeprecated.h
    libkern/OSAtomicQueue.h
    libkern/OSCacheControl.h
    libkern/OSSpinLockDeprecated.h
    os/alloc_once_impl.h
    os/base.h
    os/base_private.h
    os/internal/atomic.h
    os/internal/crashlog.h
    os/internal/internal_shared.h
    os/lock.h
    os/lock_private.h
    os/once_private.h
    os/semaphore_private.h
    platform/compat.h
    platform/introspection_private.h
    platform/string.h
    setjmp.h
    ucontext.h
  '';
}
