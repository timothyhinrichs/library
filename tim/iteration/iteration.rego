package iteration

deny[msg] {
  containers[c]    # check if value 7 belongs to set containers: containers[7]
  not startswith(c.image, "hooli.com")
  msg := sprintf("image %v fails to come from a trusted registry", [c.image])
}

# deny["same name and image"] {
#     c := input.request.object.spec.containers[_]
#     c.image == c.name
# }

# deny[msg] {
#     all := [data.units.convert(m) | containers[c]; m := c.resources.limits.memory]
#     s := sum(all)
#     s > data.units.convert("10T")
#     msg := sprintf("Total memory limit exceeds 10T: %v", [s])
# }

containers[c] {
    c := input.request.object.spec.containers[_]
}

containers[c] {
    c := input.request.object.spec.initContainers[_]
}

containers[c] {
    c := input.request.object.spec.template.spec.containers[_]
}