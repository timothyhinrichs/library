package lib.kubernetes.rbac

import data.kubernetes.clusterrolebindings
import data.kubernetes.rolebindings
import data.kubernetes.clusterroles
import data.kubernetes.roles

# Implementation for k8s RBAC.  Guide is here:
#   https://kubernetes.io/docs/reference/access-authn-authz/rbac/
#
# perms_for_input: returns the set of permissions for a given user
#
# Input describes a single user and should include the following paths
#    request:
#      userInfo:
#        username: <string>
#        groups: <array of strings>
#
# perms_for_input is a set of objects of the following form:
#    apiGroups: <from a (Cluster)Role rule>
#    resources: <from a (Cluster)Role rule>
#    verbs: <from a (Cluster)Role rule>
#    namespace: <string> or null (if cluster-level perms)
#    explanation:
#      bindingName: <string>
#      bindingKind: <string>
#      roleName: <string>
#      roleKind: <string>
#
# Examples
#   Ask for all permissions for the user
#   perms_for_input
#
#   Ask for all permissions within namespace "default"
#   perms_for_input[{"namespace": "default", "apiGroups": api, "resources": res, "verbs": verbs, "explanation": expl}]
#
#   Ask for all permissions within namespace "default" for "pods" resources
#   perms_for_input[{"namespace": "default", "apiGroups": api, "resources": res, "verbs": verbs, "explanation": expl}]; res[_] == "pods"
#
# kube-mgmt options
#     --replicate=rbac.authorization.k8s.io/v1/rolebindings
#     --replicate=rbac.authorization.k8s.io/v1/roles
#     --replicate-cluster=rbac.authorization.k8s.io/v1/clusterrolebindings
#     --replicate-cluster=rbac.authorization.k8s.io/v1/clusterroles
#
# kube-mgmt permissions (in addition to the ones in the OPA tutorial)
#
# kind: ClusterRoleBinding
# apiVersion: rbac.authorization.k8s.io/v1
# metadata:
#   name: opa-rbac-viewer
# roleRef:
#   kind: ClusterRole
#   name: view-rbac
#   apiGroup: rbac.authorization.k8s.io
# subjects:
# - kind: Group
#   name: system:serviceaccounts:opa
#   apiGroup: rbac.authorization.k8s.io
# ---
# kind: ClusterRole
# apiVersion: rbac.authorization.k8s.io/v1
# metadata:
#   name: view-rbac
# rules:
# - apiGroups: ["rbac.authorization.k8.io/v1"]
#   resources: ["rolebindings", "clusterrolebindings", "roles", "clusterroles"]
#   verbs: ["get", "list", "watch"]
# ---


# clusterrolebinding and clusterrole
perms_for_input[perm] {
    subj := clusterrolebindings[bindingname].subjects[i]
    subject_match(subj)
    rolename := clusterrolebindings[bindingname].roleRef.name
    clusterrolebindings[bindingname].roleRef.kind == "ClusterRole"
    extended_rule[["ClusterRole", rolename, rule]]
    perm := {"apiGroups": rule.apiGroups,
             "resources": rule.resources,
             "verbs": rule.verbs,
             "namespace": null,
             "explanation": {"bindingName": bindingname,
                             "bindingKind": "ClusterRoleBinding",
                             "roleName": rolename,
                             "roleKind": "ClusterRole"}}
}

# rolebinding and clusterrole
perms_for_input[perm] {
    subj := rolebindings[bindingname].subjects[i]
    subject_match(subj)
    rolename := rolebindings[bindingname].roleRef.name
    rolebindings[bindingname].roleRef.kind == "ClusterRole"
    extended_rule[["ClusterRole", rolename, rule]]
    perm := {"apiGroups": rule.apiGroups,
             "resources": rule.resources,
             "verbs": rule.verbs,
             "namespace": rolebindings[bindingname].metadata.namespace,
             "explanation": {"bindingName": bindingname,
                             "bindingKind": "RoleBinding",
                             "roleName": rolename,
                             "roleKind": "ClusterRole"}}
}

# rolebinding and role
perms_for_input[perm] {
    subj := rolebindings[bindingname].subjects[i]
    subject_match(subj)
    rolename := rolebindings[bindingname].roleRef.name
    rolebindings[bindingname].roleRef.kind == "Role"
    rule := roles[rolename].rules[_]     # Roles do not support aggregation
    perm := {"apiGroups": rule.apiGroups,
             "resources": rule.resources,
             "verbs": rule.verbs,
             "namespace": rolebindings[bindingname].metadata.namespace,
             "explanation": {"bindingName": bindingname,
                             "bindingKind": "RoleBinding",
                             "roleName": rolename,
                             "roleKind": "Role"}}
}

# TODO: Permitted by k8s? clusterrolebinding and role


# Check if a (Cluster)RoleBinding matches the input
subject_match(subject) {
    # Check if username matches
    is_user_kind = {"User", "ServiceAccount"}
    is_user_kind[subject.kind]
    subject.name == input.request.userInfo.username
}

subject_match(subject) {
    # Check if Group matches
    subject.kind == "Group"
    subject.name == input.request.userInfo.groups[_]
}

# Handle Role Aggregation for ClusterRole.
#   Role Aggregation enables rules to come from multiple
#   ClusterRole objects.

# Rule comes from ClusterRole object
extended_rule[["ClusterRole", name, rule]] {
    rule := clusterroles[name].rules[_]
}
# Rule comes from a different ClusterRole object.
# TODO: docs say these aggregates are handled by the controller.  Does
#   that mean the controller rewrites one ClusterRole to include rules from
#   the other ones?  If so, we don't need to do this at all.
extended_rule[["ClusterRole", name, rule]] {
    clusterroles[name].aggregationRule.clusterRoleSelectors[_].matchLabels[key] = value
    clusterroles[newname].metadata.labels[key] = value
    rule := clusterroles[newname].rules[_]
}


