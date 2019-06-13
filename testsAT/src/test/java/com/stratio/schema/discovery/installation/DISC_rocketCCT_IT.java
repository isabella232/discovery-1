package com.stratio.schema.discovery.installation;

import com.stratio.qa.cucumber.testng.CucumberRunner;
import com.stratio.qa.data.BrowsersDataProvider;
import com.stratio.tests.utils.BaseTest;
import cucumber.api.CucumberOptions;
import org.testng.annotations.Factory;
import org.testng.annotations.Test;

import java.io.PrintWriter;

@CucumberOptions(features = {
        "src/test/resources/features/001_installation/002_disc_installDiscoveryCC.feature",
        "src/test/resources/features/003_login/001_disc_loginUserPassword.feature",
        "src/test/resources/features/002_connections/001_disc_connectionXD_CCT.feature",
        "src/test/resources/features/002_connections/002_disc_connectionPG_CCT.feature",
        "src/test/resources/features/099_uninstall/001_disc_uninstallDiscoveryCC.feature"
},format = "json:target/cucumber.json")

public class DISC_rocketCCT_IT extends BaseTest {

    @Factory(enabled = false, dataProviderClass = BrowsersDataProvider.class, dataProvider = "availableUniqueBrowsers")
    public DISC_rocketCCT_IT(String browser) {
        this.browser = browser;
    }

    @Test(enabled = true, groups = {"rocket"})
    public void AppWithSecurityES() throws Exception {
        PrintWriter writer = new PrintWriter("target/sparta-info-qa-cucumber.properties", "UTF-8");
        writer.println("DISCOVERY_VERSION = " + System.getProperty("DISC_VERSION","value not defined"));
        String URLvalue= System.getProperty("BUILD_URL","value not defined")+"artifact/testsAT/target/executions/com.stratio.schema.discovery.installation.DISC_rocketCCT_IT /";
        writer.println("DISCOVERY_EVIDENCES = <a href="+URLvalue+   ">Evidences</a>");
        writer.close();
        new CucumberRunner(this.getClass()).runCukes();
    }

}

