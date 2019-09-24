import io.gatling.app.Gatling
import io.gatling.core.config.GatlingPropertiesBuilder

object GatlingRunner {

  def main(args: Array[String]): Unit = {

    if(args.length < 1) {
      println("You must provide the test execution class")
      System.exit(1)
    }

    val executionClass: String = s"com.stratio.performance.tests.${args(0)}"
    val simClass = Class.forName(executionClass).getName

    val props = new GatlingPropertiesBuilder
    props.simulationClass(simClass)

    Gatling.fromMap(props.build)

  }

}
