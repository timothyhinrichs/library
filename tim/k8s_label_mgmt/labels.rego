package kubernetes.labels

# No costcenter label
deny[msg]{
    input.request.kind == "Pod"
    not input.request.object.metadata.labels.costcenter
    msg := "Pod does not have `costcenter` label"
}

# imagePullPolicy does not exist
patch[p] {
    container := input.request.object.spec.containers[i]
    not container.imagePullPolicy
    p := {"op": "add",
          "path": sprintf("spec/containers/%v/imagePullPolicy", [i]),
          "value": "Always"}
}

# imagePullPolicy exists but is wrong
patch[p] {
    container := input.request.object.spec.containers[i]
    container.imagePullPolicy != "Always"
    p := {"op": "update",
          "path": sprintf("spec/containers/%v/imagePullPolicy", [i]),
          "value": "Always"}
}
