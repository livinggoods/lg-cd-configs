function(
  chtCoreImage='gcr.io/heptio-images/ks-guestbook-demo:0.2',
  couchDbImage='bitnami/couchdb:2',
  containerPort=5988,
  replicas=1,
  name='cht-core-platform',
  servicePort=5988,
  type='ClusterIP',
  pullPolicy='Always',
  buildsServer='https://build-server.lg-apps.com/_couch/builds',
  chtCoreSecrets='couchdb-secrets',
  couchdbSecrets='couchdb-secrets',
  chtCoreVersion='3.6.0',
  couchDbNodeName='couchdb@127.0.0.1',
  couchDbServer='localhost',
  couchDbProtocal='http',
  couchDbUser='admin',
  couchDbPort=5984,
  adminUser='admin',
  dataPort=5984,
  adminPort=5986,
  volumeCapacity='5Gi',
  ingressHost=name + '-cht-core.livinggoods.net',
  ingressCouchdbHost=name + '-couchdb.livinggoods.net',
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
                image: chtCoreImage,
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
    {
      apiVersion: 'v1',
      kind: 'Service',
      metadata: {
        name: name + '-couchdb',
      },
      spec: {
        ports: [
          {
            port: dataPort,
            targetPort: dataPort,
            protocol: 'TCP',
            name: 'data',
          },
          {
            port: adminPort,
            targetPort: adminPort,
            protocol: 'TCP',
            name: 'admin',
          },
        ],
        selector: {
          app: name + '-couchdb',
        },
        type: type,
      },
    },
    {
      apiVersion: 'apps/v1',
      kind: 'StatefulSet',
      metadata: {
        name: name + '-couchdb',
      },
      spec: {
        replicas: replicas,
        serviceName: name + '-couchdb',
        revisionHistoryLimit: 3,
        selector: {
          matchLabels: {
            app: name + '-couchdb',
          },
        },
        volumeClaimTemplates: [
          {
            metadata: {
              name: 'couchdb-data',
              labels: {
                app: name + '-couchdb',
              },
            },
            spec: {
              accessModes: [
                'ReadWriteOnce',
              ],
              resources: {
                requests: {
                  storage: volumeCapacity,
                },
              },
            },
          },
        ],
        template: {
          metadata: {
            labels: {
              app: name + '-couchdb',
            },
          },
          spec: {
            initContainers: [
              {
                name: name + '-couchdb' + 'init',
                image: 'alpine:3.6',
                command: ['chown', '-R', '1001:1001', '/bitnami/couchdb'],
                volumeMounts: [
                  {
                    name: 'couchdb-data',
                    mountPath: '/bitnami/couchdb',
                  },
                ],
              },
            ],
            containers: [
              {
                image: couchDbImage,
                imagePullPolicy: pullPolicy,
                name: name + '-couchdb',
                env: [
                  {
                    name: 'COUCHDB_USER',
                    value: adminUser,
                  },

                  {
                    valueFrom: {
                      secretKeyRef: {
                        name: couchdbSecrets,
                        key: 'adminPassword',
                      },
                    },
                    name: 'COUCHDB_PASSWORD',
                  },
                ],
                volumeMounts: [
                  {
                    name: 'couchdb-data',
                    mountPath: '/bitnami/couchdb',
                  },
                ],
                ports: [
                  {
                    name: 'data',
                    containerPort: dataPort,
                  },
                  {
                    name: 'admin',
                    containerPort: dataPort,
                  },
                ],
              },
            ],
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
          app: name + '-couchdb',
        },
        name: name + '-couchdb',
      },
      spec: {
        rules: [
          {
            host: ingressHost,
            http: {
              paths: [
                {
                  backend: {
                    serviceName: name + '-couchdb',
                    servicePort: dataPort,
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
