{
  _config+:: {
    local this = self,

    syncthingSelector: 'job="syncthing"',

    // Default datasource name
    datasourceName: 'default',
    datasourceFilterRegex: '',

    // Opt-in to multiCluster dashboards by overriding this and the clusterLabel.
    showMultiCluster: false,
    clusterLabel: 'cluster',

    grafanaUrl: 'https://grafana.com',

    tags: ['syncthing', 'syncthing-mixin'],

    dashboardIds: {
      'syncthing-overview': 'syncthing-overview-jkwq',
    },
    dashboardUrls: {
      'syncthing-overview': '%s/d/%s/syncthing-overview' % [this.grafanaUrl, this.dashboardIds['syncthing-overview']],
    },

    // Syncthing alert configuration
    alerts: {
      enabled: true,

      eventsDropped: {
        enabled: true,
        severity: 'warning',
        interval: '1m',
      },

      folderOutOfSync: {
        enabled: true,
        severity: 'info',
        interval: '1h',
      },
    },

    // Custom annotations to display in graphs
    annotation: {
      enabled: false,
      name: 'Custom Annotation',
      tags: [],
      datasource: '-- Grafana --',
      iconColor: 'blue',
      type: 'tags',
    },
  },
}
