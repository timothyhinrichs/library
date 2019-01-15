package lib.kubernetes.test_rbac
import data.lib.kubernetes.rbac

test_role_rolebinding_positive {
    k8s := {"roles": roles, "rolebindings": rolebindings}
    actual := rbac.perms_for_input with input as jane_input with data.kubernetes as k8s
    count(actual) == 1
    actual[i].resources[_] == "pods"
    actual[i].explanation.bindingKind == "RoleBinding"
    actual[i].explanation.roleKind == "Role"
    actual[i].namespace == "default"
}

test_role_rolebinding_negative {
    k8s := {"roles": roles, "rolebindings": rolebindings}
    actual := rbac.perms_for_input with input as eve_input with data.kubernetes as k8s
    count(actual) == 0
}

test_clusterrole_rolebinding_positive {
    k8s := {"clusterroles": clusterroles, "rolebindings": rolebindings}
    actual := rbac.perms_for_input with input as dave_input with data.kubernetes as k8s
    count(actual) == 1
    actual[i].resources[_] == "secrets"
    actual[i].explanation.bindingKind == "RoleBinding"
    actual[i].explanation.roleKind == "ClusterRole"
    actual[i].namespace == "development"
}

test_clusterrole_rolebinding_negative {
    k8s := {"clusterroles": clusterroles, "rolebindings": rolebindings}
    actual := rbac.perms_for_input with input as jane_input with data.kubernetes as k8s
    count(actual) == 0
}

test_clusterrole_clusterrolebinding_positive {
    k8s := {"clusterroles": clusterroles, "clusterrolebindings": clusterrolebindings}
    actual := rbac.perms_for_input with input as mgr_input with data.kubernetes as k8s
    count(actual) == 1
    actual[i].resources[_] == "secrets"
    actual[i].explanation.bindingKind == "ClusterRoleBinding"
    actual[i].explanation.roleKind == "ClusterRole"
    actual[i].namespace == null
}

test_clusterrole_clusterrolebinding_negative {
    k8s := {"clusterroles": clusterroles, "clusterrolebindings": clusterrolebindings}
    actual := rbac.perms_for_input with input as dave_input with data.kubernetes as k8s
    count(actual) == 0
}

test_clusterrole_clusterrolebinding_agg {
    k8s := {"clusterroles": clusterroles, "clusterrolebindings": clusterrolebindings}
    actual := rbac.perms_for_input with input as fabio_input with data.kubernetes as k8s
    actual[_].resources[_] == "services"
    actual[_].resources[_] == "fancyservices"
}


jane_input = {"request": {"userInfo": {"username": "jane", "groups": []}}}
dave_input = {"request": {"userInfo": {"username": "dave", "groups": []}}}
eve_input = {"request": {"userInfo": {"username": "eve", "groups": []}}}
fabio_input = {"request": {"userInfo": {"username": "fabio", "groups": []}}}
mgr_input = {"request": {"userInfo": {"username": "alicia", "groups": ["manager"]}}}

roles["pod-reader"] = {
	"kind": "Role",
	"apiVersion": "rbac.authorization.k8s.io/v1",
	"metadata": {
		"namespace": "default",
		"name": "pod-reader"
	},
	"rules": [
		{
			"apiGroups": [
				""
			],
			"resources": [
				"pods"
			],
			"verbs": [
				"get",
				"watch",
				"list"
			]
		}
	]
}

rolebindings["read-pods"] = {
	"kind": "RoleBinding",
	"apiVersion": "rbac.authorization.k8s.io/v1",
	"metadata": {
		"name": "read-pods",
		"namespace": "default"
	},
	"subjects": [
		{
			"kind": "User",
			"name": "jane",
			"apiGroup": "rbac.authorization.k8s.io"
		}
	],
	"roleRef": {
		"kind": "Role",
		"name": "pod-reader",
		"apiGroup": "rbac.authorization.k8s.io"
	}
}

rolebindings["read-secrets"] = {
	"kind": "RoleBinding",
	"apiVersion": "rbac.authorization.k8s.io/v1",
	"metadata": {
		"name": "read-secrets",
		"namespace": "development"
	},
	"subjects": [
		{
			"kind": "User",
			"name": "dave",
			"apiGroup": "rbac.authorization.k8s.io"
		}
	],
	"roleRef": {
		"kind": "ClusterRole",
		"name": "secret-reader",
		"apiGroup": "rbac.authorization.k8s.io"
	}
}

clusterrolebindings["read-secrets-global"] = {
	"kind": "ClusterRoleBinding",
	"apiVersion": "rbac.authorization.k8s.io/v1",
	"metadata": {
		"name": "read-secrets-global"
	},
	"subjects": [
		{
			"kind": "Group",
			"name": "manager",
			"apiGroup": "rbac.authorization.k8s.io"
		}
	],
	"roleRef": {
		"kind": "ClusterRole",
		"name": "secret-reader",
		"apiGroup": "rbac.authorization.k8s.io"
	}
}

clusterrolebindings["read-services-global"] = {
	"kind": "ClusterRoleBinding",
	"apiVersion": "rbac.authorization.k8s.io/v1",
	"metadata": {
		"name": "read-secrets-global"
	},
	"subjects": [
		{
			"kind": "User",
			"name": "fabio",
			"apiGroup": "rbac.authorization.k8s.io"
		}
	],
	"roleRef": {
		"kind": "ClusterRole",
		"name": "service-reader",
		"apiGroup": "rbac.authorization.k8s.io"
	}
}



clusterroles["service-reader"] = {
	"kind": "ClusterRole",
	"apiVersion": "rbac.authorization.k8s.io/v1",
	"metadata": {
		"name": "service-reader"
	},
	"aggregationRule": {
		"clusterRoleSelectors": [
			{
				"matchLabels": {
					"rbac.example.com/aggregate-to-service-reader": "true"
				}
			}
		]
	},
	"rules": [
		{
			"apiGroups": [
				""
			],
			"resources": [
				"services"
			],
			"verbs": [
				"get",
				"watch",
				"list"
			]
		}
	]
}
clusterroles["secret-reader"] = {
	"kind": "ClusterRole",
	"apiVersion": "rbac.authorization.k8s.io/v1",
	"metadata": {
		"name": "secret-reader"
	},
	"rules": [
		{
			"apiGroups": [
				""
			],
			"resources": [
				"secrets"
			],
			"verbs": [
				"get",
				"watch",
				"list"
			]
		}
	]
}

clusterroles["fancyservice-reader"] = {
	"kind": "ClusterRole",
	"apiVersion": "rbac.authorization.k8s.io/v1",
	"metadata": {
		"name": "service-writer",
        "labels": {
			"rbac.example.com/aggregate-to-service-reader": "true"
        }
	},
	"rules": [
		{
			"apiGroups": [
				""
			],
			"resources": [
				"fancyservices"
			],
			"verbs": [
				"get",
				"watch",
				"list"
			]
		}
	]
}

