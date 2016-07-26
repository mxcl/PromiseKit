@import CloudKit;

CKDiscoveredUserInfo *PMKDiscoveredUserInfo() {
    return [CKDiscoveredUserInfo new];
}


#if TARGET_OS_SIMULATOR
BOOL isTravis() {
    NSString *tmpDir = @(getenv("TMPDIR"));
    // Travis CI
    if ([tmpDir hasPrefix:@"/Users/travis"]) {
        return true;
    }
    return false;
}
#else
BOOL isTravis() {
    return getenv("CI")
    || getenv("CONTINUOUS_INTEGRATION")
    || getenv("BUILD_ID")
    || getenv("BUILD_NUMBER")
    || getenv("TEAMCITY_VERSION")
    || getenv("TRAVIS")
    || getenv("CIRCLECI")
    || getenv("JENKINS_URL")
    || getenv("HUDSON_URL")
    || getenv("bamboo.buildKey")
    || getenv("PHPCI")
    || getenv("GOCD_SERVER_HOST")
    || getenv("BUILDKITE");
}
#endif
