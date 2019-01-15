package units

example {
    convert("100K") = x
}
convert(str) = result {
    suffixes[suffix] = factor
    endswith(str, suffix)
    num_str := substring(str, 0, count(str) - count(suffix))  # off by 1?
    num := to_number(num_str)
    result := num * factor
}

test_convert {
    102400 == convert("100Ki")
    100000 == convert("100k")
    not test_fail
}

test_fail {
    factor := suffixes[suf]
    actual := convert(sprintf("100%v", [suf]))
    correct := 100 * factor
    actual != correct
}


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
