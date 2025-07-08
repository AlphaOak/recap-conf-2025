const cds = require('@sap/cds')



module.exports = class AdminService extends cds.ApplicationService {
    async init() {

        this.on('READ', 'Bla', async (req) => {
            return {ID: 1, Name: 'Sample Admin Service'};
        })


        // Call the base class init method
        await super.init();
    }
    }