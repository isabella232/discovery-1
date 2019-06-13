package com.stratio.schema.discovery.specs;

import com.stratio.qa.assertions.Assertions;
import com.stratio.qa.assertions.SeleniumAssert;
import com.stratio.qa.specs.BaseGSpec;
import com.stratio.qa.specs.CommonG;
import cucumber.api.java.en.Given;
import cucumber.api.java.en.When;
import org.openqa.selenium.WebElement;

import java.util.concurrent.TimeUnit;

/**
 * Generic Selenium Specs.
 */
public class SeleniumSpec extends BaseGSpec {

    /**
     * Generic constructor.
     *
     * @param spec object
     */
    public SeleniumSpec(CommonG spec) {
        this.commonspec = spec;

    }

    /**
     * Browse to {@code url} using the current browser.
     *
     * @param path path of running app
     * @throws Exception exception
     */


    @Given("^I( securely)? browse a longtime2 to '(.+?)'$")
    public void seleniumBrowse2(String isSecured, String path) throws Exception {
            Assertions.assertThat(path).isNotEmpty();
        this.commonspec.getDriver().manage().window().maximize();
        this.commonspec.getDriver().manage().timeouts().implicitlyWait(400, TimeUnit.SECONDS);
        if(this.commonspec.getWebHost() == null) {
                throw new Exception("Web host has not been set");
            } else if(this.commonspec.getWebPort() == null) {
                throw new Exception("Web port has not been set");
            } else {
                String protocol = "http://";
                if(isSecured != null) {
                    protocol = "https://";
                }

                String webURL = protocol + this.commonspec.getWebHost() + this.commonspec.getWebPort();
                this.commonspec.getDriver().get(webURL + path);
                this.commonspec.setParentWindow(this.commonspec.getDriver().getWindowHandle());
            }
    }

}
