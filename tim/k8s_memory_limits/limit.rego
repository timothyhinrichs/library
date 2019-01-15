
package kubernetes.quota

# Deny a Pod if its total resource memory limit is greater than 1T
deny[msg] {
  input.object.kind == "Pod"
  all_mem := [convert(x) | x := input.object.spec.containers[_].resources.limits.memory]
  total := sum(all_mem)
  total > 1e12
  msg := sprintf("Total memory limit for pod exceeds 1T: %v", [total])
}


# // <binarySI>        ::= Ki | Mi | Gi | Ti | Pi | Ei
# // <decimalSI>       ::= m | "" | k | M | G | T | P | E

suffixes = {
    "Ki": 1024,
    "Mi": 1024 * 1024,
    "Gi": 1024 * 1024 * 1024,
    "Ti": 1024 * 1024 * 1024 * 1024,
    "Pi": 1024 * 1024 * 1024 * 1024 * 1024,
    "Ei": 1024 * 1024 * 1024 * 1024 * 1024 * 1024,
    "k": 1000,
    "M": 1000 * 1000,
    "G": 1000 * 1000 * 1000,
    "T": 1000 * 1000 * 1000 * 1000,
    "P": 1000 * 1000 * 1000 * 1000 * 1000,
    "E": 1000 * 1000 * 1000 * 1000 * 1000 * 1000,
    "m": 1
}
convert(str) = result {
    suffixes[suffix] = factor
    endswith(str, suffix)
    num_str := substring(str, 0, count(str) - count(suffix))  # off by 1?
    num := to_number(num_str)
    result := num * factor
}

# # 128G
# convert(str) = result {
#   endswith(str, "G")
#   num_str := substring(str, 0, count(str) - 1)
#   num := to_number(num_str)   # 128
#   result := num * 1e9
# }




