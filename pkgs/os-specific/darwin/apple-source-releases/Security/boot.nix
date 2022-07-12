{ appleDerivation', stdenv, darwin-stubs }:

appleDerivation' stdenv {
  phases = [ "unpackPhase" "patchPhase" "installPhase" ];

  __propagatedImpureHostDeps = [
    "/System/Library/Frameworks/Security.framework/Security"
    "/System/Library/Frameworks/Security.framework/Resources"
    "/System/Library/Frameworks/Security.framework/PlugIns"
    "/System/Library/Frameworks/Security.framework/XPCServices"
    "/System/Library/Frameworks/Security.framework/Versions"
  ];

  patches = [ ./0001-Correct-__PHONE_NA-macros-to-__IPHONE_NA.patch ];

  installPhase = ''
    mkdir -p $out/Library/Frameworks/Security.framework

    ###### IMPURITIES
    ln -s /System/Library/Frameworks/Security.framework/{Resources,Plugins,XPCServices} \
      $out/Library/Frameworks/Security.framework

    ###### STUBS
    cp ${darwin-stubs}/System/Library/Frameworks/Security.framework/Versions/A/Security.tbd \
      $out/Library/Frameworks/Security.framework

    ###### HEADERS

    export dest=$out/Library/Frameworks/Security.framework/Headers
    mkdir -p $dest

    cp OSX/libsecurity_asn1/lib/SecAsn1Coder.h     $dest
    cp OSX/libsecurity_asn1/lib/SecAsn1Templates.h $dest
    cp OSX/libsecurity_asn1/lib/SecAsn1Types.h     $dest
    cp OSX/libsecurity_asn1/lib/oidsalg.h          $dest
    cp OSX/libsecurity_asn1/lib/oidsattr.h         $dest

    cp OSX/libsecurity_authorization/lib/AuthSession.h         $dest
    cp OSX/libsecurity_authorization/lib/Authorization.h       $dest
    cp OSX/libsecurity_authorization/lib/AuthorizationDB.h     $dest
    cp OSX/libsecurity_authorization/lib/AuthorizationPlugin.h $dest
    cp OSX/libsecurity_authorization/lib/AuthorizationTags.h   $dest

    cp OSX/libsecurity_cms/lib/CMSDecoder.h $dest
    cp OSX/libsecurity_cms/lib/CMSEncoder.h $dest

    cp OSX/libsecurity_codesigning/lib/CSCommon.h       $dest
    cp OSX/libsecurity_codesigning/lib/CodeSigning.h    $dest
    cp OSX/libsecurity_codesigning/lib/SecCode.h        $dest
    cp OSX/libsecurity_codesigning/lib/SecCodeHost.h    $dest
    cp OSX/libsecurity_codesigning/lib/SecRequirement.h $dest
    cp OSX/libsecurity_codesigning/lib/SecStaticCode.h  $dest
    cp sectask/SecTask.h        $dest

    cp cssm/certextensions.h $dest
    cp OSX/libsecurity_cssm/lib/cssm.h           $dest
    cp OSX/libsecurity_cssm/lib/cssmaci.h        $dest
    cp OSX/libsecurity_cssm/lib/cssmapi.h        $dest
    cp cssm/cssmapple.h      $dest
    cp OSX/libsecurity_cssm/lib/cssmcli.h        $dest
    cp OSX/libsecurity_cssm/lib/cssmconfig.h     $dest
    cp OSX/libsecurity_cssm/lib/cssmcspi.h       $dest
    cp OSX/libsecurity_cssm/lib/cssmdli.h        $dest
    cp OSX/libsecurity_cssm/lib/cssmerr.h        $dest
    cp OSX/libsecurity_cssm/lib/cssmkrapi.h      $dest
    cp OSX/libsecurity_cssm/lib/cssmkrspi.h      $dest
    cp OSX/libsecurity_cssm/lib/cssmspi.h        $dest
    cp OSX/libsecurity_cssm/lib/cssmtpi.h        $dest
    cp OSX/libsecurity_cssm/lib/cssmtype.h       $dest
    cp OSX/libsecurity_cssm/lib/eisl.h           $dest
    cp OSX/libsecurity_cssm/lib/emmspi.h         $dest
    cp OSX/libsecurity_cssm/lib/emmtype.h        $dest
    cp OSX/libsecurity_cssm/lib/oidsbase.h       $dest
    cp OSX/libsecurity_cssm/lib/oidscert.h       $dest
    cp OSX/libsecurity_cssm/lib/oidscrl.h        $dest
    cp OSX/libsecurity_cssm/lib/x509defs.h       $dest

    cp OSX/libsecurity_keychain/lib/SecACL.h                $dest
    cp OSX/libsecurity_keychain/lib/SecAccess.h             $dest
    cp base/SecBase.h               $dest
    cp base/SecBasePriv.h           $dest
    cp trust/SecCertificate.h        $dest
    cp trust/SecCertificatePriv.h    $dest # Private
    cp OSX/libsecurity_keychain/lib/SecCertificateOIDs.h    $dest
    cp keychain/SecIdentity.h           $dest
    cp OSX/libsecurity_keychain/lib/SecIdentitySearch.h     $dest
    cp keychain/SecImportExport.h       $dest
    cp keychain/SecItem.h               $dest
    cp keychain/SecKey.h                $dest
    cp OSX/libsecurity_keychain/lib/SecKeychain.h           $dest
    cp OSX/libsecurity_keychain/lib/SecKeychainItem.h       $dest
    cp OSX/libsecurity_keychain/lib/SecKeychainSearch.h     $dest
    cp trust/SecPolicy.h             $dest
    cp OSX/libsecurity_keychain/lib/SecPolicySearch.h       $dest
    cp base/SecRandom.h             $dest
    cp trust/SecTrust.h              $dest
    cp trust/SecTrustSettings.h      $dest
    cp OSX/libsecurity_keychain/lib/SecTrustedApplication.h $dest
    cp base/Security.h             $dest
    cp keychain/SecAccessControl.h $dest
    cp trust/oids.h $dest

    cp OSX/libsecurity_manifest/lib/SecureDownload.h $dest

    cp OSX/libsecurity_mds/lib/mds.h        $dest
    cp OSX/libsecurity_mds/lib/mds_schema.h $dest

    cp OSX/libsecurity_ssl/lib/CipherSuite.h     $dest
    cp OSX/libsecurity_ssl/lib/SecureTransport.h $dest

    cp OSX/libsecurity_transform/lib/SecCustomTransform.h        $dest
    cp OSX/libsecurity_transform/lib/SecDecodeTransform.h        $dest
    cp OSX/libsecurity_transform/lib/SecDigestTransform.h        $dest
    cp OSX/libsecurity_transform/lib/SecEncodeTransform.h        $dest
    cp OSX/libsecurity_transform/lib/SecEncryptTransform.h       $dest
    cp OSX/libsecurity_transform/lib/SecReadTransform.h          $dest
    cp OSX/libsecurity_transform/lib/SecSignVerifyTransform.h    $dest
    cp OSX/libsecurity_transform/lib/SecTransform.h              $dest
    cp OSX/libsecurity_transform/lib/SecTransformReadTransform.h $dest

  '';
}
