package foo

#######################
# Diff-based version

# allowed: changed_paths = {["metadata", "labels"]}
# not allowed:
allow {
    allowed_path_changes = {["metadata", "labels"], ["metadata", "annotations"]}
    # diff would return a SET OF
    #   {op: add, path: metadata.labels.foo, value: bar}
    #   {op: add, path: metadata.labels.baz, value: qux}
    #for all in diff, path there must be a prefix in allowed_path_changes
    diff_paths := {x.path | diff(input.object, input.oldObject)}
    not some_missing_prefix(diff_paths, allowed_path_changes)
}
some_missing_prefix(changes, prefixes) {
    not prefixed(changes[x], prefixes)
}
prefixed(change, prefixes) {
    match(change, prefixes[p])
}

############################
# Named-based version

allow {
    object_equal_except(input.object, input.oldObject, "metadata")
    object_equal_except(input.object.metadata, input.oldObject.metadata, "labels")
}

# there are no differences (other than the key NAME)
object_equal_except(a, b, name) {
    not object_unequal_except(a, b, name)
}

# objects have same keys but different values (other than key NAME)
object_unequal_except(a, b, name) {
    a[x] != b[x]
    x != name
}
# objects have different keys (other than key name)
object_unequal_except(a, b, name) {
    akeys = {x | a[x]; x != name}
    bkeys = {x | b[x]; x != name}
    akeys != bkeys
}

############################
# Path-based version
allow {
    object_equal_except(input.object, input.oldObject, ["metadata", "labels"])
}

# there are no differences (other than the path)
object_equal_except(a, b, path) {
    not object_unequal_except(a, b, path)
}

# objects have same keys but different values (other than key NAME)
object_unequal_except(a, b, path) {
    walk(a, [x, avalue])
    walk(b, [x, bvalue])
    not prefixOf(path, x)
    avalue != bvalue
}
# objects have different paths (other than path)
object_unequal_except(a, b, path) {
    apaths = {x | walk(a, [x, _]; not prefixOf(path, x)}
    bpaths = {x | walk(b, [x, _]; not prefixOf(path, x)}
    apaths != bpaths
}

prefixOf(shorter, longer) {
    mismatches := { shorter[i] != longer[i] | shorter[i] }
    count(mismatches) == 0
}


###########################
## Fully general version

bad = changed_path - allowed_path_changes

allowed_path_changes = {
  [],
  ["metadata"], ["metadata", "labels"],
  ["spec"], ["spec", "container"]}

input.object.metadata.labels != input.oldobject.metadata.labels

changed_path[path] {
    walk(input.object, [path, value])
    changed(path, value)
}

changed(path, value) {
    walk(input.oldobject, [path, oldvalue])
    value != oldvalue
}
changed(path, value) {
    not pathexists(input.oldobject, path)   # walk(input.oldobject, [path, oldvalue])
}

pathexists(obj, path) {
    walk(obj, [path, _])
}






