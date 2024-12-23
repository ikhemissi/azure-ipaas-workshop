const { app, input } = require('@azure/functions');

const cosmosInput = input.cosmosDB({
    databaseName: '%COSMOS_DB_DATABASE_NAME%',
    containerName: '%COSMOS_DB_CONTAINER_NAME%',
    connection: 'COSMOS_DB',
    sqlQuery: 'SELECT * FROM c ORDER BY c._ts DESC OFFSET 0 LIMIT 50',
});

app.http('FetchOrders', {
    methods: ['GET'],
    authLevel: 'anonymous',
    extraInputs: [cosmosInput],
    handler: async (request, context) => {
        let orders = [];
        context.log('Fetching orders...');

        // orders = context.extraInputs.get(cosmosInput);

        context.log(`Found ${orders?.length} orders...`);

        return {
            jsonBody: orders,
        };
    }
});
