{
  local clusterVariableQueryString = if $._config.showMultiCluster then '&var-%(clusterLabel)s={{ $labels.%(clusterLabel)s}}' % $._config else '',
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'syncthing',
        rules: [
          {
            alert: 'SyncthingEventsDropped',
            expr: |||
              sum(
                increase(
                  syncthing_events_total{
                    %(default)s,
                    state="created"
                  }[5m]
                )
              ) by (%(clusterLabel)s, job, event)
              > 0
            ||| % $._config,
            labels: {
              severity: 'warning',
            },
            'for': '1m',
            annotations: {
              summary: 'Syncthing events dropped.',
              description: 'The job {{ $labels.job }} has dropped events of type {{ $labels.event }} in the last minute.',
              dashboard_url: $._config.dashboardUrls['syncthing-overview'] + '?var-job={{ $labels.job }}' + clusterVariableQueryString,
            },
          },
          {
            alert: 'SyncthingFolderOutOfSync',
            expr: |||
              sum(
                syncthing_model_folder_summary{
                  scope="need",
                  type="bytes"
                }
              ) by (%(clusterLabel)s, job, folder)
              > 0
            ||| % $._config,
            labels: {
              severity: 'info',
            },
            'for': $._config.syncthingFolderOutOfSyncFor,
            annotations: {
              summary: 'Syncthing folder out of sync.',
              description: 'The folder {{ $labels.folder }} in job {{ $labels.job }} is out of sync for more than %(syncthingFolderOutOfSyncFor)s.' % $._config,
              dashboard_url: $._config.dashboardUrls['syncthing-overview'] + '?var-job={{ $labels.job }}&var-folder={{ $labels.folder }}' + clusterVariableQueryString,
            },
          },
        ],
      },
    ],
  },
}
