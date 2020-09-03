package com.stratio.schema.discovery.installation;

import com.stratio.qa.cucumber.testng.CucumberFeatureWrapper;
import com.stratio.qa.cucumber.testng.CucumberRunner;
import com.stratio.qa.cucumber.testng.PickleEventWrapper;
import com.stratio.qa.data.BrowsersDataProvider;
import com.stratio.tests.utils.BaseTest;
import cucumber.api.CucumberOptions;
import org.testng.annotations.Factory;
import org.testng.annotations.Test;

@CucumberOptions(features = {
        "src/test/resources/features/001_installation/002_disc_installDiscoveryCC.feature",
        "src/test/resources/features/002_connections/002_disc_connectionPG_CCT.feature",
        "src/test/resources/features/002_connections/001_disc_connectionXD_CCT.feature",
        "src/test/resources/features/099_uninstall/001_disc_uninstallDiscoveryCC.feature",
}, plugin = "json:target/cucumber.json")
public class DISC_nightlyCCT_IT extends BaseTest {


    @Factory(dataProviderClass = BrowsersDataProvider.class, dataProvider = "availableUniqueBrowsers")
    public DISC_nightlyCCT_IT(String browser) {
        this.browser = browser;
    }

    @Test(enabled = true, groups = {"nightly"}, dataProvider = "scenarios")
    public void runFeatures(PickleEventWrapper pickleWrapper, CucumberFeatureWrapper featureWrapper) throws Throwable {
        runScenario(pickleWrapper, featureWrapper);
    }

}
