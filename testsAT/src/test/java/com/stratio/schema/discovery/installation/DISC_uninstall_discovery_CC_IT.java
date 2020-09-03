package com.stratio.schema.discovery.installation;

import com.stratio.qa.cucumber.testng.CucumberFeatureWrapper;
import com.stratio.qa.cucumber.testng.CucumberRunner;
import com.stratio.qa.cucumber.testng.PickleEventWrapper;
import com.stratio.tests.utils.BaseTest;
import cucumber.api.CucumberOptions;
import org.testng.annotations.Test;

@CucumberOptions(features = { "src/test/resources/features/099_uninstall/001_disc_uninstallDiscoveryCC.feature" }, plugin = "json:target/cucumber.json")
public class DISC_uninstall_discovery_CC_IT extends BaseTest {

    public DISC_uninstall_discovery_CC_IT() {}
    @Test(enabled = true, groups = {"purge_discovery_cc"}, dataProvider = "scenarios")
    public void runFeatures(PickleEventWrapper pickleWrapper, CucumberFeatureWrapper featureWrapper) throws Throwable {
        runScenario(pickleWrapper, featureWrapper);
    }

}
