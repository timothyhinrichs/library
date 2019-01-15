package kubernetes.test_labels

import data.kubernetes.labels

test_costcenter_allow {
   count(labels.deny) == 0 with input as data.input_costcenter_safe
}

test_costcenter_deny {
    actual := labels.deny with input as data.input_costcenter_unsafe
    actual[msg]
    indexof(msg, "costcenter") > 0
}

test_imagepull_mutate {
    actual := labels.patch with input as data.input_costcenter_unsafe
    actual[p1]
    p1.op == "add"
    actual[p2]
    p2.op == "update"
    count(actual) == 2
}

test_imagepull_mutate_nochange {
    actual := labels.patch with input as data.input_costcenter_safe
    count(actual) == 0
}





