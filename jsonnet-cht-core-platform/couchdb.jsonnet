function(
  image='bitnami/couchdb:2',
  name='lg-couchdb',
  replicas=1,
  type='ClusterIP',
  pullPolicy='Always',
  couchdbSecrets='couchdb-secrets',
  adminUser='admin',
  dataPort=5984,
  adminPort=5986,
  volumeCapacity='5Gi',
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
          app: name,
        },
        type: type,
      },
    },
    {
      apiVersion: 'apps/v1',
      kind: 'StatefulSet',
      metadata: {
        name: name,
      },
      spec: {
        replicas: replicas,
        serviceName: name,
        revisionHistoryLimit: 3,
        selector: {
          matchLabels: {
            app: name,
          },
        },
        volumeClaimTemplates: [
          {
            metadata: {
              name: 'couchdb-data',
              labels: {
                app: 'name',
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
              app: name,
            },
          },
          spec: {
            initContainers: [
              {
                name: name + 'init',
                image: 'alpine:3.6',
                command: ['chown', '-R', '1001:1001', '/bitnami/couchdb'],
              },
            ],
            containers: [
              {
                image: image,
                imagePullPolicy: pullPolicy,
                name: name,
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
