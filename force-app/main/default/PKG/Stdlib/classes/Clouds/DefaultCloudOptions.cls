global virtual class DefaultCloudOptions implements ICloudOptions {
    // sfcc
    global virtual Double sfccVersion() { return 21.10; }
    global virtual String sfccClientId() { return 'clientId'; }
    global virtual String sfccCertificateName() { return 'certificateName'; }
    // sfmc
    global virtual String sfmcStack() { return '1'; }
    global virtual String sfmcAccountId() { return 'accountId'; }
    global virtual String sfmcClientId() { return 'clientId'; }
    global virtual String sfmcClientSecret() { return 'clientSecret'; }
}