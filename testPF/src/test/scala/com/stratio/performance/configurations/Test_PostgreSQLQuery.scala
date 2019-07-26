/*
 * © 2017. Stratio Big Data Inc., Sucursal en España. All rights reserved.
 *
 * This software – including all its source code – contains proprietary information of Stratio Big Data Inc.,
 * Sucursal en España and may not be revealed, sold, transferred, modified, distributed or otherwise made
 * available, licensed or sublicensed to third parties; nor reverse engineered, disassembled or decompiled
 * without express written authorization from Stratio Big Data Inc., Sucursal en España.
 */

package com.stratio.performance.configurations

import com.stratio.performance.common.Common

trait Test_PostgreSQLQuery extends Common {

  override val query: String = System.getProperty("QUERY", "{\"query\":{\"source_table\":236,\"filter\":[\"CONTAINS\",[\"field-id\",1560],\"a\",{\"case-sensitive\":false}]},\"type\":\"query\",\"database\":10,\"parameters\":[]}")


}
