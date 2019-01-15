package kubernetes.test_quota

import data.kubernetes.quota

test_deny {
   count(quota.deny) > 0 with input as data.sampleinput
}

test_convert {
   not convert_failed
}

convert_failed {
   factor := quota.suffixes[suffix]
   actual := quota.convert(sprintf("256%v", [suffix]))
   correct := 256*factor
   actual != correct
}
