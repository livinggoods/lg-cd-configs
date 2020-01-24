#Docs command don't excute
echo "Docs command don't excute"
exit 0
argocd app create argocd-test2 --upsert --repo https://github.com/livinggoods/lg-cd-configs.git --path jsonnet-cht-core-platform --dest-server https://kubernetes.default.svc --dest-namespace medic  --jsonnet-tla-str 'name=${ARGOCD_APP_NAME}' --jsonnet-tla-str 'couchDbServer=${ARGOCD_APP_NAME}-couchdb.${ARGOCD_APP_NAMESPACE}.svc.cluster.local' --jsonnet-tla-str 'chtCoreServer=${ARGOCD_APP_NAME}-chtcore.${ARGOCD_APP_NAMESPACE}.svc.cluster.local'