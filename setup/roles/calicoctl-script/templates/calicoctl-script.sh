#! /bin/bash
DATASTORE_TYPE=kubernetes KUBECONFIG={{ CONTROL_BASE_DIR }}/admin.conf {{ SETUP_TOOLS_DIR }}/bin/calicoctl $@