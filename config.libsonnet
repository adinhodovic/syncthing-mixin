{
  _config+:: {
    local this = self,

    syncthingSelector: 'job="syncthing"',

    // Default datasource name
    datasourceName: 'default',

    // Opt-in to multiCluster dashboards by overriding this and the clusterLabel.
    showMultiCluster: false,
    clusterLabel: 'cluster',

    grafanaUrl: 'https://grafana.com',

    syncthingFolderOutOfSyncFor: '1h',

    tags: ['syncthing', 'syncthing-mixin'],

    dashboardIds: {
      'syncthing-overview': 'syncthing-overview-jkwq',
    },
    dashboardUrls: {
      'syncthing-overview': '%s/d/%s/syncthing-overview' % [this.grafanaUrl, this.dashboardIds['syncthing-overview']],
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
