(ns playground
  (:require [clojure.string :as str]))

(defn groups
  [re s groups]
  (let [matcher (re-matcher re s)]
    (re-find matcher) ; populate matcher
    (into {} (map (fn [k] [k (.group matcher (name k))])) groups)))

(def xs
  {"dt.entity.host"                   "host"
   "dt.entity.process_group_instance" "process"
   "dt.trace_sampled"                 "sampled"
   "dt.trace_id"                      "trace"
   "dt.span_id"                       "span"})

(defn dt-fields-pattern [java-friendly?]
  (str/join (map (fn [[k group]]
                   (format "(?=.*%s: (?<%s>[^ ^,]+))"
                           k
                           (if java-friendly? group k)))
                 (dissoc xs "dt.trace_sampled"))))

(defn dt-meta-pattern []
  (format ".*(%s): ([^ ]+)( - )?" (str/join "|" (keys xs))))

(defn example-log
  []
  (str (str/join
        ", "
        (shuffle
         ["dt.entity.process_group_instance: PROCESS_GROUP_INSTANCE-94RN4476Q87R2O4R"
          "dt.entity.host: 123"
          "dt.trace_sampled: true"
          "dt.trace_id: np3p4n3pn744rnop02no8s1o9oo92o83"
          "dt.span_id: 1n145nq5s75sq4o3"]))
       " - some message"))

(comment
  (groups (re-pattern (dt-fields-pattern true)) (example-log) [:host :process :trace :span])
  (->> #(str/replace (example-log) (re-pattern (dt-meta-pattern)) "")
       (repeatedly 1000)
       frequencies)
  nil)
