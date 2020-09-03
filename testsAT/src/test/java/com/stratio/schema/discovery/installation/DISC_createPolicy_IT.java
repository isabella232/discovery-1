package com.stratio.schema.discovery.installation;

import com.stratio.qa.cucumber.testng.CucumberFeatureWrapper;
import com.stratio.qa.cucumber.testng.CucumberRunner;
import com.stratio.qa.cucumber.testng.PickleEventWrapper;
import com.stratio.tests.utils.BaseTest;
import cucumber.api.CucumberOptions;
import org.testng.annotations.Test;

@CucumberOptions(features = { "src/test/resources/features/001_installation/000_disc_createPolicies.feature" }, plugin = "json:target/cucumber.json")
public class DISC_createPolicy_IT extends BaseTest{
    public DISC_createPolicy_IT() {}
    @Test(enabled = true, groups = {"create_policy"}, dataProvider = "scenarios")
    public void runFeatures(PickleEventWrapper pickleWrapper, CucumberFeatureWrapper featureWrapper) throws Throwable {
        runScenario(pickleWrapper, featureWrapper);
    }
}
