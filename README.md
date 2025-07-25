# re>≡CAP Conference 2025
AlphaOak is developing a SAP extension app called ['Sigma'](https://www.alphaoak.com/products/sigma/) that is using S/4 as a foundation.

The concept of Sigma is at it's core to calculate some standard Asset and Work Management KPI's. 

Why do you need CAP for it you ask? 

A few reasons: 
1. Standard Analytics Engines like SAC or BDC don't have the capabilty to configure thresholds when lights turn green and other factors like weighting of multiple measures into a single KPI. 
2. We have lots of data points that don't exist or exist in another system, so we want to have standard interfaces in place to feed the information into out data model or (if no external system exists), use a Fiori app to enter it in reference to our main entity (in our case a Job).  

At the end of the day the overall solution allows me to consume the data set through three different channels: 
1. For key decision makers in SAC with some standard Dashboards. Once I drill down I can then offer a jump into a Fiori App that provides all the line item details.  
2. If I want to provide the analytics team an additional level of flexibility, I can provide the information to BDC/Datasphere and ultimately to SAC. 
3. For the Field User and Supervisor I can use a simple Fiori Analytical app as third channel to consume the information. 

## System Landscape
Sigma is utilizing the following solution architecture.
<img src="./docs/img/sigma-architecture.png">



# Sigma Structure Overview

```
                        +-----------------+                                                                                                                                                
                        | @alphaoak/sigma |                                                                                                                                                
                        +--------|--------+                                                                                                                                                
                                 |                                                                                                                                                         
           +---------------------|                                                                                                                                                         
           |                     |                                                                                                                                                         
           |                     |                                                                                                                                                         
           |          +--------------------+                                                                                                                                               
           |          | @alphaoak/eam-kpis |                                                                                                                                               
           |          +----+---------------+                                                                                                                                               
           |                     |                                                                                                                                                         
           |                     |-------------------------------------------------------------------------------------------------------+---------------------------+                     
           |                     |                |                         |                             |                              |                           |                     
           |                     |    +-----------|-----------+ +-----------|----------+   +--------------|-------------+ +--------------|--------------+ +----------|---------+           
           |                     |    | @alphaoak/eam-quality | | @alphaoak/eam-safety |   | @alphaoak/eam-customer-sat | | @alphaoak/eam-cost-burdened | | @alphaoak/workdate |           
           |                     |    +-----------|-----------+ +-----------|----------+   +--------------|-------------+ +--------------|--------------+ +--------------------+           
           |                     |                |                         |                             |                              |                                                 
           |                     --------------------------------------------------------------------------------------------------------+                                                 
           |           +--------------------+                                                                                                                                              
           |           | @alphaoak/eam-core |                                                                                                                                              
           |           +--------------------+                                                                                                                                              
           |                     |                                                                                                                                                         
           |                     |                                                                                                                                                        
           |                +----------------------------------------------------+                                                                                                         
           |                |                         |                          |                                                                                                         
           |       +--------------------+ +-------------------------+ +---------------------+                                                                                              
           |       | @alphaoak/cds-core | | @alphaoak/material-core | | @alphaoak/cost-core |                                                                                              
           |       +--------------------+ +-------------------------+ +---------------------+                                                                                              
+----------|----------+                                                                                                                                                                    
| @alphaoak/cds-utils |                                                                                                                                                                    
+---------------------+                                                                                                                                                                                                    

```


# Example plugin use to model semantics
## Why using Plugins
We are using plugins to separate the different data models and extensions from each other. The easiest analogy would be modules in SAP S/4.

As we are re-using components in varying applications, we don't want to copy and paste data models around. 


# Step-by-step instructions
## 1. Prepare the project environment
1. Create an overall project folder. Let's say it is called `tapp`
2. Create two sub folders. The first one called `capapp`, the second `capplugin`
3. Initialize CAP projects in both folders
    1. in folder `cappplugin` execute: `cds init`
    2. in folder `capapp` execute: `cds init`
4. You can then create a new workspace that couples the two projects by executing the following command in the project folder `tapp`. The command is: `npm init -w capplugin --include-workspace-root`
5. Add `capapp` to `workspaces` section.
6. Change `package.json` in `capplugin` directory and change name to `@alphaoak/capplugin`
7. Change `package.json` in `capapp` directory and add `@alphaoak/capplugin` to dependencies
8. Change back to `t2` and run `npm i`
9. Validate that a symlink to `@alphaoak/capplugin` exists in `node_modules` directory

## 2. Start the plugin implementation
1. Create a file called `cds-plugin.js` with the following content
```javascript
const cds = require('@sap/cds')

const LOG = cds.log('recap-plugin')

cds.on('served', () => {
    LOG.info('*** Recap Plugin Loaded ***');
})
```
2. Test if the plugin is working when you start it up.
    1. Run `cds w` in the `capapp` directory and see if you get an output line like the following in the console:
    ```bash
    [recap-plugin] - *** Recap Plugin Loaded ***
    ```
3. Create the plugin data model by creating a file called `eam-core.cds` in the `[plugin]/db` folder
    ```cds
    namespace ao.recap;

    entity Jobs {
        key ID             : UUID;
            sapWorkOrderId : String(50);
            description    : String(500);
            effort         : Double;
            startedAt      : DateTime;
            finishedAt     : DateTime;
            createdAt      : DateTime;
            updatedAt      : DateTime;
    }
    ```
4. Create a default api service that exposes the data model
    ```cds
    using {ao.recap as recap} from '../db/eam-core';

    service ApiService {

        entity Jobs as projection on recap.Jobs;

    }
    ```
5. Combining all the data model pieces in an index.cds
    ```cds
    using from './db/eam-core';
    using from './srv/api';
    ```

## 3. Start the app implementation
1. Create the app data model supplmenting the core model defined in the plugin. Create a file in folder `db` of the application (not plugin) called `app-dbmodel.cds` 
```cds
namespace ao.recap;

using {ao.recap as eam} from '@alphaoak/recap-plugin';


entity SafetyInspections {
    key ID             : Integer;
        sapWorkOrderId : String(50);
        description    : String(500);
        status         : String(50);
        createdAt      : DateTime;
        updatedAt      : DateTime;
}


extend eam.Jobs with {
    extensionField    : String(50);
    safetyInspections : Association to many SafetyInspections
                            on $self.sapWorkOrderId = safetyInspections.sapWorkOrderId;
};

```

2. Create a new Admin Service by creating a new file `admin.cds` in the `srv` folder
```cds
using {ao.recap as eam }from '../db/app-dbmodel';

service AdminService{

    entity Jobs as projection on eam.Jobs;
    entity SafetyInspections as projection on eam.SafetyInspections;
}

```

3. Create some test data for entity SafetyInspections. 
    1. Create a file called `ao.recap-SafetyInspections.csv` in directory `test/data/`
    2. Paste the following content
    ```csv
    ID,sapWorkOrderId,description,status,createdAt,updatedAt
    1,8100001,Inspection of safety equipment,Completed,2023-01-01T10:00:00Z,2023-01-02T12:00:00Z
    2,8100001,Fire extinguisher check,In Progress,2023-01-03T14:00:00Z,2023-01-04T16:00:00Z
    3,8100002,Emergency exit inspection,Pending,2023-01-05T18:00:00Z,2023-01-06T20:00:00Z

    ```

4. Setup test
    1. Create folder `test/http`
    2. Create a file called `admin.http` with the following content
    ```http
    @server=http://localhost:4004
    @service=/odata/v4/admin

    ### Admin Service
    GET {{server}}{{service}}/Bla


    ### Admin Service
    GET {{server}}{{service}}/Jobs?$expand=safetyInspections

    ### Admin Service POST
    POST {{server}}{{service}}/Jobs
    Content-Type: application/json

    {
    "ID": "123",
    "sapWorkOrderId":"8100001",
    "description": "Test Job",
    "extensionField": "Extended Value"
    }
    ```

## Test the combination
1. Start watch with `cds w` in the application folder.
1. Execute the `POST` in the admin.http test file.
2. Execute the `GET` in the admin.http test file. The result should look like this: 
```http
HTTP/1.1 200 OK
X-Powered-By: Express
X-Correlation-ID: ae695a94-7730-4f04-88cd-45a76eb57bcb
OData-Version: 4.0
Content-Type: application/json; charset=utf-8
Content-Length: 592
Date: Mon, 07 Jul 2025 03:36:24 GMT
Connection: close

{
  "@odata.context": "$metadata#Jobs",
  "value": [
    {
      "ID": "123",
      "sapWorkOrderId": "8100001",
      "description": "Test Job",
      "effort": null,
      "startedAt": null,
      "finishedAt": null,
      "createdAt": null,
      "updatedAt": null,
      "extensionField": "Extended Value",
      "safetyInspections": [
        {
          "ID": 1,
          "sapWorkOrderId": "8100001",
          "description": "Inspection of safety equipment",
          "status": "Completed",
          "createdAt": "2023-01-01T10:00:00Z",
          "updatedAt": "2023-01-02T12:00:00Z"
        },
        {
          "ID": 2,
          "sapWorkOrderId": "8100001",
          "description": "Fire extinguisher check",
          "status": "In Progress",
          "createdAt": "2023-01-03T14:00:00Z",
          "updatedAt": "2023-01-04T16:00:00Z"
        }
      ]
    }
  ]
}
```
# Fiori apps in plugins
## Challenges
The current tooling from SAP does not allow you easily to make Fiori apps you have defined in a plugin in an overall application. The steps I took for making those apps available are the following. 

## Our current solution 
1. Create a directory with the same appname as the plugin in the application `app` directory
2. in that directory create a symlink with the name `symwebapp` that points to the `webapp` folder in the imported plugin directory (i.e. node_modules/[cds plugin package name]/app/[appname]/webapp)
3. Add xs-app.json file to the directory.
    1. Adjust the first route and change
        1. The destination name
        2. The route to the proper service
4. Create a new file called `ui5-deploy.yaml`
    1. copy the file
    2. Replace metadata/name with metadata/name from ui5.yaml
    3. In the custom task `ui5-task-zipper`, replace the configuration/archivename with the metadata/name stripped of all special characters.
5. Adjust package.json 
    1. Add this line to the scripts section of the package.json `build:cf": "ui5 build preload --clean-dest --config ui5-deploy.yaml --include-task=generateCachebusterInfo`
    2. Add devDependencies
        1. "@sap/ui5-builder-webide-extension": "^1.1.9",
        2. "ui5-task-zipper": "^3.3.1"

# i18n support
## Challenges
As a product developer I want to make sure that all text labels are language supported.

## Our current solution
We wrote a small tool that goes through the csn and checks if 
1. Are i18n placeholders specified where flexible texts are used.
2. Do we have a value for the placeholder in the i18n text files. 


