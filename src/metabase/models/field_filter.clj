(ns metabase.models.field-filter
    (:require [metabase.util :as u]
              [toucan.models :as models]))

(models/defmodel FieldFilter :card_field_sql_filter)

(u/strict-extend (class FieldFilter)
                 models/IModel
                 (merge models/IModelDefaults
                        {:types      (constantly {:filter :clob})
                         }))

