function(
  containerPort=5988,
  image='gcr.io/heptio-images/ks-guestbook-demo:0.2',
  name='jsonnet-guestbook-ui',
  replicas=1,
  servicePort=5988,
  type='LoadBalancer',
  pullPolicy='Always',
  buildsServer='https://build-server.lg-apps.com/_couch/builds',
  chtCoreSecrets='couchdb-secrets',
  chtCoreVersion='3.6.0',
  couchDbNodeName='couchdb@127.0.0.1',
  couchDbServer='localhost',
  couchDbProtocal='http',
  couchDbUser='admin',
  couchDbPort=5984,
  ingressHost='cht-core-dev.livinggoods.net',
)
  [
    {
      apiVersion: 'v1',
      kind: 'Service',
      metadata: {
        name: name,
      },
      spec: {
        ports: [
          {
            port: servicePort,
            targetPort: containerPort,
          },
        ],
        selector: {
          app: name,
        },
        type: type,
      },
    },
    {
      apiVersion: 'apps/v1',
      kind: 'Deployment',
      metadata: {
        name: name,
      },
      spec: {
        replicas: replicas,
        revisionHistoryLimit: 3,
        selector: {
          matchLabels: {
            app: name,
          },
        },
        template: {
          metadata: {
            labels: {
              app: name,
            },
          },
          spec: {
            volumes: [
              {
                name: 'horti-data',
                persistentVolumeClaim: {
                  claimName: name + 'horti-pvc',
                },
              },
            ],
            containers: [
              {
                image: image,
                name: name,
                volumeMounts: [
                  {
                    name: 'horti-data',
                    mountPath: '/root',
                  },
                ],
                env: [
                  {
                    name: 'COUCHDB_USER',
                    value: couchDbUser,
                  },
                  {
                    name: 'HORTI_BUILDS_SERVER',
                    value: buildsServer,
                  },
                  {
                    name: 'COUCHDB_SERVER',
                    value: couchDbServer,
                  },
                  {
                    name: 'MEDIC_VERSION',
                    value: chtCoreVersion,
                  },
                  {
                    name: 'COUCH_NODE_NAME',
                    value: couchDbNodeName,
                  },
                  {
                    valueFrom: {
                      secretKeyRef: {
                        name: chtCoreSecrets,
                        key: 'adminPassword',
                      },
                    },
                    name: 'COUCHDB_PASSWORD',
                  },
                ],
                ports: [
                  {
                    name: 'http',
                    containerPort: containerPort,
                    protocol: 'TCP',
                  },
                ],
              },
            ],
          },
        },
      },
    },
    {
      apiVersion: 'v1',
      kind: 'PersistentVolumeClaim',
      metadata: {
        annotations: {
          app: name,
        },
        name: name + 'horti-pvc',
      },
      spec: {
        accessModes: [
          'ReadWriteOnce',
        ],
        resources: {
          requests: {
            storage: '1Gi',
          },
        },
      },
    },
    {
      apiVersion: 'extensions/v1beta1',
      kind: 'Ingress',
      metadata: {
        annotations: {
          'ingress.kubernetes.io/proxy-body-size': '500m',
          'kubernetes.io/ingress.class': 'nginx',
          'nginx.ingress.kubernetes.io/force-ssl-redirect': 'true',
          'nginx.ingress.kubernetes.io/proxy-body-size': '500m',
        },
        labels: {
          app: name,
        },
        name: name,
      },
      spec: {
        rules: [
          {
            host: ingressHost,
            http: {
              paths: [
                {
                  backend: {
                    serviceName: name,
                    servicePort: servicePort,
                  },
                  path: '/',
                },
              ],
            },
          },
        ],
      },
    },
  ]
