const cds = require('@sap/cds')

const LOG = cds.log('recap-plugin')

cds.on('served', () => {
    LOG.info('*** Recap Plugin Loaded ***');
})